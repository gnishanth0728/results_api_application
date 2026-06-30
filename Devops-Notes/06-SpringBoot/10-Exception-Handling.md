# 📘 Chapter 51 — Spring Boot Exception Handling

> 📂 File: `student-results-api-notes/06-SpringBoot/10-Exception-Handling.md`

This chapter is one of the most valuable Spring Boot chapters because every production application must handle failures gracefully.

After learning Controllers, Services, Repositories, DTOs, Bean Lifecycle, and Dependency Injection, the next logical question is:

What happens when something goes wrong?

Examples:

Student not found
Invalid request body
Database connection failure
NullPointerException
Validation failure
JSON parsing error

Instead of crashing the application or exposing stack traces, Spring Boot provides a structured Exception Handling mechanism.

This chapter explains the complete exception flow—from the moment an exception is thrown until a clean JSON error response is returned to the client.

---

# 🌍 Introduction

So far we've learned how a request travels through:

```text id="6g4s2q"
Browser
    │
    ▼
Tomcat
    │
    ▼
DispatcherServlet
    │
    ▼
Controller
    │
    ▼
Service
    │
    ▼
Repository
```

Everything works perfectly when no errors occur.

But what if the requested student doesn't exist?

Example:

```http id="k9u2m7"
GET /students/9999999999
```

Repository:

```java id="v4r7a2"
repository.findById(id)
```

Result:

```text id="7x5j3d"
No Student Found
```

Should the application:

* ❌ Crash?
* ❌ Return a Java stack trace?
* ❌ Return `500 Internal Server Error`?

No.

Instead, Spring Boot provides a structured exception handling mechanism that converts Java exceptions into meaningful HTTP responses.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* ❌ What Exceptions are
* 🎯 Checked vs Unchecked Exceptions
* 🏷️ Custom Exceptions
* 🛡️ `@ControllerAdvice`
* 🎯 `@ExceptionHandler`
* 📄 ErrorResponse DTO
* 🌍 Global Exception Handling
* 📥 Validation Errors
* ⚙️ Spring Boot Default Error Handling
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ What Is an Exception?

An Exception represents an unexpected situation during program execution.

Examples:

```text id="f7d9h2"
Student Not Found

↓

Database Connection Lost

↓

NullPointerException

↓

JSON Parsing Error

↓

Validation Failure
```

When an exception occurs, normal program execution stops.

Spring Boot intercepts the exception and decides how to respond.

---

# 🏗️ Exception Flow

```text id="b6k3w1"
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
Exception
    │
    ▼
@ControllerAdvice
    │
    ▼
JSON Error Response
    │
    ▼
Browser
```

This prevents raw stack traces from being sent to clients.

---

# 🏷️ Creating a Custom Exception

Instead of throwing generic exceptions:

```java id="j3f8q9"
throw new RuntimeException();
```

Create a meaningful exception:

```java id="t8w4r1"
public class StudentNotFoundException
        extends RuntimeException {

    public StudentNotFoundException(Long id) {

        super("Student not found : " + id);

    }

}
```

Now your code clearly communicates what went wrong.

---

# ⚙️ Throwing the Exception

Service:

```java id="y5p7n3"
public StudentResponse getStudent(Long id){

    Student student =
        repository.findById(id)
        .orElseThrow(() ->
            new StudentNotFoundException(id));

    return mapper.toResponse(student);

}
```

Instead of returning `null`, the Service throws a domain-specific exception.

---

# 🛡️ Global Exception Handling

Spring Boot provides:

```java id="n2q6v8"
@ControllerAdvice
public class GlobalExceptionHandler {
}
```

This class receives exceptions from **all Controllers**.

It centralizes error handling across the application.

---

# 🎯 @ExceptionHandler

Handle a specific exception:

```java id="u9m3k7"
@ExceptionHandler(StudentNotFoundException.class)
public ResponseEntity<ErrorResponse>
handleStudentNotFound(
        StudentNotFoundException ex){

    ErrorResponse response =
        new ErrorResponse(
            404,
            ex.getMessage());

    return ResponseEntity
            .status(404)
            .body(response);

}
```

Whenever `StudentNotFoundException` is thrown, Spring automatically invokes this method.

---

# 📄 ErrorResponse DTO

Instead of returning plain text:

```text id="c5r2h8"
Student Not Found
```

Return a structured response:

```java id="x7k9m2"
public class ErrorResponse {

    private int status;

    private String message;

    private Instant timestamp;

}
```

JSON:

```json id="p4d6q1"
{
  "status":404,
  "message":"Student not found : 1051110244",
  "timestamp":"2026-06-29T16:00:00Z"
}
```

Clients receive predictable error responses.

---

# 🌍 Complete Exception Flow

```text id="m8w1t5"
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
StudentNotFoundException
      │
      ▼
@ControllerAdvice
      │
      ▼
ErrorResponse DTO
      │
      ▼
JSON
      │
      ▼
HTTP 404
      │
      ▼
Browser
```

---

# 📥 Validation Exceptions

Suppose the request body is:

```json id="r2h7v4"
{
  "name":"",
  "marks":150
}
```

DTO:

```java id="v5m8n6"
public class StudentRequest {

    @NotBlank
    private String name;

    @Max(100)
    private int marks;

}
```

Spring throws:

```text id="d9k3p7"
MethodArgumentNotValidException
```

Handle it globally:

```java id="z6t4q8"
@ExceptionHandler(
MethodArgumentNotValidException.class)
```

Return:

```json id="q8n5r3"
{
  "status":400,
  "message":"Validation Failed"
}
```

---

# ⚙️ Spring Boot Default Error Handling

Without custom handlers:

```text id="h4m2v9"
Exception

↓

BasicErrorController

↓

Default JSON Error
```

Example:

```json id="j7q1w6"
{
  "timestamp":"...",
  "status":500,
  "error":"Internal Server Error",
  "path":"/students/1"
}
```

While useful during development, production APIs typically replace this with custom error responses.

---

# 🍃 Student Results API Example

Request:

```http id="g5v9r2"
GET /students/9999999999
```

Flow:

```text id="n3p6x8"
Controller

↓

Service

↓

StudentNotFoundException

↓

GlobalExceptionHandler

↓

ErrorResponse

↓

HTTP 404
```

The client receives a clear, consistent error instead of an unexpected server failure.

---

# 🚫 Common Mistakes

## ❌ Catching Every Exception

```java id="k6w3m9"
try {

}
catch(Exception e){

}
```

This often hides programming errors and makes debugging difficult.

Catch only exceptions you can meaningfully handle.

---

## ❌ Returning Stack Traces

Never expose:

```text id="a8j4f7"
java.lang.NullPointerException
...
```

Stack traces reveal internal implementation details.

Return a clean ErrorResponse instead.

---

## ❌ Returning null

```java id="b7x2p5"
return null;
```

Instead:

```java id="m9r5q3"
throw new StudentNotFoundException(id);
```

Explicit exceptions are easier to understand and maintain.

---

# 🐳 Docker Perspective

```text id="w6h8n1"
Docker Container
        │
        ▼
Spring Boot
        │
        ▼
GlobalExceptionHandler
        │
        ▼
JSON Error
```

Exception handling works the same inside containers.

---

# ☸️ Kubernetes Perspective

```text id="s4t7m2"
Ingress

↓

Service

↓

Pod

↓

Spring Boot

↓

@ControllerAdvice

↓

HTTP Response
```

Each Pod handles exceptions independently while Kubernetes manages infrastructure-level failures.

---

# 🧪 Hands-on Lab

## Create a Custom Exception

```java id="y3n8k6"
public class StudentNotFoundException
        extends RuntimeException {
}
```

Throw it from the Service when a student cannot be found.

---

## Create a Global Exception Handler

```java id="u2q5v9"
@ControllerAdvice
public class GlobalExceptionHandler {
}
```

Add an `@ExceptionHandler` for `StudentNotFoundException`.

---

## Test the API

Run:

```bash id="x9m4r8"
curl http://localhost:8080/students/9999999999
```

Verify that the response is:

```http id="e7w2t6"
HTTP/1.1 404 Not Found
```

with a structured JSON body.

---

## Test Validation

Send:

```json id="t8p3n5"
{
  "name":"",
  "marks":150
}
```

Verify that Spring returns:

```http id="h6q1k9"
HTTP/1.1 400 Bad Request
```

with validation details.

---

## Debug Exception Flow

Set breakpoints in:

* `StudentService#getStudent()`
* `GlobalExceptionHandler#handleStudentNotFound()`

Watch the exception propagate from the Service to the global handler.

---

# 📈 Complete Exception Lifecycle

```text id="p5m8v4"
Browser
      │
      ▼
DispatcherServlet
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
Exception Thrown
      │
      ▼
@ControllerAdvice
      │
      ▼
@ExceptionHandler
      │
      ▼
ErrorResponse DTO
      │
      ▼
JSON
      │
      ▼
HTTP Status Code
      │
      ▼
Browser
```

This is the complete exception-handling pipeline in a Spring Boot REST application.

---

# 📊 Common HTTP Error Codes

| HTTP Status                  | Meaning                   | Typical Cause                  |
| ---------------------------- | ------------------------- | ------------------------------ |
| ✅ 200 OK                     | Request successful        | Resource found                 |
| 🆕 201 Created               | Resource created          | Successful `POST`              |
| ❌ 400 Bad Request            | Invalid input             | Validation failure             |
| 🚫 401 Unauthorized          | Authentication required   | Missing or invalid credentials |
| ⛔ 403 Forbidden              | Access denied             | User lacks permission          |
| 🔍 404 Not Found             | Resource not found        | Student does not exist         |
| ⚠️ 409 Conflict              | State conflict            | Duplicate data                 |
| 💥 500 Internal Server Error | Unexpected server failure | Unhandled exception            |

---

# 💡 Key Takeaways

✅ Exceptions represent unexpected situations that interrupt normal program execution.

✅ Business-specific failures should use custom exceptions such as `StudentNotFoundException` instead of generic `RuntimeException`.

✅ `@ControllerAdvice` centralizes exception handling for the entire application.

✅ `@ExceptionHandler` methods convert Java exceptions into meaningful HTTP responses.

✅ Returning a structured `ErrorResponse` DTO provides clients with consistent and predictable error information.

✅ Validation failures, JSON parsing errors, and application exceptions can all be handled through the same global mechanism.

✅ Proper exception handling improves API usability, security, maintainability, and observability by preventing internal implementation details from leaking to clients.

---

# ➡️ Next Chapter

📘 **`06-SpringBoot/11-Validation.md`**

In the next chapter, we'll learn how Spring Boot validates incoming requests **before they reach your business logic**.

We'll cover:

* ✅ Bean Validation (Jakarta Validation)
* 🏷️ `@Valid`
* ✍️ `@NotNull`, `@NotBlank`, `@Size`, `@Email`, `@Min`, `@Max`
* 📄 Validation groups
* 🛡️ Custom validators
* 🔄 Validation flow through `DispatcherServlet`
* 📥 How validation integrates with global exception handling

By the end of the next chapter, you'll understand how Spring Boot automatically rejects invalid requests before your Controller or Service performs any business processing.
