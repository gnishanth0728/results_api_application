# 📘 Chapter 60 — PostgreSQL Connection Lifecycle

> 📂 File: `student-results-api-notes/08-PostgreSQL/02-Connection.md`

This chapter is where we move from the application into the database server.

In the previous chapter, we saw PostgreSQL's overall architecture.

Now we'll zoom into one JDBC connection and answer:

What exactly happens when Spring Boot executes dataSource.getConnection()?

This chapter explains the complete connection lifecycle—from HikariCP to PostgreSQL backend process creation, authentication, SQL execution, and connection pooling.

---

# 🌍 Introduction

In the previous chapter, we learned PostgreSQL's internal architecture.

We saw:

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
```

But another important question appears:

> 🤔 **How does Spring Boot actually connect to PostgreSQL?**

When your application starts, Hibernate cannot execute SQL immediately.

It must first establish a database connection.

This chapter explains the complete lifecycle of that connection.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🔌 JDBC Connections
* 🏊 Connection Pooling
* 🚀 HikariCP
* 🤝 PostgreSQL Authentication
* ⚙️ Backend Process Creation
* 📦 Session Lifecycle
* 🔄 Connection Reuse
* ❌ Connection Closing
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ Why Do We Need a Connection?

Suppose Hibernate wants to execute:

```sql
SELECT *
FROM student
WHERE id = 1;
```

Without a connection:

```text
Hibernate

↓

SQL

↓

❌ Nowhere to send it
```

A connection creates a communication channel between the application and PostgreSQL.

---

# 🏗️ Complete Connection Architecture

```text
Spring Boot
      │
      ▼
Hibernate
      │
      ▼
JPA Repository
      │
      ▼
DataSource
      │
      ▼
HikariCP
      │
      ▼
JDBC Driver
      │
      ▼
TCP Socket
      │
      ▼
PostgreSQL
```

The SQL query travels through this stack before reaching the database.

---

# 🚀 Application Startup

When Spring Boot starts:

```text
SpringApplication.run()

↓

Auto Configuration

↓

Create DataSource

↓

Create HikariCP

↓

Open Initial Connections

↓

Application Ready
```

Connections are usually created before the first HTTP request arrives.

---

# 🏊 What Is HikariCP?

HikariCP is Spring Boot's default **connection pool**.

Instead of creating a new connection for every request:

```text
Request 1

↓

New Connection

↓

Close Connection

------------------

Request 2

↓

New Connection

↓

Close Connection
```

HikariCP keeps reusable connections alive.

---

# 🏗️ Connection Pool

```text
+-----------------------------+
|       HikariCP Pool         |
|-----------------------------|
| Connection 1                |
| Connection 2                |
| Connection 3                |
| Connection 4                |
| Connection 5                |
+-----------------------------+
```

When a request needs the database:

```text
Borrow Connection

↓

Execute SQL

↓

Return Connection
```

The physical connection stays open.

---

# 🔌 Creating a Connection

When no reusable connection exists:

```text
Hibernate

↓

DataSource

↓

JDBC Driver

↓

TCP Connection

↓

PostgreSQL Port 5432
```

The JDBC driver initiates a TCP connection to the PostgreSQL server.

---

# 🤝 Authentication

After TCP is established:

```text
Client

↓

Username

↓

Password

↓

Authentication

↓

Session Created
```

If authentication fails:

```text
FATAL

password authentication failed
```

No SQL can be executed.

---

# ⚙️ Backend Process Creation

After successful authentication:

```text
Postmaster

↓

Fork Backend Process

↓

Assign Client

↓

Ready
```

Every client connection receives its own backend process.

Example:

```text
Spring Boot

↓

Connection #5

↓

Backend Process PID 23518
```

---

# 📦 Session State

Each backend process maintains session information.

```text
Backend Process

↓

Current User

↓

Current Database

↓

Transaction State

↓

Temporary Objects

↓

Session Variables
```

This session exists until the connection closes.

---

# 🍃 Student Results API Example

Request:

```http
GET /students/1
```

Execution:

```text
Browser
      │
      ▼
Controller
      │
      ▼
Repository
      │
      ▼
DataSource
      │
      ▼
Borrow Connection
      │
      ▼
Backend Process
      │
      ▼
Execute SQL
      │
      ▼
Return Rows
```

The connection is borrowed only for the duration of the database work.

---

# 🔄 Connection Reuse

After SQL completes:

```text
Connection

↓

Returned to Pool

↓

Idle

↓

Ready for Next Request
```

Notice:

The connection is **not destroyed**.

It waits for another request.

---

# ❌ Closing Connections

Suppose:

```java
connection.close();
```

With HikariCP:

```text
close()

↓

Return to Pool

↓

NOT Actually Closed
```

The physical TCP connection remains open.

Only HikariCP decides when to close idle connections.

---

# 📊 Complete Connection Lifecycle

```text
Application Starts
       │
       ▼
Create HikariCP
       │
       ▼
Open TCP Connection
       │
       ▼
Authenticate
       │
       ▼
Create Backend Process
       │
       ▼
Connection Pool
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
Reuse Later
```

---

# ⚡ Why Connection Pooling Is Important

Without pooling:

```text
100 Requests

↓

100 TCP Connections

↓

100 Authentication Steps

↓

Slow
```

With pooling:

```text
100 Requests

↓

10 Existing Connections

↓

Reuse

↓

Fast
```

Pooling dramatically reduces latency and CPU overhead.

---

# 📈 Connection Pool Configuration

Typical Spring Boot configuration:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/studentdb

spring.datasource.username=postgres

spring.datasource.password=password

spring.datasource.hikari.maximum-pool-size=10

spring.datasource.hikari.minimum-idle=5

spring.datasource.hikari.connection-timeout=30000
```

Important settings:

* `maximum-pool-size` → Maximum active connections
* `minimum-idle` → Idle connections kept ready
* `connection-timeout` → Maximum wait time to borrow a connection

---

# 🚫 Common Mistakes

## ❌ Creating a New Connection for Every Query

```java
DriverManager.getConnection(...)
```

for every request is expensive.

Always use a connection pool.

---

## ❌ Large Connection Pools

```text
Pool Size = 500
```

If PostgreSQL allows only 100 connections, many clients will fail.

Choose the pool size based on application load and database capacity.

---

## ❌ Holding Connections Too Long

```text
Borrow Connection

↓

Call External API

↓

Sleep 30 Seconds

↓

Execute SQL

↓

Return Connection
```

Connections should be held only while interacting with the database.

---

# 🐳 Docker Perspective

```text
Spring Boot Container
        │
        ▼
HikariCP
        │
        ▼
TCP Port 5432
        │
        ▼
PostgreSQL Container
```

Containers communicate over a Docker network, but the JDBC connection lifecycle remains unchanged.

---

# ☸️ Kubernetes Perspective

```text
Spring Boot Pod
       │
       ▼
HikariCP
       │
       ▼
ClusterIP Service
       │
       ▼
PostgreSQL Pod
```

The Service provides a stable network endpoint while HikariCP manages reusable connections.

---

# 🧪 Hands-on Lab

## View Active Connections

Run:

```sql
SELECT pid,
       usename,
       application_name,
       state
FROM pg_stat_activity;
```

Observe the backend processes created for your application.

---

## Configure Pool Size

```properties
spring.datasource.hikari.maximum-pool-size=5
```

Restart the application.

Verify that no more than five active connections are created.

---

## Observe Connection Reuse

Enable Hikari logging:

```properties
logging.level.com.zaxxer.hikari=DEBUG
```

Make several API requests.

Notice that connections are borrowed and returned instead of recreated.

---

## Monitor Connection State

Execute:

```sql
SELECT state,
       count(*)
FROM pg_stat_activity
GROUP BY state;
```

Observe idle and active connections.

---

## Simulate Pool Exhaustion

Set:

```properties
spring.datasource.hikari.maximum-pool-size=2
```

Generate many concurrent requests.

Observe how additional requests wait until a connection becomes available.

---

# 📈 Complete Connection Flow

```text
Spring Boot
      │
      ▼
Repository
      │
      ▼
DataSource
      │
      ▼
HikariCP Pool
      │
      ▼
Borrow Connection
      │
      ▼
JDBC Driver
      │
      ▼
TCP Socket
      │
      ▼
PostgreSQL
      │
      ▼
Backend Process
      │
      ▼
Execute SQL
      │
      ▼
Return Results
      │
      ▼
Return Connection to Pool
```

This is the complete lifecycle of a PostgreSQL connection in a Spring Boot application.

---

# 📊 Component Summary

| Component                | Responsibility                                    |
| ------------------------ | ------------------------------------------------- |
| 🌱 Spring Boot           | Requests database access                          |
| 📦 DataSource            | Provides database connections                     |
| 🏊 HikariCP              | Manages and reuses pooled connections             |
| 🔌 JDBC Driver           | Implements the PostgreSQL wire protocol           |
| 🌐 TCP Socket            | Carries network traffic between client and server |
| 🐘 PostgreSQL Postmaster | Accepts new client connections                    |
| ⚙️ Backend Process       | Executes SQL for one client session               |

---

# 💡 Key Takeaways

✅ Every SQL statement requires a database connection.

✅ Spring Boot obtains connections through a `DataSource`, which is backed by HikariCP by default.

✅ HikariCP improves performance by reusing existing connections instead of creating new ones for every request.

✅ Each PostgreSQL connection is handled by a dedicated backend process.

✅ Calling `Connection.close()` in a pooled environment usually returns the connection to the pool rather than closing the physical TCP connection.

✅ Proper connection pool sizing is essential for application scalability and database stability.

✅ Understanding the connection lifecycle is the foundation for learning transactions, locking, query execution, and PostgreSQL performance tuning.

---

# ➡️ Next Chapter

📘 **`08-PostgreSQL/03-Query-Execution.md`**

In the next chapter, we'll follow a SQL statement **inside PostgreSQL**.

We'll explore:

* 📝 SQL parsing
* 📈 Query planning
* 🧠 Cost-based optimization
* 📄 Execution plans
* 📦 Buffer access
* 💽 Disk I/O
* ⚡ Returning result rows

By the end of the next chapter, you'll understand exactly what happens internally after PostgreSQL receives:

```sql
SELECT *
FROM student
WHERE id = 1;
```

and how that query is transformed into an efficient execution plan before any data is read from disk.
