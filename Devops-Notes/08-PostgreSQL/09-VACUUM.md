# 📘 Chapter 67 — PostgreSQL VACUUM

> 📂 File: `student-results-api-notes/08-PostgreSQL/09-VACUUM.md`

This chapter explains one of PostgreSQL's most unique maintenance features.

After learning about MVCC (where updates create new row versions instead of overwriting existing rows), an important question naturally follows:

If old row versions are never immediately deleted, won't the database keep growing forever?

The answer is:

VACUUM

VACUUM is PostgreSQL's cleanup mechanism. It removes dead tuples created by MVCC, reclaims storage, updates statistics, and keeps the database performing efficiently.

Without VACUUM, PostgreSQL databases would eventually suffer from table bloat, slower queries, and even transaction ID wraparound, which can stop the database.

---

# 🌍 Introduction

In the previous chapter, we learned about **Multi-Version Concurrency Control (MVCC)**.

Suppose we execute:

```sql id="b2n7x4"
UPDATE student
SET marks = 95
WHERE id = 1;
```

PostgreSQL does **not** overwrite the existing row.

Instead:

```text id="m7r2q8"
Old Tuple

↓

New Tuple

↓

Old Tuple Becomes Dead
```

This design allows readers and writers to work simultaneously.

But another important question appears:

> 🤔 **What happens to the dead tuple?**

Does PostgreSQL keep it forever?

❌ No.

Dead tuples are cleaned up by **VACUUM**.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🧹 What VACUUM is
* 💀 Dead Tuples
* 🌱 Live Tuples
* 📈 Table Bloat
* 🤖 Autovacuum
* 📊 Statistics
* 🔄 Transaction ID Wraparound
* 🚀 VACUUM FULL
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ Why Does PostgreSQL Need VACUUM?

Suppose we update the same row several times.

```sql id="h5t9p3"
UPDATE student
SET marks = 91;

UPDATE student
SET marks = 92;

UPDATE student
SET marks = 93;
```

Internally:

```text id="k4v8m1"
Tuple 1 (Dead)

↓

Tuple 2 (Dead)

↓

Tuple 3 (Dead)

↓

Tuple 4 (Live)
```

Old tuples remain in the table until they are cleaned.

---

# 🏗️ MVCC Without VACUUM

Imagine a table containing 1 million rows.

After many updates:

```text id="q8p2w6"
Live Tuples

1,000,000

--------------------

Dead Tuples

600,000
```

The Executor must skip dead tuples while scanning.

This wastes:

* Disk space
* Memory
* CPU
* I/O bandwidth

---

# 🧹 What Does VACUUM Do?

VACUUM scans table pages and:

* Removes dead tuples
* Marks space as reusable
* Updates visibility information
* Refreshes planner statistics (when using `VACUUM ANALYZE`)

Flow:

```text id="n6x4r7"
Table

↓

Find Dead Tuples

↓

Mark Free Space

↓

Update Visibility Map

↓

Finish
```

---

# 🌱 Live vs Dead Tuples

Example:

```text id="p3m9q5"
Page

------------------

Live Tuple

Live Tuple

Dead Tuple

Live Tuple

Dead Tuple
```

After VACUUM:

```text id="f7k2v1"
Page

------------------

Live Tuple

Live Tuple

Free Space

Live Tuple

Free Space
```

The free space can be reused for future inserts and updates.

---

# 📈 Table Bloat

Without VACUUM:

```text id="x5r8m4"
Live Data

500 MB

Dead Tuples

700 MB
```

Actual table size:

```text id="z9p6k2"
1.2 GB
```

Even though only 500 MB of live data remains.

This unnecessary growth is called **Table Bloat**.

---

# 🤖 Autovacuum

Fortunately, PostgreSQL automatically runs VACUUM.

Background architecture:

```text id="u4n7q9"
Postmaster

↓

Autovacuum Launcher

↓

Autovacuum Worker

↓

VACUUM Tables
```

Most production systems rely on Autovacuum.

---

# 📊 VACUUM ANALYZE

Regular VACUUM cleans dead tuples.

```sql id="r1v5m8"
VACUUM student;
```

`VACUUM ANALYZE` also refreshes table statistics.

```sql id="t8p3x6"
VACUUM ANALYZE student;
```

Benefits:

```text id="d2m9k4"
Clean Dead Tuples

+

Update Statistics

↓

Better Query Plans
```

---

# 🚀 VACUUM FULL

Normal VACUUM:

```text id="s7q4n2"
Remove Dead Tuples

↓

Reuse Space
```

The physical table size usually remains the same.

`VACUUM FULL`:

```sql id="e5v8r1"
VACUUM FULL student;
```

Execution:

```text id="w9k2p7"
Create Compact Copy

↓

Replace Old Table

↓

Shrink Disk Size
```

Advantages:

* Reclaims disk space

Disadvantages:

* Requires an exclusive table lock
* Can take significant time on large tables

---

# 🔄 Transaction ID Wraparound

Every PostgreSQL transaction receives a Transaction ID (XID).

Example:

```text id="c6n3v5"
Transaction

↓

XID

↓

1

2

3

...

4,294,967,295
```

Transaction IDs are finite.

Without VACUUM:

```text id="a2p7m9"
Old XIDs

↓

Cannot Be Reused

↓

Wraparound Risk
```

If wraparound occurs, PostgreSQL may refuse further writes to protect data integrity.

VACUUM prevents this by freezing old tuples.

---

# ❄️ FREEZE

Sometimes VACUUM performs:

```sql id="k8r4q2"
VACUUM FREEZE student;
```

Purpose:

```text id="h3m7p8"
Old XIDs

↓

Frozen

↓

Never Need Checking Again
```

This protects against transaction ID wraparound.

---

# 🍃 Student Results API Example

Suppose users continuously update marks.

```http id="v6x2r5"
PUT /students/1
```

Every update creates:

```text id="j4q9n1"
Old Tuple

↓

Dead Tuple

↓

New Tuple
```

Later:

```text id="m8p5v7"
Autovacuum

↓

Remove Dead Tuples

↓

Reuse Space
```

The API continues running without manual cleanup.

---

# 📊 VACUUM Architecture

```text id="y5n3k8"
Application
      │
      ▼
UPDATE
      │
      ▼
MVCC
      │
      ▼
Dead Tuples
      │
      ▼
Autovacuum
      │
      ▼
Free Space
      │
      ▼
Future Inserts
```

VACUUM works continuously in the background.

---

# 🚫 Common Mistakes

## ❌ Disabling Autovacuum

Without Autovacuum:

```text id="u8m4q1"
Updates

↓

Dead Tuples

↓

Table Bloat

↓

Slow Queries
```

Autovacuum should almost always remain enabled.

---

## ❌ Running VACUUM FULL Frequently

`VACUUM FULL` locks the table.

It should be reserved for situations where reclaiming disk space is truly necessary.

---

## ❌ Ignoring Table Bloat

Large bloated tables:

* Require more disk I/O
* Consume more memory
* Increase backup size
* Slow sequential scans

Monitor and address bloat proactively.

---

# 🐳 Docker Perspective

```text id="q7r2v6"
PostgreSQL Container
        │
        ▼
Autovacuum
        │
        ▼
Shared Buffers
        │
        ▼
Volume
```

Autovacuum runs normally inside the PostgreSQL container.

---

# ☸️ Kubernetes Perspective

```text id="n4p8m3"
Spring Boot Pod
       │
       ▼
Service
       │
       ▼
PostgreSQL Pod
       │
       ▼
Autovacuum
       │
       ▼
Persistent Volume
```

Autovacuum operates inside the PostgreSQL Pod without application involvement.

---

# 🧪 Hands-on Lab

## Observe Dead Tuples

```sql id="v2m6k9"
SELECT
    relname,
    n_live_tup,
    n_dead_tup
FROM pg_stat_user_tables;
```

Monitor live and dead tuple counts.

---

## Run VACUUM

```sql id="r8q3p1"
VACUUM student;
```

Observe that dead tuples are cleaned and space becomes reusable.

---

## Update Statistics

```sql id="w5n7v4"
VACUUM ANALYZE student;
```

Then execute:

```sql id="j3k8m2"
EXPLAIN
SELECT *
FROM student
WHERE id = 1;
```

Compare the execution plan before and after updating statistics.

---

## Measure Table Size

```sql id="x9p4r6"
SELECT
    pg_size_pretty(
        pg_relation_size('student')
    );
```

Observe the table size.

---

## View Autovacuum Activity

```sql id="m6q2v8"
SELECT
    relname,
    last_autovacuum,
    last_vacuum
FROM pg_stat_user_tables;
```

Verify when Autovacuum last processed each table.

---

# 📈 Complete VACUUM Flow

```text id="t7n5p3"
UPDATE
   │
   ▼
MVCC
   │
   ▼
Dead Tuples
   │
   ▼
Autovacuum
   │
   ▼
Scan Table
   │
   ▼
Remove Dead Tuples
   │
   ▼
Free Space
   │
   ▼
Future INSERT / UPDATE
```

This is the complete lifecycle of dead tuple cleanup in PostgreSQL.

---

# 📊 VACUUM Commands

| Command          | Purpose                                                            |
| ---------------- | ------------------------------------------------------------------ |
| `VACUUM`         | Removes dead tuples and makes space reusable                       |
| `VACUUM ANALYZE` | Cleans dead tuples and updates planner statistics                  |
| `VACUUM FULL`    | Rewrites the table to reclaim disk space (requires exclusive lock) |
| `VACUUM FREEZE`  | Freezes old transaction IDs to prevent wraparound                  |

---

# 💡 Key Takeaways

✅ PostgreSQL uses MVCC, so updates and deletes create dead tuples instead of immediately removing old row versions.

✅ VACUUM scans tables, removes dead tuples, and marks their space as reusable for future operations.

✅ Regular VACUUM prevents table bloat and helps maintain good query performance.

✅ Autovacuum automatically runs in the background and should remain enabled in almost all production environments.

✅ `VACUUM ANALYZE` also refreshes planner statistics, improving query optimization.

✅ `VACUUM FULL` physically shrinks tables but requires an exclusive lock and should be used sparingly.

✅ VACUUM also protects PostgreSQL from transaction ID wraparound by freezing old tuples when necessary.

---

# ➡️ Next Chapter

📘 **`08-PostgreSQL/10-Locks-and-Concurrency.md`**

In the next chapter, we'll explore how PostgreSQL manages concurrent access to data.

We'll cover:

* 🔒 Row-level locks
* 📋 Table locks
* ⏳ Lock queues
* 🤝 Deadlocks
* 🚦 Lock modes
* ⚖️ How locks work together with MVCC

By the end of the next chapter, you'll understand how PostgreSQL safely handles thousands of simultaneous transactions while maintaining consistency and preventing data corruption.
