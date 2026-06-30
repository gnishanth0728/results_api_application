# 📘 Chapter 47 — Spring Boot Repository Layer

> 📂 File: `student-results-api-notes/06-SpringBoot/06-Repository.md`

This chapter is one of the most important in the Spring Boot section because it explains how Java code becomes SQL.

After the previous chapter, the reader knows:

Controller
    ↓
Service

Now we answer:

How does repository.findById() become a PostgreSQL query?

This chapter explains:

@Repository
Spring Data JPA
JpaRepository
Hibernate integration
EntityManager
Query generation
SQL execution
Result mapping
Exception translation

This chapter bridges Spring Boot and the Database module

---

# 🌍 Introduction

In the previous chapter, we learned that the **Service Layer** contains the application's business logic.

Eventually, the Service needs to read or write data.

Example:

```java
Student student =
        repository.findById(id)
                .orElseThrow();
```

This raises an important question:

> 🤔 **How does a Java method like `findById()` become a SQL query executed in PostgreSQL?**

The answer is the **Repository Layer**.

Repositories hide the complexity of database access and provide a simple Java interface for working with persistent data.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🗄️ What a Repository is
* 🏷️ `@Repository`
* 🌱 Spring Data JPA
* 📚 `JpaRepository`
* 🧠 EntityManager
* ⚙️ Hibernate Integration
* 🔍 Derived Query Methods
* 📄 JPQL Queries
* 💾 Native SQL Queries
* ❌ Exception Translation
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ What Is a Repository?

A Repository is the **data access layer** of your application.

It is responsible for communicating with the database.

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
Database
```

Repositories should only perform:

* Database queries
* Insert
* Update
* Delete
* Entity retrieval

Repositories should **not** contain business logic.

---

# 🏗️ Repository in Spring Boot

```text
Browser
    │
    ▼
Controller
    │
    ▼
StudentService
    │
    ▼
+-----------------------------------------+
|         StudentRepository               |
|-----------------------------------------|
| findById()                              |
| save()                                  |
| deleteById()                            |
| findAll()                               |
| existsById()                            |
+-----------------------------------------+
    │
    ▼
Hibernate
    │
    ▼
PostgreSQL
```

The Repository acts as the bridge between Java objects and database records.

---

# 🏷️ @Repository

Repositories are Spring Beans.

Example:

```java
@Repository
public interface StudentRepository
        extends JpaRepository<Student, Long> {
}
```

Spring automatically:

* Creates the implementation
* Registers it as a Bean
* Injects it into Services

Notice that **you never implement this interface yourself**.

---

# 🌱 Spring Data JPA

Spring Data JPA eliminates boilerplate database code.

Without Spring Data:

```java
Connection connection

PreparedStatement statement

ResultSet result

while(result.next()){
}
```

With Spring Data:

```java
repository.findById(id);
```

Spring generates the implementation automatically.

---

# 📚 JpaRepository

`JpaRepository` provides dozens of ready-made operations.

```java
public interface StudentRepository
extends JpaRepository<Student, Long> {
}
```

Common methods:

```text
save()

findById()

findAll()

delete()

deleteById()

existsById()

count()

flush()
```

Most CRUD applications require no additional implementation.

---

# 🧠 What Happens Inside findById()?

Suppose your Service executes:

```java
repository.findById(1051110244L);
```

Internal flow:

```text
StudentService
        │
        ▼
StudentRepository
        │
        ▼
JpaRepository Proxy
        │
        ▼
EntityManager
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
PostgreSQL
```

Several frameworks work together before the database receives SQL.

---

# ⚙️ Hibernate Integration

Hibernate is the JPA implementation used by Spring Boot.

Responsibilities:

* Generate SQL
* Map Java objects to tables
* Cache entities
* Manage persistence context
* Track object changes

Example SQL:

```sql
SELECT *
FROM student
WHERE id = ?
```

You never write this SQL when using `findById()`.

---

# 🧩 EntityManager

The Repository internally delegates to the **EntityManager**.

Conceptually:

```text
Repository

↓

EntityManager

↓

Hibernate

↓

Database
```

The EntityManager manages:

* Entity lifecycle
* Persistence context
* SQL execution
* Transactions

---

# 🔍 Derived Query Methods

Spring can generate queries from method names.

Example:

```java
findByName(String name)

findByMarksGreaterThan(int marks)

findByDepartment(String department)
```

Spring automatically creates SQL similar to:

```sql
SELECT *
FROM student
WHERE name = ?
```

No SQL needs to be written manually.

---

# 📄 JPQL Queries

Sometimes derived queries are not enough.

Example:

```java
@Query("""
SELECT s
FROM Student s
WHERE s.marks > :marks
""")
List<Student> findTopStudents(int marks);
```

JPQL operates on **Entities**, not database tables.

---

# 💾 Native SQL Queries

For complex database-specific queries:

```java
@Query(value="""
SELECT *
FROM student
WHERE marks > ?
""",
nativeQuery=true)
List<Student> findTopStudents(int marks);
```

Native queries execute directly against PostgreSQL.

---

# 📈 Complete Request Flow

Suppose:

```http
GET /students/1051110244
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
    ▼
StudentRepository
    │
    ▼
EntityManager
    │
    ▼
Hibernate
    │
    ▼
JDBC
    │
    ▼
PostgreSQL
    │
    ▼
Student Entity
    │
    ▼
StudentService
    │
    ▼
DTO
    │
    ▼
JSON
```

The Repository isolates all database access.

---

# ❌ Exception Translation

Suppose PostgreSQL throws:

```text
SQLException
```

Spring automatically converts it into:

```text
DataAccessException
```

Benefits:

* Database-independent exceptions
* Cleaner business code
* Easier testing

The Service layer usually catches Spring exceptions—not JDBC exceptions.

---

# 🍃 Student Results API Example

Repository:

```java
@Repository
public interface StudentRepository
extends JpaRepository<Student, Long> {

    Optional<Student> findByRollNumber(String rollNumber);

    List<Student> findByMarksGreaterThan(int marks);

}
```

Service:

```java
Student student =
repository.findByRollNumber(rollNumber)
          .orElseThrow();
```

No SQL is required.

Spring generates everything automatically.

---

# 🚫 Common Mistakes

## ❌ Business Logic in Repository

```java
@Repository

// Grade calculation

// Email sending

// Validation
```

Repositories should not perform business operations.

---

## ❌ HTTP Logic in Repository

Repositories should never know about:

* HTTP Requests
* Controllers
* JSON
* DTOs

Their only responsibility is persistent data access.

---

## ✅ Correct Architecture

```text
Controller

↓

Service

↓

Repository

↓

Database
```

Each layer has one clearly defined responsibility.

---

# 🐳 Docker Perspective

```text
Container

↓

Spring Boot

↓

Repository

↓

Hibernate

↓

PostgreSQL Container
```

The Repository communicates with the database through JDBC regardless of whether the database is running locally or in another container.

---

# ☸️ Kubernetes Perspective

```text
Pod

↓

Spring Boot

↓

Repository

↓

Database Service

↓

PostgreSQL Pod
```

Repositories are unaware of Kubernetes networking—they simply use the configured datasource.

---

# 🧪 Hands-on Lab

## Retrieve a Student

```java
repository.findById(1L);
```

Enable Hibernate SQL logging:

```properties
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
```

Observe the generated SQL.

---

## Test a Derived Query

```java
repository.findByMarksGreaterThan(90);
```

Verify that Spring automatically generates the appropriate SQL.

---

## Create a JPQL Query

```java
@Query("""
SELECT s
FROM Student s
WHERE s.department = :department
""")
```

Run the method and inspect the generated SQL.

---

## Execute a Native Query

```java
@Query(
value="SELECT * FROM student",
nativeQuery=true)
```

Compare the result with the JPQL version.

---

## Observe Repository Bean

```bash
curl http://localhost:8080/actuator/beans
```

Locate the generated `StudentRepository` bean.

---

# 📈 Complete Repository Flow

```text
Browser
      │
      ▼
Controller
      │
      ▼
StudentService
      │
      ▼
StudentRepository
      │
      ▼
JpaRepository Proxy
      │
      ▼
EntityManager
      │
      ▼
Hibernate
      │
      ▼
SQL Generation
      │
      ▼
JDBC Driver
      │
      ▼
PostgreSQL
      │
      ▼
Student Entity
      │
      ▼
Service
      │
      ▼
DTO
      │
      ▼
JSON Response
```

This is the complete data access pipeline in your Student Results API.

---

# 💡 Key Takeaways

✅ The Repository layer is responsible only for database access.

✅ `@Repository` registers the repository as a Spring Bean and enables automatic exception translation.

✅ Spring Data JPA generates implementations automatically from interfaces that extend `JpaRepository`.

✅ `JpaRepository` provides built-in CRUD methods such as `findById()`, `save()`, `findAll()`, and `deleteById()`.

✅ Internally, repositories delegate to the `EntityManager`, which uses Hibernate to generate SQL and interact with the database through JDBC.

✅ Derived query methods, JPQL, and native SQL queries provide increasing levels of flexibility for database access.

✅ Repositories should remain focused on persistence while business logic stays in the Service layer.

---

# ➡️ Next Chapter

📘 **`06-SpringBoot/07-Dependency-Injection.md`**

In the next chapter, we'll explore one of Spring's most powerful features:

* 💉 What Dependency Injection (DI) is
* 🧠 Inversion of Control (IoC)
* 🏗️ Constructor Injection
* 🏷️ `@Autowired`
* 🔄 Bean wiring
* 🔍 Bean resolution
* ⚙️ How Spring creates and injects dependencies automatically

By the end of the next chapter, you'll understand why you never write `new StudentService()` or `new StudentRepository()` in a well-designed Spring Boot application.
