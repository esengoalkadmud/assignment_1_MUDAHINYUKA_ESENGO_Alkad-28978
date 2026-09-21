# SQL JOINs & Window Functions Project
Course : INSY 8311 Database Development with PL/SQL

Student : MUDAHINYUKA ESENGO Alkad 

StudentId : 28978

Group I

Instructor: Eric Maniraguha




## 1. Problem Definition

### Business Scenario
This project is based on a SuperMarket business that sells various products to customers. Management wants to understand who their customers are, what they are buying, and how sales are trending over time. I built this database and wrote queries to answer those business questions.


### Outcome
The DB should help identify top selling products, understand customer purchasing behavior, and track sales trends to support better business decisions.


## 2. Success Criteria

## JOIN Queries

### Query 1: List every order with the customer's name, city, and order date (INNER JOIN)
**Explanation:** SELECT o.order_id, c.customer_name, c.city, o.order_date
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id;.This query uses an INNER JOIN to connect the orders table and the customers table on the customer_id. It shows us who placed each order and where they live.
<img width="743" height="745" alt="1" src="https://github.com/user-attachments/assets/183a1ec8-eb3c-43de-910b-ee77c08c9be0" />


### Query 2: List every order item with product name, category, price, and quantity (JOIN)
**Explanation:** SELECT oi.order_item_id, p.product_name, p.category, p.price, oi.quantity
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id; This joins the order_items table with the products table so we can see exactly what products were bought in each order, along with their price and category.
<img width="714" height="747" alt="2" src="https://github.com/user-attachments/assets/613bb138-3d27-4d97-aef8-96e530b7a39c" />


### Query 3: List all customers and their orders where they exist, including customers with no orders (LEFT JOIN)
**Explanation:** SELECT c.customer_name, o.order_id, o.order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;
 I used a LEFT JOIN here because management wanted to see all customers, even the ones who haven't placed any orders yet. If a customer has no order, the order columns just show up as empty.
<img width="795" height="718" alt="3" src="https://github.com/user-attachments/assets/445db5c5-7c9c-4fda-bf45-1f943b88c31f" />



## CTE Query

### Query 1: Calculate each customer's total spend and return customers above average spend
**Explanation:** WITH CustomerSpend AS (
    SELECT c.customer_id, c.customer_name, SUM(p.price * oi.quantity) AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT customer_name, total_spend
FROM CustomerSpend
WHERE total_spend > (SELECT AVG(total_spend) FROM CustomerSpend);
Its the long one among, I used a Common Table Expression (CTE) to first calculate how much each customer spent in total. Then, I selected only the customers whose total spend was higher than the average spend of everyone.
<img width="893" height="641" alt="CTE" src="https://github.com/user-attachments/assets/3dc1ee72-2099-45f1-96b1-29cc116fbb5e" />



## Window-Function Queries

### Query 1: Rank customers by total amount spent, highest first
**Explanation:** SELECT c.customer_name, SUM(p.price * oi.quantity) AS total_spent,
       RANK() OVER (ORDER BY SUM(p.price * oi.quantity) DESC) as spend_rank
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.customer_name;
This query uses the RANK() window function to give a ranking number to each customer based on how much money they spent, with the highest spender getting rank 1.
<img width="733" height="718" alt="4" src="https://github.com/user-attachments/assets/2f1892b2-fbeb-4483-9468-966d71977a6d" />


### Query 2: Number each customer's orders in the order placed
**Explanation:** SELECT customer_id, order_id, order_date,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date ASC) as order_sequence
FROM orders;
I used ROW_NUMBER() partitioned by the customer to number their orders chronologically. It shows whether an order was their 1st, 2nd, 3rd, etc.
<img width="874" height="745" alt="5" src="https://github.com/user-attachments/assets/219959a9-83b1-4fe1-b2e3-d624902633b2" />


### Query 3: Show a running total of revenue over time, ordered by order date
**Explanation:** SELECT o.order_date, SUM(p.price * oi.quantity) as daily_revenue,
       SUM(SUM(p.price * oi.quantity)) OVER (ORDER BY o.order_date ASC) as running_total
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY o.order_date
ORDER BY o.order_date;
This uses SUM() OVER to calculate a running total. It adds up the daily revenue as we go through the dates, showing the cumulative total revenue over time.
<img width="801" height="748" alt="6" src="https://github.com/user-attachments/assets/20e17c80-ccd4-40a7-be64-c0ddfa131d6b" />


### Query 4: For each customer with more than one order, show days between the current and previous order
**Explanation:** WITH OrderDates AS (
    SELECT customer_id, order_date,
           LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) as prev_order_date
    FROM orders
)
SELECT customer_id, order_date, prev_order_date,
       (order_date - prev_order_date) as days_between_orders
FROM OrderDates
WHERE prev_order_date IS NOT NULL;
I used the LAG() window function to look at the previous order date for each customer. Then I subtracted it from the current order date to see how many days passed between their orders.
<img width="884" height="757" alt="7" src="https://github.com/user-attachments/assets/656328b9-812c-4011-b69f-c5c724250c78" />




## 3. Database Schema Design

For this project, I designed a relational database made up of 4 related tables: **customers**, **products**, and **orders**, **products**. The **customers** table stores customer information such as name and region, while the **products** table stores product details like category and price.

Each table contains a **primary key** to uniquely identify records. The **orders_items** table includes **foreign keys** (`order_id` and `product_id`) that reference the **customers** and **products** tables. These relationships ensure data integrity and allow the use of SQL JOIN operations for analysis. The schema structure supports reporting, sales tracking, and window function queries used in this project.




## 4. Entity Relationship Diagram (ERD)

<img width="555" height="711" alt="Screenshot 2026-09-21 022158" src="https://github.com/user-attachments/assets/dae009ad-a6cb-452f-9cbb-eab28bad928e" />




## Results Analysis

### Diagnostic
This pattern occurs because certain products are consistently purchased across multiple regions, and a small group of loyal customers contributes significantly to total sales revenue.

### Prescriptive
The business should prioritize stocking and promoting high  performing products, build loyalty programs for repeat customers, and review pricing or promotion strategies for low selling products.

---

## References
PostgreSQL Official Documentation  
Pgadmin4 Window Functions Documentation  

---

## Integrity Statement
All sources were properly cited. Implementations and analysis represent original work. No AI generated content was copied without attribution or adaptation. <br>
## **And sorry for Some unnecessary file created  on this repository, Am new on this platform, am trying things and things - - -Thanks!!!**