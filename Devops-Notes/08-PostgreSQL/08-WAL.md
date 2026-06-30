# 📘 Chapter 66 — PostgreSQL Write-Ahead Logging (WAL)

> 📂 File: `student-results-api-notes/08-PostgreSQL/08-WAL.md`

his chapter explains how PostgreSQL guarantees that committed data is never lost, even if the server crashes or loses power.

So far you've learned:

Parser 📝
Planner 📈
Executor ⚡
Shared Buffers 📦

One important question remains:

If PostgreSQL updates data only in Shared Buffers first, what happens if the server crashes before the page is written to disk?

Would the update be lost?

The answer is No, because PostgreSQL first writes every change to the Write-Ahead Log (WAL).

WAL is one of PostgreSQL's most important internal mechanisms. It provides:

💥 Crash Recovery
🔄 Point-in-Time Recovery (PITR)
🌍 Streaming Replication
🛡️ Durability (the D in ACID)

---

# 🌍 Introduction

In the previous chapter, we learned about **Shared Buffers**.

When PostgreSQL executes:

```sql id="w8k1p7"
UPDATE student
SET marks = 95
WHERE id = 1;
```

The page is modified **inside Shared Buffers**.

```text id="n2v8k1"
Shared Buffers

↓

Modified Page

↓

Dirty Page
```

But another important question appears:

> 🤔 **What if the server crashes before the dirty page is written to disk?**

Would the update disappear?

The answer is:

# 📒 Write-Ahead Logging (WAL)

Before PostgreSQL modifies the data file, it first records the change in the Write-Ahead Log.

This guarantees that committed transactions can always be recovered.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📒 What WAL is
* ✍️ WAL Records
* 💾 Write-Ahead Rule
* 💥 Crash Recovery
* 🔄 Checkpoints
* 🌍 Streaming Replication
* ⏪ Point-in-Time Recovery (PITR)
* 🛡️ ACID Durability
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ Why Do We Need WAL?

Suppose PostgreSQL directly updated the table file.

```text id="x4n2h7"
UPDATE

↓

Data File

↓

💥 Power Failure
```

The page could become partially written or corrupted.

The database might not know whether the update completed successfully.

To prevent this:

```text id="v6m9q2"
UPDATE

↓

Write WAL

↓

Flush WAL

↓

Update Shared Buffers

↓

Write Data File Later
```

This is called the **Write-Ahead Rule**.

---

# 🏗️ Write-Ahead Rule

The rule is simple:

> **The WAL record must reach durable storage before the corresponding data page is written.**

Flow:

```text id="d7q4w8"
UPDATE

↓

Generate WAL Record

↓

Write WAL

↓

Flush WAL

↓

Modify Data Page

↓

Commit
```

Only after the WAL is safely stored can PostgreSQL report success.

---

# 📦 WAL Record

Suppose:

```sql id="j5r8t1"
UPDATE student
SET marks = 95
WHERE id = 1;
```

PostgreSQL generates a WAL record similar to:

```text id="m3c6k9"
Transaction ID = 123

Table = student

Page = 42

Offset = 7

Old Value = 90

New Value = 95
```

The WAL stores **how to reproduce the change**, not a copy of the entire database.

---

# 🔄 Complete Update Flow

```text id="p1v7m4"
SQL UPDATE
      │
      ▼
Executor
      │
      ▼
Modify Shared Buffers
      │
      ▼
Generate WAL Record
      │
      ▼
WAL Buffer
      │
      ▼
WAL File
      │
      ▼
COMMIT
      │
      ▼
Background Writer
      │
      ▼
Data File
```

Notice that the WAL reaches durable storage before the table page.

---

# 💥 Crash Scenario

Suppose:

```text id="r8n2j5"
UPDATE

↓

WAL Written

↓

💥 Server Crash

↓

Dirty Page NOT Written
```

After restart:

```text id="k4w9p1"
Read WAL

↓

Replay WAL

↓

Recreate Data Page

↓

Database Consistent
```

The committed transaction is recovered successfully.

---

# 🔄 Crash Recovery

Recovery process:

```text id="y6m3t8"
Server Starts

↓

Read Last Checkpoint

↓

Read WAL

↓

Replay Changes

↓

Database Ready
```

Only committed transactions are recovered.

Uncommitted transactions are discarded.

---

# 📍 Checkpoints

Writing every dirty page immediately would be slow.

Instead PostgreSQL periodically creates **Checkpoints**.

```text id="b7k1v6"
Dirty Pages

↓

Checkpoint

↓

Write Pages

↓

Update Checkpoint Record
```

Recovery starts from the latest checkpoint rather than replaying the entire WAL history.

---

# 🌍 Streaming Replication

WAL is also used for replication.

```text id="g5n8p2"
Primary Server

↓

Generate WAL

↓

Send WAL

↓

Replica Server

↓

Replay WAL

↓

Replica Updated
```

The replica applies WAL records to stay synchronized with the primary.

---

# ⏪ Point-in-Time Recovery (PITR)

Suppose:

```text id="s2m4q9"
10:00 Backup

↓

10:05 WAL

↓

10:10 WAL

↓

10:15 WAL

↓

10:20 Mistake
```

With WAL you can restore:

```text id="v9t3k7"
Backup

+

Replay WAL

↓

Recover Database

↓

Stop at 10:19
```

This is **Point-in-Time Recovery**.

---

# 🍃 Student Results API Example

Browser:

```http id="u4j6r1"
PUT /students/1
```

Hibernate:

```sql id="a8p5w3"
UPDATE student
SET marks = 95
WHERE id = 1;
```

PostgreSQL:

```text id="f2k7m9"
Executor

↓

Shared Buffers

↓

Generate WAL

↓

Flush WAL

↓

COMMIT

↓

Background Writer

↓

Data File
```

Only after the WAL is safely stored does PostgreSQL acknowledge the commit.

---

# 📊 WAL Architecture

```text id="q1v8r4"
Spring Boot
      │
      ▼
Hibernate
      │
      ▼
JDBC
      │
      ▼
PostgreSQL
      │
      ▼
Executor
      │
      ▼
Shared Buffers
      │
      ▼
Generate WAL
      │
      ▼
WAL Buffer
      │
      ▼
WAL Files
      │
      ▼
Checkpoint
      │
      ▼
Data Files
```

---

# 🛡️ WAL and ACID

WAL primarily guarantees the **Durability** property of ACID.

```text id="h6m2p8"
Transaction

↓

COMMIT

↓

WAL Flushed

↓

Success Returned
```

Even if the server crashes immediately afterward, PostgreSQL can recover the committed changes from the WAL.

---

# 🚫 Common Mistakes

## ❌ Assuming Data Files Are Updated First

The order is:

```text id="l9t5k2"
WAL

↓

Data Files
```

Never the other way around.

---

## ❌ Confusing WAL with a Backup

The WAL is **not** a full database backup.

It contains the changes required to recover or replay database modifications.

---

## ❌ Ignoring Checkpoints

Without checkpoints, crash recovery would require replaying the WAL from the beginning of the database's lifetime.

Checkpoints dramatically reduce recovery time.

---

# 🐳 Docker Perspective

```text id="c3n7w5"
Spring Boot Container
        │
        ▼
PostgreSQL Container
        │
        ├── WAL Files
        │
        └── Data Files
```

If Docker uses a persistent volume, both WAL files and data files survive container restarts.

---

# ☸️ Kubernetes Perspective

```text id="z8p1m4"
Spring Boot Pod
       │
       ▼
Service
       │
       ▼
PostgreSQL Pod
       │
       ├── WAL
       │
       └── Persistent Volume
```

Persistent Volumes preserve WAL files and table data across Pod restarts.

---

# 🧪 Hands-on Lab

## View WAL Settings

```sql id="t5r9q3"
SHOW wal_level;

SHOW max_wal_size;

SHOW min_wal_size;
```

Observe the current WAL configuration.

---

## Force a Checkpoint

```sql id="e2m8v6"
CHECKPOINT;
```

Observe that dirty pages are flushed to disk.

---

## View WAL Statistics

```sql id="w7k3p1"
SELECT
    wal_records,
    wal_fpi,
    wal_bytes
FROM pg_stat_wal;
```

Monitor WAL activity generated by your workload.

---

## Generate WAL

Run:

```sql id="x4n7q8"
UPDATE student
SET marks = marks + 1;
```

Then query `pg_stat_wal` again to observe increased WAL activity.

---

## Inspect WAL Directory

On the PostgreSQL server:

```bash id="m8v2r5"
ls $PGDATA/pg_wal
```

Observe the WAL segment files created by PostgreSQL.

---

# 📈 Complete WAL Flow

```text id="n6q3w7"
SQL UPDATE
      │
      ▼
Executor
      │
      ▼
Shared Buffers
      │
      ▼
Generate WAL Record
      │
      ▼
WAL Buffer
      │
      ▼
Flush WAL
      │
      ▼
COMMIT
      │
      ▼
Background Writer
      │
      ▼
Data Files
      │
      ▼
Crash?
      │
 ┌────┴─────┐
 ▼          ▼
No       Recovery
            │
            ▼
       Replay WAL
            │
            ▼
     Database Consistent
```

This is the complete lifecycle of an update protected by Write-Ahead Logging.

---

# 📊 WAL Component Summary

| Component                | Responsibility                                                 |
| ------------------------ | -------------------------------------------------------------- |
| 📒 WAL Record            | Describes a database change                                    |
| 🧠 WAL Buffer            | Temporarily stores WAL records in memory                       |
| 💽 WAL Files (`pg_wal`)  | Persist WAL records on disk                                    |
| 📍 Checkpoint            | Synchronizes dirty pages and creates a recovery starting point |
| 🔄 Crash Recovery        | Replays WAL after an unexpected shutdown                       |
| 🌍 Streaming Replication | Ships WAL records to replica servers                           |
| ⏪ PITR                   | Restores the database to a chosen point in time                |

---

# 💡 Key Takeaways

✅ PostgreSQL follows the **Write-Ahead Rule**: WAL records are written and flushed before corresponding data pages are written.

✅ WAL ensures the **Durability** property of ACID by preserving committed changes even after crashes.

✅ Modified pages remain in Shared Buffers as dirty pages and are written to table files later by background processes.

✅ During recovery, PostgreSQL starts from the latest checkpoint and replays WAL records to restore committed transactions.

✅ WAL is also the foundation for streaming replication and Point-in-Time Recovery (PITR).

✅ Checkpoints reduce crash recovery time by limiting how much WAL must be replayed.

✅ Understanding WAL is essential for database reliability, backup strategies, disaster recovery, and high availability.

---

# ➡️ Next Chapter

📘 **`08-PostgreSQL/09-MVCC.md`**

In the next chapter, we'll explore **Multi-Version Concurrency Control (MVCC)**, one of PostgreSQL's most powerful concurrency mechanisms.

We'll learn:

* 👥 How readers and writers work simultaneously
* 📸 Row versions (tuple versions)
* 🆔 Transaction IDs (`xmin` and `xmax`)
* 🚫 Why readers don't block writers
* 🔒 Isolation levels
* 🧹 Dead tuples and VACUUM

By the end of the next chapter, you'll understand how PostgreSQL supports thousands of concurrent users while maintaining consistency without locking entire tables.
