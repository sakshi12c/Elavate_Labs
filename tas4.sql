# SQL Aggregate Functions & Grouping - Complete Guide

## Overview
Aggregate functions perform calculations on multiple rows and return a single result. They're essential for data analysis and reporting.

---

## 1. Basic Aggregate Functions

### COUNT - Count rows
```sql
-- Count all rows
SELECT COUNT(*) AS total_orders
FROM orders;

-- Count non-null values in a column
SELECT COUNT(customer_id) AS customers_with_orders
FROM orders;

-- Count distinct values
SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM orders;
```

### SUM - Add up values
```sql
-- Total revenue
SELECT SUM(amount) AS total_revenue
FROM orders;

-- Sum with condition (using CASE)
SELECT SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END) AS completed_revenue
FROM orders;
```

### AVG - Calculate average
```sql
-- Average order value
SELECT AVG(amount) AS average_order_value
FROM orders;

-- Average excluding nulls (AVG automatically excludes nulls)
SELECT AVG(rating) AS average_rating
FROM product_reviews;
```

### MIN and MAX - Find extremes
```sql
-- Oldest and newest orders
SELECT 
    MIN(order_date) AS first_order,
    MAX(order_date) AS latest_order
FROM orders;

-- Price range
SELECT 
    MIN(price) AS lowest_price,
    MAX(price) AS highest_price
FROM products;
```

---

## 2. GROUP BY - Categorizing Data

### Basic Grouping
```sql
-- Total sales by product
SELECT 
    product_id,
    SUM(quantity) AS total_quantity_sold,
    SUM(amount) AS total_revenue
FROM order_items
GROUP BY product_id;

-- Orders per customer
SELECT 
    customer_id,
    COUNT(*) AS order_count,
    AVG(amount) AS avg_order_value
FROM orders
GROUP BY customer_id;
```

### Multiple Column Grouping
```sql
-- Sales by product and month
SELECT 
    product_id,
    STRFTIME('%Y-%m', order_date) AS month,
    SUM(amount) AS monthly_revenue
FROM orders
GROUP BY product_id, STRFTIME('%Y-%m', order_date)
ORDER BY product_id, month;

-- Customer orders by status
SELECT 
    customer_id,
    status,
    COUNT(*) AS order_count
FROM orders
GROUP BY customer_id, status;
```

---

## 3. HAVING - Filter Grouped Results

The `WHERE` clause filters rows **before** grouping.  
The `HAVING` clause filters groups **after** aggregation.

### Basic HAVING Examples
```sql
-- Customers with more than 5 orders
SELECT 
    customer_id,
    COUNT(*) AS order_count
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 5;

-- Products with average rating above 4.0
SELECT 
    product_id,
    AVG(rating) AS avg_rating,
    COUNT(*) AS review_count
FROM reviews
GROUP BY product_id
HAVING AVG(rating) > 4.0;
```

### Combining WHERE and HAVING
```sql
-- High-value customers in 2024 (total spent > $1000)
SELECT 
    customer_id,
    COUNT(*) AS order_count,
    SUM(amount) AS total_spent
FROM orders
WHERE STRFTIME('%Y', order_date) = '2024'
GROUP BY customer_id
HAVING SUM(amount) > 1000
ORDER BY total_spent DESC;
```

---

## 4. Practical Real-World Examples

### Example 1: Sales Report
```sql
-- Monthly sales summary
SELECT 
    STRFTIME('%Y-%m', order_date) AS month,
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(amount) AS revenue,
    AVG(amount) AS avg_order_value,
    MIN(amount) AS min_order,
    MAX(amount) AS max_order
FROM orders
WHERE status = 'completed'
GROUP BY STRFTIME('%Y-%m', order_date)
ORDER BY month DESC;
```

### Example 2: Product Performance Analysis
```sql
-- Top performing products (by revenue)
SELECT 
    p.product_name,
    p.category,
    COUNT(oi.order_id) AS times_ordered,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.quantity * oi.price) AS total_revenue,
    AVG(oi.price) AS avg_selling_price
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category
HAVING SUM(oi.quantity * oi.price) > 5000
ORDER BY total_revenue DESC
LIMIT 10;
```

### Example 3: Customer Segmentation
```sql
-- Categorize customers by spending
SELECT 
    CASE 
        WHEN total_spent >= 5000 THEN 'Premium'
        WHEN total_spent >= 1000 THEN 'Regular'
        ELSE 'Occasional'
    END AS customer_segment,
    COUNT(*) AS customer_count,
    AVG(total_spent) AS avg_spending,
    SUM(total_spent) AS segment_revenue
FROM (
    SELECT 
        customer_id,
        SUM(amount) AS total_spent
    FROM orders
    GROUP BY customer_id
) customer_totals
GROUP BY customer_segment
ORDER BY avg_spending DESC;
```

### Example 4: Inventory Analysis
```sql
-- Products needing restock (low stock, high demand)
SELECT 
    p.product_id,
    p.product_name,
    p.stock_quantity,
    COUNT(oi.order_id) AS orders_last_30_days,
    SUM(oi.quantity) AS units_sold_last_30_days,
    AVG(oi.quantity) AS avg_order_quantity
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_date >= DATE('now', '-30 days') OR o.order_date IS NULL
GROUP BY p.product_id, p.product_name, p.stock_quantity
HAVING p.stock_quantity < AVG(oi.quantity) * 10
ORDER BY units_sold_last_30_days DESC;
```

---

## 5. Common Patterns & Best Practices

### Pattern 1: Rolling Aggregations
```sql
-- Year-over-year comparison
SELECT 
    STRFTIME('%Y', order_date) AS year,
    COUNT(*) AS orders,
    SUM(amount) AS revenue,
    AVG(amount) AS avg_order_value
FROM orders
GROUP BY STRFTIME('%Y', order_date)
ORDER BY year;
```

### Pattern 2: Percentage Calculations
```sql
-- Category distribution (percentage of total sales)
SELECT 
    category,
    COUNT(*) AS product_count,
    SUM(quantity_sold) AS units_sold,
    ROUND(SUM(quantity_sold) * 100.0 / (SELECT SUM(quantity_sold) FROM products), 2) AS percentage_of_total
FROM products
GROUP BY category
ORDER BY units_sold DESC;
```

### Pattern 3: Finding Top N per Group
```sql
-- Top 3 products per category by revenue
SELECT *
FROM (
    SELECT 
        category,
        product_name,
        revenue,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank
    FROM (
        SELECT 
            p.category,
            p.product_name,
            SUM(oi.quantity * oi.price) AS revenue
        FROM products p
        JOIN order_items oi ON p.product_id = oi.product_id
        GROUP BY p.category, p.product_name
    )
)
WHERE rank <= 3;
```

---

## 6. Interview Practice Questions

### Question 1: Basic Aggregation
**Find the total number of orders, total revenue, and average order value.**
```sql
SELECT 
    COUNT(*) AS total_orders,
    SUM(amount) AS total_revenue,
    AVG(amount) AS avg_order_value
FROM orders;
```

### Question 2: Grouping
**Show the number of orders and total revenue per customer.**
```sql
SELECT 
    customer_id,
    COUNT(*) AS order_count,
    SUM(amount) AS total_revenue
FROM orders
GROUP BY customer_id
ORDER BY total_revenue DESC;
```

### Question 3: HAVING Clause
**Find customers who have placed more than 3 orders and spent over $500.**
```sql
SELECT 
    customer_id,
    COUNT(*) AS order_count,
    SUM(amount) AS total_spent
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 3 AND SUM(amount) > 500;
```

### Question 4: Complex Analysis
**Find the top 5 products by revenue, showing product name, units sold, and total revenue.**
```sql
SELECT 
    p.product_name,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.quantity * oi.price) AS total_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 5;
```

### Question 5: Date-based Grouping
**Calculate monthly revenue for the year 2024.**
```sql
SELECT 
    STRFTIME('%Y-%m', order_date) AS month,
    COUNT(*) AS order_count,
    SUM(amount) AS monthly_revenue
FROM orders
WHERE STRFTIME('%Y', order_date) = '2024'
GROUP BY month
ORDER BY month;
```

---

## 7. Common Mistakes to Avoid

1. **Using non-aggregated columns without GROUP BY**
   ```sql
   -- WRONG
   SELECT customer_id, product_id, SUM(amount)
   FROM orders;
   
   -- CORRECT
   SELECT customer_id, product_id, SUM(amount)
   FROM orders
   GROUP BY customer_id, product_id;
   ```

2. **Using WHERE instead of HAVING for aggregates**
   ```sql
   -- WRONG
   SELECT customer_id, COUNT(*)
   FROM orders
   WHERE COUNT(*) > 5
   GROUP BY customer_id;
   
   -- CORRECT
   SELECT customer_id, COUNT(*)
   FROM orders
   GROUP BY customer_id
   HAVING COUNT(*) > 5;
   ```

3. **Forgetting COUNT(*) counts nulls, but COUNT(column) doesn't**
   ```sql
   -- COUNT(*) includes all rows
   SELECT COUNT(*) FROM orders;
   
   -- COUNT(column) excludes NULL values
   SELECT COUNT(customer_id) FROM orders;
   ```

---

## 8. Summary Cheat Sheet

| Function | Purpose | Example |
|----------|---------|---------|
| `COUNT()` | Count rows | `COUNT(*)` or `COUNT(column)` |
| `SUM()` | Add values | `SUM(amount)` |
| `AVG()` | Calculate average | `AVG(price)` |
| `MIN()` | Find minimum | `MIN(order_date)` |
| `MAX()` | Find maximum | `MAX(quantity)` |
| `GROUP BY` | Categorize data | `GROUP BY customer_id` |
| `HAVING` | Filter groups | `HAVING COUNT(*) > 5` |

**Key Concept**: WHERE filters rows → GROUP BY groups rows → HAVING filters groups → ORDER BY sorts results

---

## Practice Exercise

Create a comprehensive sales report that shows:
- Monthly trends
- Customer segments
- Product performance
- Revenue analysis

Try building this step by step using the patterns above!