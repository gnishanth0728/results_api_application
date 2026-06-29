# 📘 Chapter 53 — Hibernate Persistence Context

> 📂 File: `student-results-api-notes/07-Hibernate/02-Persistence-Context.md`

Most developers know what an Entity is.

Very few understand the Persistence Context.

Without understanding the Persistence Context, concepts like:

Dirty Checking
Lazy Loading
Transactions
First-Level Cache
Entity Lifecycle
Flush
Merge
Detach

will never make complete sense.

This chapter should answer:

When I call repository.findById(), where does that Java object actually live?

The answer is:

Inside the Persistence Context.

---

# 🌍 Introduction

In the previous chapter, we learned that a Java **Entity** represents a row in a database table.

Example:

```java
Student student =
    repository.findById(1L)
              .orElseThrow();
```

The database contains:

| id | name  | marks |
| -- | ----- | ----: |
| 1  | Alice |    95 |

Hibernate creates:

```java
Student student = new Student();

student.setId(1L);
student.setName("Alice");
student.setMarks(95);
```

This raises a very important question:

> 🤔 **Where does this Java object live after Hibernate creates it?**

Does Hibernate immediately discard it?

Does it create a new object every time?

How does Hibernate know if the object has changed?

The answer is:

# 🧠 Persistence Context

The Persistence Context is the heart of Hibernate.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🧠 What the Persistence Context is
* 📦 EntityManager
* 🗂️ First-Level Cache
* 🏛️ Managed Entities
* 🔄 Entity States
* 💾 Automatic Change Tracking
* 🚀 Dirty Checking
* 🧹 Detach
* 🔄 Merge
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ What Is the Persistence Context?

The Persistence Context is an **in-memory workspace** managed by Hibernate.

Think of it as a smart container.

```text
Application
      │
      ▼
EntityManager
      │
      ▼
+-------------------------------+
|      Persistence Context      |
|-------------------------------|
| Student(id=1)                 |
| Student(id=2)                 |
| Course(id=10)                 |
| Teacher(id=5)                 |
+-------------------------------+
      │
      ▼
PostgreSQL
```

Instead of constantly talking to the database, Hibernate keeps managed objects here.

---

# 🧠 Why Does Hibernate Need It?

Without a Persistence Context:

```text
findById()

↓

SELECT

↓

New Java Object

↓

Discard
```

Every operation would require unnecessary database access.

With a Persistence Context:

```text
findById()

↓

Persistence Context

↓

Already Exists?

      │
 ┌────┴────┐
 │         │
Yes       No
 │         │
 ▼         ▼
Reuse    Query Database
```

This improves performance and enables automatic change tracking.

---

# 🏗️ Complete Architecture

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
+-------------------------------------+
|     Persistence Context             |
|-------------------------------------|
| Student(id=1)                       |
| Student(id=2)                       |
| Course(id=10)                       |
+-------------------------------------+
      │
      ▼
Hibernate
      │
      ▼
PostgreSQL
```

The Persistence Context sits between your Java code and the database.

---

# 📦 EntityManager

The Persistence Context is owned by the **EntityManager**.

```java
@PersistenceContext
private EntityManager entityManager;
```

Think of the EntityManager as the manager of all persistent objects.

Responsibilities:

* Create Entities
* Track Entities
* Cache Entities
* Synchronize with the database
* Remove Entities

---

# 🗂️ First-Level Cache

The Persistence Context is also called the **First-Level Cache**.

Example:

```java
Student s1 =
repository.findById(1L).orElseThrow();

Student s2 =
repository.findById(1L).orElseThrow();
```

Execution:

```text
First Call

↓

SELECT

↓

Persistence Context

Second Call

↓

Already Cached

↓

No SQL
```

Only one SQL query is executed.

Both variables reference the same Java object.

---

# 🔄 Entity States

Every Entity exists in one of four states.

```text
New Object
      │
      ▼
Transient
      │
persist()
      ▼
Managed
      │
detach()
      ▼
Detached
      │
remove()
      ▼
Removed
```

Understanding these states is essential for mastering Hibernate.

---

# 🟢 Managed State

Suppose:

```java
Student student =
repository.findById(1L)
          .orElseThrow();
```

Now:

```text
Student

↓

Persistence Context

↓

Managed
```

Hibernate watches every change made to this object.

---

# 🚀 Automatic Change Tracking

Suppose:

```java
student.setMarks(98);
```

Notice:

No SQL.

No `save()`.

Nothing else.

Hibernate simply records:

```text
Old Value

95

↓

New Value

98
```

The Entity remains managed inside the Persistence Context.

---

# ⚡ Dirty Checking

At transaction commit:

```text
Managed Entity

↓

Compare Original State

↓

Changed?

      │
 ┌────┴────┐
 │         │
Yes       No
 │         │
 ▼         ▼
UPDATE   Do Nothing
```

Hibernate automatically generates:

```sql
UPDATE student
SET marks = 98
WHERE id = 1;
```

This feature is called **Dirty Checking**.

---

# 🧹 Detach

Sometimes you want Hibernate to stop tracking an Entity.

```java
entityManager.detach(student);
```

Flow:

```text
Managed

↓

Detached
```

Now:

```java
student.setMarks(100);
```

Hibernate ignores the change because the Entity is no longer managed.

---

# 🔄 Merge

A detached Entity can become managed again.

```java
Student managed =
entityManager.merge(student);
```

Flow:

```text
Detached

↓

Merge

↓

Managed
```

Hibernate resumes tracking changes.

---

# 🍃 Student Results API Example

Request:

```http
GET /students/1
```

Execution:

```text
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

Student(id=1)

↓

Return Entity
```

Later:

```java
student.setMarks(99);
```

Hibernate already knows about this object.

At commit:

```sql
UPDATE student
SET marks = 99
WHERE id = 1;
```

No explicit `save()` call is required for a managed Entity.

---

# 📊 Complete Lifecycle

```text
Database Row
      │
      ▼
SELECT
      │
      ▼
Hibernate
      │
      ▼
Persistence Context
      │
      ▼
Managed Entity
      │
      ▼
Modify Fields
      │
      ▼
Dirty Checking
      │
      ▼
UPDATE SQL
      │
      ▼
Database
```

This is Hibernate's core workflow.

---

# 🚫 Common Mistakes

## ❌ Assuming Every `findById()` Hits the Database

Within the same Persistence Context:

```java
repository.findById(1L);
repository.findById(1L);
```

The second call usually returns the cached managed Entity.

---

## ❌ Modifying Detached Entities

```java
entityManager.detach(student);

student.setMarks(100);
```

Hibernate does **not** save this change automatically.

Detached objects are no longer tracked.

---

## ❌ Calling `save()` After Every Change

For managed Entities inside an active transaction:

```java
student.setMarks(95);
```

Hibernate's Dirty Checking automatically persists the modification at commit time.

Calling `save()` repeatedly is often unnecessary.

---

# 🐳 Docker Perspective

```text
Docker Container
       │
       ▼
JVM
       │
       ▼
Spring Boot
       │
       ▼
Hibernate
       │
       ▼
Persistence Context
       │
       ▼
PostgreSQL
```

The Persistence Context lives entirely in JVM memory.

---

# ☸️ Kubernetes Perspective

```text
Pod
 │
 ▼
Spring Boot
 │
 ▼
EntityManager
 │
 ▼
Persistence Context
 │
 ▼
Database Service
```

Each application instance (Pod) has its own independent Persistence Context.

Persistence Contexts are **never shared** across Pods.

---

# 🧪 Hands-on Lab

## Enable SQL Logging

```properties
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
```

Observe when Hibernate actually executes SQL.

---

## Test the First-Level Cache

```java
Student s1 =
repository.findById(1L).orElseThrow();

Student s2 =
repository.findById(1L).orElseThrow();
```

Verify that only one `SELECT` statement appears in the logs.

---

## Observe Dirty Checking

```java
@Transactional
public void updateStudent() {

    Student student =
        repository.findById(1L).orElseThrow();

    student.setMarks(99);

}
```

Notice:

* ❌ No explicit `save()`
* ✅ Hibernate still executes an `UPDATE` at transaction commit.

---

## Test Detach

```java
entityManager.detach(student);

student.setMarks(100);
```

Verify that no SQL `UPDATE` is generated.

---

## Test Merge

```java
Student managed =
entityManager.merge(student);
```

Modify the returned managed instance and verify that Hibernate persists the change.

---

# 📈 Complete Persistence Context Flow

```text
Application
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
      ├───────────────┐
      ▼               ▼
Managed Entity    First-Level Cache
      │
      ▼
Dirty Checking
      │
      ▼
SQL Generation
      │
      ▼
JDBC Driver
      │
      ▼
PostgreSQL
```

The Persistence Context is the central component that enables Hibernate's intelligent object management.

---

# 📊 Entity States Summary

| State        | Description                              | Tracked by Hibernate?         |
| ------------ | ---------------------------------------- | ----------------------------- |
| 🌱 Transient | Newly created object (`new Student()`)   | ❌ No                          |
| 🟢 Managed   | Stored inside the Persistence Context    | ✅ Yes                         |
| 📴 Detached  | Previously managed but no longer tracked | ❌ No                          |
| 🗑️ Removed  | Scheduled for deletion                   | ✅ Until transaction completes |

---

# 💡 Key Takeaways

✅ The Persistence Context is an in-memory workspace managed by the `EntityManager`.

✅ Every managed Entity lives inside the Persistence Context until it is detached, removed, or the context is closed.

✅ The Persistence Context also acts as Hibernate's **First-Level Cache**, preventing duplicate database queries within the same context.

✅ Managed Entities are automatically tracked, enabling Hibernate's **Dirty Checking** mechanism.

✅ Changes to managed Entities are synchronized with the database automatically during transaction commit.

✅ Detached Entities are ordinary Java objects and are no longer monitored by Hibernate until they are merged back into the Persistence Context.

✅ Understanding the Persistence Context is essential for mastering transactions, caching, lazy loading, flushing, and Hibernate performance optimization.

---

# ➡️ Next Chapter

📘 **`07-Hibernate/03-Dirty-Checking.md`**

In the next chapter, we'll dive deeply into one of Hibernate's most powerful features:

* ⚡ What Dirty Checking is
* 🔍 How Hibernate detects field changes
* 🧠 Snapshot comparison
* ⏱️ When Dirty Checking runs
* 💾 Automatic SQL generation
* 🚀 Performance implications
* 🛑 Situations where Dirty Checking does **not** occur

By the end of the next chapter, you'll understand why changing a single Java field can automatically generate an `UPDATE` statement without ever calling `save()`.
