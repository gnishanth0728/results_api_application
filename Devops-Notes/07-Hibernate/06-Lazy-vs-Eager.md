# 📘 Chapter 57 — Hibernate Lazy vs Eager Loading

> 📂 File: `student-results-api-notes/07-Hibernate/06-Lazy-vs-Eager.md`

This chapter covers one of the most misunderstood Hibernate concepts.

Many developers know about FetchType.LAZY and FetchType.EAGER, but they don't understand:

When is SQL executed?
Why do extra SELECT statements appear?
What causes the N+1 Query Problem?
Why does LazyInitializationException happen?

This chapter explains the complete lifecycle of lazy and eager loading, including what happens inside the Persistence Context.

---

# 🌍 Introduction

In the previous chapter, we learned how Hibernate generates SQL automatically.

Example:

```java
Student student =
repository.findById(1L)
          .orElseThrow();
```

Hibernate generated:

```sql
SELECT *
FROM student
WHERE id = 1;
```

But suppose our `Student` has enrolled in multiple courses.

```text
Student
   │
   ├── Course 1
   ├── Course 2
   ├── Course 3
```

This raises an important question:

> 🤔 **Should Hibernate load all the courses immediately?**

Or should it wait until our code actually needs them?

The answer depends on the **Fetch Strategy**.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📥 What Fetching is
* 🐢 Lazy Loading
* ⚡ Eager Loading
* 🧩 Hibernate Proxies
* 🏛️ Persistence Context
* 📈 SQL Generation
* 🚨 LazyInitializationException
* 📊 N+1 Query Problem
* 🚀 Performance Best Practices
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ What Is Fetching?

Fetching means:

> **Loading related objects from the database.**

Example:

```java
Student
```

contains:

```java
List<Course> courses;
```

Hibernate must decide:

```text
Load Student Only

OR

Load Student + Courses
```

This decision is controlled by the fetch strategy.

---

# 🏗️ Example Entity Relationship

```java
@Entity
public class Student {

    @Id
    private Long id;

    private String name;

    @OneToMany(mappedBy = "student")
    private List<Course> courses;

}
```

Database:

```text
student
-------
1 Alice

course
-------
Math
Physics
Chemistry
```

One Student is related to many Courses.

---

# 🐢 Lazy Loading

Lazy loading means:

> **Load the related data only when it is actually needed.**

Configuration:

```java
@OneToMany(fetch = FetchType.LAZY)
private List<Course> courses;
```

Execution:

```java
Student student =
repository.findById(1L)
          .orElseThrow();
```

Generated SQL:

```sql
SELECT *
FROM student
WHERE id = 1;
```

Notice:

Courses are **not** loaded yet.

---

# 🧩 Hibernate Proxy

Instead of loading courses immediately, Hibernate creates a **Proxy**.

```text
Student
   │
   ▼
Courses

↓

Hibernate Proxy

↓

Not Loaded Yet
```

The proxy acts like a placeholder.

---

# 🚀 Triggering Lazy Loading

Suppose:

```java
student.getCourses();
```

Now Hibernate executes:

```sql
SELECT *
FROM course
WHERE student_id = 1;
```

Only now are the courses loaded.

---

# ⚡ Eager Loading

Eager loading means:

> **Load related objects immediately.**

Configuration:

```java
@OneToMany(fetch = FetchType.EAGER)
private List<Course> courses;
```

Now:

```java
repository.findById(1L);
```

Immediately loads:

```text
Student

+

Courses
```

Possible SQL:

```sql
SELECT *
FROM student;

SELECT *
FROM course;
```

or a single JOIN query depending on Hibernate's strategy.

---

# 📊 Lazy vs Eager

| Feature                  | 🐢 Lazy   | ⚡ Eager             |
| ------------------------ | --------- | ------------------- |
| Loads immediately        | ❌ No      | ✅ Yes               |
| Better performance       | ✅ Usually | ❌ Often slower      |
| Memory usage             | Lower     | Higher              |
| Additional SQL later     | ✅ Yes     | ❌ Usually not       |
| Default for `@OneToMany` | ✅ Yes     | ❌ No                |
| Default for `@ManyToOne` | ❌ No      | ✅ Yes (JPA default) |

---

# 🏗️ Internal Architecture

```text
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
Student Entity   Hibernate Proxy
                     │
                     ▼
               Database
```

The proxy delays SQL execution until needed.

---

# 🚨 LazyInitializationException

Suppose:

```java
Student student =
repository.findById(1L)
          .orElseThrow();
```

Transaction ends.

Later:

```java
student.getCourses();
```

Hibernate throws:

```text
LazyInitializationException
```

Why?

```text
Transaction Closed

↓

Persistence Context Closed

↓

Proxy Cannot Load Data
```

The proxy no longer has an active `EntityManager`.

---

# 📊 N+1 Query Problem

Suppose:

```java
List<Student> students =
repository.findAll();
```

Hibernate executes:

```sql
SELECT *
FROM student;
```

Later:

```java
for(Student s : students){

    s.getCourses();

}
```

Now SQL becomes:

```text
1 Query

↓

Students

+

100 Queries

↓

Courses
```

Total:

```text
101 Queries
```

This is called the **N+1 Query Problem**.

---

# 🍃 Student Results API Example

Request:

```http
GET /students
```

Flow:

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
Students Loaded
      │
      ▼
DTO Mapping
      │
      ▼
Need Courses?
      │
      ├──────────────┐
      ▼              ▼
No             Trigger Lazy SQL
```

Fetching strategy directly affects API performance.

---

# 🚀 Best Practices

✅ Use **LAZY** by default for collections.

```java
@OneToMany(fetch = FetchType.LAZY)
```

✅ Load relationships only when needed.

✅ Use DTO projections for REST APIs.

✅ Avoid exposing Entities directly.

✅ Use `JOIN FETCH` when related data is always required.

---

# 🚫 Common Mistakes

## ❌ Making Everything EAGER

```java
@OneToMany(fetch = FetchType.EAGER)
```

Large object graphs can cause:

* Slow startup
* High memory usage
* Massive SQL joins

---

## ❌ Returning Lazy Entities Directly

```java
return student;
```

Jackson may try to serialize:

```java
student.getCourses();
```

after the transaction has closed.

Result:

```text
LazyInitializationException
```

Return DTOs instead.

---

## ❌ Ignoring the N+1 Problem

```java
students.forEach(
    s -> s.getCourses()
);
```

May generate hundreds of unnecessary SQL queries.

Always inspect generated SQL logs.

---

# 🐳 Docker Perspective

```text
Docker Container
       │
       ▼
Spring Boot
       │
       ▼
Hibernate Proxy
       │
       ▼
Lazy SQL
       │
       ▼
PostgreSQL Container
```

Lazy loading happens inside the JVM. Containers do not change this behavior.

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
Lazy Loading
 │
 ▼
Database Service
```

Each Pod manages its own Persistence Context and proxies.

---

# 🧪 Hands-on Lab

## Test Lazy Loading

```java
@OneToMany(fetch = FetchType.LAZY)
private List<Course> courses;
```

Enable SQL logging.

Run:

```java
Student student =
repository.findById(1L)
          .orElseThrow();
```

Verify that only the `student` table is queried.

---

## Trigger Lazy Loading

```java
student.getCourses().size();
```

Observe the second SQL query for the `course` table.

---

## Test Eager Loading

Change:

```java
fetch = FetchType.EAGER
```

Run the same code and compare the generated SQL.

---

## Reproduce LazyInitializationException

Retrieve a Student inside a transaction.

After the transaction ends:

```java
student.getCourses();
```

Observe the exception.

---

## Detect the N+1 Problem

```java
List<Student> students =
repository.findAll();

for(Student s : students){

    s.getCourses();

}
```

Count the SQL queries in the log.

---

# 📈 Complete Lazy Loading Flow

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
Student Entity
     │
     ▼
Hibernate Proxy
     │
     ▼
student.getCourses()
     │
     ▼
Lazy SQL Generation
     │
     ▼
JDBC Driver
     │
     ▼
PostgreSQL
```

This is the complete lifecycle of lazy loading in Hibernate.

---

# 📊 Fetch Strategy Comparison

| Feature                               | 🐢 LAZY  | ⚡ EAGER                       |
| ------------------------------------- | -------- | ----------------------------- |
| Data loaded immediately               | ❌ No     | ✅ Yes                         |
| Uses proxy objects                    | ✅ Yes    | ❌ No                          |
| Initial SQL volume                    | Lower    | Higher                        |
| Memory consumption                    | Lower    | Higher                        |
| Risk of `LazyInitializationException` | ✅ Yes    | ❌ No                          |
| Risk of N+1 queries                   | ✅ Higher | ⚠️ Possible in some scenarios |
| Best for large collections            | ✅ Yes    | ❌ Usually no                  |
| Good default for `@OneToMany`         | ✅ Yes    | ❌ No                          |

---

# 💡 Key Takeaways

✅ Fetching determines **when related entities are loaded** from the database.

✅ `FetchType.LAZY` delays loading until the related data is accessed, usually using a Hibernate proxy.

✅ `FetchType.EAGER` loads related entities immediately, increasing initial query cost and memory usage.

✅ Lazy loading improves performance in many scenarios but requires an active Persistence Context.

✅ Accessing a lazy relationship after the Persistence Context is closed results in a `LazyInitializationException`.

✅ Poorly designed lazy loading can lead to the **N+1 Query Problem**, generating excessive SQL queries.

✅ Choose fetch strategies based on application access patterns, and prefer DTOs or `JOIN FETCH` for REST APIs instead of exposing entities directly.

---

# ➡️ Next Chapter

📘 **`07-Hibernate/07-Entity-Relationships.md`**

In the next chapter, we'll learn how Hibernate maps relationships between entities.

We'll cover:

* 👤 `@OneToOne`
* 👥 `@OneToMany`
* 🔗 `@ManyToOne`
* 🌐 `@ManyToMany`
* 🔑 Foreign Keys
* 🔄 Cascade Operations
* 🧹 Orphan Removal
* 📊 Join Tables

By the end of the next chapter, you'll understand how complex object graphs are mapped to relational database tables while maintaining data integrity and performance.
