# 📘 Chapter 54 — Hibernate Entity Lifecycle

> 📂 File: `student-results-api-notes/07-Hibernate/03-Entity-Lifecycle.md`

You're now at one of the most fundamental Hibernate concepts.

The previous chapter explained where an Entity lives (Persistence Context).

This chapter explains how an Entity changes throughout its lifetime.

Many Hibernate features—Dirty Checking, persist(), merge(), remove(), detach(), flush(), commit()—only make sense after understanding the Entity Lifecycle.

This chapter answers:

What actually happens to a Java object from new Student() until it is deleted from the database?

---

# 🌍 Introduction

In the previous chapter, we learned that every managed Entity lives inside the **Persistence Context**.

Example:

```java
Student student =
    repository.findById(1L)
              .orElseThrow();
```

Hibernate stores this object inside the Persistence Context and tracks every modification.

But another important question appears:

> 🤔 **Does every Entity always stay inside the Persistence Context?**

No.

An Entity moves through different **states** during its lifetime.

Understanding these states is the key to mastering Hibernate.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🌱 Transient State
* 🟢 Managed State
* 📴 Detached State
* 🗑️ Removed State
* 🧠 Persistence Context
* 💾 persist()
* 🔄 merge()
* 🧹 detach()
* ❌ remove()
* 🚀 SQL generation
* 🐳 Docker
* ☸️ Kubernetes

---

# 🏗️ Complete Entity Lifecycle

```text
                new Student()
                      │
                      ▼
          🌱 Transient State
                      │
             entityManager.persist()
                      │
                      ▼
           🟢 Managed State
                      │
      ┌───────────────┼────────────────┐
      ▼               ▼                ▼
 entityManager   Transaction      Dirty Checking
    .detach()      Commit
      │               │
      ▼               ▼
 📴 Detached     UPDATE / INSERT
      │
 entityManager.merge()
      │
      ▼
 🟢 Managed
      │
 entityManager.remove()
      │
      ▼
 🗑️ Removed
      │
 Transaction Commit
      │
      ▼
 Deleted From Database
```

Every Hibernate Entity follows this lifecycle.

---

# 🌱 State 1 — Transient

An Entity starts as an ordinary Java object.

```java
Student student = new Student();

student.setName("Alice");
student.setMarks(95);
```

Current state:

```text
Java Heap

↓

Student Object

↓

NOT managed

↓

NOT in database
```

Characteristics:

* ❌ Not managed by Hibernate
* ❌ Not inside Persistence Context
* ❌ No database row exists
* ❌ No SQL generated

Hibernate knows nothing about this object.

---

# 💾 Moving to Managed State

When you call:

```java
entityManager.persist(student);
```

Hibernate performs:

```text
Transient

↓

Persistence Context

↓

Managed
```

The object is now tracked.

---

# 🟢 State 2 — Managed

This is the most important state.

```java
Student student =
entityManager.find(Student.class,1L);
```

Current state:

```text
Persistence Context

↓

Student

↓

Managed
```

Characteristics:

* ✅ Hibernate tracks changes
* ✅ Dirty Checking enabled
* ✅ Cached in First-Level Cache
* ✅ SQL generated automatically

---

# ✏️ Modifying a Managed Entity

Example:

```java
student.setMarks(98);
```

Notice:

No SQL yet.

No save().

No update().

Hibernate simply records:

```text
Old Value

95

↓

New Value

98
```

The SQL is generated later during flush or commit.

---

# 🚀 Transaction Commit

When the transaction commits:

```text
Managed Entity

↓

Dirty Checking

↓

UPDATE SQL

↓

Database
```

Generated SQL:

```sql
UPDATE student
SET marks = 98
WHERE id = 1;
```

This happens automatically.

---

# 📴 State 3 — Detached

Sometimes an Entity should stop being managed.

```java
entityManager.detach(student);
```

Flow:

```text
Managed

↓

Detached
```

Characteristics:

* ❌ No Dirty Checking
* ❌ No automatic SQL
* ❌ Not inside Persistence Context
* ✅ Still exists as a Java object

---

# ✏️ Modifying a Detached Entity

```java
student.setMarks(100);
```

Nothing happens.

No SQL.

No update.

Because Hibernate no longer tracks this object.

---

# 🔄 Returning to Managed

A detached Entity can be managed again.

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

Hibernate copies the detached object's state into a managed instance.

---

# 🗑️ State 4 — Removed

Suppose:

```java
entityManager.remove(student);
```

Current state:

```text
Managed

↓

Removed
```

The object still exists in memory until the transaction commits.

At commit:

```sql
DELETE
FROM student
WHERE id = 1;
```

After commit:

```text
Database Row

↓

Deleted
```

---

# 📊 State Transition Diagram

```text
new Student()
      │
      ▼
🌱 Transient
      │
persist()
      ▼
🟢 Managed
      │
detach()
      ▼
📴 Detached
      │
merge()
      ▼
🟢 Managed
      │
remove()
      ▼
🗑️ Removed
      │
commit()
      ▼
Deleted
```

This diagram summarizes the complete lifecycle.

---

# 🍃 Student Results API Example

Creating a student:

```java
Student student = new Student();

student.setName("Alice");

repository.save(student);
```

Flow:

```text
Transient

↓

Managed

↓

INSERT

↓

Database
```

Updating:

```java
student.setMarks(99);
```

Flow:

```text
Managed

↓

Dirty Checking

↓

UPDATE
```

Deleting:

```java
repository.delete(student);
```

Flow:

```text
Managed

↓

Removed

↓

DELETE
```

---

# 🚫 Common Mistakes

## ❌ Assuming `new` Saves Data

```java
Student student = new Student();
```

This only creates a Java object.

No database row exists.

---

## ❌ Updating Detached Entities

```java
entityManager.detach(student);

student.setMarks(99);
```

Hibernate ignores the change.

Use `merge()` to reattach the Entity.

---

## ❌ Calling `save()` for Managed Entities

```java
student.setMarks(100);
repository.save(student);
```

Inside an active transaction, this is often unnecessary because Dirty Checking will update the database automatically.

---

# 🧠 Lifecycle vs Database

| Entity State | Exists in Memory | Exists in Database | Managed by Hibernate |
| ------------ | ---------------- | ------------------ | -------------------- |
| 🌱 Transient | ✅ Yes            | ❌ No               | ❌ No                 |
| 🟢 Managed   | ✅ Yes            | ✅ Usually          | ✅ Yes                |
| 📴 Detached  | ✅ Yes            | ✅ Yes              | ❌ No                 |
| 🗑️ Removed  | ✅ Until commit   | ❌ After commit     | ✅ Until commit       |

---

# 🐳 Docker Perspective

```text
Docker Container
        │
        ▼
JVM
        │
        ▼
Persistence Context
        │
        ▼
Entity Lifecycle
        │
        ▼
PostgreSQL
```

The Entity lifecycle happens entirely inside the JVM.

---

# ☸️ Kubernetes Perspective

```text
Pod

↓

Spring Boot

↓

Hibernate

↓

Persistence Context

↓

Entity Lifecycle
```

Each Pod manages its own Entity lifecycle independently.

---

# 🧪 Hands-on Lab

## Create a Transient Entity

```java
Student student = new Student();

student.setName("Alice");
```

Observe that no SQL is generated.

---

## Persist the Entity

```java
entityManager.persist(student);
```

Commit the transaction and observe the generated `INSERT`.

---

## Modify a Managed Entity

```java
student.setMarks(99);
```

Commit the transaction and verify that Hibernate generates an `UPDATE` automatically.

---

## Detach the Entity

```java
entityManager.detach(student);

student.setMarks(100);
```

Verify that no SQL is executed.

---

## Merge the Entity

```java
Student managed =
entityManager.merge(student);
```

Modify the managed object and commit the transaction.

Observe the generated `UPDATE`.

---

## Remove the Entity

```java
entityManager.remove(managed);
```

Commit the transaction and observe the generated `DELETE`.

---

# 📈 Complete Entity Lifecycle

```text
Java Object
      │
      ▼
🌱 Transient
      │
persist()
      ▼
🟢 Managed
      │
Dirty Checking
      │
UPDATE / INSERT
      │
detach()
      ▼
📴 Detached
      │
merge()
      ▼
🟢 Managed
      │
remove()
      ▼
🗑️ Removed
      │
commit()
      ▼
DELETE FROM Database
```

This is the complete lifecycle followed by every Hibernate Entity.

---

# 💡 Key Takeaways

✅ Every Hibernate Entity moves through well-defined lifecycle states.

✅ A **Transient** Entity is a normal Java object that Hibernate does not manage.

✅ A **Managed** Entity lives inside the Persistence Context and is automatically tracked for changes.

✅ A **Detached** Entity still exists in memory but is no longer tracked by Hibernate.

✅ A **Removed** Entity is scheduled for deletion and is deleted when the transaction commits.

✅ `persist()`, `merge()`, `detach()`, and `remove()` transition an Entity between lifecycle states.

✅ Understanding the Entity Lifecycle is essential for mastering Dirty Checking, Transactions, Caching, and overall Hibernate behavior.

---

# ➡️ Next Chapter

📘 **`07-Hibernate/04-Dirty-Checking.md`**

In the next chapter, we'll explore one of Hibernate's most powerful optimizations:

* ⚡ How Dirty Checking works internally
* 📸 Snapshot creation
* 🔍 Field-by-field comparison
* 🧠 When Hibernate decides to generate an `UPDATE`
* 🚀 Performance implications
* 🛑 Cases where Dirty Checking does not occur

By the end of the next chapter, you'll understand why simply changing:

```java
student.setMarks(100);
```

can automatically result in:

```sql
UPDATE student
SET marks = 100
WHERE id = 1;
```

without ever calling `save()` or writing SQL yourself.
