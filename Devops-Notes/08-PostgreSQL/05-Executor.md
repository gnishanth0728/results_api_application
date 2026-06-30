# 📘 Chapter 63 — PostgreSQL Query Executor

> 📂 File: `student-results-api-notes/08-PostgreSQL/05-Executor.md`

The previous chapter ended with the Planner producing an execution plan.

Now the next question is:

Who actually executes that plan?

The answer is the Executor.

The Executor:

Walks through the execution plan
Reads pages from Shared Buffers or disk
Applies filters (WHERE)
Performs joins, sorting, aggregation
Produces result rows
Sends them back to the JDBC driver

This is the point where SQL becomes actual data.

---

# 🌍 Introduction

In the previous chapter, we learned about the **Query Planner**.

The Planner takes a parsed SQL statement and generates the most efficient **Execution Plan**.

Example:

```sql id="7xj9d2"
SELECT *
FROM student
WHERE id = 1;
```

Execution Plan:

```text id="9m3k7v"
Index Scan

↓

student_pkey

↓

Estimated Cost = 0.15
```

But an execution plan is only a blueprint.

It does **not** actually retrieve any data.

This raises the next important question:

> 🤔 **Who executes the plan and reads the actual rows from disk?**

The answer is:

# ⚡ PostgreSQL Executor

The Executor is responsible for running the execution plan and producing the query results.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* ⚡ What the Executor is
* 📄 Execution Plan Nodes
* 📦 Shared Buffers
* 💽 Disk Reads
* 🔍 Row Filtering
* 🔗 Join Execution
* 📤 Result Generation
* 🧠 Buffer Manager
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ What Is the Executor?

The Executor is the component that **runs the execution plan**.

Flow:

```text id="g8v5m1"
Planner

↓

Execution Plan

↓

Executor

↓

Rows
```

The Planner decides **what to do**.

The Executor performs the actual work.

---

# 🏗️ Complete Query Pipeline

```text id="4p9h6r"
SQL

↓

Parser

↓

Analyzer

↓

Planner

↓

Execution Plan

↓

Executor

↓

Result Rows
```

The Executor is the last major stage before data is returned to the client.

---

# 📄 Execution Plan Nodes

An execution plan is made of **nodes**.

Example:

```sql id="r6w2q4"
SELECT *
FROM student
WHERE id = 1;
```

Plan:

```text id="v1x8n5"
Index Scan
```

More complex query:

```sql id="d7m4k9"
SELECT *

FROM student

JOIN marks

ON student.id = marks.student_id;
```

Plan:

```text id="c3z7p1"
Nested Loop

↓

Index Scan

↓

Seq Scan
```

The Executor processes these nodes one by one.

---

# 📦 Reading Data

Suppose the plan requires:

```text id="k9f2u6"
Index Scan
```

The Executor first asks:

```text id="a5h8r3"
Is Page in Shared Buffers?

      │
 ┌────┴────┐
 │         │
Yes       No
 │         │
 ▼         ▼
Read      Disk
Memory    Read
```

Whenever possible, PostgreSQL avoids reading from disk.

---

# 🧠 Shared Buffers

If the required page is already cached:

```text id="z8w4m7"
Executor

↓

Shared Buffers

↓

Page Found

↓

Return Row
```

This is called a **Cache Hit**.

Cache hits are significantly faster than disk access.

---

# 💽 Disk Read

If the page is not cached:

```text id="u2n6k8"
Executor

↓

Buffer Manager

↓

Disk

↓

Read Page

↓

Shared Buffers

↓

Executor
```

The page is loaded into Shared Buffers before being processed.

---

# 🔍 Applying the WHERE Clause

Suppose:

```sql id="j1q9v3"
SELECT *
FROM student
WHERE marks > 90;
```

Executor:

```text id="y4p7r5"
Read Row

↓

marks = 85

↓

Discard

----------------

Read Row

↓

marks = 95

↓

Return
```

Only matching rows are passed to the next stage.

---

# 🔗 Join Execution

Suppose:

```sql id="x8t3h6"
SELECT *

FROM student

JOIN marks

ON student.id = marks.student_id;
```

The Executor may perform:

```text id="q5m1c9"
Read Student

↓

Read Marks

↓

Compare Keys

↓

Join Rows

↓

Return Result
```

Different execution plans use different join algorithms.

---

# 📊 Sorting

Example:

```sql id="h3v8k2"
SELECT *

FROM student

ORDER BY marks;
```

Execution:

```text id="p7n4x1"
Read Rows

↓

Sort

↓

Return Sorted Rows
```

Sorting may happen in memory or on disk depending on the amount of data.

---

# 📈 Aggregation

Example:

```sql id="b6j2r8"
SELECT AVG(marks)

FROM student;
```

Execution:

```text id="s9q5v4"
Read Row

↓

Accumulate Total

↓

Count Rows

↓

Compute Average

↓

Return Value
```

The Executor performs the aggregation while reading rows.

---

# 🍃 Student Results API Example

Browser:

```http id="l2w7m5"
GET /students/1
```

Hibernate:

```sql id="m8c1p7"
SELECT *
FROM student
WHERE id = 1;
```

Executor:

```text id="e6r9k3"
Execution Plan

↓

Index Scan

↓

Shared Buffers

↓

Disk (if necessary)

↓

Student Row

↓

Hibernate
```

The retrieved row is then converted into a Java Entity.

---

# 📊 Executor Architecture

```text id="f4h8y2"
Execution Plan
      │
      ▼
Executor
      │
      ▼
Buffer Manager
      │
 ┌────┴────┐
 ▼         ▼
Cache     Disk
 │         │
 └────┬────┘
      ▼
Process Rows
      │
      ▼
Return Results
```

The Executor works closely with the Buffer Manager.

---

# 🚫 Common Mistakes

## ❌ Thinking the Planner Reads Data

The Planner never reads table data.

It only creates an execution strategy.

Reading data is the Executor's responsibility.

---

## ❌ Assuming Every Query Reads the Disk

Most frequently accessed data comes from Shared Buffers.

Disk reads occur mainly on cache misses.

---

## ❌ Ignoring Execution Plans

Without understanding execution plans, it is difficult to explain why one query runs in milliseconds while another takes seconds.

---

# 🐳 Docker Perspective

```text id="g1r6p8"
Spring Boot Container
        │
        ▼
PostgreSQL Container
        │
        ▼
Executor
        │
        ▼
Shared Buffers
        │
        ▼
Volume
```

The Executor runs inside the PostgreSQL process regardless of containerization.

---

# ☸️ Kubernetes Perspective

```text id="v5k2h9"
Spring Boot Pod
       │
       ▼
Service
       │
       ▼
PostgreSQL Pod
       │
       ▼
Executor
       │
       ▼
Persistent Volume
```

The Executor retrieves pages from PostgreSQL's storage managed by the Persistent Volume.

---

# 🧪 Hands-on Lab

## View an Execution Plan

```sql id="c9m7q1"
EXPLAIN

SELECT *

FROM student

WHERE id = 1;
```

Observe the execution plan node selected by PostgreSQL.

---

## Measure Actual Execution

```sql id="n2t6v8"
EXPLAIN ANALYZE

SELECT *

FROM student

WHERE id = 1;
```

Observe:

* Planning Time
* Execution Time
* Actual Rows

---

## Force a Sequential Scan

```sql id="j7f4r3"
SELECT *
FROM student;
```

Run `EXPLAIN ANALYZE` and observe every row being read.

---

## Test ORDER BY

```sql id="k5w9h6"
EXPLAIN ANALYZE

SELECT *

FROM student

ORDER BY marks;
```

Observe the `Sort` node in the execution plan.

---

## Test Aggregation

```sql id="q1p8x4"
EXPLAIN ANALYZE

SELECT AVG(marks)

FROM student;
```

Observe the `Aggregate` node.

---

# 📈 Complete Executor Flow

```text id="d8n3m7"
SQL
 │
 ▼
Parser
 │
 ▼
Planner
 │
 ▼
Execution Plan
 │
 ▼
Executor
 │
 ▼
Buffer Manager
 │
 ├───────────────┐
 ▼               ▼
Shared Buffers   Disk
 │               │
 └──────┬────────┘
        ▼
Read Pages
        │
        ▼
Apply Filters
        │
        ▼
Join / Sort / Aggregate
        │
        ▼
Return Rows
        │
        ▼
JDBC Driver
        │
        ▼
Hibernate
```

This is the complete execution path inside PostgreSQL after the Planner finishes its work.

---

# 📊 Common Execution Plan Nodes

| Plan Node          | Responsibility                                                        |
| ------------------ | --------------------------------------------------------------------- |
| 📄 Sequential Scan | Read every row in a table                                             |
| 📚 Index Scan      | Read rows using an index                                              |
| 📘 Index Only Scan | Read directly from an index without accessing the table when possible |
| ⚡ Bitmap Heap Scan | Efficiently retrieve many matching rows                               |
| 🔗 Nested Loop     | Join two data sources by iterating over one and probing the other     |
| 🧮 Aggregate       | Compute values such as `COUNT`, `SUM`, or `AVG`                       |
| 📊 Sort            | Order rows before returning them                                      |

---

# 💡 Key Takeaways

✅ The Executor is responsible for running the execution plan produced by the Planner.

✅ Execution plans consist of nodes such as Sequential Scan, Index Scan, Sort, Aggregate, and Join operations.

✅ The Executor retrieves pages from Shared Buffers whenever possible and falls back to disk on cache misses.

✅ The `WHERE` clause, joins, sorting, and aggregation are all performed during execution.

✅ Query performance depends heavily on cache hits, execution plan quality, and efficient access to storage.

✅ `EXPLAIN ANALYZE` is one of the most valuable tools for understanding what the Executor actually does.

✅ The Executor transforms an execution plan into actual database rows that are ultimately returned through JDBC to Hibernate and then to your Spring Boot application.

---

# ➡️ Next Chapter

📘 **`08-PostgreSQL/06-Shared-Buffers.md`**

In the next chapter, we'll explore **Shared Buffers**, PostgreSQL's primary in-memory cache.

We'll answer questions such as:

* 📦 What are Shared Buffers?
* 🧠 How are database pages cached?
* 💽 What is a cache hit versus a cache miss?
* 🔄 How does page replacement work?
* 🚀 Why do repeated queries become much faster?

By the end of the next chapter, you'll understand why PostgreSQL often serves queries from RAM instead of reading from disk, making modern database systems dramatically faster.
