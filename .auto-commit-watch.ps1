param(
    [switch]$Watch,
    [switch]$RunOnce,
    [string]$Branch = "main",
    [string]$CommitMessage = "Auto commit"
)

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { throw "This folder is not a Git repository." }

function Invoke-AutoPush {
    $status = git -C $repoRoot status --porcelain
    if ([string]::IsNullOrWhiteSpace($status)) {
        Write-Host "No changes to commit."
        return
    }

    git -C $repoRoot add .
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $msg = if ($CommitMessage -eq 'Auto commit') { "Auto commit - $timestamp" } else { $CommitMessage }

    git -C $repoRoot commit -m $msg | Out-Host
    git -C $repoRoot pull --rebase origin $Branch | Out-Host
    git -C $repoRoot push origin $Branch | Out-Host
    Write-Host "Push complete."
}

if ($RunOnce) {
    Invoke-AutoPush
    exit 0
}

if (-not $Watch) {
    Write-Host "Use -Watch or -RunOnce."
    exit 0
}

Write-Host "Watching $repoRoot ..."
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $repoRoot
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.Filter = '*'

$syncLock = [System.Threading.Mutex]::new($false, 'AutoPushLock')

Register-ObjectEvent -InputObject $watcher -EventName Changed -Action {
    try {
        $syncLock.WaitOne() | Out-Null
        Start-Sleep -Seconds 2
        Invoke-AutoPush
    }
    finally { $syncLock.ReleaseMutex() }
} | Out-Null

Register-ObjectEvent -InputObject $watcher -EventName Created -Action {
    try {
        $syncLock.WaitOne() | Out-Null
        Start-Sleep -Seconds 2
        Invoke-AutoPush
    }
    finally { $syncLock.ReleaseMutex() }
} | Out-Null

while ($true) { Start-Sleep -Seconds 5 }
