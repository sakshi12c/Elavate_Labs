-- Task 2: Data Insertion and Handling Nulls
-- Database: SQLite
-- Practice inserting, updating, and deleting data with proper NULL handling

-- ============================================
-- PART 1: CREATE SAMPLE TABLES
-- ============================================

-- Create Students table
CREATE TABLE IF NOT EXISTS Students (
    student_id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE,
    phone TEXT,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    gpa REAL
);

-- Create Courses table
CREATE TABLE IF NOT EXISTS Courses (
    course_id INTEGER PRIMARY KEY AUTOINCREMENT,
    course_name TEXT NOT NULL,
    instructor TEXT,
    credits INTEGER DEFAULT 3,
    department TEXT
);

-- Create Enrollments table
CREATE TABLE IF NOT EXISTS Enrollments (
    enrollment_id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    grade TEXT,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (course_id) REFERENCES Courses(course_id)
);

-- ============================================
-- PART 2: INSERT STATEMENTS - Adding Rows
-- ============================================

-- Basic INSERT with all fields
INSERT INTO Students (first_name, last_name, email, phone, enrollment_date, gpa)
VALUES ('John', 'Doe', 'john.doe@email.com', '555-0101', '2024-01-15', 3.75);

INSERT INTO Students (first_name, last_name, email, phone, enrollment_date, gpa)
VALUES ('Jane', 'Smith', 'jane.smith@email.com', '555-0102', '2024-01-16', 3.92);

-- INSERT with NULL phone (omitted field becomes NULL)
INSERT INTO Students (first_name, last_name, email, enrollment_date, gpa)
VALUES ('Alice', 'Johnson', 'alice.j@email.com', '2024-01-17', 3.45);

-- INSERT with explicit NULL for optional fields
INSERT INTO Students (first_name, last_name, email, phone, enrollment_date, gpa)
VALUES ('Bob', 'Williams', 'bob.w@email.com', NULL, '2024-01-18', NULL);

-- INSERT using default values (enrollment_date uses CURRENT_DATE)
INSERT INTO Students (first_name, last_name, email, phone, gpa)
VALUES ('Charlie', 'Brown', 'charlie.b@email.com', '555-0105', 3.60);

-- Multiple row INSERT
INSERT INTO Students (first_name, last_name, email, phone, gpa)
VALUES 
    ('Diana', 'Prince', 'diana.p@email.com', '555-0106', 3.88),
    ('Eve', 'Davis', 'eve.d@email.com', NULL, 3.70),
    ('Frank', 'Miller', 'frank.m@email.com', '555-0108', NULL);

-- Insert courses with various NULL scenarios
INSERT INTO Courses (course_name, instructor, credits, department)
VALUES ('Database Systems', 'Dr. Smith', 4, 'Computer Science');

INSERT INTO Courses (course_name, instructor, credits, department)
VALUES ('Data Structures', 'Dr. Johnson', 3, 'Computer Science');

-- NULL instructor, uses default credits value
INSERT INTO Courses (course_name, instructor, department)
VALUES ('Web Development', NULL, 'Computer Science');

-- Multiple rows with mixed NULL values
INSERT INTO Courses (course_name, instructor, credits, department)
VALUES 
    ('Machine Learning', 'Dr. Anderson', 4, 'AI'),
    ('Software Engineering', 'Dr. Brown', 3, 'Computer Science'),
    ('Algorithms', NULL, 3, NULL);

-- Insert enrollments with grades
INSERT INTO Enrollments (student_id, course_id, grade)
VALUES (1, 1, 'A');

INSERT INTO Enrollments (student_id, course_id, grade)
VALUES (2, 1, 'A-');

-- Enrollment without grade (grade is NULL - student enrolled but not graded yet)
INSERT INTO Enrollments (student_id, course_id, grade)
VALUES (3, 2, NULL);

INSERT INTO Enrollments (student_id, course_id)
VALUES (4, 2);

-- Multiple enrollments
INSERT INTO Enrollments (student_id, course_id, grade)
VALUES 
    (1, 2, 'B+'),
    (2, 3, NULL),
    (5, 1, 'A'),
    (6, 4, 'B');

-- ============================================
-- PART 3: UPDATE STATEMENTS - Modifying Data
-- ============================================

-- Simple UPDATE with WHERE condition
UPDATE Students
SET phone = '555-0199'
WHERE student_id = 3;

-- UPDATE multiple columns
UPDATE Students
SET email = 'bob.williams@newemail.com', phone = '555-0104'
WHERE student_id = 4;

-- UPDATE to set NULL value
UPDATE Students
SET phone = NULL
WHERE student_id = 6;

-- UPDATE based on text condition
UPDATE Courses
SET instructor = 'Dr. Wilson'
WHERE course_name = 'Web Development';

-- UPDATE with calculation
UPDATE Students
SET gpa = gpa + 0.1
WHERE gpa IS NOT NULL AND gpa < 3.5;

-- UPDATE multiple rows matching condition
UPDATE Enrollments
SET grade = 'B'
WHERE grade IS NULL AND student_id IN (3, 4);

-- UPDATE using CASE for conditional logic
UPDATE Students
SET gpa = CASE
    WHEN gpa IS NULL THEN 2.5
    WHEN gpa < 2.0 THEN 2.0
    ELSE gpa
END;

-- UPDATE with subquery
UPDATE Courses
SET credits = 4
WHERE course_name IN ('Machine Learning', 'Database Systems');

-- ============================================
-- PART 4: DELETE STATEMENTS - Removing Data
-- ============================================

-- DELETE with specific WHERE condition
DELETE FROM Enrollments
WHERE enrollment_id = 5;

-- DELETE based on NULL value
DELETE FROM Courses
WHERE department IS NULL;

-- DELETE multiple rows matching condition
DELETE FROM Students
WHERE gpa < 2.0 AND enrollment_date < '2024-01-17';

-- DELETE with subquery
DELETE FROM Enrollments
WHERE student_id IN (
    SELECT student_id 
    FROM Students 
    WHERE email LIKE '%newemail.com'
);

-- DELETE with JOIN-like condition (using subquery)
DELETE FROM Enrollments
WHERE course_id IN (
    SELECT course_id 
    FROM Courses 
    WHERE instructor IS NULL
);

-- ============================================
-- PART 5: HANDLING NULLS - Query Examples
-- ============================================

-- Find students with missing phone numbers
SELECT * FROM Students
WHERE phone IS NULL;

-- Find students with phone numbers
SELECT * FROM Students
WHERE phone IS NOT NULL;

-- Count students with and without GPA
SELECT 
    COUNT(*) as total_students,
    COUNT(gpa) as students_with_gpa,
    COUNT(*) - COUNT(gpa) as students_without_gpa
FROM Students;

-- Use COALESCE to provide default values for NULLs
SELECT 
    first_name,
    last_name,
    COALESCE(phone, 'No Phone') as phone_display,
    COALESCE(gpa, 0.0) as gpa_display
FROM Students;

-- Use IFNULL (SQLite specific)
SELECT 
    course_name,
    IFNULL(instructor, 'TBA') as instructor_name,
    IFNULL(department, 'Unassigned') as dept_name
FROM Courses;

-- Find enrollments without grades (incomplete)
SELECT 
    s.first_name,
    s.last_name,
    c.course_name,
    e.grade
FROM Enrollments e
JOIN Students s ON e.student_id = s.student_id
JOIN Courses c ON e.course_id = c.course_id
WHERE e.grade IS NULL;

-- Use NULLIF to convert empty strings to NULL
UPDATE Students
SET phone = NULLIF(phone, '')
WHERE phone = '';

-- ============================================
-- PART 6: BEST PRACTICES EXAMPLES
-- ============================================

-- Insert with explicit column names (recommended)
INSERT INTO Students (first_name, last_name, email)
VALUES ('George', 'Martin', 'george.m@email.com');

-- Avoid inserting without column names (not recommended but shown for learning)
-- INSERT INTO Students VALUES (NULL, 'Henry', 'Ford', 'henry.f@email.com', NULL, CURRENT_DATE, 3.5);

-- Update with safety check
UPDATE Students
SET gpa = 3.8
WHERE student_id = 1 AND gpa IS NOT NULL;

-- Delete with confirmation query first (run SELECT before DELETE)
-- SELECT * FROM Enrollments WHERE grade IS NULL;
-- Then run the DELETE:
DELETE FROM Enrollments
WHERE grade IS NULL AND enrollment_date < '2024-01-01';

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- View all students
SELECT * FROM Students ORDER BY student_id;

-- View all courses
SELECT * FROM Courses ORDER BY course_id;

-- View all enrollments with details
SELECT 
    e.enrollment_id,
    s.first_name || ' ' || s.last_name as student_name,
    c.course_name,
    COALESCE(e.grade, 'Not Graded') as grade
FROM Enrollments e
JOIN Students s ON e.student_id = s.student_id
JOIN Courses c ON e.course_id = c.course_id
ORDER BY e.enrollment_id;