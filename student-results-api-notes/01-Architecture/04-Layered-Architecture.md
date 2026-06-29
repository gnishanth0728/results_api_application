# 📘 Chapter 4 — Layered Architecture

> 📂 File: `student-results-api-notes/01-Architecture/04-Layered-Architecture.md`

---

# 🚀 Introduction

When developers first learn Spring Boot, they often create applications where everything is written inside a single class.

For small projects this may work.

However, as applications grow, this approach quickly becomes difficult to maintain.

Imagine placing:

* 🌐 HTTP handling
* 🧠 Business logic
* 🗄️ Database queries
* 📦 JSON creation
* ⚠️ Exception handling

inside one Java class.

Very quickly the code becomes thousands of lines long and almost impossible to understand.

Modern enterprise applications solve this problem using **Layered Architecture**.

Each layer has **one responsibility**.

This design follows one of the most important software engineering principles:

> **Separation of Concerns (SoC)**

Each component focuses on one job and delegates the remaining work to another layer.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🏗️ Why applications are divided into layers
* 🎯 Controller responsibilities
* 🧠 Service responsibilities
* 🗄️ Repository responsibilities
* 📦 DTO responsibilities
* 🗃️ Entity responsibilities
* 💉 Dependency Injection
* 🌱 Spring Bean lifecycle (overview)
* ⚠️ Exception handling
* 📈 Advantages of layered architecture
* 🚫 Common design mistakes

---

# 🏗️ Complete Layered Architecture

```text
                    🌐 Client (React)
                           │
                           ▼
                 🎯 Controller Layer
                           │
                           ▼
                  🧠 Service Layer
                           │
                           ▼
                🗄️ Repository Layer
                           │
                           ▼
                 ⚙️ Hibernate (JPA)
                           │
                           ▼
                  🔗 JDBC Driver
                           │
                           ▼
                  🐘 PostgreSQL
```

Notice that every layer communicates only with the layer directly below it.

This creates a clean and maintainable architecture.

---

# 🎯 Controller Layer

## 📖 Purpose

The Controller is the **entry point** of your application.

It receives HTTP requests from Tomcat and converts them into Java method calls.

Example:

```java
@GetMapping("/students/{rollNumber}")
public StudentResponse getStudentResult(
        @PathVariable Long rollNumber) {

    return studentService.getStudentResult(rollNumber);
}
```

### Responsibilities

* Receive HTTP requests
* Validate request parameters
* Extract path variables
* Call the Service layer
* Return the response

### Should NOT Do

❌ SQL queries

❌ Business calculations

❌ Percentage calculations

❌ Grade calculation

❌ PASS/FAIL logic

Those belong in the Service layer.

---

# 🧠 Service Layer

The Service layer contains the application's business logic.

Think of it as the **brain** of the application.

Example responsibilities:

* Calculate total marks
* Calculate percentage
* Determine grade
* Determine PASS/FAIL
* Validate business rules

Example:

```java
int total = marks.stream()
        .mapToInt(StudentMark::getMarks)
        .sum();

double percentage = total / 6.0;

response.setGrade(getGrade(percentage));
```

### Why not place this inside the Controller?

Because Controllers should remain small and focused on HTTP.

Keeping business rules inside the Service makes them reusable from:

* REST APIs
* Scheduled jobs
* Batch processing
* Message queues
* Unit tests

---

# 🗄️ Repository Layer

The Repository is responsible for data access.

It hides all database details from the rest of the application.

Example:

```java
public interface StudentRepository
        extends JpaRepository<Student, Long> {

}
```

The Service never writes SQL directly.

Instead it asks:

```java
studentRepository.findById(rollNumber);
```

Spring Data JPA and Hibernate generate the SQL automatically.

Responsibilities:

* Query database
* Save data
* Update data
* Delete data

Nothing more.

---

# 🗃️ Entity Layer

Entities represent database tables.

Example:

```java
@Entity
@Table(name = "students")
public class Student {

    @Id
    private Long rollNumber;

    private String firstName;

    private String lastName;

}
```

Each Entity maps directly to a relational table.

| Java Entity | Database Table |
| ----------- | -------------- |
| Student     | students       |
| StudentMark | student_marks  |

Entities should represent persistence data, not API responses.

---

# 📦 DTO Layer

DTO stands for **Data Transfer Object**.

Purpose:

Transfer data between the backend and the frontend.

Example:

```java
public class StudentResponse {

    private Long rollNumber;

    private String firstName;

    private String lastName;

    private double percentage;

    private String grade;

    private String result;

}
```

Why use DTOs?

✅ Hide internal database fields

✅ Customize API responses

✅ Prevent exposing Entity objects

✅ Version APIs safely

---

# 💉 Dependency Injection

Instead of creating objects manually:

```java
StudentService service =
    new StudentService();
```

Spring creates and manages objects automatically.

Example:

```java
private final StudentService studentService;

public StudentController(
        StudentService studentService){

    this.studentService = studentService;
}
```

Benefits:

* Loose coupling
* Easier testing
* Better maintainability
* Centralized object lifecycle

---

# 🌱 Spring Bean Lifecycle (Overview)

When the application starts:

```text
Spring Boot Starts
        │
        ▼
Component Scan
        │
        ▼
Create Beans
        │
        ▼
Inject Dependencies
        │
        ▼
Application Ready
```

Beans include:

* Controller
* Service
* Repository

These objects are created once and reused throughout the application's lifetime.

---

# ⚠️ Exception Handling

Instead of returning raw exceptions:

```text
RuntimeException
```

Create meaningful exceptions.

Example:

```java
throw new StudentNotFoundException(
    "Student not found");
```

Handle them centrally:

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
}
```

Benefits:

* Consistent error responses
* Cleaner Controllers
* Easier maintenance

---

# 🔄 Layer Interaction

The request always flows in one direction.

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

The response flows back in reverse.

```text
Database
   │
   ▲
Repository
   │
   ▲
Service
   │
   ▲
Controller
   │
   ▲
Browser
```

Each layer communicates only with its immediate neighbor.

---

# 🚫 Common Mistakes

### ❌ SQL inside Controller

Bad:

```java
@GetMapping(...)
public Student getStudent() {

    jdbcTemplate.query(...);

}
```

---

### ❌ Business Logic inside Repository

Bad:

```java
if(total>500){
    grade="A";
}
```

Repositories should only access data.

---

### ❌ Returning Entities Directly

Entities often contain internal fields that should never be exposed.

Always prefer DTOs.

---

# 📈 Advantages of Layered Architecture

✅ Easier maintenance

✅ Better testing

✅ Better readability

✅ Clear separation of responsibilities

✅ Reusable business logic

✅ Scalable architecture

✅ Enterprise-ready design

---

# 🧪 Hands-on Lab

Explore your project structure:

```bash
tree src/main/java
```

Find all Controllers:

```bash
find src/main/java -name "*Controller.java"
```

Find all Services:

```bash
find src/main/java -name "*Service.java"
```

Find all Repositories:

```bash
find src/main/java -name "*Repository.java"
```

Run the application and follow the call flow using your IDE debugger:

```
Controller
    ↓
Service
    ↓
Repository
    ↓
Hibernate
    ↓
PostgreSQL
```

---

# 💡 Key Takeaways

✅ Every layer has exactly one responsibility.

✅ Controllers handle HTTP.

✅ Services implement business rules.

✅ Repositories access the database.

✅ Entities represent database tables.

✅ DTOs represent API responses.

✅ Dependency Injection keeps components loosely coupled.

✅ Layered Architecture improves readability, maintainability, and scalability.

---

# ➡️ Next Chapter

📘 **01-Architecture/05-Sequence-Diagram.md**

In the next chapter we'll visualize the complete interaction using UML-style sequence diagrams, thread ownership, activation bars, and timing so you can see exactly how every component collaborates during a single request.
