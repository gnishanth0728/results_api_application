# 📘 Chapter 48 — Data Transfer Objects (DTO)

> 📂 File: `student-results-api-notes/06-SpringBoot/07-DTO.md`

---

# 🌍 Introduction

In the previous chapter, we learned how the **Repository Layer** retrieves entities from the database.

Example:

```java id="kg7m2a"
Student student =
        repository.findById(id)
                .orElseThrow();
```

Now another important question appears:

> 🤔 **Why don't we simply return the `Student` entity directly to the browser?**

Example:

```java id="k5n9r4"
@GetMapping("/{id}")
public Student getStudent(Long id){

    return repository.findById(id);

}
```

Technically, this works.

But in real-world enterprise applications, it is considered a poor practice.

Instead, Spring applications usually return a **DTO (Data Transfer Object)**.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📦 What a DTO is
* 🏛️ Entity vs DTO
* 📥 Request DTO
* 📤 Response DTO
* 🔐 Security benefits
* ⚡ Performance benefits
* 🧩 DTO mapping
* 🛠️ MapStruct
* 🚫 Common mistakes
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ What Is a DTO?

DTO stands for:

# 📦 Data Transfer Object

A DTO is a Java object whose only purpose is to transfer data between systems.

Examples:

```text id="h3k7m8"
Browser

↓

JSON

↓

StudentRequest DTO

↓

Service

↓

Entity

↓

Database
```

And on the way back:

```text id="f8q2n1"
Database

↓

Entity

↓

StudentResponse DTO

↓

JSON

↓

Browser
```

A DTO is **not** a database object.

It is an API object.

---

# 🏗️ Entity vs DTO

```text id="r2w6k5"
Database

↓

Entity

↓

Service

↓

DTO

↓

JSON

↓

Browser
```

Think of them as two different representations of the same information.

---

# 🏛️ Entity

An Entity represents a database table.

Example:

```java id="z9m4x2"
@Entity
public class Student {

    Long id;

    String name;

    String password;

    String internalRemarks;

    int marks;

}
```

The Entity contains everything stored in the database.

Some fields may be sensitive.

---

# 📤 Response DTO

Example:

```java id="d5r8v1"
public class StudentResponse {

    Long id;

    String name;

    int marks;

}
```

Notice:

Missing fields:

* password
* internalRemarks

The API exposes only what clients need.

---

# 📥 Request DTO

When creating a student:

Incoming JSON:

```json id="b7j1n3"
{
  "name":"Alice",
  "marks":95
}
```

Spring converts it into:

```java id="v2x6q8"
public class StudentRequest {

    String name;

    int marks;

}
```

The Controller receives the Request DTO instead of raw JSON.

---

# 🤔 Why Not Return Entities?

Suppose your entity contains:

```java id="m4k9p7"
password

salary

ssn

internalRemarks
```

Returning the entity directly would expose sensitive information.

DTOs provide a security boundary.

---

# 🔐 Security Benefits

Example Entity:

```java id="p8t5r6"
Student

id

name

password

salary

internalRemarks
```

Response DTO:

```java id="q1f7m4"
StudentResponse

id

name

marks
```

Sensitive data never leaves the server.

---

# ⚡ Performance Benefits

Suppose the Entity contains:

```text id="w9n3b5"
40 Fields
```

But the UI needs only:

```text id="u6d8r2"
3 Fields
```

Using a DTO:

```text id="gx4p1y"
Less JSON

↓

Less Bandwidth

↓

Faster API
```

DTOs reduce payload size and improve performance.

---

# 🧩 DTO Mapping

The Service converts:

```text id="k3v9h7"
Entity

↓

DTO
```

Example:

```java id="y8t2n6"
StudentResponse response =
new StudentResponse();

response.setId(student.getId());

response.setName(student.getName());

response.setMarks(student.getMarks());
```

This is called **mapping**.

---

# 🛠️ MapStruct

Manual mapping becomes repetitive.

Example:

```text id="c7m5p8"
Student

↓

StudentResponse
```

Libraries like **MapStruct** generate mapping code automatically.

Example:

```java id="n4q1r9"
@Mapper
public interface StudentMapper {

    StudentResponse
    toResponse(Student student);

}
```

Spring injects the generated mapper just like any other Bean.

---

# 📈 Complete Request Flow

```http id="a6k8v2"
POST /students
```

Execution:

```text id="l9f4w7"
Browser

↓

JSON

↓

StudentRequest DTO

↓

Controller

↓

Service

↓

Student Entity

↓

Repository

↓

Database
```

---

# 📉 Complete Response Flow

```text id="d8q6m1"
Database

↓

Student Entity

↓

Service

↓

StudentResponse DTO

↓

Jackson

↓

JSON

↓

Browser
```

DTOs define the contract between your API and its clients.

---

# 🍃 Student Results API Example

Entity:

```java id="s5x9k4"
@Entity
public class Student {

    Long id;

    String name;

    String password;

    String internalRemarks;

    int marks;

}
```

Response DTO:

```java id="f2v7n6"
public class StudentResponse {

    Long id;

    String name;

    int marks;

}
```

Controller:

```java id="m8r3t1"
@GetMapping("/{id}")
public StudentResponse getStudent(
        @PathVariable Long id){

    return service.getStudent(id);

}
```

The browser never sees the Entity.

---

# 🚫 Common Mistakes

## ❌ Returning Entities

```java id="g6w2p8"
return student;
```

Problems:

* Security risks
* Tight coupling
* API changes when database changes
* Exposes internal implementation

---

## ❌ Database Logic in DTO

DTOs should contain:

* Fields
* Getters
* Setters
* Validation annotations

They should **not**:

* Execute SQL
* Call Services
* Contain business logic

---

## ✅ Correct Design

```text id="h7k4n2"
Entity

↓

Service

↓

DTO

↓

Controller

↓

JSON
```

---

# 🧠 DTO Lifecycle

Request:

```text id="v4m6r9"
JSON

↓

Jackson

↓

Request DTO

↓

Controller

↓

Service
```

Response:

```text id="p3x8f1"
Entity

↓

DTO

↓

Jackson

↓

JSON
```

DTOs are short-lived objects created for each request.

---

# 🐳 Docker Perspective

```text id="t5q9b3"
Container

↓

Spring Boot

↓

DTO

↓

JSON
```

DTOs exist only inside the JVM during request processing.

---

# ☸️ Kubernetes Perspective

```text id="y2n7m5"
Client

↓

Ingress

↓

Service

↓

Pod

↓

Spring Boot

↓

DTO
```

Every Pod independently creates DTO instances while processing requests.

---

# 🧪 Hands-on Lab

## Create a Request DTO

```java id="u8r1k6"
public class StudentRequest {

    String name;

    int marks;

}
```

Use it in a `POST /students` endpoint.

---

## Create a Response DTO

```java id="b9p4v7"
public class StudentResponse {

    Long id;

    String name;

    int marks;

}
```

Return it from the Controller instead of the Entity.

---

## Test the API

```bash id="c6x2m8"
curl http://localhost:8080/students/1051110244
```

Verify that only the DTO fields appear in the JSON response.

---

## Add Validation

```java id="r5n8q1"
@NotBlank
private String name;

@Min(0)
@Max(100)
private int marks;
```

Spring automatically validates the incoming Request DTO.

---

## Implement a Mapper

Create a mapper that converts:

```text id="e4w7t9"
Student Entity

↓

StudentResponse DTO
```

Compare manual mapping with MapStruct.

---

# 📈 Complete DTO Flow

```text id="m1k5q8"
Browser
      │
      ▼
JSON Request
      │
      ▼
StudentRequest DTO
      │
      ▼
Controller
      │
      ▼
Service
      │
      ▼
Student Entity
      │
      ▼
Repository
      │
      ▼
Database
      │
      ▼
Student Entity
      │
      ▼
StudentResponse DTO
      │
      ▼
Jackson
      │
      ▼
JSON Response
      │
      ▼
Browser
```

DTOs form the boundary between the outside world and your domain model.

---

# 📊 Entity vs DTO Comparison

| Feature                 | Entity 🏛️       | DTO 📦                                   |
| ----------------------- | ---------------- | ---------------------------------------- |
| Purpose                 | Database mapping | API data transfer                        |
| Annotation              | `@Entity`        | None (or validation annotations)         |
| Lifetime                | Managed by JPA   | Created per request/response             |
| Contains business logic | No               | No                                       |
| Used by Repository      | ✅ Yes            | ❌ No                                     |
| Sent to clients         | ❌ Usually not    | ✅ Yes                                    |
| Can contain validation  | Rarely           | ✅ Commonly (`@NotBlank`, `@Email`, etc.) |
| Sensitive fields        | May contain them | Should exclude them                      |

---

# 💡 Key Takeaways

✅ A DTO (Data Transfer Object) represents the data exchanged between your API and its clients.

✅ Entities represent database tables, while DTOs represent request and response payloads.

✅ Using DTOs improves security by preventing sensitive Entity fields from being exposed.

✅ DTOs improve performance by sending only the fields required by the client.

✅ The Service layer is the best place to convert between Entities and DTOs.

✅ Mapping can be performed manually or automatically using libraries such as MapStruct.

✅ Separating Entities from DTOs creates a clean boundary between your persistence model and your public API contract.

---

# ➡️ Next Chapter

📘 **`06-SpringBoot/08-Dependency-Injection.md`**

In the next chapter, we'll explore one of the most powerful features of the Spring Framework:

* 💉 Dependency Injection (DI)
* 🧠 Inversion of Control (IoC)
* 🏗️ Constructor Injection
* 🏷️ `@Autowired`
* 📦 Bean creation
* 🔄 Bean wiring
* 🔍 Bean resolution process

By the end of the next chapter, you'll understand exactly how Spring automatically creates and connects your `Controller`, `Service`, `Repository`, `Mapper`, and every other Bean in your application.
