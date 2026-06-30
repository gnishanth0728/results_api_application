📘 Chapter 108 — Database Performance

📂 File: student-results-api-notes/12-Performance/06-DatabasePerformance.md

🌍 Introduction

In previous chapters we learned:

Browser
      │
      ▼
Tomcat Thread Pool
      │
      ▼
Spring Boot
      │
      ▼
Connection Pool
      │
      ▼
PostgreSQL

Every request eventually reaches the database.

But another important question appears:

🤔 What determines how fast a SQL query executes?

A slow API is often caused by:

Missing indexes
Full table scans
Poor query design
Excessive disk I/O
Too many database connections
Lock contention

Understanding database performance is essential for building scalable applications.

🎯 Learning Objectives

After completing this chapter you will understand:

🚀 Database Performance Fundamentals
📊 Query Execution Time
📑 Index Optimization
🔍 Query Plans
💾 Buffer Cache
🔒 Lock Contention
🏊 Connection Pool Effects
🍃 Student Results API Examples
☸️ Kubernetes Considerations
📈 Database Performance Tuning
❓ What Determines Database Performance?

Every SQL query consumes resources:

SQL Query
      │
      ▼
Parser
      │
      ▼
Planner
      │
      ▼
Executor
      │
      ▼
Shared Buffers
      │
      ▼
Disk (if needed)

The execution time depends on how efficiently each step completes.

Query Execution Time

Example:

SELECT *
FROM students
WHERE roll_number = 1051110001;

Execution time:

3 ms

Now compare:

SELECT *
FROM students;

Execution time:

4 seconds

Why?

The second query reads the entire table.

Full Table Scan

Without an index:

Student Table

↓

Row 1

↓

Row 2

↓

Row 3

↓

...

↓

Row 1,000,000

Every row must be examined.

This is called a sequential scan.

Index Scan

With an index:

B-Tree Index

↓

roll_number

↓

Matching Row

Only the required rows are accessed.

Student Results API Example

Endpoint:

GET /students/{rollNumber}

SQL:

SELECT *
FROM students
WHERE roll_number = ?;

Recommended index:

CREATE INDEX idx_students_roll
ON students(roll_number);

Now PostgreSQL performs an index scan instead of a sequential scan (assuming the planner determines the index is the best choice).

EXPLAIN

Always inspect the execution plan:

EXPLAIN ANALYZE
SELECT *
FROM students
WHERE roll_number = 1051110001;

Good plan:

Index Scan

Poor plan:

Seq Scan
Buffer Cache

Suppose:

First Query

↓

Disk Read

↓

100 ms

Second query:

Shared Buffers

↓

2 ms

Frequently accessed pages are often served from memory instead of disk.

Query Optimization

Instead of:

SELECT *
FROM students;

Retrieve only the required columns:

SELECT first_name,
       last_name
FROM students
WHERE roll_number = ?;

Reading less data reduces CPU, memory, and network overhead.

Avoid N+1 Queries

Bad pattern:

Student

↓

Subjects

↓

One Query Per Subject

Example:

1 Query

+

100 Queries

Better:

Single JOIN Query

or an appropriate fetch strategy depending on the use case.

Lock Contention

Suppose:

UPDATE students
SET marks = 95
WHERE roll_number = 1051110001;

Another transaction:

UPDATE students
SET marks = 96
WHERE roll_number = 1051110001;

One transaction may wait for the other to release its lock.

Excessive lock contention increases response times.

Connection Pool Impact

Tomcat:

200 Threads

HikariCP:

20 Connections

PostgreSQL:

20 Active Queries

The database can process only as many concurrent queries as there are available connections and server resources.

Monitoring PostgreSQL

Useful query:

SELECT pid,
       state,
       query
FROM pg_stat_activity;

Shows:

Active sessions
Waiting sessions
Running SQL
Slow Queries

Enable PostgreSQL's slow query logging (for example, by configuring log_min_duration_statement).

Example log:

Duration: 3500 ms

SELECT ...

These queries should be investigated first.

Performance Workflow
Slow API
      │
      ▼
Measure API Latency
      │
      ▼
EXPLAIN ANALYZE
      │
      ▼
Check Indexes
      │
      ▼
Optimize Query
      │
      ▼
Retest
Kubernetes Example

Suppose:

8 Pods

Each Pod:

20 Connections

Total:

160 Connections

Ensure PostgreSQL is configured to support the expected connection count, or consider a connection pooler such as PgBouncer if appropriate.

Hands-on Lab
Run Query
SELECT *
FROM students
WHERE roll_number = 1051110001;
Inspect Plan
EXPLAIN ANALYZE
SELECT *
FROM students
WHERE roll_number = 1051110001;
Create Index
CREATE INDEX idx_students_roll
ON students(roll_number);

Run EXPLAIN ANALYZE again and compare the plan.

Monitor Sessions
SELECT pid,
       state,
       query
FROM pg_stat_activity;
Generate Load
ab -n 5000 -c 100 \
http://localhost:8080/students/1051110001

Observe:

Response time
CPU usage
Active database sessions
Common Mistakes
❌ Assuming the Application Is Always the Bottleneck

Many performance issues originate in:

SQL queries
Missing indexes
Disk I/O
Lock contention

Investigate the database before tuning application code.

❌ Adding Indexes Everywhere

Indexes speed up many reads but:

Consume storage
Increase write cost
Require maintenance

Create indexes based on actual query patterns.

❌ Using SELECT * Unnecessarily

Fetching unused columns increases:

Network traffic
Memory usage
CPU time

Retrieve only the data you need.

❌ Ignoring Query Plans

Never assume a query is efficient.

Use:

EXPLAIN ANALYZE

to verify how PostgreSQL actually executes it.

Database Performance Checklist
Slow API
      │
      ▼
Measure
      │
      ▼
Check Query
      │
      ▼
EXPLAIN ANALYZE
      │
      ▼
Index?
      │
      ▼
Locks?
      │
      ▼
Connections?
      │
      ▼
Disk I/O?
      │
      ▼
Optimize
Useful PostgreSQL Commands
Command	Purpose
EXPLAIN ANALYZE	Show execution plan and timing
CREATE INDEX	Create an index
pg_stat_activity	View active sessions
VACUUM ANALYZE	Refresh statistics and reclaim storage
\d+ table_name	View table and index information
💡 Key Takeaways

✅ Database performance has a major impact on end-to-end API latency.

✅ Efficient indexes, well-designed queries, and appropriate execution plans are essential for fast responses.

✅ EXPLAIN ANALYZE is the primary tool for understanding how PostgreSQL executes a query.

✅ Shared buffers reduce disk I/O by serving frequently accessed data from memory.

✅ Monitor active sessions, connection pools, lock contention, and slow queries before making tuning decisions.

➡️ Next Chapter

📘 12-Performance/07-Caching.md

In the next chapter, you'll learn how to reduce database load with caching.

Topics include:

⚡ Cache hits vs cache misses
🧠 Spring Cache abstraction
🔴 Redis integration
⏱️ Cache expiration (TTL)
🔄 Cache invalidation strategies
☸️ Distributed caching for Spring Boot applications running in Docker and
