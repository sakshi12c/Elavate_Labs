-- ============================================
-- SQL JOINS TUTORIAL: COMPLETE GUIDE
-- ============================================

-- STEP 1: CREATE DATABASE AND TABLES
-- ============================================

-- Create Customers table
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    Email VARCHAR(100),
    City VARCHAR(50),
    Country VARCHAR(50)
);

-- Create Orders table
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    OrderDate DATE,
    TotalAmount DECIMAL(10, 2),
    Status VARCHAR(20),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- STEP 2: INSERT SAMPLE DATA
-- ============================================

-- Insert Customers
INSERT INTO Customers (CustomerID, CustomerName, Email, City, Country) VALUES
(1, 'John Smith', 'john@email.com', 'New York', 'USA'),
(2, 'Maria Garcia', 'maria@email.com', 'Madrid', 'Spain'),
(3, 'David Chen', 'david@email.com', 'Beijing', 'China'),
(4, 'Sarah Johnson', 'sarah@email.com', 'London', 'UK'),
(5, 'Ahmed Ali', 'ahmed@email.com', 'Cairo', 'Egypt'),
(6, 'Emma Wilson', 'emma@email.com', 'Sydney', 'Australia');

-- Insert Orders (Note: Customer 5 and 6 have no orders)
INSERT INTO Orders (OrderID, CustomerID, OrderDate, TotalAmount, Status) VALUES
(101, 1, '2024-01-15', 150.00, 'Delivered'),
(102, 1, '2024-02-20', 275.50, 'Delivered'),
(103, 2, '2024-01-18', 89.99, 'Delivered'),
(104, 3, '2024-02-05', 450.00, 'Shipped'),
(105, 4, '2024-02-10', 125.75, 'Processing'),
(106, 2, '2024-03-01', 199.99, 'Delivered'),
(107, NULL, '2024-03-05', 75.00, 'Cancelled'); -- Order without customer

-- ============================================
-- 1. INNER JOIN
-- Returns only matching records from both tables
-- ============================================

-- Basic INNER JOIN
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.City,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- INNER JOIN with filtering
SELECT 
    c.CustomerName,
    COUNT(o.OrderID) as TotalOrders,
    SUM(o.TotalAmount) as TotalSpent
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.Status = 'Delivered'
GROUP BY c.CustomerID, c.CustomerName
HAVING SUM(o.TotalAmount) > 100
ORDER BY TotalSpent DESC;

-- ============================================
-- 2. LEFT JOIN (LEFT OUTER JOIN)
-- Returns all records from left table, matching from right
-- ============================================

-- Basic LEFT JOIN - Shows all customers, even without orders
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email,
    o.OrderID,
    o.TotalAmount,
    o.Status
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
ORDER BY c.CustomerID;

-- Find customers who have NEVER placed an order
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email,
    c.City
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;

-- Customers with order statistics (including zero orders)
SELECT 
    c.CustomerName,
    c.Country,
    COUNT(o.OrderID) as OrderCount,
    COALESCE(SUM(o.TotalAmount), 0) as TotalSpent
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName, c.Country
ORDER BY TotalSpent DESC;

-- ============================================
-- 3. RIGHT JOIN (RIGHT OUTER JOIN)
-- Returns all records from right table, matching from left
-- ============================================

-- Basic RIGHT JOIN - Shows all orders, even without customers
SELECT 
    c.CustomerName,
    c.Email,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount,
    o.Status
FROM Customers c
RIGHT JOIN Orders o ON c.CustomerID = o.CustomerID
ORDER BY o.OrderID;

-- Find orders without associated customers (orphaned orders)
SELECT 
    o.OrderID,
    o.OrderDate,
    o.TotalAmount,
    o.Status
FROM Customers c
RIGHT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerID IS NULL;

-- ============================================
-- 4. FULL OUTER JOIN
-- Returns all records when there's a match in either table
-- ============================================

-- NOTE: SQLite doesn't support FULL OUTER JOIN directly
-- MySQL doesn't support FULL OUTER JOIN natively either
-- Here's the workaround using UNION:

-- FULL OUTER JOIN simulation
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
UNION
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
RIGHT JOIN Orders o ON c.CustomerID = o.CustomerID;

-- For databases that support FULL OUTER JOIN (PostgreSQL, SQL Server):
/*
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email,
    o.OrderID,
    o.TotalAmount,
    o.Status
FROM Customers c
FULL OUTER JOIN Orders o ON c.CustomerID = o.CustomerID;
*/

-- ============================================
-- ADVANCED JOIN EXAMPLES
-- ============================================

-- Multiple conditions in JOIN
SELECT 
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o 
    ON c.CustomerID = o.CustomerID 
    AND o.TotalAmount > 100
    AND o.Status = 'Delivered';

-- Self JOIN - Create Products table for example
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    Price DECIMAL(10, 2),
    RelatedProductID INT
);

INSERT INTO Products VALUES
(1, 'Laptop', 'Electronics', 999.99, 2),
(2, 'Laptop Bag', 'Accessories', 49.99, NULL),
(3, 'Mouse', 'Accessories', 29.99, 4),
(4, 'Mousepad', 'Accessories', 9.99, NULL);

-- Self JOIN to find related products
SELECT 
    p1.ProductName as Product,
    p1.Price as ProductPrice,
    p2.ProductName as RelatedProduct,
    p2.Price as RelatedPrice
FROM Products p1
LEFT JOIN Products p2 ON p1.RelatedProductID = p2.ProductID;

-- ============================================
-- THREE-TABLE JOINS
-- ============================================

-- Create OrderDetails table
CREATE TABLE OrderDetails (
    OrderDetailID INT PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    Quantity INT,
    UnitPrice DECIMAL(10, 2),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

INSERT INTO OrderDetails VALUES
(1, 101, 1, 1, 999.99),
(2, 101, 2, 1, 49.99),
(3, 102, 3, 2, 29.99),
(4, 103, 1, 1, 999.99);

-- Join three tables
SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    p.ProductName,
    od.Quantity,
    od.UnitPrice,
    (od.Quantity * od.UnitPrice) as LineTotal
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
ORDER BY c.CustomerName, o.OrderDate;

-- ============================================
-- PRACTICE QUERIES
-- ============================================

-- 1. List all customers and their order count (including 0)
SELECT 
    c.CustomerName,
    COUNT(o.OrderID) as OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- 2. Find customers who have spent more than $200
SELECT 
    c.CustomerName,
    SUM(o.TotalAmount) as TotalSpent
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
HAVING SUM(o.TotalAmount) > 200;

-- 3. List all orders with customer details, show 'Unknown' for missing customers
SELECT 
    COALESCE(c.CustomerName, 'Unknown Customer') as CustomerName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount,
    o.Status
FROM Orders o
LEFT JOIN Customers c ON o.CustomerID = c.CustomerID;

-- 4. Find the most recent order for each customer
SELECT 
    c.CustomerName,
    MAX(o.OrderDate) as LastOrderDate,
    COUNT(o.OrderID) as TotalOrders
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- View all customers
SELECT * FROM Customers;

-- View all orders
SELECT * FROM Orders;

-- Count records
SELECT 'Total Customers' as Metric, COUNT(*) as Count FROM Customers
UNION ALL
SELECT 'Total Orders', COUNT(*) FROM Orders
UNION ALL
SELECT 'Customers with Orders', COUNT(DISTINCT CustomerID) FROM Orders WHERE CustomerID IS NOT NULL;