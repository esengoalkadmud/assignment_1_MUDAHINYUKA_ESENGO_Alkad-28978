param(
    [switch]$Watch,
    [switch]$RunOnce,
    [int]$DebounceSeconds = 2,
    [string]$Branch = "main",
    [string]$CommitMessage = "Auto commit"
)

$ErrorActionPreference = 'Stop'

function Invoke-GitCommitPush {
    param(
        [string]$RepoRoot,
        [string]$Message,
        [string]$TargetBranch
    )

    $status = git -C $RepoRoot status --porcelain
    if ([string]::IsNullOrWhiteSpace($status)) {
        Write-Host "No changes to commit."
        return
    }

    Write-Host "Changes detected. Staging files..."
    git -C $RepoRoot add .

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $finalMessage = if ($Message -eq 'Auto commit') { "$Message - $timestamp" } else { $Message }

    try {
        git -C $RepoRoot commit -m $finalMessage | Out-Host
    }
    catch {
        Write-Host "Commit failed or there was nothing to commit."
        return
    }

    Write-Host "Pushing to origin/$TargetBranch..."
    git -C $RepoRoot push origin $TargetBranch
    Write-Host "Push complete."
}

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    throw "This folder is not a Git repository."
}

if ($RunOnce) {
    Invoke-GitCommitPush -RepoRoot $repoRoot -Message $CommitMessage -TargetBranch $Branch
    exit 0
}

if (-not $Watch) {
    Write-Host "Use -Watch to monitor changes, or -RunOnce to commit current changes once."
    exit 0
}

Write-Host "Watching for file changes in: $repoRoot"
Write-Host "Press Ctrl+C to stop."

$filter = '*'
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $repoRoot
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.Filter = $filter

$lastEvent = [DateTime]::MinValue
$locker = [System.Threading.Mutex]::new($false, 'AutoCommitMutex')

Register-ObjectEvent -InputObject $watcher -EventName 'Changed' -Action {
    $now = Get-Date
    if (($now - $lastEvent).TotalSeconds -lt $DebounceSeconds) { return }
    $lastEvent = $now

    try {
        $locker.WaitOne() | Out-Null
        Start-Sleep -Seconds $DebounceSeconds
        $status = git -C $repoRoot status --porcelain
        if (-not [string]::IsNullOrWhiteSpace($status)) {
            Write-Host "Detected file change at $($now.ToString('yyyy-MM-dd HH:mm:ss'))."
            Invoke-GitCommitPush -RepoRoot $repoRoot -Message $CommitMessage -TargetBranch $Branch
        }
    }
    finally {
        $locker.ReleaseMutex()
    }
} | Out-Null

Register-ObjectEvent -InputObject $watcher -EventName 'Created' -Action {
    $now = Get-Date
    if (($now - $lastEvent).TotalSeconds -lt $DebounceSeconds) { return }
    $lastEvent = $now

    try {
        $locker.WaitOne() | Out-Null
        Start-Sleep -Seconds $DebounceSeconds
        $status = git -C $repoRoot status --porcelain
        if (-not [string]::IsNullOrWhiteSpace($status)) {
            Write-Host "Detected file creation at $($now.ToString('yyyy-MM-dd HH:mm:ss'))."
            Invoke-GitCommitPush -RepoRoot $repoRoot -Message $CommitMessage -TargetBranch $Branch
        }
    }
    finally {
        $locker.ReleaseMutex()
    }
} | Out-Null

Register-ObjectEvent -InputObject $watcher -EventName 'Deleted' -Action {
    $now = Get-Date
    if (($now - $lastEvent).TotalSeconds -lt $DebounceSeconds) { return }
    $lastEvent = $now

    try {
        $locker.WaitOne() | Out-Null
        Start-Sleep -Seconds $DebounceSeconds
        $status = git -C $repoRoot status --porcelain
        if (-not [string]::IsNullOrWhiteSpace($status)) {
            Write-Host "Detected file deletion at $($now.ToString('yyyy-MM-dd HH:mm:ss'))."
            Invoke-GitCommitPush -RepoRoot $repoRoot -Message $CommitMessage -TargetBranch $Branch
        }
    }
    finally {
        $locker.ReleaseMutex()
    }
} | Out-Null

while ($true) {
    Start-Sleep -Seconds 5
}
