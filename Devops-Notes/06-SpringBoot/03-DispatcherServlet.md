# 📘 Chapter 44 — Spring MVC DispatcherServlet (Internal Working)

> 📂 File: `student-results-api-notes/06-SpringBoot/03-DispatcherServlet.md`

This chapter is intentionally different from the earlier Tomcat DispatcherServlet chapter.

In 05-Tomcat/07-DispatcherServlet.md, you learned where the DispatcherServlet fits inside Tomcat.

In this chapter, you'll dive into the internal working of the DispatcherServlet itself—what happens inside Spring MVC after Tomcat hands over the request.

This chapter should explain:

How DispatcherServlet.service() works
HandlerMapping
HandlerExecutionChain
HandlerAdapter
Interceptors
Argument Resolvers
HttpMessageConverters
ExceptionResolvers
Response generation

This is one of the deepest Spring MVC chapters.

---

# 🌍 Introduction

In the Tomcat section, we learned that the **Tomcat Worker Thread** eventually calls:

```java
dispatcherServlet.service(request, response);
```

At that moment:

* ✅ TCP packets have already been received.
* ✅ HTTP has already been parsed.
* ✅ `HttpServletRequest` has already been created.
* ✅ `HttpServletResponse` has already been created.

Now Spring MVC takes complete control.

The next question is:

> 🤔 **How does DispatcherServlet decide which controller to execute and how does it build the final JSON response?**

This chapter answers that question by exploring the **internal architecture** of Spring MVC.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🚀 DispatcherServlet lifecycle
* 🗺️ HandlerMapping
* 🔗 HandlerExecutionChain
* 🔧 HandlerAdapter
* 🛡️ Interceptors
* 📝 ArgumentResolvers
* 🎮 Controller invocation
* 📦 HttpMessageConverters
* ❌ ExceptionResolvers
* 📤 Response generation
* 🐳 Docker
* ☸️ Kubernetes

---

# 🏗️ Complete DispatcherServlet Architecture

```text
                     Browser
                         │
                         ▼
                 Tomcat Worker Thread
                         │
                         ▼
              HttpServletRequest
                         │
                         ▼
+-------------------------------------------------------+
|                DispatcherServlet                      |
|-------------------------------------------------------|
| HandlerMapping                                        |
|        │                                              |
|        ▼                                              |
| HandlerExecutionChain                                 |
|        │                                              |
|        ▼                                              |
| HandlerAdapter                                        |
|        │                                              |
|        ▼                                              |
| ArgumentResolvers                                     |
|        │                                              |
|        ▼                                              |
| Controller                                            |
|        │                                              |
|        ▼                                              |
| HttpMessageConverters                                |
|        │                                              |
|        ▼                                              |
| HttpServletResponse                                  |
+-------------------------------------------------------+
```

DispatcherServlet coordinates every component involved in processing a request.

---

# 🚀 Step 1 — Request Arrives

Tomcat calls:

```java
dispatcherServlet.service(request, response);
```

Flow:

```text
Tomcat

↓

DispatcherServlet

↓

doService()

↓

doDispatch()
```

`doDispatch()` is the heart of Spring MVC.

Almost everything happens inside this method.

---

# 🗺️ Step 2 — HandlerMapping

DispatcherServlet asks:

> "Who can handle this request?"

Incoming request:

```http
GET /students/1051110244
```

HandlerMapping searches:

```text
@RequestMapping

@GetMapping

@PostMapping

@DeleteMapping

@PutMapping
```

Result:

```text
StudentController#getStudent()
```

---

# 🔗 Step 3 — HandlerExecutionChain

Spring doesn't return only the controller.

Instead it creates:

```text
HandlerExecutionChain

↓

Controller

+

Interceptors
```

Example:

```text
HandlerExecutionChain

├── StudentController

├── LoggingInterceptor

├── SecurityInterceptor

└── MetricsInterceptor
```

This allows additional processing before and after controller execution.

---

# 🛡️ Step 4 — Interceptors (PreHandle)

Before the controller executes:

```text
LoggingInterceptor

↓

SecurityInterceptor

↓

Authentication

↓

Authorization
```

Each interceptor may:

* Continue processing
* Modify the request
* Reject the request

---

# 🔧 Step 5 — HandlerAdapter

DispatcherServlet now asks:

> "How do I invoke this controller?"

Different controller styles require different adapters.

The most common is:

```text
RequestMappingHandlerAdapter
```

Responsibilities:

* Invoke controller methods
* Resolve parameters
* Process annotations
* Handle return values

---

# 📝 Step 6 — ArgumentResolvers

Suppose your controller looks like this:

```java
@GetMapping("/{id}")
public StudentResponse getStudent(
        @PathVariable Long id,
        HttpServletRequest request) {
}
```

Spring automatically resolves:

```text
@PathVariable

↓

1051110244

-------------------

HttpServletRequest

↓

Current Request

-------------------

@RequestParam

↓

Query Parameters

-------------------

@RequestBody

↓

JSON Object
```

No manual parsing is required.

---

# 🎮 Step 7 — Controller Execution

Controller executes:

```text
StudentController

↓

StudentService

↓

StudentRepository

↓

PostgreSQL
```

Everything runs on the same Tomcat Worker Thread.

---

# 📄 Step 8 — Return Value

Suppose the controller returns:

```java
StudentResponse
```

DispatcherServlet now asks:

> "How should I send this object back?"

---

# 📦 Step 9 — HttpMessageConverter

Spring chooses:

```text
MappingJackson2HttpMessageConverter
```

Conversion:

```text
StudentResponse

↓

Jackson

↓

JSON

↓

Byte[]
```

The object becomes HTTP response bytes.

---

# 📤 Step 10 — HttpServletResponse

DispatcherServlet writes:

```text
JSON

↓

HttpServletResponse

↓

Tomcat

↓

Socket

↓

Browser
```

The browser receives the JSON response.

---

# ❌ Exception Handling

Suppose:

```java
throw new StudentNotFoundException();
```

DispatcherServlet catches the exception.

Flow:

```text
Controller

↓

Exception

↓

HandlerExceptionResolver

↓

@ResponseStatus

↓

HTTP 404
```

Or:

```text
@ControllerAdvice

↓

GlobalExceptionHandler

↓

Custom JSON Error
```

---

# 🔄 Complete Internal Flow

```text
HTTP Request
      │
      ▼
DispatcherServlet
      │
      ▼
HandlerMapping
      │
      ▼
HandlerExecutionChain
      │
      ▼
Interceptors (PreHandle)
      │
      ▼
HandlerAdapter
      │
      ▼
ArgumentResolvers
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
HttpMessageConverter
      │
      ▼
Interceptors (PostHandle)
      │
      ▼
HttpServletResponse
      │
      ▼
Browser
```

---

# 🍃 Student Results API Example

Request:

```http
GET /students/1051110244
```

Execution:

```text
DispatcherServlet

↓

Find StudentController

↓

Resolve id = 1051110244

↓

Call Service

↓

Query PostgreSQL

↓

Student Entity

↓

StudentResponse DTO

↓

Jackson

↓

JSON

↓

Browser
```

---

# 🐳 Docker Perspective

```text
Container

↓

Java Process

↓

Tomcat

↓

DispatcherServlet

↓

Spring MVC

↓

Controller
```

The internal DispatcherServlet flow is identical inside a Docker container.

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

Spring MVC
```

Kubernetes delivers traffic to the Pod; DispatcherServlet manages the request inside the application.

---

# 🧪 Hands-on Lab

## Enable Spring MVC Debug Logs

```properties
logging.level.org.springframework.web.servlet=DEBUG
```

Observe:

* Handler mapping
* Controller selection
* Message converter selection

---

## View Request Mappings

```bash
curl http://localhost:8080/actuator/mappings
```

Inspect every registered controller.

---

## Set Debug Breakpoints

Debug these methods:

```
DispatcherServlet#doDispatch()

RequestMappingHandlerMapping#getHandler()

RequestMappingHandlerAdapter#handle()

StudentController#getStudent()
```

Step through the request and observe every stage.

---

## Inspect Message Converters

Place a breakpoint inside:

```
MappingJackson2HttpMessageConverter
```

Watch the `StudentResponse` object become JSON.

---

# 📈 Complete DispatcherServlet Internal Pipeline

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
HandlerMapping
      │
      ▼
HandlerExecutionChain
      │
      ▼
Interceptors
      │
      ▼
HandlerAdapter
      │
      ▼
ArgumentResolvers
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
MappingJackson2HttpMessageConverter
      │
      ▼
JSON
      │
      ▼
HttpServletResponse
      │
      ▼
Browser
```

---

# 💡 Key Takeaways

✅ `DispatcherServlet` is the central coordinator of Spring MVC.

✅ The heart of request processing is the `doDispatch()` method.

✅ `HandlerMapping` finds the correct controller, while `HandlerExecutionChain` combines the controller with any configured interceptors.

✅ `HandlerAdapter` invokes the controller and uses `ArgumentResolvers` to populate method parameters such as `@PathVariable`, `@RequestParam`, and `@RequestBody`.

✅ `HttpMessageConverter` (typically `MappingJackson2HttpMessageConverter`) serializes Java objects into JSON for REST APIs.

✅ `HandlerExceptionResolver` converts exceptions into appropriate HTTP error responses.

✅ Every stage—from controller lookup to JSON serialization—runs on the same Tomcat worker thread that accepted the request.

---

# ➡️ Next Chapter

📘 **`06-SpringBoot/04-ApplicationContext.md`**

In the next chapter, we'll leave the HTTP request lifecycle and explore the **Spring IoC Container**.

You'll learn:

* 🧠 What `ApplicationContext` is
* 📦 How Beans are created and managed
* 🔍 Component scanning
* 💉 Dependency Injection
* 🔄 Bean lifecycle
* 🏗️ Singleton and Prototype scopes
* ⚙️ How Spring Boot prepares the application before the first request ever reaches `DispatcherServlet`

By the end of the next chapter, you'll understand how Spring creates and wires every object that `DispatcherServlet` depends on.
