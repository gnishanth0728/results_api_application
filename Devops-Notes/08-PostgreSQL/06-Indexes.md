# 📘 Chapter 64 — PostgreSQL Indexes

> 📂 File: `student-results-api-notes/08-PostgreSQL/06-Indexes.md`

This chapter covers one of the most important database performance concepts.

After learning how the Planner chooses an execution plan and how the Executor reads data, the next obvious question is:

How does PostgreSQL find one row out of 100 million rows so quickly?

The answer is:

Indexes

Without indexes, PostgreSQL may need to scan the entire table.

With indexes, it can locate the required rows in milliseconds.

This chapter explains not only how to create indexes, but also how they work internally using B-Tree structures, why they speed up reads, and when they can actually hurt performance

---

# 🌍 Introduction

In the previous chapter, we learned how the PostgreSQL **Executor** runs an execution plan.

For example:

```sql id="p6x9m2"
SELECT *
FROM student
WHERE id = 1;
```

The Executor needs to find the matching row.

This raises an important question:

> 🤔 **How can PostgreSQL locate one row among millions without reading the entire table?**

The answer is:

# 📚 Indexes

Indexes are specialized data structures that allow PostgreSQL to find rows quickly without scanning every record.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📚 What an Index is
* 🌳 B-Tree Structure
* 🔍 Index Scan
* 📄 Sequential Scan
* 📘 Index Only Scan
* ⚡ Bitmap Index Scan
* 📈 Query Planner Decisions
* 🛠️ Creating Indexes
* 🚫 Common Mistakes
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ What Is an Index?

Think of a book.

Without an index:

```text id="d8m4q1"
Page 1

↓

Page 2

↓

Page 3

↓

...

↓

Page 1000
```

You search page by page.

With an index:

```text id="g5v2r8"
Index

↓

"Student"

↓

Page 742
```

You immediately jump to the correct page.

A PostgreSQL index works the same way.

---

# 🏗️ Table Without an Index

Suppose:

```text id="q2f7h5"
student

---------------------

id   name

1    Alice

2    Bob

3    Charlie

...

1000000
```

Query:

```sql id="x8j1k6"
SELECT *
FROM student
WHERE id = 999999;
```

Without an index:

```text id="h4w9n3"
Row 1

↓

Row 2

↓

Row 3

↓

...

↓

Row 999999
```

This is a **Sequential Scan**.

---

# 📚 Table With an Index

Now create:

```sql id="m7r5p2"
CREATE INDEX idx_student_id
ON student(id);
```

PostgreSQL builds:

```text id="s3k8v1"
Index

1

↓

2

↓

3

↓

...

↓

999999
```

The Executor can now jump directly to the desired row.

---

# 🌳 B-Tree Index

The default PostgreSQL index type is the **B-Tree**.

Structure:

```text id="c6n2q9"
            500
          /     \
      250         750
     /  \        /   \
   100 300    600   900
```

Instead of checking every row, PostgreSQL follows a path through the tree.

Search complexity is approximately:

```text id="a1p7m4"
O(log n)
```

instead of:

```text id="t9v3k8"
O(n)
```

---

# 🔍 Index Scan

Suppose:

```sql id="e4r8x5"
SELECT *
FROM student
WHERE id = 1;
```

Execution:

```text id="k2w6j7"
Planner

↓

Index Scan

↓

B-Tree

↓

Leaf Node

↓

Table Row
```

Only a few pages are read.

---

# 📄 Sequential Scan

Suppose:

```sql id="n8h3q6"
SELECT *
FROM student;
```

Planner chooses:

```text id="u5m9v1"
Sequential Scan

↓

Read Every Page

↓

Return Every Row
```

Using an index would actually be slower because every row is needed.

---

# 📘 Index Only Scan

Sometimes PostgreSQL can answer the query **using only the index**.

Example:

```sql id="r6t2p9"
SELECT id
FROM student
WHERE id = 1;
```

Execution:

```text id="j3x7k4"
Index

↓

Return id

↓

Done
```

No table page needs to be read.

This is called an **Index Only Scan**.

---

# ⚡ Bitmap Index Scan

Suppose:

```sql id="b5m1r8"
SELECT *
FROM student
WHERE marks > 90;
```

Many rows match.

Planner may choose:

```text id="y9q4v6"
Bitmap Index Scan

↓

Bitmap Heap Scan

↓

Return Rows
```

This reduces random page access for large result sets.

---

# 🧠 How the Planner Chooses

Suppose:

```text id="f2p8k1"
10 Rows
```

Planner chooses:

```text id="d4n6m7"
Sequential Scan
```

Suppose:

```text id="l7v2x5"
100 Million Rows
```

Planner chooses:

```text id="z3r9h4"
Index Scan
```

The Planner always estimates which strategy has the lowest cost.

---

# 🍃 Student Results API Example

Browser:

```http id="q8w5j2"
GET /students/1
```

Hibernate:

```sql id="h1k7n3"
SELECT *
FROM student
WHERE id = 1;
```

Execution:

```text id="m4p9v6"
Planner

↓

Primary Key Index

↓

Executor

↓

B-Tree

↓

Table Page

↓

Student Row

↓

Hibernate
```

The application receives the row without scanning the whole table.

---

# 🛠️ Creating Indexes

Create a single-column index:

```sql id="c7t3m8"
CREATE INDEX idx_student_name
ON student(name);
```

Create a multi-column index:

```sql id="v2r6q1"
CREATE INDEX idx_student_name_marks
ON student(name, marks);
```

Unique index:

```sql id="w5p8n4"
CREATE UNIQUE INDEX idx_student_email
ON student(email);
```

---

# 📊 Common Index Types

| Index Type | Best For                                               |
| ---------- | ------------------------------------------------------ |
| 🌳 B-Tree  | Equality and range searches (`=`, `<`, `>`, `BETWEEN`) |
| 🔍 Hash    | Equality comparisons (`=`)                             |
| 🌍 GiST    | Geometric data, ranges, nearest-neighbor searches      |
| 📚 GIN     | Arrays, JSONB, Full-Text Search                        |
| 🧬 BRIN    | Very large tables with naturally ordered data          |

Most applications primarily use **B-Tree** indexes.

---

# 🚫 Common Mistakes

## ❌ Indexing Every Column

Every index:

* Uses disk space
* Increases memory usage
* Slows `INSERT`, `UPDATE`, and `DELETE`

Index only columns that are frequently searched or joined.

---

## ❌ Expecting an Index to Help Every Query

Example:

```sql id="g6n9k5"
SELECT *
FROM student;
```

A Sequential Scan is often faster than an Index Scan because every row must be read anyway.

---

## ❌ Ignoring Execution Plans

Always verify index usage:

```sql id="k3m7p2"
EXPLAIN ANALYZE

SELECT *
FROM student
WHERE id = 1;
```

Never assume PostgreSQL is using your index.

---

# 🐳 Docker Perspective

```text id="x9r4t7"
Spring Boot Container
        │
        ▼
PostgreSQL Container
        │
        ▼
B-Tree Index
        │
        ▼
Data Files
```

Indexes are stored inside PostgreSQL's data files regardless of containerization.

---

# ☸️ Kubernetes Perspective

```text id="h2q8m6"
Spring Boot Pod
       │
       ▼
Service
       │
       ▼
PostgreSQL Pod
       │
       ▼
Indexes
       │
       ▼
Persistent Volume
```

Indexes persist on disk because PostgreSQL stores them in the Persistent Volume.

---

# 🧪 Hands-on Lab

## Create a Table

```sql id="b1t5v9"
CREATE TABLE student (

    id BIGINT PRIMARY KEY,

    name TEXT,

    marks INT

);
```

Insert a large number of rows.

---

## Run Without an Index

```sql id="j7k2p4"
EXPLAIN ANALYZE

SELECT *

FROM student

WHERE marks = 95;
```

Observe whether PostgreSQL performs a Sequential Scan.

---

## Create an Index

```sql id="n4x8r3"
CREATE INDEX idx_student_marks
ON student(marks);
```

Run the same query again.

Compare the execution plan and execution time.

---

## Test an Index Only Scan

```sql id="u6m1q7"
EXPLAIN ANALYZE

SELECT id

FROM student

WHERE id = 1;
```

Observe whether PostgreSQL chooses an `Index Only Scan`.

---

## List Existing Indexes

```sql id="e5v9k2"
SELECT indexname,
       indexdef
FROM pg_indexes
WHERE tablename = 'student';
```

Inspect the indexes associated with the table.

---

# 📈 Complete Index Lookup Flow

```text id="r8h3n6"
SQL
 │
 ▼
Parser
 │
 ▼
Planner
 │
 ▼
Index Scan
 │
 ▼
B-Tree
 │
 ▼
Leaf Page
 │
 ▼
Table Page
 │
 ▼
Matching Row
 │
 ▼
Executor
 │
 ▼
JDBC Driver
 │
 ▼
Hibernate
```

This is the complete path of an indexed query from SQL to the returned row.

---

# 📊 Scan Comparison

| Feature                    | 📄 Sequential Scan | 📚 Index Scan              |
| -------------------------- | ------------------ | -------------------------- |
| Reads every row            | ✅ Yes              | ❌ No                       |
| Best for small tables      | ✅ Yes              | ⚠️ Depends                 |
| Best for selective lookups | ❌ No               | ✅ Yes                      |
| Requires an index          | ❌ No               | ✅ Yes                      |
| Typical complexity         | O(n)               | O(log n) for B-Tree lookup |

---

# 💡 Key Takeaways

✅ An index is a data structure that allows PostgreSQL to locate rows efficiently without scanning the entire table.

✅ PostgreSQL uses **B-Tree indexes** by default because they provide fast lookups for equality and range queries.

✅ The Query Planner decides whether to use an index based on estimated cost and table statistics.

✅ Indexes greatly improve read performance but increase storage requirements and the cost of write operations.

✅ `Index Only Scan` can answer some queries entirely from the index, avoiding table access.

✅ `EXPLAIN ANALYZE` should always be used to verify whether an index is actually being used.

✅ Proper indexing is one of the most effective ways to improve database performance, but indexes should be created thoughtfully rather than on every column.

---

# ➡️ Next Chapter

📘 **`08-PostgreSQL/07-MVCC.md`**

In the next chapter, we'll explore one of PostgreSQL's most powerful features:

* 🔄 Multi-Version Concurrency Control (MVCC)
* 👥 How readers and writers work simultaneously
* 📸 Row versions (tuple versions)
* 🧠 Transaction IDs (`xmin` and `xmax`)
* 🚫 Why readers don't block writers
* 🧹 Dead tuples and VACUUM

By the end of the next chapter, you'll understand how PostgreSQL allows thousands of concurrent users to read and write data without locking the entire table.
