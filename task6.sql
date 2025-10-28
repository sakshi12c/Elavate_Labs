-- ============================================
-- SUBQUERIES AND NESTED QUERIES GUIDE
-- ============================================

-- Sample Database Setup
-- First, let's create sample tables for practice

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department_id INT,
    salary DECIMAL(10, 2),
    hire_date DATE,
    manager_id INT
);

CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100),
    location VARCHAR(100)
);

CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    employee_id INT,
    sale_date DATE,
    amount DECIMAL(10, 2),
    product_id INT
);

-- Sample Data
INSERT INTO departments VALUES 
(1, 'Sales', 'New York'),
(2, 'IT', 'San Francisco'),
(3, 'HR', 'Chicago'),
(4, 'Finance', 'Boston');

INSERT INTO employees VALUES
(101, 'John', 'Doe', 1, 75000, '2020-01-15', NULL),
(102, 'Jane', 'Smith', 1, 65000, '2021-03-20', 101),
(103, 'Mike', 'Johnson', 2, 85000, '2019-07-10', NULL),
(104, 'Sarah', 'Williams', 2, 72000, '2021-05-12', 103),
(105, 'Tom', 'Brown', 3, 55000, '2022-02-18', NULL),
(106, 'Lisa', 'Davis', 1, 68000, '2020-11-25', 101),
(107, 'David', 'Miller', 4, 90000, '2018-09-05', NULL),
(108, 'Emma', 'Wilson', 2, 78000, '2020-06-30', 103);

INSERT INTO sales VALUES
(1, 102, '2024-01-15', 5000, 1),
(2, 102, '2024-02-20', 7500, 2),
(3, 106, '2024-01-10', 6200, 1),
(4, 104, '2024-03-05', 3500, 3),
(5, 108, '2024-02-14', 9000, 2),
(6, 102, '2024-03-25', 4800, 1);

-- ============================================
-- 1. SCALAR SUBQUERIES (Return Single Value)
-- ============================================

-- Example 1: Compare employee salary to average salary
SELECT 
    employee_id,
    first_name,
    last_name,
    salary,
    (SELECT AVG(salary) FROM employees) AS avg_salary,
    salary - (SELECT AVG(salary) FROM employees) AS diff_from_avg
FROM employees;

-- Example 2: Find employees earning more than average
SELECT 
    first_name,
    last_name,
    salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- Example 3: Get department with highest average salary
SELECT 
    department_name,
    (SELECT AVG(salary) 
     FROM employees e 
     WHERE e.department_id = d.department_id) AS avg_salary
FROM departments d
ORDER BY avg_salary DESC
LIMIT 1;

-- ============================================
-- 2. SUBQUERIES IN WHERE CLAUSE
-- ============================================

-- Example 4: Using IN operator
-- Find employees in departments located in New York or Chicago
SELECT 
    first_name,
    last_name,
    department_id
FROM employees
WHERE department_id IN (
    SELECT department_id 
    FROM departments 
    WHERE location IN ('New York', 'Chicago')
);

-- Example 5: Using NOT IN
-- Find employees who haven't made any sales
SELECT 
    employee_id,
    first_name,
    last_name
FROM employees
WHERE employee_id NOT IN (
    SELECT DISTINCT employee_id 
    FROM sales
);

-- Example 6: Using comparison operators
-- Find employees earning more than the highest paid HR employee
SELECT 
    first_name,
    last_name,
    salary
FROM employees
WHERE salary > (
    SELECT MAX(salary) 
    FROM employees 
    WHERE department_id = 3
);

-- Example 7: Using ANY/ALL
-- Find employees earning more than ANY employee in HR
SELECT 
    first_name,
    last_name,
    salary
FROM employees
WHERE salary > ANY (
    SELECT salary 
    FROM employees 
    WHERE department_id = 3
);

-- Find employees earning more than ALL employees in HR
SELECT 
    first_name,
    last_name,
    salary
FROM employees
WHERE salary > ALL (
    SELECT salary 
    FROM employees 
    WHERE department_id = 3
);

-- ============================================
-- 3. CORRELATED SUBQUERIES
-- ============================================

-- Example 8: Find employees earning above their department average
SELECT 
    e1.first_name,
    e1.last_name,
    e1.salary,
    e1.department_id
FROM employees e1
WHERE salary > (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.department_id = e1.department_id
);

-- Example 9: Find employees with above-average sales
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name
FROM employees e
WHERE (
    SELECT AVG(amount)
    FROM sales s
    WHERE s.employee_id = e.employee_id
) > (
    SELECT AVG(amount)
    FROM sales
);

-- Example 10: Rank employees by salary within department
SELECT 
    first_name,
    last_name,
    department_id,
    salary,
    (SELECT COUNT(*)
     FROM employees e2
     WHERE e2.department_id = e1.department_id
     AND e2.salary >= e1.salary) AS dept_rank
FROM employees e1
ORDER BY department_id, dept_rank;

-- ============================================
-- 4. SUBQUERIES WITH EXISTS
-- ============================================

-- Example 11: Find employees who have made sales
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name
FROM employees e
WHERE EXISTS (
    SELECT 1
    FROM sales s
    WHERE s.employee_id = e.employee_id
);

-- Example 12: Find departments with at least one employee
SELECT 
    d.department_id,
    d.department_name
FROM departments d
WHERE EXISTS (
    SELECT 1
    FROM employees e
    WHERE e.department_id = d.department_id
);

-- Example 13: NOT EXISTS - Find employees without sales
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name
FROM employees e
WHERE NOT EXISTS (
    SELECT 1
    FROM sales s
    WHERE s.employee_id = e.employee_id
);

-- ============================================
-- 5. SUBQUERIES IN FROM CLAUSE (Derived Tables)
-- ============================================

-- Example 14: Calculate statistics on department averages
SELECT 
    AVG(dept_avg_salary) AS overall_avg,
    MAX(dept_avg_salary) AS highest_dept_avg,
    MIN(dept_avg_salary) AS lowest_dept_avg
FROM (
    SELECT 
        department_id,
        AVG(salary) AS dept_avg_salary
    FROM employees
    GROUP BY department_id
) AS dept_stats;

-- Example 15: Join with derived table
SELECT 
    e.first_name,
    e.last_name,
    e.salary,
    dept_avg.avg_salary,
    dept_avg.employee_count
FROM employees e
JOIN (
    SELECT 
        department_id,
        AVG(salary) AS avg_salary,
        COUNT(*) AS employee_count
    FROM employees
    GROUP BY department_id
) AS dept_avg ON e.department_id = dept_avg.department_id;

-- Example 16: Top performers by department
SELECT 
    dept_name,
    employee_name,
    salary
FROM (
    SELECT 
        d.department_name AS dept_name,
        CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
        e.salary,
        ROW_NUMBER() OVER (PARTITION BY e.department_id ORDER BY e.salary DESC) AS rn
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
) AS ranked
WHERE rn = 1;

-- ============================================
-- 6. SUBQUERIES IN SELECT CLAUSE
-- ============================================

-- Example 17: Add calculated columns using subqueries
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    e.salary,
    (SELECT department_name 
     FROM departments d 
     WHERE d.department_id = e.department_id) AS dept_name,
    (SELECT COUNT(*) 
     FROM sales s 
     WHERE s.employee_id = e.employee_id) AS total_sales,
    (SELECT SUM(amount) 
     FROM sales s 
     WHERE s.employee_id = e.employee_id) AS total_revenue
FROM employees e;

-- Example 18: Calculate percentile ranking
SELECT 
    first_name,
    last_name,
    salary,
    (SELECT COUNT(*) 
     FROM employees e2 
     WHERE e2.salary < e1.salary) * 100.0 / 
    (SELECT COUNT(*) FROM employees) AS percentile_rank
FROM employees e1
ORDER BY salary DESC;

-- ============================================
-- 7. COMPLEX NESTED QUERIES
-- ============================================

-- Example 19: Multi-level nesting
-- Find departments where average salary is higher than company average
SELECT 
    d.department_name,
    (SELECT AVG(salary) 
     FROM employees e 
     WHERE e.department_id = d.department_id) AS dept_avg
FROM departments d
WHERE (
    SELECT AVG(salary) 
    FROM employees e 
    WHERE e.department_id = d.department_id
) > (
    SELECT AVG(salary) 
    FROM employees
);

-- Example 20: Find employees in top-performing departments
SELECT 
    first_name,
    last_name,
    department_id
FROM employees
WHERE department_id IN (
    SELECT department_id
    FROM employees
    GROUP BY department_id
    HAVING AVG(salary) > (
        SELECT AVG(salary) * 1.1
        FROM employees
    )
);

-- Example 21: Sales analysis with multiple subqueries
SELECT 
    e.first_name,
    e.last_name,
    total_sales.sale_count,
    total_sales.total_amount
FROM employees e
JOIN (
    SELECT 
        employee_id,
        COUNT(*) AS sale_count,
        SUM(amount) AS total_amount
    FROM sales
    WHERE sale_date >= '2024-01-01'
    GROUP BY employee_id
) AS total_sales ON e.employee_id = total_sales.employee_id
WHERE total_sales.total_amount > (
    SELECT AVG(total_amount)
    FROM (
        SELECT SUM(amount) AS total_amount
        FROM sales
        WHERE sale_date >= '2024-01-01'
        GROUP BY employee_id
    ) AS avg_sales
);

-- ============================================
-- 8. COMMON TABLE EXPRESSIONS (CTE) - Alternative to Subqueries
-- ============================================

-- Example 22: Using CTE for better readability
WITH dept_stats AS (
    SELECT 
        department_id,
        AVG(salary) AS avg_salary,
        COUNT(*) AS emp_count
    FROM employees
    GROUP BY department_id
)
SELECT 
    e.first_name,
    e.last_name,
    e.salary,
    ds.avg_salary,
    ds.emp_count
FROM employees e
JOIN dept_stats ds ON e.department_id = ds.department_id
WHERE e.salary > ds.avg_salary;

-- Example 23: Recursive CTE for organizational hierarchy
WITH RECURSIVE employee_hierarchy AS (
    -- Anchor: Top-level managers
    SELECT 
        employee_id,
        first_name,
        last_name,
        manager_id,
        1 AS level
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive: Employees reporting to previous level
    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        eh.level + 1
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT * FROM employee_hierarchy
ORDER BY level, employee_id;

