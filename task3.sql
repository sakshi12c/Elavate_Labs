-- ============================================
-- BASIC SELECT QUERIES - COMPREHENSIVE GUIDE
-- ============================================

-- Sample data context: We'll use a typical database with tables like:
-- employees(id, name, department, salary, hire_date, email)
-- products(id, product_name, category, price, stock_quantity)
-- orders(id, customer_name, order_date, total_amount, status)


-- ============================================
-- 1. BASIC SELECT STATEMENTS
-- ============================================

-- Select all columns from a table
SELECT * FROM employees;

-- Select specific columns
SELECT name, department, salary FROM employees;

-- Select with column aliases for better readability
SELECT 
    name AS employee_name,
    salary AS annual_salary,
    department AS dept
FROM employees;

-- Select distinct values (remove duplicates)
SELECT DISTINCT department FROM employees;

-- Select with calculated columns
SELECT 
    name,
    salary,
    salary * 12 AS yearly_salary,
    salary / 12 AS monthly_salary
FROM employees;


-- ============================================
-- 2. WHERE CLAUSE - FILTERING DATA
-- ============================================

-- Simple equality condition
SELECT * FROM employees
WHERE department = 'Sales';

-- Numeric comparisons
SELECT name, salary FROM employees
WHERE salary > 50000;

SELECT name, salary FROM employees
WHERE salary <= 60000;

-- Not equal to
SELECT * FROM employees
WHERE department != 'IT';
-- OR
SELECT * FROM employees
WHERE department <> 'IT';

-- String pattern matching with LIKE
-- % matches any sequence of characters
-- _ matches any single character

SELECT * FROM employees
WHERE name LIKE 'J%';  -- Names starting with J

SELECT * FROM employees
WHERE email LIKE '%@gmail.com';  -- Gmail addresses

SELECT * FROM employees
WHERE name LIKE '_a%';  -- Second letter is 'a'

SELECT * FROM products
WHERE product_name LIKE '%phone%';  -- Contains 'phone'

-- Case-insensitive search (depends on database)
SELECT * FROM employees
WHERE LOWER(name) LIKE '%smith%';


-- ============================================
-- 3. LOGICAL OPERATORS - AND, OR, NOT
-- ============================================

-- AND - all conditions must be true
SELECT * FROM employees
WHERE department = 'Sales' 
  AND salary > 55000;

SELECT * FROM products
WHERE category = 'Electronics' 
  AND price < 500 
  AND stock_quantity > 10;

-- OR - at least one condition must be true
SELECT * FROM employees
WHERE department = 'Sales' 
   OR department = 'Marketing';

SELECT * FROM products
WHERE category = 'Electronics' 
   OR category = 'Computers';

-- Combining AND & OR (use parentheses for clarity)
SELECT * FROM employees
WHERE (department = 'Sales' OR department = 'Marketing')
  AND salary > 50000;

SELECT * FROM products
WHERE category = 'Electronics'
  AND (price < 100 OR stock_quantity > 50);

-- NOT operator
SELECT * FROM employees
WHERE NOT department = 'IT';

SELECT * FROM products
WHERE NOT (price > 1000);


-- ============================================
-- 4. BETWEEN - RANGE CONDITIONS
-- ============================================

-- Numeric range (inclusive)
SELECT * FROM employees
WHERE salary BETWEEN 40000 AND 60000;

-- Equivalent to:
SELECT * FROM employees
WHERE salary >= 40000 AND salary <= 60000;

-- Date range
SELECT * FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31';

-- NOT BETWEEN
SELECT * FROM products
WHERE price NOT BETWEEN 100 AND 500;


-- ============================================
-- 5. IN OPERATOR - MULTIPLE VALUES
-- ============================================

-- Check if value exists in a list
SELECT * FROM employees
WHERE department IN ('Sales', 'Marketing', 'HR');

-- Much cleaner than:
SELECT * FROM employees
WHERE department = 'Sales' 
   OR department = 'Marketing' 
   OR department = 'HR';

-- Numeric values
SELECT * FROM products
WHERE id IN (1, 5, 10, 15, 20);

-- NOT IN
SELECT * FROM employees
WHERE department NOT IN ('IT', 'Finance');


-- ============================================
-- 6. NULL VALUES
-- ============================================

-- Find NULL values
SELECT * FROM employees
WHERE email IS NULL;

-- Find non-NULL values
SELECT * FROM employees
WHERE email IS NOT NULL;

-- Note: You cannot use = or != with NULL
-- Wrong: WHERE email = NULL
-- Correct: WHERE email IS NULL


-- ============================================
-- 7. ORDER BY - SORTING RESULTS
-- ============================================

-- Sort ascending (default)
SELECT * FROM employees
ORDER BY salary;

-- Sort ascending (explicit)
SELECT * FROM employees
ORDER BY salary ASC;

-- Sort descending
SELECT * FROM employees
ORDER BY salary DESC;

-- Sort by multiple columns
SELECT * FROM employees
ORDER BY department ASC, salary DESC;

-- Sort by column position (not recommended, but possible)
SELECT name, department, salary FROM employees
ORDER BY 3 DESC;  -- Sorts by 3rd column (salary)

-- Sort with expression
SELECT name, salary, salary * 12 AS yearly_salary
FROM employees
ORDER BY salary * 12 DESC;


-- ============================================
-- 8. LIMIT - RESTRICTING NUMBER OF ROWS
-- ============================================

-- Get first 10 rows
SELECT * FROM employees
LIMIT 10;

-- Top 5 highest salaries
SELECT name, salary FROM employees
ORDER BY salary DESC
LIMIT 5;

-- OFFSET - skip rows (pagination)
SELECT * FROM products
LIMIT 10 OFFSET 20;  -- Skip first 20, get next 10

-- Alternative syntax (MySQL)
SELECT * FROM products
LIMIT 20, 10;  -- Skip 20, get 10


-- ============================================
-- 9. PRACTICAL EXAMPLES
-- ============================================

-- Example 1: Find all employees in Sales earning more than 55k
SELECT name, department, salary
FROM employees
WHERE department = 'Sales' 
  AND salary > 55000
ORDER BY salary DESC;

-- Example 2: Find products low on stock
SELECT product_name, stock_quantity, price
FROM products
WHERE stock_quantity < 20
ORDER BY stock_quantity ASC
LIMIT 10;

-- Example 3: Recent high-value orders
SELECT customer_name, order_date, total_amount
FROM orders
WHERE total_amount > 1000
  AND order_date >= '2024-10-01'
ORDER BY order_date DESC, total_amount DESC;

-- Example 4: Search for specific employees
SELECT name, department, email
FROM employees
WHERE (name LIKE 'John%' OR name LIKE 'Jane%')
  AND email IS NOT NULL
ORDER BY name;

-- Example 5: Products in specific price ranges
SELECT product_name, category, price
FROM products
WHERE category IN ('Electronics', 'Computers')
  AND price BETWEEN 200 AND 1000
ORDER BY category, price DESC;

-- Example 6: Employee salary analysis
SELECT 
    name,
    department,
    salary,
    CASE 
        WHEN salary < 40000 THEN 'Junior'
        WHEN salary BETWEEN 40000 AND 70000 THEN 'Mid-Level'
        ELSE 'Senior'
    END AS salary_grade
FROM employees
WHERE department IN ('IT', 'Engineering')
ORDER BY salary DESC;


-- ============================================
-- 10. COMBINING EVERYTHING
-- ============================================

-- Complex query using multiple concepts
SELECT 
    name AS employee_name,
    department,
    salary,
    salary * 12 AS annual_salary,
    hire_date
FROM employees
WHERE (department = 'Sales' OR department = 'Marketing')
  AND salary BETWEEN 45000 AND 80000
  AND hire_date >= '2020-01-01'
  AND email IS NOT NULL
  AND name LIKE '%a%'
ORDER BY department ASC, salary DESC
LIMIT 25;


-- ============================================
-- PRACTICE EXERCISES
-- ============================================

-- Try these queries yourself:

-- 1. Find all products with 'Pro' in the name and price less than 500
-- SELECT * FROM products WHERE ...

-- 2. Get top 10 most expensive products in Electronics category
-- SELECT * FROM products WHERE ...

-- 3. Find employees hired in 2023 or 2024, earning between 50k-75k
-- SELECT * FROM employees WHERE ...

-- 4. List all pending orders above $500 from the last 30 days
-- SELECT * FROM orders WHERE ...

-- 5. Find employees whose names end with 'son' and work in IT or Engineering
-- SELECT * FROM employees WHERE ...