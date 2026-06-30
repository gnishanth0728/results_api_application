# 📘 Chapter 68 — PostgreSQL EXPLAIN & EXPLAIN ANALYZE

> 📂 File: `student-results-api-notes/08-PostgreSQL/10-EXPLAIN.md`

This chapter teaches one of the most important PostgreSQL debugging and performance tools.

Every database engineer, backend developer, and DevOps engineer uses EXPLAIN to answer questions like:

Why is my query slow?
Is PostgreSQL using my index?
Why is it doing a Sequential Scan?
How many rows does PostgreSQL expect to read?
How long did the query actually take?

Without EXPLAIN, you're guessing.

With EXPLAIN, you can see exactly what PostgreSQL plans to do and what it actually did.
---

# 🌍 Introduction

In the previous chapters, we learned how PostgreSQL processes SQL.

The journey looked like this:

```text id="y6a2m8"
SQL

↓

Parser

↓

Planner

↓

Execution Plan

↓

Executor

↓

Rows
```

But another important question appears:

> 🤔 **How can we see what PostgreSQL is actually doing internally?**

The answer is:

# 📊 EXPLAIN

`EXPLAIN` allows us to inspect the execution plan chosen by PostgreSQL.

It is one of the most valuable tools for understanding and optimizing SQL performance.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📊 What EXPLAIN is
* 📈 Execution Plans
* 📄 Plan Nodes
* 🔍 Sequential Scan
* 📚 Index Scan
* ⚡ EXPLAIN ANALYZE
* ⏱️ Planning Time
* 🚀 Execution Time
* 🛠️ Query Optimization
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ Why Do We Need EXPLAIN?

Suppose:

```sql id="m4r8p2"
SELECT *
FROM student
WHERE id = 1;
```

The query is slow.

Without EXPLAIN:

```text id="c7n5q4"
Developer

↓

Guess

↓

Maybe Index?

↓

Maybe Disk?
```

With EXPLAIN:

```text id="q2v9m7"
Execution Plan

↓

Index Scan

↓

Estimated Cost

↓

Estimated Rows
```

No guessing is required.

---

# 🏗️ What EXPLAIN Shows

Run:

```sql id="h6k3r1"
EXPLAIN

SELECT *

FROM student

WHERE id = 1;
```

Example output:

```text id="t9p4x6"
Index Scan

using student_pkey

Cost=0.15..8.17

Rows=1
```

This is PostgreSQL's planned execution strategy.

---

# 📄 Execution Plan

The Planner creates a tree of execution nodes.

Example:

```text id="j1m8q3"
Index Scan
     │
     ▼
Table Page
     │
     ▼
Return Row
```

Complex queries contain many nodes.

---

# 🔍 Sequential Scan

Example:

```sql id="v7n2k5"
EXPLAIN

SELECT *

FROM student;
```

Output:

```text id="w3p6r9"
Seq Scan

on student
```

Meaning:

```text id="u5m1q8"
Read

Every Row
```

Sequential Scans are efficient when most rows are needed.

---

# 📚 Index Scan

Example:

```sql id="k8r5v2"
EXPLAIN

SELECT *

FROM student

WHERE id = 1;
```

Output:

```text id="a4n9m6"
Index Scan

using student_pkey
```

Meaning:

```text id="r2q7k4"
Use B-Tree

↓

Locate Row

↓

Return Result
```

---

# ⚡ Bitmap Heap Scan

Suppose:

```sql id="e3p8x7"
SELECT *

FROM student

WHERE marks > 90;
```

Output:

```text id="f9m2v5"
Bitmap Index Scan

↓

Bitmap Heap Scan
```

Useful when many rows match.

---

# 📊 Cost

Example:

```text id="s5k7r1"
Cost=0.15..8.17
```

Meaning:

```text id="b2v9m4"
Startup Cost

↓

0.15

-------------------

Total Cost

↓

8.17
```

Important:

Cost is **not milliseconds**.

It is an internal estimate used by PostgreSQL to compare plans.

---

# 📈 Estimated Rows

Example:

```text id="y8q4n2"
Rows=1
```

Planner prediction:

```text id="c6m1p9"
Expected Rows

↓

1
```

If actual rows differ greatly from estimates, planner statistics may be outdated.

---

# ⚡ EXPLAIN ANALYZE

`EXPLAIN`:

```text id="d7r3k8"
Plan Only
```

`EXPLAIN ANALYZE`:

```text id="x5p9m1"
Execute Query

↓

Measure Performance

↓

Show Actual Statistics
```

Command:

```sql id="h2n6v4"
EXPLAIN ANALYZE

SELECT *

FROM student

WHERE id = 1;
```

---

# ⏱️ Actual Output

Example:

```text id="k1m7q5"
Index Scan

Actual Rows = 1

Execution Time = 0.08 ms
```

Now PostgreSQL reports:

* Actual rows
* Actual execution time
* Actual loops

---

# 📊 Planning Time vs Execution Time

Output:

```text id="q4v8n6"
Planning Time

0.25 ms

Execution Time

0.08 ms
```

Planning:

```text id="m8r2p7"
Parser

↓

Planner

↓

Execution Plan
```

Execution:

```text id="w1k9q3"
Executor

↓

Read Pages

↓

Return Rows
```

These are separate phases.

---

# 🍃 Student Results API Example

Browser:

```http id="z6p3x8"
GET /students/1
```

Hibernate:

```sql id="t5n7m2"
SELECT *
FROM student
WHERE id = 1;
```

Run:

```sql id="r9k4v1"
EXPLAIN ANALYZE

SELECT *

FROM student

WHERE id = 1;
```

Output:

```text id="e2m8q6"
Index Scan

↓

Execution Time

↓

0.05 ms
```

You can verify that PostgreSQL uses the primary key index.

---

# 📊 Reading a Plan

Example:

```text id="n7v1p5"
Index Scan

Cost=0.15..8.17

Rows=1

Width=40
```

Meaning:

| Field | Meaning                     |
| ----- | --------------------------- |
| Cost  | Estimated execution cost    |
| Rows  | Estimated number of rows    |
| Width | Estimated row size in bytes |
| Node  | Operation performed         |

---

# 🚫 Common Mistakes

## ❌ Assuming Cost Equals Time

```text id="b5q8r2"
Cost=100
```

This is **not** 100 milliseconds.

It is an internal planning metric.

---

## ❌ Looking Only at Execution Time

Always inspect:

* Plan node
* Cost
* Rows
* Index usage

Execution time alone rarely explains *why* a query is slow.

---

## ❌ Ignoring Actual vs Estimated Rows

Example:

```text id="u9m4k7"
Estimated

10 Rows

Actual

100000 Rows
```

Large differences usually indicate stale statistics or poor data distribution estimates.

---

# 🐳 Docker Perspective

```text id="p2r6n9"
Spring Boot Container
        │
        ▼
PostgreSQL Container
        │
        ▼
EXPLAIN
```

`EXPLAIN` behaves the same whether PostgreSQL runs on bare metal, a VM, or inside Docker.

---

# ☸️ Kubernetes Perspective

```text id="g7k1m4"
Spring Boot Pod
       │
       ▼
Service
       │
       ▼
PostgreSQL Pod
       │
       ▼
EXPLAIN ANALYZE
```

You can use `EXPLAIN` on production-like Kubernetes environments to diagnose slow queries (carefully, especially `EXPLAIN ANALYZE` on heavy write queries).

---

# 🧪 Hands-on Lab

## View a Basic Execution Plan

```sql id="j4v8p6"
EXPLAIN

SELECT *

FROM student

WHERE id = 1;
```

Observe whether PostgreSQL chooses an Index Scan.

---

## Measure Actual Performance

```sql id="k9m2q5"
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

## Compare Sequential Scan vs Index Scan

Without an index:

```sql id="w6r3n1"
EXPLAIN

SELECT *

FROM student

WHERE marks = 95;
```

Create an index:

```sql id="x8p4
```
