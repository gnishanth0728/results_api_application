# 📘 Chapter 62 — PostgreSQL Query Planner (Optimizer)

> 📂 File: `student-results-api-notes/08-PostgreSQL/04-Planner.md`

This chapter is where PostgreSQL starts making intelligent decisions.

The Parser has already verified that the SQL is valid.

Now PostgreSQL asks:

"What is the fastest way to execute this query?"

For the same SQL statement, PostgreSQL might choose:

📄 Sequential Scan
📚 Index Scan
⚡ Index Only Scan
🔄 Bitmap Scan

The Planner (Optimizer) decides which one is best based on statistics and estimated cost.

This is one of the biggest reasons PostgreSQL performs so well on large databases.

---

# 🌍 Introduction

In the previous chapter, we learned about the **SQL Parser**.

The parser converts SQL text into a **Parse Tree**.

Example:

```sql id="sqo7k1"
SELECT *
FROM student
WHERE id = 1;
```

Parser Output:

```text id="s0hk3v"
SQL

↓

Tokens

↓

Parse Tree
```

The SQL is now valid.

But PostgreSQL still has another important question:

> 🤔 **How should this query actually be executed?**

Should it:

* Scan the entire table?
* Use an index?
* Read every row?
* Read only one page?

This decision is made by the **Query Planner**.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📈 What the Query Planner is
* ⚙️ Cost-Based Optimization
* 📊 Table Statistics
* 📄 Execution Plans
* 🔍 Sequential Scan
* 📚 Index Scan
* ⚡ Bitmap Scan
* 🧠 EXPLAIN
* 🚀 EXPLAIN ANALYZE
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ What Is the Query Planner?

The Query Planner decides the **best execution strategy** for every SQL query.

Example:

```sql id="r4x7l9"
SELECT *
FROM student
WHERE id = 1;
```

Possible strategies:

```text id="g2u0r6"
Option 1

Read Entire Table

----------------

Option 2

Use Primary Key Index

----------------

Option 3

Bitmap Scan
```

The planner estimates the cost of each strategy and chooses the cheapest one.

---

# 🏗️ Query Pipeline

```text id="w8d3h2"
SQL

↓

Parser

↓

Parse Tree

↓

Planner

↓

Execution Plan

↓

Executor
```

The Planner converts the Parse Tree into an **Execution Plan**.

---

# 🧠 Cost-Based Optimizer

PostgreSQL uses a **Cost-Based Optimizer (CBO)**.

It estimates:

* Disk reads
* CPU usage
* Memory usage
* Number of rows
* Index efficiency

Example:

```text id="n6v9q4"
Sequential Scan

Cost = 350

-----------------

Index Scan

Cost = 2
```

Planner chooses:

```text id="9y2k7c"
Index Scan
```

Lower cost wins.

---

# 📊 Where Do Costs Come From?

The Planner relies on **statistics** collected by PostgreSQL.

Examples:

```text id="k1r4p8"
Table Size

Row Count

Distinct Values

NULL Count

Column Distribution
```

These statistics are maintained by:

```sql id="d8m3z5"
ANALYZE
```

or automatically by:

```text id="f3h8v1"
Autovacuum
```

---

# 📄 Execution Plan

The Planner produces an execution plan.

Example:

```sql id="x5w2c9"
EXPLAIN

SELECT *

FROM student

WHERE id = 1;
```

Output:

```text id="a7t6e3"
Index Scan

↓

student_pkey

↓

Cost 0.15..8.17
```

This describes how PostgreSQL intends to execute the query.

---

# 🔍 Sequential Scan

Suppose:

```sql id="u2c5m1"
SELECT *
FROM student;
```

Planner chooses:

```text id="b9j7q6"
Sequential Scan

↓

Read Every Row

↓

Return Results
```

Suitable when:

* Small tables
* Most rows are required

---

# 📚 Index Scan

Suppose:

```sql id="c4n8r2"
SELECT *
FROM student
WHERE id = 1;
```

Planner chooses:

```text id="h7v3l0"
Primary Key Index

↓

Locate Row

↓

Read Data Page
```

Only a few rows are accessed.

Much faster for selective queries.

---

# ⚡ Bitmap Scan

Sometimes many rows match the condition.

Example:

```sql id="z6p1k4"
SELECT *
FROM student
WHERE marks > 90;
```

Planner may choose:

```text id="r0t5x8"
Bitmap Index Scan

↓

Bitmap Heap Scan

↓

Return Rows
```

This reduces random disk access for larger result sets.

---

# 🍃 Student Results API Example

Browser:

```http id="j5m2s7"
GET /students/1
```

Hibernate:

```sql id="e3k9w6"
SELECT *
FROM student
WHERE id = 1;
```

Planner:

```text id="t4q8v1"
Primary Key Exists?

      │
 ┌────┴────┐
 │         │
Yes       No
 │         │
 ▼         ▼
Index     Seq Scan
```

Execution then proceeds using the selected plan.

---

# 📈 EXPLAIN

Use:

```sql id="w1d7u4"
EXPLAIN

SELECT *

FROM student

WHERE id = 1;
```

Example output:

```text id="o8y5n2"
Index Scan using student_pkey

Cost=0.15..8.17

Rows=1
```

Important fields:

* Node Type
* Estimated Cost
* Estimated Rows

---

# 🚀 EXPLAIN ANALYZE

`EXPLAIN` estimates.

`EXPLAIN ANALYZE` actually runs the query.

```sql id="m4h9r5"
EXPLAIN ANALYZE

SELECT *

FROM student

WHERE id = 1;
```

Output:

```text id="y2k6w8"
Execution Time

0.08 ms
```

Now you see:

* Estimated cost
* Actual rows
* Actual execution time

---

# 📊 Planner Decision Example

Suppose:

```text id="q7v1m3"
student

10 rows
```

Planner chooses:

```text id="i4p8x6"
Sequential Scan
```

Why?

Reading 10 rows is cheaper than navigating an index.

Now suppose:

```text id="e6n3r9"
student

10 Million Rows
```

Planner chooses:

```text id="s9d5l2"
Primary Key Index
```

Scanning the whole table would be much more expensive.

---

# 🧠 Planner Statistics

The planner uses metadata such as:

```text id="u3f7h1"
Table Size

↓

Rows

↓

Value Distribution

↓

Indexes

↓

Selectivity

↓

Estimated Cost
```

Without accurate statistics, PostgreSQL may choose a poor execution plan.

---

# 🚫 Common Mistakes

## ❌ Assuming PostgreSQL Always Uses an Index

```sql id="b5w9k7"
SELECT *
FROM student;
```

For a full-table query, a Sequential Scan is often faster than using an index.

---

## ❌ Ignoring Statistics

If statistics are outdated:

```text id="x8c4n1"
Planner

↓

Wrong Cost

↓

Wrong Plan

↓

Slow Query
```

Run `ANALYZE` or rely on Autovacuum to keep statistics current.

---

## ❌ Using EXPLAIN Without Understanding Cost

```text id="m1v6p4"
Cost = 100
```

The cost is **not milliseconds**.

It is an internal unit PostgreSQL uses to compare execution strategies.

---

# 🐳 Docker Perspective

```text id="f7k2q9"
Spring Boot Container
        │
        ▼
PostgreSQL Container
        │
        ▼
Planner
        │
        ▼
Execution Plan
```

The planner works exactly the same inside Docker.

---

# ☸️ Kubernetes Perspective

```text id="d4r8m2"
Spring Boot Pod
       │
       ▼
Service
       │
       ▼
PostgreSQL Pod
       │
       ▼
Planner
```

Every SQL statement entering the PostgreSQL Pod is optimized before execution.

---

# 🧪 Hands-on Lab

## View an Execution Plan

```sql id="t2x5n7"
EXPLAIN

SELECT *

FROM student

WHERE id = 1;
```

Observe whether PostgreSQL chooses an Index Scan.

---

## Measure Actual Performance

```sql id="n8q3w1"
EXPLAIN ANALYZE

SELECT *

FROM student

WHERE id = 1;
```

Compare estimated rows with actual rows.

---

## Force a Sequential Scan

```sql id="p6v4c8"
SELECT *
FROM student;
```

Use `EXPLAIN` to verify a Sequential Scan is selected.

---

## Create an Index

```sql id="r5y9m3"
CREATE INDEX idx_student_marks
ON student(marks);
```

Run:

```sql id="g1k7u5"
EXPLAIN

SELECT *

FROM student

WHERE marks = 95;
```

Observe whether PostgreSQL now chooses an Index Scan.

---

## Refresh Statistics

```sql id="v9d2x6"
ANALYZE student;
```

Run `EXPLAIN` again and compare the estimated costs.

---

# 📈 Complete Planner Flow

```text id="h3n8q2"
SQL
 │
 ▼
Parser
 │
 ▼
Parse Tree
 │
 ▼
Planner
 │
 ├──────────────┐
 ▼              ▼
Seq Scan    Index Scan
 │              │
 └──────┬───────┘
        ▼
Execution Plan
        │
        ▼
Executor
        │
        ▼
Database Pages
```

This is the complete journey from parsed SQL to an executable plan.

---

# 📊 Scan Type Comparison

| Scan Type          | Best Use Case                                          |
| ------------------ | ------------------------------------------------------ |
| 📄 Sequential Scan | Read most or all rows from a table                     |
| 📚 Index Scan      | Retrieve a small number of matching rows               |
| ⚡ Bitmap Scan      | Retrieve many matching rows efficiently using an index |
| 📘 Index Only Scan | Read data directly from the index when possible        |

---

# 💡 Key Takeaways

✅ The Query Planner converts a parsed SQL statement into an execution plan.

✅ PostgreSQL uses a **Cost-Based Optimizer** to estimate the cheapest execution strategy.

✅ Planner decisions are based on table statistics, indexes, estimated row counts, and operation costs.

✅ Different queries may use Sequential Scans, Index Scans, Bitmap Scans, or Index Only Scans depending on the estimated cost.

✅ `EXPLAIN` shows the estimated execution plan, while `EXPLAIN ANALYZE` executes the query and reports actual performance.

✅ Accurate statistics are essential for good execution plans and efficient query performance.

✅ Understanding the Query Planner is fundamental to diagnosing slow queries and optimizing PostgreSQL applications.

---

# ➡️ Next Chapter

📘 **`08-PostgreSQL/05-Executor.md`**

In the next chapter, we'll follow the **Execution Plan** into the PostgreSQL **Executor**.

We'll learn:

* ⚡ How execution plan nodes are processed
* 📦 How table pages are read
* 🧠 Shared Buffer access
* 💽 Disk I/O
* 🔄 Row filtering
* 📤 Returning rows to the JDBC driver

By the end of the next chapter, you'll understand how PostgreSQL transforms an execution plan into actual result rows that are returned to your Spring Boot application.
