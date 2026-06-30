📘 Chapter 107 — Database Connection Pool (HikariCP)

📂 File: student-results-api-notes/12-Performance/05-ConnectionPool.md

🌍 Introduction

In the previous chapter we learned that Tomcat uses a thread pool.

Each incoming request is assigned a worker thread.

Browser
      │
      ▼
Tomcat Thread
      │
      ▼
Spring Boot

But another important question appears:

🤔 How does Spring Boot communicate with PostgreSQL?

Should every request create a brand new database connection?

No.

Instead, Spring Boot uses a connection pool.

🎯 Learning Objectives

After completing this chapter you will understand:

🏊 What a Connection Pool is
⚡ Why Database Connections are Expensive
🔄 Connection Reuse
📥 Borrow and Return
🚫 Pool Exhaustion
🍃 Student Results API Example
☸️ Kubernetes Considerations
🚀 HikariCP Tuning
❓ What is a Connection Pool?

A connection pool is a collection of reusable database connections.

Instead of:

Request

↓

Create Connection

↓

Execute SQL

↓

Close Connection

Spring Boot does:

Create Connections Once

↓

Reuse Forever

until the application shuts down.

Why Are Database Connections Expensive?

Opening a PostgreSQL connection involves:

TCP Handshake
      │
      ▼
SSL (optional)
      │
      ▼
Authentication
      │
      ▼
Backend Process
      │
      ▼
Ready

This takes significantly longer than reusing an existing connection.

High-Level Architecture
Browser
      │
      ▼
Tomcat Thread
      │
      ▼
Spring Boot
      │
      ▼
HikariCP
      │
      ▼
PostgreSQL
Default Connection Pool

Spring Boot uses:

HikariCP

by default (unless another DataSource implementation is configured).

HikariCP is designed to be lightweight and high-performance.

Borrow and Return

Suppose the pool contains:

Connection-1

Connection-2

Connection-3

Request A:

Borrow Connection-1

↓

Execute SQL

↓

Return Connection-1

The connection is reused, not recreated.

Student Results API Example

Suppose:

GET /students/1051110001

Execution:

Tomcat Thread

↓

Borrow Connection

↓

SELECT

↓

Return Connection

The next request may receive the same connection.

Connection Pool Size

Suppose:

maximumPoolSize = 10

Pool:

Connection-1

Connection-2

...

Connection-10

Only ten database operations can execute concurrently using pool-managed connections.

Pool Exhaustion

Suppose:

10 Connections

Traffic:

50 Requests

Execution:

10 Using Connections

↓

40 Waiting

If a connection is not returned before the configured timeout expires, waiting requests fail with a connection timeout.

Relationship with Tomcat Threads

Suppose:

Tomcat Threads

200

Database pool:

Connections

20

Execution:

200 Worker Threads

↓

20 Database Connections

↓

180 Waiting

The connection pool becomes the bottleneck.

Spring Boot Configuration

Example:

spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.idle-timeout=600000
spring.datasource.hikari.max-lifetime=1800000

Common properties:

Property	Meaning
maximum-pool-size	Maximum number of database connections
minimum-idle	Minimum idle connections kept ready
connection-timeout	Maximum wait time for a connection
idle-timeout	Time before an idle connection may be removed
max-lifetime	Maximum lifetime of a connection before replacement
Request Lifecycle
HTTP Request
      │
      ▼
Tomcat Thread
      │
      ▼
Borrow Connection
      │
      ▼
Execute SQL
      │
      ▼
Return Connection
      │
      ▼
Response

Returning the connection promptly is essential.

Connection Leak

Bad code:

Borrow Connection

↓

Never Return

Eventually:

Pool Empty

↓

Timeout

Modern Spring applications normally avoid this by managing connections through transactions and the framework, but custom JDBC code that doesn't close resources can still cause leaks.

Load Testing Example

Run:

ab -n 10000 -c 200 \
http://localhost:8080/students/1051110001

Observe:

Tomcat Threads

↓

Waiting for Connections

If the database pool is too small relative to the workload, response times increase even when CPU usage remains low.

Kubernetes Example

Suppose:

4 Pods

Each Pod:

20 Connections

Total database connections:

80 Connections

When scaling Pods, ensure PostgreSQL can support the total number of connections across all application instances.

Monitoring HikariCP

With Spring Boot Actuator and Micrometer, you can monitor metrics such as:

Active connections
Idle connections
Pending connection requests
Connection acquisition time

These metrics help identify pool exhaustion before users notice performance issues.

Performance Tuning

Do not assume:

maximumPoolSize=500

is better.

Too many connections can:

Overload PostgreSQL
Increase memory usage
Increase context switching
Reduce database performance

Tune the pool based on:

Database capacity
Query execution time
Application concurrency
CPU resources
Hands-on Lab
View HikariCP Configuration
spring.datasource.hikari.maximum-pool-size=10
Generate Load
ab -n 5000 -c 100 \
http://localhost:8080/students/1051110001
Observe Database Connections

In PostgreSQL:

SELECT count(*)
FROM pg_stat_activity;

This shows active database sessions.

Observe Application

Monitor:

top
jcmd <PID> Thread.print

Watch for application threads waiting on database operations.

Common Mistakes
❌ Making the Connection Pool Larger Than Necessary

A larger pool does not automatically improve performance.

The database server has finite CPU, memory, and I/O capacity.

❌ Ignoring Database Capacity

The application's pool size must align with what PostgreSQL can realistically handle across all application instances.

❌ Holding Connections Too Long

Long-running transactions keep connections busy and reduce pool availability.

Return connections as quickly as possible by keeping transactions short.

❌ Forgetting Total Connections in Kubernetes

Example:

5 Pods

×

20 Connections

=

100 Database Connections

Always calculate the total number of possible connections across all replicas.

Connection Pool Workflow
HTTP Request
       │
       ▼
Tomcat Thread
       │
       ▼
Borrow Connection
       │
       ▼
Execute SQL
       │
       ▼
Return Connection
       │
       ▼
Next Request Reuses Connection
Useful Configuration
Setting	Purpose
maximum-pool-size	Maximum database connections
minimum-idle	Idle connections kept available
connection-timeout	Wait time for a connection
idle-timeout	Idle connection lifetime
max-lifetime	Maximum connection lifetime
Thread Pool vs Connection Pool
Thread Pool	Connection Pool
Manages worker threads	Manages database connections
Used by Tomcat	Used by HikariCP
Executes HTTP requests	Executes SQL through reusable connections
Limited by CPU and application workload	Limited by database capacity
💡 Key Takeaways

✅ Spring Boot uses HikariCP as its default database connection pool.

✅ Opening a new database connection for every request is expensive, so connections are reused.

✅ Each request borrows a connection, executes SQL, and returns the connection to the pool.

✅ If all connections are busy, additional requests wait until a connection becomes available or the connection timeout is reached.

✅ Connection pool sizing should be based on database capacity and total application concurrency, especially in Kubernetes where multiple Pods contribute to the total number of database connections.

➡️ Next Chapter

📘 12-Performance/06-Caching.md

In the next chapter, we'll explore application caching.

You'll learn:

⚡ Why repeated database queries are expensive
🧠 In-memory caching with Spring Cache
🔴 Distributed caching with Redis
📦 Cache hits vs cache misses
⏱️ Time-to-live (TTL) and cache invalidation
☸️ Using Redis with Spring Boot applications running in Docker and Kubernetes
