-- ============================================
-- Task 8: Stored Procedures and Functions
-- ============================================

-- Step 1: Create Database and Table
-- ============================================
CREATE DATABASE IF NOT EXISTS company_db;
USE company_db;

DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary DECIMAL(10, 2),
    hire_date DATE,
    performance_rating INT
);

-- Insert Sample Data
INSERT INTO employees (first_name, last_name, department, salary, hire_date, performance_rating)
VALUES 
('John', 'Smith', 'IT', 75000.00, '2020-01-15', 4),
('Sarah', 'Johnson', 'HR', 65000.00, '2019-03-20', 5),
('Michael', 'Brown', 'IT', 80000.00, '2018-06-10', 3),
('Emily', 'Davis', 'Sales', 70000.00, '2021-02-28', 4),
('David', 'Wilson', 'Sales', 68000.00, '2020-11-05', 5),
('Lisa', 'Anderson', 'HR', 62000.00, '2021-07-12', 2),
('James', 'Taylor', 'IT', 85000.00, '2017-09-30', 5);


-- Step 2: Create Stored Procedure
-- ============================================
DELIMITER //

DROP PROCEDURE IF EXISTS GiveSalaryRaise//

CREATE PROCEDURE GiveSalaryRaise(
    IN emp_id INT,
    IN raise_percentage DECIMAL(5,2)
)
BEGIN
    DECLARE current_salary DECIMAL(10,2);
    DECLARE new_salary DECIMAL(10,2);
    DECLARE emp_rating INT;
    DECLARE emp_exists INT;
    
    -- Check if employee exists
    SELECT COUNT(*) INTO emp_exists
    FROM employees 
    WHERE employee_id = emp_id;
    
    IF emp_exists = 0 THEN
        SELECT CONCAT('Error: Employee ID ', emp_id, ' does not exist') AS message;
    ELSE
        -- Get current salary and rating
        SELECT salary, performance_rating 
        INTO current_salary, emp_rating
        FROM employees 
        WHERE employee_id = emp_id;
        
        -- Conditional logic based on performance rating
        IF emp_rating >= 4 THEN
            SET new_salary = current_salary + (current_salary * raise_percentage / 100);
            
            UPDATE employees 
            SET salary = new_salary 
            WHERE employee_id = emp_id;
            
            SELECT CONCAT('SUCCESS: Salary updated for employee ', emp_id, 
                         '. Old salary: $', current_salary,
                         ', New salary: $', new_salary,
                         ' (', raise_percentage, '% increase)') AS message;
        ELSE
            SELECT CONCAT('DENIED: Employee ', emp_id, 
                         ' does not qualify for raise. Performance rating: ', 
                         emp_rating, ' (minimum 4 required)') AS message;
        END IF;
    END IF;
END//

DELIMITER ;


-- Step 3: Create Function
-- ============================================
DELIMITER //

DROP FUNCTION IF EXISTS CalculateBonus//

CREATE FUNCTION CalculateBonus(
    emp_salary DECIMAL(10,2),
    rating INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE bonus DECIMAL(10,2);
    
    -- Conditional logic for bonus calculation
    IF rating = 5 THEN
        SET bonus = emp_salary * 0.15;  -- 15% bonus for excellent performance
    ELSEIF rating = 4 THEN
        SET bonus = emp_salary * 0.10;  -- 10% bonus for good performance
    ELSEIF rating = 3 THEN
        SET bonus = emp_salary * 0.05;  -- 5% bonus for average performance
    ELSE
        SET bonus = 0;  -- No bonus for poor performance
    END IF;
    
    RETURN bonus;
END//

DELIMITER ;


-- Step 4: Create Advanced Stored Procedure with OUT Parameters
-- ============================================
DELIMITER //

DROP PROCEDURE IF EXISTS DepartmentReport//

CREATE PROCEDURE DepartmentReport(
    IN dept_name VARCHAR(50),
    OUT total_employees INT,
    OUT avg_salary DECIMAL(10,2),
    OUT total_payroll DECIMAL(12,2)
)
BEGIN
    -- Calculate department statistics
    SELECT 
        COUNT(*),
        AVG(salary),
        SUM(salary)
    INTO 
        total_employees,
        avg_salary,
        total_payroll
    FROM employees
    WHERE department = dept_name;
    
    -- Provide feedback message
    IF total_employees = 0 THEN
        SELECT CONCAT('WARNING: No employees found in ', dept_name, ' department') AS message;
    ELSE
        SELECT CONCAT('SUCCESS: Report generated for ', dept_name, 
                     ' department with ', total_employees, ' employees') AS message;
    END IF;
END//

DELIMITER ;


-- Step 5: Create Additional Function for Employee Status
-- ============================================
DELIMITER //

DROP FUNCTION IF EXISTS GetEmployeeStatus//

CREATE FUNCTION GetEmployeeStatus(
    rating INT,
    years_of_service INT
)
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE status VARCHAR(50);
    
    -- Complex conditional logic
    IF rating >= 5 AND years_of_service >= 5 THEN
        SET status = 'Senior Star Performer';
    ELSEIF rating >= 4 AND years_of_service >= 3 THEN
        SET status = 'High Performer';
    ELSEIF rating >= 3 THEN
        SET status = 'Good Standing';
    ELSEIF rating = 2 THEN
        SET status = 'Needs Improvement';
    ELSE
        SET status = 'Under Review';
    END IF;
    
    RETURN status;
END//

DELIMITER ;


-- ============================================
-- TESTING SECTION
-- ============================================

-- Test 1: View original data
SELECT * FROM employees;

-- Test 2: Call Stored Procedure - GiveSalaryRaise
-- Give 10% raise to employee with good rating
CALL GiveSalaryRaise(1, 10);

-- Try with employee who has low performance rating
CALL GiveSalaryRaise(3, 10);

-- Try with excellent performer
CALL GiveSalaryRaise(2, 15);

-- Try with non-existent employee
CALL GiveSalaryRaise(999, 10);


-- Test 3: Use Function - CalculateBonus
-- Calculate bonus for all employees
SELECT 
    employee_id,
    first_name,
    last_name,
    department,
    salary,
    performance_rating,
    CalculateBonus(salary, performance_rating) AS annual_bonus,
    salary + CalculateBonus(salary, performance_rating) AS total_compensation
FROM employees
ORDER BY annual_bonus DESC;

-- Find employees with bonus greater than 10000
SELECT 
    first_name,
    last_name,
    salary,
    performance_rating,
    CalculateBonus(salary, performance_rating) AS annual_bonus
FROM employees
WHERE CalculateBonus(salary, performance_rating) > 10000;


-- Test 4: Call Stored Procedure with OUT parameters - DepartmentReport
-- Generate report for IT department
CALL DepartmentReport('IT', @emp_count, @avg_sal, @total_pay);
SELECT 
    'IT' AS department,
    @emp_count AS total_employees,
    @avg_sal AS average_salary,
    @total_pay AS total_payroll;

-- Generate report for Sales department
CALL DepartmentReport('Sales', @emp_count, @avg_sal, @total_pay);
SELECT 
    'Sales' AS department,
    @emp_count AS total_employees,
    @avg_sal AS average_salary,
    @total_pay AS total_payroll;

-- Generate report for HR department
CALL DepartmentReport('HR', @emp_count, @avg_sal, @total_pay);
SELECT 
    'HR' AS department,
    @emp_count AS total_employees,
    @avg_sal AS average_salary,
    @total_pay AS total_payroll;

-- Test with non-existent department
CALL DepartmentReport('Marketing', @emp_count, @avg_sal, @total_pay);
SELECT @emp_count, @avg_sal, @total_pay;


-- Test 5: Use GetEmployeeStatus Function
SELECT 
    employee_id,
    first_name,
    last_name,
    performance_rating,
    YEAR(CURDATE()) - YEAR(hire_date) AS years_of_service,
    GetEmployeeStatus(
        performance_rating, 
        YEAR(CURDATE()) - YEAR(hire_date)
    ) AS employee_status
FROM employees;


-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- View all procedures in database
SHOW PROCEDURE STATUS WHERE Db = 'company_db';

-- View all functions in database
SHOW FUNCTION STATUS WHERE Db = 'company_db';

-- View procedure definition
SHOW CREATE PROCEDURE GiveSalaryRaise;

-- View function definition
SHOW CREATE FUNCTION CalculateBonus;


