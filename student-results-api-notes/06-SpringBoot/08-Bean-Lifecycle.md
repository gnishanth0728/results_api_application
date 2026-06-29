# 📘 Chapter 49 — Spring Bean Lifecycle

> 📂 File: `student-results-api-notes/06-SpringBoot/08-Bean-Lifecycle.md`

This is one of the most important Spring Boot internals chapters.

After learning about Controllers, Services, Repositories, and DTOs, the next logical question is:

Who creates these objects?

Even more importantly:

When are they created, initialized, injected, used, and destroyed?

The answer is the Spring Bean Lifecycle.

This chapter explains exactly what happens from the moment you execute:

java -jar student-results-api.jar

until the application shuts down

---

# 🌍 Introduction

So far we've learned that Spring automatically creates:

* 🎮 Controllers
* ⚙️ Services
* 🗄️ Repositories
* 🗺️ Mappers
* ⚙️ Configuration Classes
* 📦 Components

Example:

```java
@RestController
public class StudentController {

    private final StudentService service;

}
```

Notice something interesting...

We never write:

```java
new StudentController();

new StudentService();

new StudentRepository();
```

Yet these objects exist.

So another important question appears:

> 🤔 **Who creates these objects?**

And another one:

> 🤔 **When are they created?**

The answer is:

# 🌱 Spring IoC Container

The IoC Container manages every Spring Bean from creation until destruction.

This complete journey is called the **Bean Lifecycle**.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🌱 What a Spring Bean is
* 🧠 IoC Container
* 🔍 Component Scanning
* 🏗️ Bean Creation
* 💉 Dependency Injection
* ⚙️ Bean Initialization
* 🚀 Bean Usage
* 🧹 Bean Destruction
* 🏷️ `@PostConstruct`
* 🗑️ `@PreDestroy`
* 🧩 BeanPostProcessor
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ What Is a Spring Bean?

A **Bean** is any object managed by the Spring IoC Container.

Examples:

```java
@RestController
class StudentController

@Service
class StudentService

@Repository
class StudentRepository

@Component
class StudentMapper
```

Spring creates these objects automatically.

---

# 🏗️ Complete Bean Lifecycle

```text
Application Starts
        │
        ▼
Component Scan
        │
        ▼
Bean Definition Created
        │
        ▼
Bean Instantiated
        │
        ▼
Dependency Injection
        │
        ▼
@PostConstruct
        │
        ▼
BeanPostProcessor
        │
        ▼
Bean Ready
        │
        ▼
Application Running
        │
        ▼
@PreDestroy
        │
        ▼
Bean Destroyed
```

Every singleton bean follows this lifecycle.

---

# 🚀 Step 1 — Application Startup

You start the application:

```bash
java -jar student-results-api.jar
```

Spring Boot executes:

```java
SpringApplication.run(...)
```

Flow:

```text
Main()

↓

SpringApplication.run()

↓

ApplicationContext

↓

Bean Factory
```

The IoC Container is created.

---

# 🔍 Step 2 — Component Scanning

Spring searches your project for classes annotated with:

```text
@Controller

@RestController

@Service

@Repository

@Component

@Configuration
```

Example project:

```text
student-results-api

├── controller

├── service

├── repository

├── mapper

├── config
```

Every annotated class becomes a **Bean Definition**.

---

# 📄 Step 3 — Bean Definition

Spring stores metadata for every Bean.

Example:

```text
Bean Definition

↓

StudentController

Scope = Singleton

Lazy = False

Dependencies

↓

StudentService
```

At this stage, the object has **not** been created yet.

Spring only knows **how** to create it.

---

# 🏗️ Step 4 — Bean Instantiation

Spring creates the object.

Equivalent to:

```java
new StudentService();
```

But Spring performs this automatically.

Flow:

```text
Bean Definition

↓

Constructor

↓

Java Object
```

---

# 💉 Step 5 — Dependency Injection

Suppose:

```java
@Service
public class StudentService {

    private final StudentRepository repository;

}
```

Spring first creates:

```text
StudentRepository
```

Then:

```text
StudentService

↓

Inject Repository
```

Finally:

```text
StudentController

↓

Inject Service
```

Dependency order matters.

---

# 🏷️ Step 6 — @PostConstruct

After dependency injection:

```java
@PostConstruct
public void init(){

    System.out.println("Bean Ready");

}
```

Flow:

```text
Bean Created

↓

Dependencies Injected

↓

@PostConstruct

↓

Ready
```

Typical use cases:

* Initialize caches
* Load configuration
* Open resources
* Validate settings

---

# 🧩 Step 7 — BeanPostProcessor

Spring now allows customization.

```text
Bean

↓

BeanPostProcessor

↓

Proxy

↓

Final Bean
```

This mechanism powers features such as:

* AOP
* Transactions
* Security
* Logging
* Caching

---

# ✅ Step 8 — Bean Ready

Now the Bean is available.

```text
ApplicationContext

↓

StudentController

↓

StudentService

↓

StudentRepository
```

DispatcherServlet can now use these Beans to process requests.

---

# 🚀 Step 9 — Bean Usage

Suppose the browser sends:

```http
GET /students/1051110244
```

Execution:

```text
DispatcherServlet

↓

StudentController Bean

↓

StudentService Bean

↓

StudentRepository Bean
```

The same singleton instances are reused for every request.

---

# 🗑️ Step 10 — @PreDestroy

When the application shuts down:

```java
@PreDestroy
public void cleanup(){

    System.out.println("Closing resources");

}
```

Flow:

```text
Shutdown

↓

@PreDestroy

↓

Bean Destroyed
```

Typical use cases:

* Close files
* Release sockets
* Stop background threads
* Flush buffers

---

# 🍃 Student Results API Example

Startup:

```text
StudentRepository

↓

StudentService

↓

StudentController

↓

DispatcherServlet Ready
```

Request:

```http
GET /students/1051110244
```

Execution:

```text
DispatcherServlet

↓

StudentController

↓

StudentService

↓

StudentRepository
```

Shutdown:

```text
@PreDestroy

↓

Resources Released
```

---

# 📊 Bean Lifecycle Timeline

```text
Application Start
        │
        ▼
Scan Packages
        │
        ▼
Create Bean Definitions
        │
        ▼
Instantiate Beans
        │
        ▼
Inject Dependencies
        │
        ▼
@PostConstruct
        │
        ▼
Bean Ready
        │
        ▼
Serve Requests
        │
        ▼
Shutdown
        │
        ▼
@PreDestroy
```

---

# 🧠 Singleton Bean Reuse

One `StudentService` Bean serves many requests.

```text
Request 1
      │
      ▼
StudentService Bean
      ▲
      │
Request 2
      ▲
      │
Request 3
      ▲
      │
Request 4
```

Spring does **not** create a new Service object for every request.

---

# 🚫 Common Mistakes

## ❌ Creating Beans Manually

```java
StudentService service =
new StudentService();
```

Doing this bypasses Spring.

No dependency injection.

No AOP.

No transactions.

No lifecycle callbacks.

---

## ❌ Heavy Work Inside Constructors

Avoid:

```java
public StudentService(){

    // Database call

    // Network call

}
```

Instead use:

```java
@PostConstruct
```

---

# 🐳 Docker Perspective

```text
Docker Container
        │
        ▼
JVM Starts
        │
        ▼
Spring Boot
        │
        ▼
ApplicationContext
        │
        ▼
Beans Created
```

Every container has its own independent Spring ApplicationContext.

---

# ☸️ Kubernetes Perspective

```text
Pod 1

↓

ApplicationContext

↓

Beans

--------------------

Pod 2

↓

ApplicationContext

↓

Beans
```

Each Pod has its own Bean instances.

Beans are **never shared** across Pods.

---

# 🧪 Hands-on Lab

## Observe Bean Creation

Add:

```java
@PostConstruct
public void init(){

    System.out.println("StudentService Initialized");

}
```

Start the application and observe the console output.

---

## Observe Bean Destruction

Add:

```java
@PreDestroy
public void cleanup(){

    System.out.println("Cleaning Resources");

}
```

Stop the application and observe the shutdown logs.

---

## List All Beans

Enable Actuator:

```properties
management.endpoints.web.exposure.include=beans
```

Run:

```bash
curl http://localhost:8080/actuator/beans
```

Observe hundreds of Spring-managed Beans.

---

## Debug Bean Creation

Set breakpoints in:

* `SpringApplication.run()`
* `AbstractAutowireCapableBeanFactory#createBean()`
* `StudentService`

Step through the startup process to watch the Bean lifecycle.

---

# 📈 Complete Bean Lifecycle

```text
java -jar
      │
      ▼
SpringApplication.run()
      │
      ▼
ApplicationContext
      │
      ▼
Component Scan
      │
      ▼
Bean Definition
      │
      ▼
Bean Instantiation
      │
      ▼
Dependency Injection
      │
      ▼
@PostConstruct
      │
      ▼
BeanPostProcessor
      │
      ▼
Bean Ready
      │
      ▼
DispatcherServlet Uses Bean
      │
      ▼
Application Shutdown
      │
      ▼
@PreDestroy
      │
      ▼
Bean Destroyed
```

This is the complete lifecycle followed by a typical Spring singleton Bean.

---

# 📊 Bean Lifecycle Callback Summary

| Stage                   | Purpose                            | Common Annotation / Component                          |
| ----------------------- | ---------------------------------- | ------------------------------------------------------ |
| 🔍 Scan                 | Discover Spring classes            | `@Component`, `@Service`, `@Repository`, `@Controller` |
| 📄 Bean Definition      | Store metadata                     | BeanDefinition                                         |
| 🏗️ Instantiation       | Create object                      | Constructor                                            |
| 💉 Dependency Injection | Inject dependencies                | Constructor Injection / `@Autowired`                   |
| ⚙️ Initialization       | Perform setup                      | `@PostConstruct`                                       |
| 🧩 Post Processing      | Create proxies, apply AOP          | `BeanPostProcessor`                                    |
| ✅ Ready                 | Bean available for application use | ApplicationContext                                     |
| 🗑️ Destruction         | Cleanup resources                  | `@PreDestroy`                                          |

---

# 💡 Key Takeaways

✅ A Spring Bean is any object managed by the Spring IoC Container.

✅ The Bean lifecycle begins when `SpringApplication.run()` creates the `ApplicationContext`.

✅ Spring scans the classpath, creates Bean definitions, instantiates objects, injects dependencies, and initializes Beans before serving requests.

✅ `@PostConstruct` is used for initialization logic after dependency injection, while `@PreDestroy` is used for cleanup before shutdown.

✅ `BeanPostProcessor` enables powerful framework features such as AOP, transactions, caching, and security by wrapping Beans with proxies.

✅ Singleton Beans are created once and reused across many HTTP requests, making them lightweight and efficient.

✅ Every Docker container or Kubernetes Pod has its own independent Spring `ApplicationContext` and Bean lifecycle.

---

# ➡️ Next Chapter

📘 **`06-SpringBoot/09-Dependency-Injection.md`**

In the next chapter, we'll dive deeper into **Dependency Injection (DI)** and answer one of the most common Spring questions:

> **How does Spring automatically inject `StudentRepository` into `StudentService`, and `StudentService` into `StudentController` without us ever calling `new`?**

We'll explore:

* 💉 Constructor Injection
* 🏷️ `@Autowired`
* 🧠 Inversion of Control (IoC)
* 🔍 Bean resolution
* ⚖️ `@Primary` and `@Qualifier`
* 🔄 Circular dependencies
* 🛠️ Best practices for dependency injection
