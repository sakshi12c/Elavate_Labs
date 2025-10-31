-- ============================================
-- Task 7: Creating Views
-- ============================================

-- Step 1: Create Database and Tables
-- ============================================
CREATE DATABASE IF NOT EXISTS business_db;
USE business_db;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS employees;

-- Customers Table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    city VARCHAR(50),
    country VARCHAR(50),
    registration_date DATE
);

-- Products Table
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100),
    category VARCHAR(50),
    unit_price DECIMAL(10, 2),
    stock_quantity INT,
    supplier VARCHAR(100)
);

-- Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10, 2),
    status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Order Items Table
CREATE TABLE order_items (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Employees Table
CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10, 2),
    hire_date DATE,
    manager_id INT
);


-- Insert Sample Data
-- ============================================

-- Insert Customers
INSERT INTO customers (first_name, last_name, email, phone, city, country, registration_date)
VALUES 
('Alice', 'Johnson', 'alice.j@email.com', '555-0101', 'New York', 'USA', '2023-01-15'),
('Bob', 'Smith', 'bob.s@email.com', '555-0102', 'London', 'UK', '2023-02-20'),
('Carol', 'Williams', 'carol.w@email.com', '555-0103', 'Toronto', 'Canada', '2023-03-10'),
('David', 'Brown', 'david.b@email.com', '555-0104', 'Sydney', 'Australia', '2023-04-05'),
('Emma', 'Davis', 'emma.d@email.com', '555-0105', 'New York', 'USA', '2023-05-12');

-- Insert Products
INSERT INTO products (product_name, category, unit_price, stock_quantity, supplier)
VALUES 
('Laptop Pro', 'Electronics', 1200.00, 50, 'Tech Suppliers Inc'),
('Wireless Mouse', 'Electronics', 25.00, 200, 'Tech Suppliers Inc'),
('Office Chair', 'Furniture', 350.00, 30, 'Furniture World'),
('Desk Lamp', 'Furniture', 45.00, 100, 'Lighting Co'),
('USB Cable', 'Electronics', 10.00, 500, 'Tech Suppliers Inc'),
('Monitor 27inch', 'Electronics', 400.00, 75, 'Tech Suppliers Inc'),
('Keyboard', 'Electronics', 80.00, 150, 'Tech Suppliers Inc');

-- Insert Orders
INSERT INTO orders (customer_id, order_date, total_amount, status)
VALUES 
(1, '2024-01-10', 1245.00, 'Completed'),
(2, '2024-01-15', 445.00, 'Completed'),
(1, '2024-02-20', 80.00, 'Completed'),
(3, '2024-03-05', 1650.00, 'Shipped'),
(4, '2024-03-12', 425.00, 'Processing'),
(5, '2024-04-01', 90.00, 'Completed'),
(2, '2024-04-10', 800.00, 'Shipped');

-- Insert Order Items
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES 
(1, 1, 1, 1200.00),
(1, 2, 1, 25.00),
(1, 5, 2, 10.00),
(2, 6, 1, 400.00),
(2, 4, 1, 45.00),
(3, 7, 1, 80.00),
(4, 1, 1, 1200.00),
(4, 3, 1, 350.00),
(4, 4, 2, 45.00),
(5, 6, 1, 400.00),
(5, 2, 1, 25.00),
(6, 2, 2, 25.00),
(6, 5, 4, 10.00),
(7, 6, 2, 400.00);

-- Insert Employees
INSERT INTO employees (first_name, last_name, email, department, salary, hire_date, manager_id)
VALUES 
('John', 'Manager', 'john.m@company.com', 'Sales', 85000.00, '2020-01-15', NULL),
('Sarah', 'Lead', 'sarah.l@company.com', 'IT', 95000.00, '2019-06-20', NULL),
('Mike', 'Developer', 'mike.d@company.com', 'IT', 75000.00, '2021-03-10', 2),
('Lisa', 'Sales Rep', 'lisa.s@company.com', 'Sales', 65000.00, '2022-02-01', 1),
('Tom', 'Analyst', 'tom.a@company.com', 'IT', 70000.00, '2021-08-15', 2);


-- ============================================
-- CREATING VIEWS
-- ============================================

-- View 1: Customer Order Summary (Complex SELECT with JOINs and Aggregation)
-- Purpose: Abstraction - Simplifies complex query for business users
-- ============================================
CREATE OR REPLACE VIEW vw_customer_order_summary AS
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    c.city,
    c.country,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent,
    AVG(o.total_amount) AS average_order_value,
    MAX(o.order_date) AS last_order_date,
    CASE 
        WHEN SUM(o.total_amount) > 1000 THEN 'Premium'
        WHEN SUM(o.total_amount) > 500 THEN 'Gold'
        ELSE 'Silver'
    END AS customer_tier
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.city, c.country;


-- View 2: Product Sales Analysis (Complex Aggregation)
-- Purpose: Business Intelligence - Track product performance
-- ============================================
CREATE OR REPLACE VIEW vw_product_sales_analysis AS
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price AS current_price,
    p.stock_quantity,
    COALESCE(SUM(oi.quantity), 0) AS total_units_sold,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_revenue,
    COALESCE(COUNT(DISTINCT oi.order_id), 0) AS number_of_orders,
    CASE 
        WHEN COALESCE(SUM(oi.quantity), 0) > 5 THEN 'Best Seller'
        WHEN COALESCE(SUM(oi.quantity), 0) > 2 THEN 'Popular'
        WHEN COALESCE(SUM(oi.quantity), 0) > 0 THEN 'Moderate'
        ELSE 'No Sales'
    END AS sales_category
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category, p.unit_price, p.stock_quantity;


-- View 3: Order Details (Complete Order Information)
-- Purpose: Abstraction - Single view for complete order info
-- ============================================
CREATE OR REPLACE VIEW vw_order_details AS
SELECT 
    o.order_id,
    o.order_date,
    o.status,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email AS customer_email,
    c.city,
    c.country,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS line_total,
    o.total_amount AS order_total
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id;


-- View 4: Employee Salary Information (Security/Restricted View)
-- Purpose: Security - Hide sensitive salary data, show only department summaries
-- ============================================
CREATE OR REPLACE VIEW vw_employee_public_info AS
SELECT 
    employee_id,
    CONCAT(first_name, ' ', last_name) AS employee_name,
    email,
    department,
    hire_date,
    YEAR(CURDATE()) - YEAR(hire_date) AS years_of_service,
    CASE 
        WHEN salary >= 90000 THEN 'Senior Level'
        WHEN salary >= 70000 THEN 'Mid Level'
        ELSE 'Entry Level'
    END AS salary_band
FROM employees;
-- Note: Actual salary is hidden for security


-- View 5: Department Statistics (Aggregation for Management)
-- Purpose: Abstraction - Quick department overview
-- ============================================
CREATE OR REPLACE VIEW vw_department_statistics AS
SELECT 
    department,
    COUNT(*) AS employee_count,
    AVG(salary) AS average_salary,
    MIN(salary) AS min_salary,
    MAX(salary) AS max_salary,
    SUM(salary) AS total_payroll,
    AVG(YEAR(CURDATE()) - YEAR(hire_date)) AS avg_years_service
FROM employees
GROUP BY department;


-- View 6: High Value Customers (Filtered View)
-- Purpose: Security & Business Logic - Only show premium customers
-- ============================================
CREATE OR REPLACE VIEW vw_high_value_customers AS
SELECT 
    customer_id,
    customer_name,
    email,
    total_orders,
    total_spent,
    customer_tier
FROM vw_customer_order_summary
WHERE total_spent > 500;


-- View 7: Low Stock Alert (Business Logic)
-- Purpose: Operational - Inventory management
-- ============================================
CREATE OR REPLACE VIEW vw_low_stock_alert AS
SELECT 
    product_id,
    product_name,
    category,
    stock_quantity,
    total_units_sold,
    CASE 
        WHEN stock_quantity < 50 THEN 'Critical - Reorder Now'
        WHEN stock_quantity < 100 THEN 'Low - Monitor Closely'
        ELSE 'Adequate'
    END AS stock_status
FROM vw_product_sales_analysis
WHERE stock_quantity < 100
ORDER BY stock_quantity ASC;


-- ============================================
-- USING VIEWS - EXAMPLES
-- ============================================

-- Example 1: Query the Customer Order Summary View
SELECT * FROM vw_customer_order_summary;

-- Example 2: Find Premium Customers
SELECT 
    customer_name,
    email,
    total_spent,
    customer_tier
FROM vw_customer_order_summary
WHERE customer_tier = 'Premium'
ORDER BY total_spent DESC;

-- Example 3: Product Performance Analysis
SELECT * FROM vw_product_sales_analysis
ORDER BY total_revenue DESC;

-- Example 4: Find Best Selling Products
SELECT 
    product_name,
    category,
    total_units_sold,
    total_revenue
FROM vw_product_sales_analysis
WHERE sales_category = 'Best Seller';

-- Example 5: View All Order Details
SELECT * FROM vw_order_details
ORDER BY order_date DESC;

-- Example 6: Orders from Specific Country
SELECT 
    order_id,
    customer_name,
    country,
    product_name,
    quantity,
    line_total
FROM vw_order_details
WHERE country = 'USA';

-- Example 7: Employee Information (No Salary Exposed)
SELECT * FROM vw_employee_public_info;

-- Example 8: Department Statistics
SELECT * FROM vw_department_statistics
ORDER BY total_payroll DESC;

-- Example 9: High Value Customers Only
SELECT * FROM vw_high_value_customers
ORDER BY total_spent DESC;

-- Example 10: Low Stock Products
SELECT * FROM vw_low_stock_alert;


-- ============================================
-- ADVANCED VIEW USAGE
-- ============================================

-- Join Views with Tables
SELECT 
    v.customer_name,
    v.total_spent,
    o.order_date,
    o.status
FROM vw_customer_order_summary v
INNER JOIN orders o ON v.customer_id = o.customer_id
WHERE o.status = 'Shipped';

-- Aggregate Data from Views
SELECT 
    country,
    COUNT(*) AS customer_count,
    SUM(total_spent) AS country_revenue
FROM vw_customer_order_summary
GROUP BY country
ORDER BY country_revenue DESC;

-- Filter Electronics Products Only
SELECT * FROM vw_product_sales_analysis
WHERE category = 'Electronics'
ORDER BY total_revenue DESC;


-- ============================================
-- VIEW MANAGEMENT COMMANDS
-- ============================================

-- Show all views in database
SHOW FULL TABLES WHERE Table_type = 'VIEW';

-- View the definition of a view
SHOW CREATE VIEW vw_customer_order_summary;

-- Modify existing view (use CREATE OR REPLACE)
CREATE OR REPLACE VIEW vw_customer_order_summary AS
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email;

-- Drop a view
-- DROP VIEW IF EXISTS vw_customer_order_summary;


-- ============================================
-- BENEFITS DEMONSTRATION
-- ============================================

-- Without View: Complex query every time
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;

-- With View: Simple query
SELECT customer_name, total_orders, total_spent 
FROM vw_customer_order_summary;


-- ============================================
-- SECURITY EXAMPLE
-- ============================================

-- Administrators can see full employee table with salaries
SELECT * FROM employees;

-- Regular users only see the view without salary information
SELECT * FROM vw_employee_public_info;

-- Business users can see department totals without individual salaries
SELECT * FROM vw_department_statistics;


