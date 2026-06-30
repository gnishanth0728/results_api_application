# 📘 Chapter 58 — Hibernate Transactions

> 📂 File: `student-results-api-notes/07-Hibernate/07-Transactions.md`

---

# 🌍 Introduction

In the previous chapter, we learned how Hibernate loads related entities using **Lazy** and **Eager** fetching.

We also learned that Hibernate generates SQL automatically using **Dirty Checking**.

Example:

```java
@Transactional
public void updateMarks(Long id){

    Student student =
        repository.findById(id)
                  .orElseThrow();

    student.setMarks(98);

}
```

Notice something surprising...

We never wrote:

```sql
UPDATE student
SET marks = 98
WHERE id = 1;
```

Yet the database was updated successfully.

This raises an important question:

> 🤔 **When exactly did Hibernate execute the SQL?**

The answer lies in the **Transaction**.

A transaction defines the boundary of a unit of work.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🔄 What a Transaction is
* 🏦 ACID Properties
* 🏷️ `@Transactional`
* 🧠 Transaction Lifecycle
* 💾 Flush
* ✅ Commit
* ↩️ Rollback
* 🏛️ Persistence Context
* ⚡ Dirty Checking
* 🚀 Transaction Propagation
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ What Is a Transaction?

A Transaction is a group of operations that are treated as **one logical unit of work**.

Example:

```text
Update Student

↓

Update Marks

↓

Insert Audit Log

↓

Send Notification
```

Either:

```text
✅ Everything succeeds
```

or

```text
❌ Everything fails
```

There is no partial success.

---

# 🏦 ACID Properties

Every database transaction follows the ACID principles.

## 🔹 Atomicity

All operations succeed together.

```text
Update Student

↓

Update Marks

↓

Insert Audit

↓

Commit
```

If one fails:

```text
Rollback Everything
```

---

## 🔹 Consistency

A transaction must leave the database in a valid state.

```text
Before Transaction

↓

Valid Database

↓

After Transaction

↓

Still Valid
```

---

## 🔹 Isolation

Multiple users should not interfere with each other.

```text
User A

↓

Transaction A

-------------------

User B

↓

Transaction B
```

Each transaction sees a consistent view of the data.

---

## 🔹 Durability

After a transaction commits:

```text
Commit

↓

Disk

↓

Permanent Data
```

Even if the application crashes immediately afterward, committed data is preserved.

---

# 🏗️ Transaction Architecture

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
@Transactional
     │
     ▼
Persistence Context
     │
     ▼
Hibernate
     │
     ▼
PostgreSQL
```

The transaction surrounds the business logic executed by the Service.

---

# 🏷️ @Transactional

Spring Boot simplifies transaction management with:

```java
@Transactional
public void updateStudent(Long id){

}
```

When this method starts:

```text
Open Transaction

↓

Execute Business Logic

↓

Commit or Rollback

↓

Close Transaction
```

Spring manages the entire lifecycle automatically.

---

# 🔄 Complete Transaction Lifecycle

```text
Method Call
      │
      ▼
Begin Transaction
      │
      ▼
Create Persistence Context
      │
      ▼
Execute Repository Methods
      │
      ▼
Dirty Checking
      │
      ▼
Flush
      │
      ▼
Commit
      │
      ▼
Close Persistence Context
```

Everything happens inside one transaction.

---

# 💾 Flush

Flush means:

> Synchronize the Persistence Context with the database.

Example:

```java
student.setMarks(99);
```

Hibernate performs:

```text
Managed Entity

↓

Dirty Checking

↓

Generate SQL

↓

Execute SQL
```

Flush sends SQL to the database but does **not** permanently save it.

The transaction is still open.

---

# ✅ Commit

Commit makes all transaction changes permanent.

Flow:

```text
SQL Executed

↓

Commit

↓

Data Permanently Stored
```

After commit:

```text
Transaction Closed

↓

Persistence Context Closed
```

---

# ↩️ Rollback

Suppose:

```java
@Transactional
public void updateStudent(){

    repository.save(student);

    throw new RuntimeException();

}
```

Execution:

```text
INSERT Student

↓

Exception

↓

Rollback

↓

Database Unchanged
```

Rollback undoes all work performed within the transaction.

---

# ⚡ Dirty Checking Inside Transactions

Example:

```java
@Transactional
public void updateStudent(){

    Student student =
        repository.findById(1L)
                  .orElseThrow();

    student.setMarks(100);

}
```

Flow:

```text
Load Entity

↓

Managed Entity

↓

Modify Field

↓

Dirty Checking

↓

Flush

↓

Commit

↓

UPDATE SQL
```

Without the transaction, Hibernate may never synchronize these changes.

---

# 🍃 Student Results API Example

Request:

```http
PUT /students/1
```

Execution:

```text
Browser
      │
      ▼
Controller
      │
      ▼
StudentService
      │
@Transactional
      ▼
Repository
      │
      ▼
Persistence Context
      │
      ▼
Dirty Checking
      │
      ▼
Flush
      │
      ▼
Commit
      │
      ▼
HTTP 200 OK
```

Every successful update is protected by a transaction.

---

# 📊 Flush vs Commit

| Flush 💾                  | Commit ✅                           |
| ------------------------- | ---------------------------------- |
| Sends SQL to database     | Permanently saves changes          |
| Transaction still open    | Transaction ends                   |
| Can happen multiple times | Happens once                       |
| Can be rolled back        | Cannot be rolled back after commit |

Flush is **not** the same as commit.

---

# 🔄 Transaction Propagation

Suppose:

```java
StudentService
```

calls:

```java
AuditService
```

Both methods use:

```java
@Transactional
```

Spring decides whether to:

* Join the existing transaction
* Start a new transaction
* Suspend the current transaction

The default propagation is:

```text
Propagation.REQUIRED
```

Meaning:

```text
Existing Transaction?

      │
 ┌────┴────┐
 │         │
Yes       No
 │         │
 ▼         ▼
Join    Create New
```

---

# 🚫 Common Mistakes

## ❌ Missing @Transactional

```java
public void updateStudent(){

    student.setMarks(99);

}
```

The Entity may be modified in memory, but Hibernate may never flush the changes to the database.

---

## ❌ Catching Exceptions Without Rethrowing

```java
try{

}
catch(Exception e){

}
```

Swallowing exceptions may prevent rollback.

If an error should cancel the transaction, allow the exception to propagate or configure rollback explicitly.

---

## ❌ Long Transactions

```text
Begin Transaction

↓

Wait 30 Seconds

↓

External API Call

↓

Commit
```

Long-running transactions:

* Hold database locks longer
* Increase contention
* Reduce scalability

Keep transactions as short as possible.

---

# 🐳 Docker Perspective

```text
Docker Container
       │
       ▼
Spring Boot
       │
       ▼
Transaction Manager
       │
       ▼
Hibernate
       │
       ▼
PostgreSQL Container
```

Transactions behave the same whether the application runs locally or inside Docker.

---

# ☸️ Kubernetes Perspective

```text
Pod
 │
 ▼
Spring Boot
 │
 ▼
Transaction Manager
 │
 ▼
Hibernate
 │
 ▼
Database Service
 │
 ▼
PostgreSQL Pod
```

Each Pod manages its own transactions independently.

Database consistency is enforced by PostgreSQL.

---

# 🧪 Hands-on Lab

## Enable SQL Logging

```properties
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
```

Observe when SQL is flushed and committed.

---

## Successful Transaction

```java
@Transactional
public void updateStudent(){

    Student student =
        repository.findById(1L)
                  .orElseThrow();

    student.setMarks(99);

}
```

Verify that Hibernate generates an `UPDATE` and commits it successfully.

---

## Rollback Example

```java
@Transactional
public void updateStudent(){

    Student student =
        repository.findById(1L)
                  .orElseThrow();

    student.setMarks(99);

    throw new RuntimeException("Failure");
}
```

Verify that the database remains unchanged after rollback.

---

## Force a Flush

```java
entityManager.flush();
```

Observe that SQL is sent to the database before the transaction commits.

---

## Debug Transaction Lifecycle

Set breakpoints in:

* `TransactionInterceptor`
* `JpaTransactionManager`
* `StudentService`

Step through the transaction begin, flush, commit, and rollback process.

---

# 📈 Complete Transaction Flow

```text
HTTP Request
      │
      ▼
Controller
      │
      ▼
@Service
      │
      ▼
@Transactional
      │
      ▼
Begin Transaction
      │
      ▼
Persistence Context Created
      │
      ▼
Repository
      │
      ▼
Managed Entities
      │
      ▼
Dirty Checking
      │
      ▼
Flush
      │
      ▼
Commit
      │
      ▼
Persistence Context Closed
      │
      ▼
HTTP Response
```

This is the complete lifecycle of a Hibernate transaction.

---

# 📊 Transaction Outcome

| Situation                            | Result                                    |
| ------------------------------------ | ----------------------------------------- |
| All operations succeed               | ✅ Commit                                  |
| Runtime exception occurs             | ↩️ Rollback (default)                     |
| Checked exception (default behavior) | ⚠️ May commit unless configured otherwise |
| Explicit `entityManager.flush()`     | 💾 SQL sent, transaction still active     |
| Commit completed                     | 🔒 Changes permanently stored             |

---

# 💡 Key Takeaways

✅ A transaction groups multiple database operations into one logical unit of work.

✅ Hibernate relies on transactions to coordinate the Persistence Context, Dirty Checking, and SQL execution.

✅ `@Transactional` automatically manages transaction begin, commit, rollback, and cleanup.

✅ **Flush** synchronizes the Persistence Context with the database, while **Commit** permanently saves those changes.

✅ If an exception causes a rollback, all changes made during the transaction are discarded, preserving database consistency.

✅ Short, well-defined transactions improve application performance and reduce database contention.

✅ Understanding transactions is essential before learning advanced topics such as cascading, locking, isolation levels, and optimistic concurrency.

---

# ➡️ Next Chapter

📘 **`07-Hibernate/08-First-Level-Cache.md`**

In the next chapter, we'll explore Hibernate's **First-Level Cache**, which lives inside the Persistence Context.

We'll answer questions such as:

* 🧠 What is the First-Level Cache?
* 🔍 Why does calling `findById()` twice often execute only one SQL query?
* 📦 How does Hibernate reuse managed entities?
* 🚀 How does the cache improve performance?
* 🧹 When is the cache cleared?

By the end of the next chapter, you'll understand why Hibernate avoids unnecessary database queries and how the First-Level Cache works together with the Persistence Context.
