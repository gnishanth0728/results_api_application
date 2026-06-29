-- ============================================================
-- PostgreSQL Initialization Script
-- Creates:
--   1. students
--   2. student_marks
--   3. Indexes
--   4. 10,000 students (1051110000 - 1051119999)
--   5. 60,000 marks (6 subjects per student)
-- ============================================================

DROP TABLE IF EXISTS student_marks;
DROP TABLE IF EXISTS students;

CREATE TABLE students (
    roll_number BIGINT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE student_marks (
    id BIGSERIAL PRIMARY KEY,
    roll_number BIGINT NOT NULL,
    subject_name VARCHAR(30) NOT NULL,
    marks INT NOT NULL CHECK (marks BETWEEN 0 AND 100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_student
        FOREIGN KEY (roll_number)
        REFERENCES students(roll_number)
        ON DELETE CASCADE
);

CREATE INDEX idx_student_marks_roll
ON student_marks(roll_number);

INSERT INTO students (roll_number, first_name, last_name)
SELECT
    r,
    (ARRAY[
        'Aarav','Vivaan','Aditya','Arjun','Sai',
        'Nishanth','Rahul','Kiran','Rohit','Varun',
        'Suresh','Mahesh','Karthik','Ajay','Vijay',
        'Priya','Ananya','Sneha','Pooja','Divya',
        'Kavya','Aishwarya','Neha','Deepika','Swathi'
    ])[((r % 25) + 1)],
    (ARRAY[
        'Sharma','Reddy','Patel','Kumar','Singh',
        'Verma','Gupta','Nair','Rao','Joshi',
        'Iyer','Mehta','Das','Kulkarni','Gundlapalle'
    ])[((r % 15) + 1)]
FROM generate_series(1051110000,1051119999) AS r;

INSERT INTO student_marks (roll_number, subject_name, marks)
SELECT
    s.roll_number,
    sub.subject_name,
    floor(random()*41 + 60)::INT
FROM students s
CROSS JOIN (
    VALUES
        ('Math'),
        ('English'),
        ('Science'),
        ('Physics'),
        ('Chemistry'),
        ('Computer')
) AS sub(subject_name);

-- Verification
SELECT COUNT(*) AS total_students FROM students;
SELECT COUNT(*) AS total_marks FROM student_marks;
