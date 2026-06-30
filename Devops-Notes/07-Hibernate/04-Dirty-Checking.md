# 📘 Chapter 55 — Hibernate Dirty Checking

> 📂 File: `student-results-api-notes/07-Hibernate/04-Dirty-Checking.md`

This chapter is one of the most magical features of Hibernate.

Many developers coming from JDBC think:

"I changed a Java object... why did Hibernate automatically execute an UPDATE?"

The answer is Dirty Checking.

This chapter explains exactly:

How Hibernate remembers the original Entity state
How it compares changes
When comparison happens
Why save() is often unnecessary
How snapshots work internally

This is one of the biggest advantages of using Hibernate over plain JDBC.

---

# 🌍 Introduction

In the previous chapter, we learned about the **Entity Lifecycle**.

We saw that when an Entity enters the **Managed** state, Hibernate starts tracking it inside the **Persistence Context**.

Example:

```java
Student student =
    repository.findById(1L)
              .orElseThrow();
```

Now consider this code:

```java
student.setMarks(98);
```

Notice something surprising...

We never called:

```java
repository.save(student);

entityManager.update(student);

UPDATE student SET ...
```

Yet when the transaction commits, Hibernate automatically executes:

```sql
UPDATE student
SET marks = 98
WHERE id = 1;
```

This raises an important question:

> 🤔 **How did Hibernate know the Entity changed?**

The answer is:

# ⚡ Dirty Checking

Dirty Checking is Hibernate's automatic mechanism for detecting changes to managed Entities and synchronizing those changes with the database.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* ⚡ What Dirty Checking is
* 📸 Entity Snapshots
* 🧠 Persistence Context
* 🔍 Change Detection
* 🚀 SQL Generation
* 💾 Flush
* ✅ Transaction Commit
* ⚠️ Performance Considerations
* 🚫 Common Mistakes
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ What Is Dirty Checking?

Dirty Checking means:

> Hibernate automatically detects modifications made to managed Entities.

Example:

```java
Student student =
repository.findById(1L)
          .orElseThrow();

student.setMarks(99);
```

You modified a Java object.

Hibernate notices the modification and generates SQL automatically.

---

# 🧠 Why Is It Called "Dirty"?

Hibernate calls an Entity **dirty** when its current state differs from its original state.

```text
Original Entity
marks = 95
        │
        ▼
Student.setMarks(99)
        │
        ▼
Current Entity
marks = 99
```

The Entity is now considered **Dirty** because it has been modified.

---

# 📸 Snapshot Creation

When Hibernate loads an Entity:

```java
Student student =
repository.findById(1L)
          .orElseThrow();
```

Hibernate creates two things:

```text
Persistence Context

├── Managed Entity

│      marks = 95

└── Snapshot

       marks = 95
```

The snapshot is a copy of the Entity's original values.

Hibernate uses it later for comparison.

---

# ✏️ Entity Modification

Suppose:

```java
student.setMarks(98);
```

Current state:

```text
Persistence Context

Managed Entity

marks = 98

------------------

Snapshot

marks = 95
```

No SQL has been executed yet.

Hibernate simply records that the current object differs from its snapshot.

---

# 🔍 Dirty Checking Process

When Hibernate flushes the Persistence Context, it compares:

```text
Snapshot

↓

marks = 95

-------------------

Current Entity

↓

marks = 98
```

Comparison:

```text
Changed?

     │
 ┌───┴────┐
 │        │
Yes      No
 │        │
 ▼        ▼
UPDATE   Ignore
```

If any field changed, Hibernate marks the Entity as dirty.

---

# 💾 Flush

Dirty Checking occurs during **Flush**.

Flush means:

> Synchronize the Persistence Context with the database.

Flow:

```text
Persistence Context

↓

Dirty Checking

↓

Generate SQL

↓

Execute SQL
```

Flush does **not** end the transaction.

It only synchronizes memory with the database.

---

# ✅ Transaction Commit

Typical sequence:

```text
Begin Transaction
        │
        ▼
Load Entity
        │
        ▼
Modify Entity
        │
        ▼
Flush
        │
        ▼
Dirty Checking
        │
        ▼
UPDATE SQL
        │
        ▼
Commit Transaction
```

Hibernate automatically updates only the changed columns.

---

# 🍃 Student Results API Example

Suppose the browser sends:

```http
PUT /students/1
```

Service:

```java
@Transactional
public void updateMarks(Long id){

    Student student =
        repository.findById(id)
                  .orElseThrow();

    student.setMarks(99);

}
```

Notice:

No `save()`.

No `update()`.

At commit:

```sql
UPDATE student
SET marks = 99
WHERE id = 1;
```

Dirty Checking performs the update automatically.

---

# 🏗️ Internal Architecture

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
      ├───────────────┐
      ▼               ▼
Managed Entity     Snapshot
      │               │
      └──────┬────────┘
             ▼
      Dirty Checking
             ▼
      SQL Generation
             ▼
        PostgreSQL
```

Dirty Checking compares the managed Entity with its snapshot.

---

# 🚫 When Dirty Checking Does NOT Work

## ❌ Detached Entity

```java
entityManager.detach(student);

student.setMarks(100);
```

No SQL.

Reason:

```text
Detached Entity

↓

Not Managed

↓

No Dirty Checking
```

---

## ❌ Outside a Transaction

```java
student.setMarks(100);
```

Without an active transaction, Hibernate may never flush changes.

Dirty Checking typically occurs when a transaction commits or an explicit flush is triggered.

---

## ❌ Transient Entity

```java
Student student = new Student();

student.setMarks(90);
```

Hibernate does not know about this object.

No Persistence Context.

No Dirty Checking.

---

# 📊 Snapshot Comparison

```text
Original Snapshot

id = 1

name = Alice

marks = 95

------------------------

Current Entity

id = 1

name = Alice

marks = 98
```

Comparison result:

```text
Only marks changed

↓

Generate

UPDATE student

SET marks = 98

WHERE id = 1
```

Hibernate updates only what changed.

---

# ⚠️ Performance Considerations

Dirty Checking is efficient, but every managed Entity must be compared with its snapshot.

Large Persistence Contexts can increase flush time.

Best practices:

* ✅ Keep transactions short
* ✅ Avoid loading thousands of managed Entities unnecessarily
* ✅ Clear the Persistence Context during large batch operations
* ✅ Use pagination for large result sets

---

# 🚫 Common Mistakes

## ❌ Calling save() Repeatedly

```java
student.setMarks(96);
repository.save(student);

student.setMarks(97);
repository.save(student);

student.setMarks(98);
repository.save(student);
```

Inside one transaction, these repeated `save()` calls are often unnecessary.

Hibernate already tracks the managed Entity.

---

## ❌ Assuming Every Setter Executes SQL

```java
student.setMarks(99);
```

Setter methods modify only the in-memory object.

SQL is generated later during flush.

---

## ❌ Modifying Detached Entities

```java
entityManager.detach(student);

student.setMarks(100);
```

Detached Entities are not tracked.

No Dirty Checking occurs.

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
Persistence Context
       │
       ▼
Dirty Checking
       │
       ▼
PostgreSQL
```

Dirty Checking occurs entirely inside the JVM before SQL is sent to the database.

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
Dirty Checking
 │
 ▼
Database Service
```

Each Pod maintains its own Persistence Context and performs Dirty Checking independently.

---

# 🧪 Hands-on Lab

## Enable SQL Logging

```properties
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
```

Observe exactly when SQL statements are executed.

---

## Modify a Managed Entity

```java
@Transactional
public void updateStudent() {

    Student student =
        repository.findById(1L)
                  .orElseThrow();

    student.setMarks(99);

}
```

Observe:

* ❌ No explicit `save()`
* ✅ Hibernate generates an `UPDATE` automatically.

---

## Force a Flush

```java
entityManager.flush();
```

Watch Hibernate perform Dirty Checking immediately instead of waiting for transaction commit.

---

## Test a Detached Entity

```java
entityManager.detach(student);

student.setMarks(100);
```

Verify that no SQL is generated.

---

## Compare Snapshot and Current State

Set a breakpoint before `entityManager.flush()` and inspect:

* Managed Entity values
* Original snapshot (through the debugger/internal Hibernate state)

Observe how Hibernate determines that the Entity is dirty.

---

# 📈 Complete Dirty Checking Flow

```text
SELECT
   │
   ▼
Managed Entity
   │
   ▼
Snapshot Created
   │
   ▼
Modify Entity
   │
   ▼
Flush
   │
   ▼
Compare Snapshot
   │
   ▼
Dirty?
   │
 ┌─┴──────────┐
 ▼            ▼
Yes           No
 │            │
 ▼            ▼
Generate      No SQL
UPDATE
 │
 ▼
JDBC
 │
 ▼
PostgreSQL
```

This is the complete Dirty Checking workflow used by Hibernate.

---

# 📊 Dirty Checking Conditions

| Condition             | Dirty Checking?                         |
| --------------------- | --------------------------------------- |
| 🟢 Managed Entity     | ✅ Yes                                   |
| 🌱 Transient Entity   | ❌ No                                    |
| 📴 Detached Entity    | ❌ No                                    |
| 🗑️ Removed Entity    | ❌ No (scheduled for DELETE instead)     |
| 🔄 Active Transaction | ✅ Yes                                   |
| ❌ No Transaction      | ⚠️ Usually no automatic synchronization |

---

# 💡 Key Takeaways

✅ Dirty Checking is Hibernate's automatic mechanism for detecting changes to managed Entities.

✅ When an Entity is loaded, Hibernate stores a snapshot of its original state inside the Persistence Context.

✅ During a flush, Hibernate compares the current Entity with its snapshot to determine whether any fields have changed.

✅ If differences are found, Hibernate generates the appropriate `UPDATE` statement automatically.

✅ Dirty Checking works only for **managed Entities** inside an active Persistence Context.

✅ Detached and transient Entities are not tracked and therefore are not automatically synchronized with the database.

✅ Understanding Dirty Checking explains why many Hibernate applications update database records without explicitly calling `save()` after modifying a managed Entity.
