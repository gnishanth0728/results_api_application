# 📘 Chapter 65 — PostgreSQL Shared Buffers

> 📂 File: `student-results-api-notes/08-PostgreSQL/07-Shared-Buffers.md`

This chapter explains why PostgreSQL is fast.

Many developers think the database reads from disk for every query.

In reality, that almost never happens.

Instead, PostgreSQL first checks a large memory cache called Shared Buffers.

If the requested data is already in memory (cache hit), PostgreSQL avoids disk I/O entirely.

This chapter explains how Shared Buffers work internally, how pages move between RAM and disk, and why repeated queries become dramatically faster.

---

# 🌍 Introduction

In the previous chapter, we learned about **Indexes**.

The Planner may choose:

```sql
SELECT *
FROM student
WHERE id = 1;
```

Execution Plan:

```text
Index Scan

↓

Leaf Page

↓

Table Page
```

But another important question appears:

> 🤔 **Where does PostgreSQL actually read that page from?**

Does it always read from disk?

❌ No.

Before touching the disk, PostgreSQL first checks its in-memory cache called **Shared Buffers**.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📦 What Shared Buffers are
* 💾 Database Pages
* 🧠 Buffer Manager
* ⚡ Cache Hits
* 💽 Cache Misses
* 🔄 Page Replacement
* ✍️ Dirty Pages
* 🚀 Query Performance
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ Why Do We Need Shared Buffers?

Reading from RAM is thousands of times faster than reading from disk.

Without Shared Buffers:

```text
SQL

↓

Disk

↓

Result
```

Every query would require physical disk I/O.

With Shared Buffers:

```text
SQL

↓

RAM

↓

Result
```

Most queries avoid disk completely.

---

# 🏗️ PostgreSQL Memory Architecture

```text
                PostgreSQL

+--------------------------------------+

| Backend Process                      |

|                                      |

|        Shared Memory                 |

|   +------------------------------+   |

|   | Shared Buffers               |   |

|   | WAL Buffers                  |   |

|   | Lock Tables                  |   |

|   +------------------------------+   |

+--------------------------------------+

              │

              ▼

         Data Files
```

Shared Buffers live inside PostgreSQL's shared memory segment.

All backend processes can access them.

---

# 📄 What Is a Database Page?

PostgreSQL stores data in **pages**.

Typical page size:

```text
8 KB
```

Example:

```text
student table

↓

Page 1

↓

Page 2

↓

Page 3

↓

...
```

PostgreSQL never reads a single row from disk.

It always reads an entire page.

---

# 📦 What Is Shared Buffers?

Shared Buffers is PostgreSQL's primary cache.

```text
Disk

↓

Read Page

↓

Shared Buffers

↓

Executor
```

Once a page is cached:

Future queries can reuse it directly from memory.

---

# ⚡ Cache Hit

Suppose:

```sql
SELECT *
FROM student
WHERE id = 1;
```

Execution:

```text
Executor

↓

Buffer Manager

↓

Shared Buffers

↓

Page Found

↓

Return Row
```

No disk access occurs.

This is called a **Cache Hit**.

---

# 💽 Cache Miss

Suppose the page is not cached.

Execution:

```text
Executor

↓

Buffer Manager

↓

Shared Buffers

↓

Page Missing

↓

Disk Read

↓

Load Page

↓

Shared Buffers

↓

Return Row
```

The page is now cached for future queries.

---

# 🔄 Query Example

First execution:

```sql
SELECT *
FROM student
WHERE id = 1;
```

Flow:

```text
Query

↓

Disk

↓

Shared Buffers

↓

Executor
```

Second execution:

```sql
SELECT *
FROM student
WHERE id = 1;
```

Flow:

```text
Query

↓

Shared Buffers

↓

Executor
```

Notice that the second query avoids disk completely.

---

# 🧠 Buffer Manager

The Buffer Manager controls Shared Buffers.

Responsibilities:

* Locate cached pages
* Load missing pages
* Evict old pages
* Track dirty pages

Architecture:

```text
Executor

↓

Buffer Manager

↓

Shared Buffers

↓

Disk
```

Every page request goes through the Buffer Manager.

---

# ✍️ Dirty Pages

Suppose:

```sql
UPDATE student
SET marks = 95
WHERE id = 1;
```

PostgreSQL updates:

```text
Shared Buffers

↓

Modified Page

↓

Dirty Page
```

The page is **not immediately written to disk**.

Instead:

```text
Dirty Page

↓

Background Writer

↓

Disk
```

This improves performance by batching writes.

---

# 🔄 Page Replacement

Shared Buffers has limited memory.

Eventually it becomes full.

```text
Shared Buffers

Page A

Page B

Page C

Page D
```

New page arrives:

```text
Need Free Space

↓

Choose Victim Page

↓

Evict

↓

Load New Page
```

The Buffer Manager decides which page to replace.

---

# 📊 Cache Hit Ratio

A healthy PostgreSQL server typically has a high cache hit ratio.

Example:

```text
1000 Queries

↓

995 Cache Hits

↓

5 Disk Reads
```

Cache Hit Ratio:

```text
99.5%
```

Higher ratios usually indicate better performance.

---

# 🍃 Student Results API Example

Browser:

```http
GET /students/1
```

Hibernate:

```sql
SELECT *
FROM student
WHERE id = 1;
```

Executor:

```text
Index Scan

↓

Buffer Manager

↓

Shared Buffers?

│

├── Yes → Return Row

└── No → Read Disk
```

The application never knows whether the row came from RAM or disk.

---

# 🚀 Why Shared Buffers Improve Performance

Disk access:

```text
Milliseconds
```

Memory access:

```text
Nanoseconds
```

Repeated queries become dramatically faster because the required pages remain cached.

---

# 📊 Shared Buffers Flow

```text
SQL

↓

Planner

↓

Executor

↓

Buffer Manager

↓

Shared Buffers

↓

Cache Hit?

│

├── Yes

│      ↓

│   Return Row

│

└── No

       ↓

     Disk

       ↓

Shared Buffers

       ↓

Return Row
```

---

# 🚫 Common Mistakes

## ❌ Assuming Every Query Reads the Disk

Most production databases serve the majority of queries directly from Shared Buffers.

---

## ❌ Confusing Shared Buffers with the Operating System Cache

PostgreSQL maintains its own cache.

The operating system also caches file pages.

These are separate layers of caching.

---

## ❌ Allocating Excessive Shared Buffers

More memory is not always better.

Very large Shared Buffer settings can reduce memory available for the operating system page cache and other workloads.

Choose values appropriate for the server.

---

# 🐳 Docker Perspective

```text
Spring Boot Container
        │
        ▼
PostgreSQL Container
        │
        ▼
Shared Buffers
        │
        ▼
Volume
```

Shared Buffers exist inside the PostgreSQL process running in the container.

---

# ☸️ Kubernetes Perspective

```text
Spring Boot Pod
       │
       ▼
Service
       │
       ▼
PostgreSQL Pod
       │
       ▼
Shared Buffers
       │
       ▼
Persistent Volume
```

If the PostgreSQL Pod restarts, Shared Buffers are emptied because they reside in RAM, while the data remains safely stored on the Persistent Volume.

---

# 🧪 Hands-on Lab

## Check Shared Buffer Size

```sql
SHOW shared_buffers;
```

Observe the configured cache size.

---

## Execute the Same Query Twice

```sql
SELECT *
FROM student
WHERE id = 1;
```

Run the query repeatedly.

Notice that later executions are usually faster because the page is already cached.

---

## View Buffer Statistics

```sql
SELECT
    blks_hit,
    blks_read
FROM pg_stat_database
WHERE datname = current_database();
```

Compare:

* `blks_hit` → Pages served from Shared Buffers
* `blks_read` → Pages read from disk

---

## Calculate Cache Hit Ratio

```sql
SELECT
    round(
        blks_hit * 100.0 /
        (blks_hit + blks_read),
        2
    ) AS cache_hit_percent
FROM pg_stat_database
WHERE datname = current_database();
```

A high percentage indicates effective caching.

---

## Observe Shared Buffer Usage

Install and enable the `pg_buffercache` extension:

```sql
CREATE EXTENSION pg_buffercache;
```

Then inspect cached pages:

```sql
SELECT *
FROM pg_buffercache
LIMIT 10;
```

---

# 📈 Complete Shared Buffer Flow

```text
Spring Boot
      │
      ▼
Hibernate
      │
      ▼
JDBC Driver
      │
      ▼
PostgreSQL
      │
      ▼
Planner
      │
      ▼
Executor
      │
      ▼
Buffer Manager
      │
      ▼
Shared Buffers
      │
 ┌────┴────┐
 ▼         ▼
Hit       Miss
 │          │
 ▼          ▼
Row      Disk Read
 │          │
 └────┬─────┘
      ▼
Return Result
```

This is the complete lifecycle of a page lookup inside PostgreSQL.

---

# 📊 Shared Buffers Summary

| Component            | Responsibility                                    |
| -------------------- | ------------------------------------------------- |
| 📦 Shared Buffers    | Primary cache for table and index pages           |
| 🧠 Buffer Manager    | Locates, loads, replaces, and tracks cached pages |
| ⚡ Cache Hit          | Requested page already exists in memory           |
| 💽 Cache Miss        | Requested page must be loaded from disk           |
| ✍️ Dirty Page        | Modified page waiting to be written to disk       |
| 📝 Background Writer | Flushes dirty pages from memory to storage        |

---

# 💡 Key Takeaways

✅ PostgreSQL stores table and index data in fixed-size pages, typically **8 KB** each.

✅ Shared Buffers is PostgreSQL's primary in-memory cache for those pages.

✅ Every page request passes through the Buffer Manager before any disk access occurs.

✅ A **cache hit** returns data directly from RAM, while a **cache miss** loads the page from disk and stores it in Shared Buffers.

✅ Updated pages become **dirty pages** and are written to disk later by background processes, improving write performance.

✅ High cache hit ratios significantly reduce disk I/O and improve query performance.

✅ Understanding Shared Buffers is essential for analyzing PostgreSQL performance and tuning memory usage.

---

# ➡️ Next Chapter

📘 **`08-PostgreSQL/08-WAL.md`**

In the next chapter, we'll explore **Write-Ahead Logging (WAL)**, one of PostgreSQL's most critical reliability mechanisms.

We'll answer questions such as:

* 📒 What is WAL?
* ✍️ Why are changes written to WAL before table files?
* 💥 What happens if PostgreSQL crashes?
* 🔄 How does crash recovery work?
* 🌍 How does streaming replication use WAL?

By the end of the next chapter, you'll understand why PostgreSQL can recover safely after failures while preserving committed transactions.
