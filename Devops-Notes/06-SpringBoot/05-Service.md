# 📘 Chapter 46 — Spring Boot Service Layer

> 📂 File: `student-results-api-notes/06-SpringBoot/05-Service.md`

This chapter explains the heart of your application's business logic.

After the previous chapter, the reader knows:

Browser
    ↓
Controller

Now the next question is:

Why doesn't the Controller directly call the Repository?

The answer is the Service Layer.

The Service layer contains:

Business rules
Validation
Transactions
Calling multiple repositories
External API integration
DTO ↔ Entity conversion
Application orchestration

It should be the largest and most important layer in most enterprise applications.

---

# 🌍 Introduction

In the previous chapter, we learned that the **Controller** is responsible for handling HTTP requests.

Example:

```http id="7ny8c1"
GET /students/1051110244
```

The Controller receives the request and delegates it to another layer.

```text id="p4b5v2"
Browser
    │
    ▼
Controller
    │
    ▼
Service
```

Now an important question appears:

> 🤔 **Why can't the Controller directly call the Repository?**

Because applications contain **business logic**.

Business logic should not be mixed with:

* HTTP processing
* Database access

Instead, Spring applications place business rules inside the **Service Layer**.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* ⚙️ What a Service is
* 🏷️ @Service annotation
* 🧠 Business Logic
* 🔄 Transactions
* 📦 DTO ↔ Entity conversion
* 🗄️ Calling repositories
* 🌐 Calling external APIs
* 🚫 Common mistakes
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ What Is a Service?

A Service represents the **business logic** of an application.

Think of the Controller as a receptionist.

The Service is the department that actually performs the work.

```text id="s8r6m4"
Browser

↓

Controller

↓

Service

↓

Repository

↓

Database
```

The Service knows **what should happen**.

The Repository only knows **how to read and write data**.

---

# 🏗️ Layered Architecture

```text id="d2q9k5"
Browser
    │
    ▼
DispatcherServlet
    │
    ▼
StudentController
    │
    ▼
+--------------------------------------+
|         StudentService               |
|--------------------------------------|
| ✔ Business Rules                     |
| ✔ Validation                         |
| ✔ Transactions                       |
| ✔ DTO Conversion                     |
| ✔ Call Repository                    |
| ✔ Call External APIs                 |
+--------------------------------------+
    │
    ▼
StudentRepository
    │
    ▼
PostgreSQL
```

The Service acts as the center of the application.

---

# 🏷️ @Service Annotation

A Service is registered as a Spring Bean using:

```java id="g4c9t7"
@Service
public class StudentService {
}
```

Spring automatically:

* Creates the object
* Manages its lifecycle
* Injects it into Controllers

---

# 🍃 Student Results API Example

Controller:

```java id="x9m2e1"
@GetMapping("/{id}")
public StudentResponse getStudent(

        @PathVariable Long id){

    return service.getStudent(id);

}
```

Service:

```java id="n6w4f8"
@Service
public class StudentService {

    public StudentResponse getStudent(Long id){

        Student student =
                repository.findById(id)
                .orElseThrow();

        return mapper.toResponse(student);

    }

}
```

The Controller delegates all work to the Service.

---

# 🧠 Business Logic

Suppose the requirement says:

> Only return results for **active students**.

The Service implements the rule.

```java id="b7q5d2"
if(!student.isActive()){

    throw new StudentInactiveException();

}
```

This logic belongs in the Service—not in the Controller or Repository.

---

# 🔄 Transactions

Many business operations involve multiple database updates.

Example:

```text id="t3p8r6"
Update Student

↓

Update Marks

↓

Insert Audit Record

↓

Send Notification
```

All operations should either:

* ✅ Succeed together
* ❌ Fail together

Spring provides:

```java id="k5v9h1"
@Transactional
public void updateMarks(...) {

}
```

If any step fails, Spring rolls back the transaction automatically.

---

# 📦 DTO ↔ Entity Conversion

The database stores **Entities**.

The API returns **DTOs**.

```text id="r8x1z4"
Database

↓

Student Entity

↓

StudentService

↓

StudentResponse DTO

↓

Controller

↓

JSON
```

The Service is the ideal place for this conversion.

---

# 🗄️ Calling Repositories

A Service can use one or more repositories.

```text id="y2n6b7"
StudentService

├── StudentRepository

├── MarksRepository

├── CourseRepository

└── AuditRepository
```

The Controller does not need to know where the data comes from.

---

# 🌐 Calling External APIs

Business logic often requires data from other systems.

Example:

```text id="m1k8q3"
StudentService

↓

Repository

↓

Payment Service

↓

Notification Service

↓

Email Service
```

The Service coordinates all these operations.

---

# 📈 Complete Request Flow

Suppose the browser sends:

```http id="j6f3u9"
GET /students/1051110244
```

Execution:

```text id="q9w7r2"
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
PostgreSQL
    │
    ▼
Student Entity
    │
    ▼
Validation
    │
    ▼
DTO Conversion
    │
    ▼
Controller
    │
    ▼
JSON Response
```

Everything between the Controller and Repository is coordinated by the Service.

---

# 🧩 Multiple Repository Example

```java id="z4h2n8"
@Service
public class StudentService {

    public StudentProfile getProfile(Long id){

        Student student =
            studentRepository.findById(id);

        Marks marks =
            marksRepository.findByStudentId(id);

        Attendance attendance =
            attendanceRepository.findByStudentId(id);

        return mapper.toProfile(
                student,
                marks,
                attendance);

    }

}
```

The Service aggregates data from multiple sources into a single response.

---

# 🚫 Common Mistakes

## ❌ Business Logic in Controller

```java id="f2p8q1"
@GetMapping("/{id}")

// SQL

// Validation

// Calculations

// External API Call
```

This makes the Controller difficult to maintain and test.

---

## ❌ Business Logic in Repository

Repositories should **not**:

* Calculate grades
* Validate rules
* Call REST APIs
* Send emails

Repositories should only access persistent data.

---

## ✅ Correct Design

```text id="v5m4x9"
Controller

↓

Service

↓

Repository
```

Each layer has one responsibility.

---

# 🧠 Service Lifecycle

Because Services are Spring Beans:

```text id="c7r2n5"
Application Startup

↓

ApplicationContext

↓

Create StudentService Bean

↓

Inject Repository

↓

Ready For Requests
```

A singleton Service instance is typically reused for every request.

---

# 🐳 Docker Perspective

```text id="d9l8q6"
Container

↓

Java Process

↓

Spring Boot

↓

StudentService Bean
```

The Service lives inside the JVM regardless of whether the application runs locally or in Docker.

---

# ☸️ Kubernetes Perspective

```text id="h4t6p8"
Ingress

↓

Service

↓

Pod

↓

Spring Boot

↓

StudentService
```

Each Pod has its own Spring ApplicationContext and its own Service Bean instances.

---

# 🧪 Hands-on Lab

## Call the Service Through the API

```bash id="u7n5b3"
curl http://localhost:8080/students/1051110244
```

Observe how the request flows through:

* Controller
* Service
* Repository

---

## Debug the Service

Set breakpoints in:

```java id="r1v9k2"
StudentService#getStudent()

StudentRepository#findById()
```

Step through the execution to observe:

* Business logic
* Repository calls
* DTO creation

---

## Test Transaction Rollback

Create a method:

```java id="p6m3t4"
@Transactional
public void updateStudent(...)
```

Throw an exception after updating the first table.

Verify that all database changes are rolled back.

---

## Observe Bean Creation

Enable the Beans Actuator endpoint:

```bash id="x8q4f7"
curl http://localhost:8080/actuator/beans
```

Locate the `StudentService` bean in the output.

---

# 📈 Complete Service Flow

```text id="w3j8n1"
Browser
      │
      ▼
Controller
      │
      ▼
StudentService
      │
      ├──────────────┐
      ▼              ▼
StudentRepository  External API
      │              │
      └──────┬───────┘
             ▼
      Business Rules
             ▼
      DTO Conversion
             ▼
Controller
      │
      ▼
JSON Response
```

The Service layer orchestrates the application's business operations.

---

# 💡 Key Takeaways

✅ The Service layer contains the application's business logic and should be the primary place where application behavior is implemented.

✅ `@Service` registers the class as a Spring-managed Bean, allowing it to be injected into Controllers and other components.

✅ Services coordinate repositories, external systems, validation, transactions, and DTO conversions.

✅ Business rules belong in the Service layer—not in Controllers or Repositories.

✅ `@Transactional` ensures that multiple related database operations succeed or fail as a single unit.

✅ A single Service method can orchestrate multiple repositories and external API calls to fulfill a business use case.

✅ Keeping Controllers thin and Services rich results in cleaner, more maintainable, and more testable Spring Boot applications.

---

# ➡️ Next Chapter

📘 **`06-SpringBoot/06-Repository.md`**

In the next chapter, we'll explore the **Repository Layer**, where Spring Data JPA communicates with the database.

We'll cover:

* 🗄️ What a Repository is
* 🏷️ `@Repository`
* 📚 Spring Data JPA
* 🔍 `JpaRepository`
* 📝 Derived query methods
* 📄 Custom JPQL queries
* ⚡ Native SQL queries
* 🧠 Exception translation

By the end of the next chapter, you'll understand how a simple method like `findById()` becomes a SQL query executed against PostgreSQL.
