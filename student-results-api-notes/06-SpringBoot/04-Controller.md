# 📘 Chapter 45 — Spring Boot Controller Layer

> 📂 File: `student-results-api-notes/06-SpringBoot/04-Controller.md`

---

# 🌍 Introduction

In the previous chapter, we learned how **DispatcherServlet** receives every HTTP request and decides which controller method should execute.

The next question is:

> 🤔 **What exactly is a Controller?**

Suppose the browser sends:

```http
GET /students/1051110244 HTTP/1.1
Host: localhost:8080
```

Eventually Spring executes:

```java
StudentController#getStudent()
```

Why?

Because the Controller is the **entry point** into your application's business logic.

It receives HTTP requests, validates input, delegates work to the Service layer, and returns the HTTP response.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🎮 What a Controller is
* 🌐 @RestController vs @Controller
* 🗺️ @RequestMapping
* 📥 @GetMapping
* 📤 @PostMapping
* ✏️ @PutMapping
* 🗑️ @DeleteMapping
* 📍 @PathVariable
* 🔍 @RequestParam
* 📦 @RequestBody
* 📄 ResponseEntity
* 🚫 Common mistakes
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ What Is a Controller?

A Controller is the **HTTP interface** of your application.

Think of it as the receptionist of a company.

```text
Client

↓

Controller

↓

Service

↓

Repository

↓

Database
```

Responsibilities:

* Receive HTTP requests
* Read request data
* Validate input
* Call business logic
* Return HTTP responses

A Controller should **not** contain business logic.

---

# 🏗️ Controller in Spring MVC

```text
Browser
    │
    ▼
DispatcherServlet
    │
    ▼
StudentController
    │
    ▼
StudentService
    │
    ▼
StudentRepository
    │
    ▼
PostgreSQL
```

The Controller acts as a bridge between HTTP and your application.

---

# 🌐 @RestController vs @Controller

## 🎮 @RestController

Used for REST APIs.

```java
@RestController
@RequestMapping("/students")
public class StudentController {
}
```

Automatically returns:

* JSON
* XML (if configured)
* Other serialized formats

Most Spring Boot APIs use `@RestController`.

---

## 🖥️ @Controller

Used for MVC applications that render views.

```java
@Controller
public class HomeController {

    @GetMapping("/")
    public String home() {

        return "index";

    }

}
```

Returns:

```text
index.html

JSP

Thymeleaf

Freemarker
```

For your Student Results API, use `@RestController`.

---

# 🗺️ @RequestMapping

Defines the base URL.

Example:

```java
@RestController
@RequestMapping("/students")
public class StudentController {
}
```

Now every method begins with:

```text
/students
```

---

# 📥 @GetMapping

Handles HTTP GET requests.

```java
@GetMapping("/{id}")
public StudentResponse getStudent(
        @PathVariable Long id){

    return service.getStudent(id);

}
```

Example request:

```http
GET /students/1051110244
```

---

# 📤 @PostMapping

Handles resource creation.

```java
@PostMapping
public StudentResponse createStudent(
        @RequestBody StudentRequest request){

    return service.createStudent(request);

}
```

Example:

```http
POST /students
Content-Type: application/json
```

Body:

```json
{
  "name":"Alice",
  "marks":95
}
```

---

# ✏️ @PutMapping

Updates an existing resource.

```java
@PutMapping("/{id}")
public StudentResponse updateStudent(
        @PathVariable Long id,
        @RequestBody StudentRequest request){

    return service.updateStudent(id, request);

}
```

---

# 🗑️ @DeleteMapping

Deletes a resource.

```java
@DeleteMapping("/{id}")
public void deleteStudent(
        @PathVariable Long id){

    service.deleteStudent(id);

}
```

---

# 📍 @PathVariable

Extracts values from the URL.

Request:

```http
GET /students/1051110244
```

Controller:

```java
@GetMapping("/{id}")
public StudentResponse getStudent(
        @PathVariable Long id){
}
```

Spring automatically sets:

```text
id = 1051110244
```

---

# 🔍 @RequestParam

Reads query parameters.

Request:

```http
GET /students?page=1&size=20
```

Controller:

```java
@GetMapping
public List<StudentResponse> getStudents(

    @RequestParam int page,

    @RequestParam int size){

}
```

Spring automatically binds:

```text
page = 1

size = 20
```

---

# 📦 @RequestBody

Reads JSON from the HTTP body.

Incoming JSON:

```json
{
  "name":"Alice",
  "marks":95
}
```

Controller:

```java
@PostMapping
public StudentResponse createStudent(

    @RequestBody StudentRequest request){

}
```

Jackson automatically converts JSON into a Java object.

---

# 📄 ResponseEntity

Instead of returning only the body:

```java
return student;
```

You can return:

```java
return ResponseEntity
        .status(201)
        .body(student);
```

Benefits:

* Set HTTP status
* Set headers
* Set cookies
* Return custom responses

Example:

```http
HTTP/1.1 201 Created
```

---

# 🍃 Student Results API Example

```java
@RestController
@RequestMapping("/students")
public class StudentController {

    @GetMapping("/{id}")
    public ResponseEntity<StudentResponse>
            getStudent(

            @PathVariable Long id){

        StudentResponse response =
                service.getStudent(id);

        return ResponseEntity.ok(response);

    }

}
```

Flow:

```text
Browser

↓

DispatcherServlet

↓

StudentController

↓

StudentService

↓

Repository

↓

Database
```

---

# 🚫 Common Mistakes

## ❌ Business Logic in Controller

```java
@GetMapping("/{id}")
public StudentResponse getStudent(){

    // SQL

    // Validation

    // Calculations

}
```

Bad because:

* Hard to test
* Hard to reuse
* Violates separation of concerns

---

## ✅ Correct

```text
Controller

↓

Service

↓

Repository
```

Each layer performs one responsibility.

---

# 📊 Complete Controller Lifecycle

```text
Browser
      │
      ▼
DispatcherServlet
      │
      ▼
@PathVariable

@RequestBody

@RequestParam
      │
      ▼
StudentController
      │
      ▼
StudentService
      │
      ▼
StudentRepository
      │
      ▼
Database
      │
      ▼
StudentResponse
      │
      ▼
ResponseEntity
      │
      ▼
JSON
      │
      ▼
Browser
```

---

# 🐳 Docker Perspective

```text
Container

↓

Java Process

↓

Spring Boot

↓

Controller

↓

Service
```

Controllers execute inside the JVM exactly the same way whether running locally or in a container.

---

# ☸️ Kubernetes Perspective

```text
Ingress

↓

Service

↓

Pod

↓

Tomcat

↓

DispatcherServlet

↓

Controller
```

The Controller is unaware of Kubernetes. It simply processes HTTP requests delivered by Spring MVC.

---

# 🧪 Hands-on Lab

## Call a GET Endpoint

```bash
curl http://localhost:8080/students/1051110244
```

Observe the JSON response.

---

## Call a POST Endpoint

```bash
curl -X POST \
-H "Content-Type: application/json" \
-d '{"name":"Alice","marks":95}' \
http://localhost:8080/students
```

Observe the newly created resource.

---

## Debug Controller Execution

Place a breakpoint in:

```java
StudentController#getStudent()
```

Step through:

1. DispatcherServlet
2. Controller
3. Service
4. Repository

Observe how Spring automatically populates `@PathVariable` and `@RequestBody`.

---

## Inspect Request Mappings

```bash
curl http://localhost:8080/actuator/mappings
```

Find all endpoints registered for `StudentController`.

---

# 📈 Complete Controller Flow

```text
Browser
      │
      ▼
Tomcat
      │
      ▼
DispatcherServlet
      │
      ▼
@PathVariable
@RequestParam
@RequestBody
      │
      ▼
StudentController
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
StudentResponse
      │
      ▼
ResponseEntity
      │
      ▼
JSON
      │
      ▼
Browser
```

---

# 💡 Key Takeaways

✅ A Controller is the HTTP entry point of a Spring Boot application.

✅ `@RestController` is used for REST APIs that return JSON, while `@Controller` is used for applications that render views.

✅ Mapping annotations such as `@GetMapping`, `@PostMapping`, `@PutMapping`, and `@DeleteMapping` connect HTTP methods to Java methods.

✅ Spring automatically binds request data using annotations like `@PathVariable`, `@RequestParam`, and `@RequestBody`.

✅ `ResponseEntity` provides full control over HTTP status codes, headers, and response bodies.

✅ Controllers should delegate business logic to the Service layer and remain focused on HTTP request/response handling.

---

# ➡️ Next Chapter

📘 **`06-SpringBoot/05-Service.md`**

In the next chapter, we'll explore the **Service Layer**, where the application's business logic lives.

We'll cover:

* ⚙️ What a Service is
* 🏷️ `@Service`
* 📋 Business rules
* 🔄 Transactions
* 📦 DTO ↔ Entity conversion
* 🧩 Calling multiple repositories
* 💡 Why business logic belongs in the Service layer

By the end of the next chapter, you'll understand why the Service layer is the core of a well-designed Spring Boot application.
