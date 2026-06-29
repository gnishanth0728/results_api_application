# 📘 Chapter 56 — Hibernate SQL Generation

> 📂 File: `student-results-api-notes/07-Hibernate/05-SQL-Generation.md`

This chapter is where everything comes together.

So far you've learned:

✅ Entity
✅ Persistence Context
✅ Entity Lifecycle
✅ Dirty Checking

Now the next logical question is:

How does Hibernate finally generate real SQL?

For example:

Student student =
repository.findById(1L).orElseThrow();

student.setMarks(98);

How does Hibernate finally produce:

UPDATE student
SET marks = 98
WHERE id = 1;

This chapter explains the complete SQL generation pipeline—from Java objects to PostgreSQL

---

# 🌍 Introduction

In the previous chapter, we learned about **Dirty Checking**.

Hibernate automatically detects modifications made to managed Entities.

Example:

```java
Student student =
repository.findById(1L)
          .orElseThrow();

student.setMarks(98);
```

We never wrote:

```sql
UPDATE student
SET marks = 98
WHERE id = 1;
```

Yet Hibernate automatically executed it.

This raises the next important question:

> 🤔 **How does Hibernate convert Java objects into SQL statements?**

The answer lies inside Hibernate's **SQL Generation Engine**.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🏗️ Hibernate SQL Generation Pipeline
* 📦 Entity Metadata
* 🔍 Query Translation
* ⚡ SQL Generation
* 🛣️ JDBC Execution
* 💾 Parameter Binding
* 🚀 INSERT
* ✏️ UPDATE
* 🗑️ DELETE
* 🔎 SELECT
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ Why SQL Generation Matters

As Java developers, we work with objects.

```java
Student student;
```

Databases understand only SQL.

```sql
SELECT *
FROM student
```

Hibernate acts as the translator.

```text
Java Objects

↓

Hibernate

↓

SQL

↓

PostgreSQL
```

Without Hibernate, developers would write SQL manually for every CRUD operation.

---

# 🏗️ Complete SQL Generation Architecture

```text
Browser
      │
      ▼
Controller
      │
      ▼
Service
      │
      ▼
Repository
      │
      ▼
EntityManager
      │
      ▼
Persistence Context
      │
      ▼
Dirty Checking
      │
      ▼
Hibernate SQL Generator
      │
      ▼
JDBC Driver
      │
      ▼
PostgreSQL
```

SQL generation occurs after Hibernate determines what operation needs to be performed.

---

# 📦 Step 1 — Entity Metadata

Hibernate first reads mapping metadata.

Example:

```java
@Entity
@Table(name="student")
public class Student {

    @Id
    private Long id;

    @Column(name="student_name")
    private String name;

    private Integer marks;

}
```

Hibernate builds metadata like:

```text
Java Class

↓

Student

↓

Table = student

↓

Columns

id

student_name

marks
```

This metadata is stored once during application startup.

---

# 🔎 Step 2 — Determine the Operation

Hibernate decides which SQL statement is required.

Possible operations:

```text
persist()

↓

INSERT

------------------

find()

↓

SELECT

------------------

Dirty Checking

↓

UPDATE

------------------

remove()

↓

DELETE
```

Each Entity state transition maps to a SQL operation.

---

# 📥 INSERT Generation

Suppose:

```java
Student student = new Student();

student.setName("Alice");

student.setMarks(95);

repository.save(student);
```

Hibernate generates:

```sql
INSERT INTO student
(student_name, marks)
VALUES (?, ?);
```

Parameter binding:

```text
? → Alice

? → 95
```

---

# 🔎 SELECT Generation

Example:

```java
repository.findById(1L);
```

Generated SQL:

```sql
SELECT
    id,
    student_name,
    marks
FROM student
WHERE id = ?;
```

Bound value:

```text
? → 1
```

Result:

```text
Database Row

↓

Entity
```

---

# ✏️ UPDATE Generation

Suppose:

```java
student.setMarks(98);
```

Dirty Checking detects:

```text
Snapshot

marks = 95

↓

Current

marks = 98
```

Generated SQL:

```sql
UPDATE student
SET marks = ?
WHERE id = ?;
```

Parameters:

```text
? → 98

? → 1
```

Only changed fields are updated (unless configured otherwise).

---

# 🗑️ DELETE Generation

Example:

```java
repository.delete(student);
```

Hibernate generates:

```sql
DELETE
FROM student
WHERE id = ?;
```

Parameter:

```text
? → 1
```

---

# 🧠 Parameter Binding

Hibernate avoids building SQL using string concatenation.

Instead:

```sql
SELECT *
FROM student
WHERE id = ?;
```

Later:

```text
Parameter

↓

1
```

Benefits:

* 🛡️ Prevents SQL Injection
* ⚡ Reuses prepared statements
* 🚀 Improves performance

---

# ⚙️ JDBC Execution

After SQL generation:

```text
Hibernate

↓

PreparedStatement

↓

JDBC Driver

↓

TCP Socket

↓

PostgreSQL
```

The JDBC driver sends the SQL over the network to the database server.

---

# 🍃 Student Results API Example

Request:

```http
PUT /students/1
```

Execution:

```text
Controller

↓

Service

↓

Repository

↓

EntityManager

↓

Persistence Context

↓

Dirty Checking

↓

UPDATE student

↓

JDBC

↓

PostgreSQL
```

The Service never writes SQL directly.

---

# 📊 SQL Generation Flow

```text
Entity

↓

Entity Metadata

↓

Persistence Context

↓

Dirty Checking

↓

SQL Generator

↓

PreparedStatement

↓

JDBC Driver

↓

Database
```

Hibernate performs every translation automatically.

---

# 🔄 End-to-End Example

Code:

```java
@Transactional
public void updateStudent() {

    Student student =
        repository.findById(1L)
                  .orElseThrow();

    student.setMarks(99);

}
```

Execution timeline:

```text
SELECT student

↓

Managed Entity

↓

Modify Field

↓

Dirty Checking

↓

Generate UPDATE

↓

PreparedStatement

↓

JDBC

↓

PostgreSQL

↓

Commit
```

One Java setter ultimately becomes an SQL `UPDATE`.

---

# ⚡ SQL Logging

Enable Hibernate SQL logging:

```properties
spring.jpa.show-sql=true

spring.jpa.properties.hibernate.format_sql=true

logging.level.org.hibernate.SQL=DEBUG

logging.level.org.hibernate.orm.jdbc.bind=TRACE
```

Example output:

```text
Hibernate:

select
    s1_0.id,
    s1_0.student_name,
    s1_0.marks
from student s1_0
where s1_0.id=?

binding parameter [1] as [BIGINT] - 1

Hibernate:

update student
set marks=?
where id=?

binding parameter [1] as [INTEGER] - 99
binding parameter [2] as [BIGINT] - 1
```

These logs are extremely useful for debugging performance issues.

---

# 🚫 Common Mistakes

## ❌ Assuming SQL Runs Immediately

```java
student.setMarks(99);
```

No SQL is executed here.

SQL is generated during:

* Flush
* Transaction commit
* Explicit `entityManager.flush()`

---

## ❌ Concatenating SQL Strings

Never do:

```java
"SELECT * FROM student WHERE id=" + id
```

Hibernate automatically uses prepared statements with parameter binding.

---

## ❌ Ignoring SQL Logs

Always inspect generated SQL when:

* Optimizing performance
* Debugging slow queries
* Finding N+1 query problems
* Verifying indexes are used correctly

---

# 🐳 Docker Perspective

```text
Docker Container
       │
       ▼
Spring Boot
       │
       ▼
Hibernate
       │
       ▼
SQL Generator
       │
       ▼
JDBC Driver
       │
       ▼
PostgreSQL Container
```

SQL generation happens inside the application container before queries are sent to the database.

---

# ☸️ Kubernetes Perspective

```text
Pod
 │
 ▼
Spring Boot
 │
 ▼
Hibernate
 │
 ▼
JDBC
 │
 ▼
Service
 │
 ▼
PostgreSQL Pod
```

Hibernate is unaware of Kubernetes—it simply sends SQL through JDBC to the configured datasource.

---

# 🧪 Hands-on Lab

## Enable SQL Logging

```properties
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.orm.jdbc.bind=TRACE
```

Observe both SQL statements and parameter values.

---

## Test INSERT

```java
Student student = new Student();

student.setName("Alice");
student.setMarks(95);

repository.save(student);
```

Verify the generated `INSERT` statement.

---

## Test SELECT

```java
repository.findById(1L);
```

Observe the generated `SELECT`.

---

## Test UPDATE

```java
@Transactional
public void updateStudent() {

    Student student =
        repository.findById(1L)
                  .orElseThrow();

    student.setMarks(99);
}
```

Observe the generated `UPDATE`.

---

## Test DELETE

```java
repository.deleteById(1L);
```

Verify the generated `DELETE` statement.

---

# 📈 Complete SQL Generation Pipeline

```text
Java Entity
      │
      ▼
Hibernate Metadata
      │
      ▼
Persistence Context
      │
      ▼
Dirty Checking
      │
      ▼
SQL Generation Engine
      │
      ▼
PreparedStatement
      │
      ▼
Parameter Binding
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

This is the complete path from a Java object to an executed SQL statement.

---

# 📊 Java Operation → Generated SQL

| Java Operation               | Generated SQL             |
| ---------------------------- | ------------------------- |
| `repository.save(student)`   | `INSERT`                  |
| `repository.findById(id)`    | `SELECT`                  |
| Modify managed Entity        | `UPDATE` (Dirty Checking) |
| `repository.delete(student)` | `DELETE`                  |
| `repository.findAll()`       | `SELECT`                  |

---

# 💡 Key Takeaways

✅ Hibernate uses Entity metadata to map Java classes and fields to database tables and columns.

✅ SQL generation is automatic and occurs after Hibernate determines the required operation (`INSERT`, `SELECT`, `UPDATE`, or `DELETE`).

✅ Dirty Checking triggers `UPDATE` generation by comparing managed Entities with their snapshots.

✅ Hibernate uses prepared statements with parameter binding, improving both security and performance.

✅ SQL is sent to the database through the JDBC driver, which communicates with PostgreSQL over a network socket.

✅ Enabling SQL logging is essential for understanding application behavior and diagnosing performance issues.

✅ Hibernate allows developers to work primarily with Java objects while transparently generating efficient SQL behind the scenes.

---

# ➡️ Next Chapter

📘 **`07-Hibernate/06-Transactions.md`**

In the next chapter, we'll explore **Hibernate Transactions**, one of the most critical concepts in enterprise applications.

We'll answer questions such as:

* 🔄 What is a transaction?
* 🏦 What are ACID properties?
* 🏷️ How does `@Transactional` work?
* 💾 When does Hibernate flush changes?
* ↩️ What happens during rollback?
* ⚡ How do transactions interact with the Persistence Context and Dirty Checking?

By the end of the next chapter, you'll understand why a single `@Transactional` annotation can coordinate dozens of SQL statements into one reliable, atomic unit of work.
