# 📘 Chapter 41 — Spring MVC DispatcherServlet

> 📂 File: `student-results-api-notes/05-Tomcat/07-DispatcherServlet.md`

Everything before this chapter has been about getting the HTTP request into the JVM.

This chapter answers the question:

How does Spring Boot know which Controller method to execute?

The answer is the DispatcherServlet, the Front Controller of Spring MVC.

This chapter should connect:

Tomcat Worker Thread
HttpServletRequest
Servlet API
DispatcherServlet
HandlerMapping
HandlerAdapter
Controller
Service
Repository
Jackson
HttpServletResponse

into one complete request-processing pipeline.

---

# 🌍 Introduction

In the previous chapter, we learned how the **Tomcat Worker Thread**:

* Reads bytes from the socket
* Parses the HTTP request
* Creates `HttpServletRequest`
* Creates `HttpServletResponse`

At this point Tomcat has converted raw TCP packets into Java objects.

```text
Browser
    │
    ▼
Linux TCP Stack
    │
    ▼
Tomcat Worker Thread
    │
    ▼
HttpServletRequest
HttpServletResponse
```

Now another important question appears:

> 🤔 **How does Spring Boot know which Controller should execute?**

Suppose the browser sends:

```http
GET /students/1051110244
```

How does Spring know it should call:

```java
StudentController#getStudent()
```

The answer is:

# 🚀 DispatcherServlet

The DispatcherServlet is the **Front Controller** of Spring MVC.

Every HTTP request passes through it before reaching your application code.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🚀 What DispatcherServlet is
* 🎯 Front Controller Pattern
* 🗺️ HandlerMapping
* 🔧 HandlerAdapter
* 🎮 Controller invocation
* 📦 ModelAndView
* 📄 REST Controllers
* 🔄 Request lifecycle
* 🍃 Spring Boot auto-configuration
* 🐳 Docker
* ☸️ Kubernetes
* 🧪 Debugging DispatcherServlet

---

# ❓ What Is DispatcherServlet?

DispatcherServlet is the **central request dispatcher** of Spring MVC.

Instead of Tomcat calling your controllers directly:

```text
Tomcat

↓

Controller
```

Tomcat always calls:

```text
Tomcat

↓

DispatcherServlet

↓

Controller
```

Every request flows through the DispatcherServlet first.

---

# 🏗️ Complete Spring MVC Architecture

```text
                    Browser
                        │
                        ▼
                 HTTP Request
                        │
                        ▼
               Tomcat Worker Thread
                        │
                        ▼
              HttpServletRequest
                        │
                        ▼
+------------------------------------------------+
|             DispatcherServlet                  |
|------------------------------------------------|
| HandlerMapping                                 |
| HandlerAdapter                                 |
| Controller                                     |
| ViewResolver (MVC Apps)                        |
| HttpMessageConverter (REST APIs)               |
+------------------------------------------------+
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

DispatcherServlet coordinates the entire request lifecycle.

---

# 🎯 Front Controller Pattern

Instead of every URL having its own servlet:

```text
/students

↓

StudentServlet

--------------------

/teachers

↓

TeacherServlet

--------------------

/courses

↓

CourseServlet
```

Spring Boot uses:

```text
All URLs

↓

DispatcherServlet

↓

Correct Controller
```

This is called the **Front Controller Pattern**.

---

# 🌱 Spring Boot Startup

When you execute:

```bash
java -jar student-results-api.jar
```

Spring Boot automatically registers:

```text
DispatcherServlet
```

Mapping:

```text
/

↓

DispatcherServlet
```

Meaning:

Every incoming HTTP request reaches DispatcherServlet first.

---

# 📥 Request Example

Browser sends:

```http
GET /students/1051110244
```

Tomcat creates:

```java
HttpServletRequest

HttpServletResponse
```

Tomcat then calls:

```java
dispatcherServlet.service(request, response);
```

From this point onward Spring MVC takes control.

---

# 🗺️ HandlerMapping

DispatcherServlet asks:

> "Which controller handles this URL?"

Example:

```text
/students/{id}

↓

StudentController
```

Internally:

```text
DispatcherServlet

↓

HandlerMapping

↓

Controller Method
```

---

# 🎮 Example Controller

```java
@RestController
@RequestMapping("/students")
public class StudentController {

    @GetMapping("/{id}")
    public StudentResponse getStudent(
            @PathVariable Long id) {

        return service.getStudent(id);

    }
}
```

HandlerMapping matches:

```text
/students/1051110244

↓

getStudent()
```

---

# 🔧 HandlerAdapter

Different handler types require different invocation mechanisms.

DispatcherServlet delegates execution to a **HandlerAdapter**.

```text
DispatcherServlet

↓

HandlerAdapter

↓

StudentController#getStudent()
```

The adapter:

* Resolves method parameters
* Injects `@PathVariable`
* Injects `@RequestParam`
* Injects `HttpServletRequest`
* Invokes the controller method

---

# 📦 Controller Execution

Flow:

```text
DispatcherServlet

↓

StudentController

↓

StudentService

↓

StudentRepository

↓

PostgreSQL
```

Everything executes on the **same Tomcat Worker Thread**.

---

# 📄 Returning the Response

Suppose the controller returns:

```java
StudentResponse
```

DispatcherServlet receives:

```text
StudentResponse
```

For REST APIs:

```text
StudentResponse

↓

HttpMessageConverter

↓

Jackson

↓

JSON
```

No JSP or HTML rendering occurs.

---

# 📤 HttpServletResponse

Jackson generates:

```json
{
  "id":1051110244,
  "name":"Alice",
  "marks":95
}
```

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

---

# 🔄 Complete Request Lifecycle

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
DispatcherServlet
      │
      ▼
HandlerMapping
      │
      ▼
HandlerAdapter
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
Jackson
      │
      ▼
HttpServletResponse
      │
      ▼
Tomcat
      │
      ▼
Browser
```

---

# 🧠 DispatcherServlet Internal Flow

Internally the DispatcherServlet performs roughly these steps:

```text
Receive Request
      │
      ▼
Check Multipart Request
      │
      ▼
Find Handler
      │
      ▼
Select HandlerAdapter
      │
      ▼
Run Interceptors (PreHandle)
      │
      ▼
Invoke Controller
      │
      ▼
Run Interceptors (PostHandle)
      │
      ▼
Convert Return Value
      │
      ▼
Write HTTP Response
```

This orchestration is what makes Spring MVC flexible and extensible.

---

# 🍃 Student Results API Example

Incoming request:

```http
GET /students/1051110244
```

Execution:

```text
DispatcherServlet

↓

Find StudentController

↓

Call getStudent()

↓

StudentService

↓

Repository

↓

Student Entity

↓

StudentResponse DTO

↓

Jackson

↓

JSON
```

---

# 🚫 What DispatcherServlet Does NOT Do

DispatcherServlet does **not**:

* Accept TCP connections
* Perform TCP handshakes
* Monitor sockets
* Parse raw HTTP bytes
* Schedule CPU execution

Those responsibilities belong to:

* Linux Kernel
* Tomcat Connector
* Acceptor Thread
* Poller Thread
* Worker Thread

DispatcherServlet focuses purely on **web request routing and processing**.

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

Controller
```

DispatcherServlet behaves identically inside and outside containers.

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

Kubernetes routes traffic to the Pod; DispatcherServlet routes it inside the application.

---

# 🧪 Hands-on Lab

## Enable Spring MVC Debug Logging

```properties
logging.level.org.springframework.web=DEBUG
```

Observe how DispatcherServlet maps incoming requests.

---

## Display Registered Request Mappings

If Spring Boot Actuator is enabled:

```bash
curl http://localhost:8080/actuator/mappings
```

View all registered controller endpoints.

---

## Run Concurrent Requests

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Watch DispatcherServlet repeatedly route requests to the same controller method.

---

## Inspect Thread Dump

```bash
jstack <PID>
```

Look for:

```text
http-nio-8080-exec-*
```

Notice that the DispatcherServlet executes entirely on the Tomcat worker thread.

---

# 📈 Complete DispatcherServlet Flow

```text
Browser
      │
      ▼
TCP Connection
      │
      ▼
Tomcat Worker Thread
      │
      ▼
HttpServletRequest
      │
      ▼
DispatcherServlet
      │
      ▼
HandlerMapping
      │
      ▼
HandlerAdapter
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
Jackson
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

✅ DispatcherServlet is the **Front Controller** of Spring MVC.

✅ Every HTTP request passes through DispatcherServlet before reaching your controllers.

✅ HandlerMapping determines which controller method matches the incoming URL.

✅ HandlerAdapter invokes the controller method and resolves parameters such as `@PathVariable`, `@RequestParam`, and request bodies.

✅ For REST APIs, `HttpMessageConverter` and Jackson serialize Java objects into JSON.

✅ The entire Spring MVC pipeline executes on the same Tomcat worker thread handling the request.

✅ DispatcherServlet separates web infrastructure from business logic, allowing controllers to focus only on application behavior.

---

# ➡️ Next Chapter

📘 **`05-Tomcat/08-HandlerMapping.md`**

In the next chapter, we'll dive deeper into one of DispatcherServlet's most important collaborators:

* 🗺️ How `HandlerMapping` finds the correct controller
* 🔍 URL pattern matching
* 🧩 `@RequestMapping`, `@GetMapping`, `@PostMapping`
* 📍 Path variables vs query parameters
* ⚖️ Request method selection
* 📝 Ambiguous mappings and conflict resolution

By the end of the next chapter, you'll understand exactly how Spring MVC matches an incoming URL to a specific controller method.
