# 📘 Chapter 42 — Spring Boot Architecture

> 📂 File: `student-results-api-notes/06-SpringBoot/01-SpringBoot-Architecture.md`

This chapter starts the Spring Boot module, where the reader finally moves beyond Tomcat into the Spring Framework itself.

Everything so far has answered:

How does the request reach Spring Boot?

Now we answer:

How does Spring Boot organize, create, wire, and execute the entire application?

This chapter serves as the foundation for everything that follows:

IoC Container
ApplicationContext
Bean Lifecycle
Dependency Injection
Auto Configuration
Spring MVC
Spring Data JPA
Spring Security

---

# 🌍 Introduction

Congratulations! 🎉

So far we've followed one HTTP request through multiple layers:

```text
Browser
    │
    ▼
TCP/IP Network
    │
    ▼
Linux Kernel
    │
    ▼
Socket
    │
    ▼
Tomcat
    │
    ▼
DispatcherServlet
```

Now another important question appears:

> 🤔 **Once DispatcherServlet receives the request, how does Spring Boot execute your application?**

Suppose the request is:

```http
GET /students/1051110244
```

Eventually your application executes:

```java
StudentController

↓

StudentService

↓

StudentRepository

↓

PostgreSQL
```

Who creates these objects?

Who connects them together?

Who injects dependencies?

Who manages their lifecycle?

The answer is:

# 🌱 Spring Boot

More specifically,

# 🏗️ Spring Boot + Spring Framework + IoC Container

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🌱 What Spring Boot is
* 🏗️ Spring Framework Architecture
* 📦 IoC Container
* 🎯 Dependency Injection
* 🧩 Spring Beans
* ⚙️ Auto Configuration
* 🚀 Spring Boot Startup
* 🌐 Spring MVC
* 🗄️ Spring Data JPA
* 🔐 Spring Security
* 🐳 Docker Integration
* ☸️ Kubernetes Deployment

---

# ❓ What Is Spring Boot?

Spring Boot is a framework that simplifies building Java applications.

Instead of manually configuring:

* Tomcat
* Servlet mappings
* Jackson
* Database connections
* Logging
* Spring MVC

Spring Boot automatically configures them.

Example:

Without Spring Boot:

```text
Create Tomcat

Configure Servlet

Configure DispatcherServlet

Configure Jackson

Configure Database

Configure Logging

Write XML

Deploy WAR
```

With Spring Boot:

```bash
java -jar student-results-api.jar
```

Everything starts automatically.

---

# 🌱 Spring Boot vs Spring Framework

Many beginners think these are the same.

They are not.

```text
                Spring Boot
                     │
                     ▼
        Auto Configuration
        Embedded Tomcat
        Starter Dependencies
        Production Features
                     │
                     ▼
             Spring Framework
                     │
                     ▼
IoC

Dependency Injection

Spring MVC

Spring Data

Spring Security

AOP

Transaction Management
```

Think of Spring Boot as a layer built on top of the Spring Framework.

---

# 🏗️ Complete Architecture

```text
                    Browser
                        │
                        ▼
                  HTTP Request
                        │
                        ▼
                  Apache Tomcat
                        │
                        ▼
              DispatcherServlet
                        │
                        ▼
+------------------------------------------------+
|              Spring Framework                  |
|------------------------------------------------|
| 🗺️ HandlerMapping                              |
|------------------------------------------------|
| 🎮 Controller                                  |
|------------------------------------------------|
| ⚙️ Service                                     |
|------------------------------------------------|
| 🗄️ Repository                                  |
|------------------------------------------------|
| 📦 Spring Beans                                |
|------------------------------------------------|
| 🧠 IoC Container                               |
|------------------------------------------------|
| ⚡ Auto Configuration                           |
+------------------------------------------------+
                        │
                        ▼
                   PostgreSQL
```

---

# 🧠 IoC (Inversion of Control)

Normally Java developers create objects manually.

Example:

```java
StudentService service =
new StudentService();
```

Spring Boot changes this.

Instead:

```java
@Autowired
StudentService service;
```

Spring creates the object.

Spring manages the object.

Spring injects the object.

This concept is called:

# 📦 Inversion of Control (IoC)

The control of object creation moves from your code to the Spring Container.

---

# 📦 Spring Beans

Every managed object is called a **Bean**.

Example:

```java
@RestController
class StudentController

@Service
class StudentService

@Repository
class StudentRepository
```

Spring automatically creates these as Beans.

Conceptually:

```text
ApplicationContext

├── StudentController Bean

├── StudentService Bean

├── StudentRepository Bean

├── ObjectMapper Bean

├── DataSource Bean

├── DispatcherServlet Bean
```

---

# 🎯 Dependency Injection

Suppose:

```java
StudentController

↓

StudentService

↓

StudentRepository
```

Instead of writing:

```java
new StudentService();
```

Spring performs:

```text
ApplicationContext

↓

Create StudentService

↓

Inject Into Controller
```

Your classes simply declare their dependencies.

---

# ⚙️ Auto Configuration

Spring Boot detects libraries automatically.

Suppose Maven contains:

```xml
spring-boot-starter-web
```

Spring Boot automatically configures:

```text
Embedded Tomcat

DispatcherServlet

Jackson

HTTP Message Converters

Validation

Error Handling
```

If you add:

```xml
spring-boot-starter-data-jpa
```

Spring Boot configures:

```text
DataSource

Hibernate

EntityManager

Transaction Manager
```

---

# 🚀 Spring Boot Startup

When you execute:

```bash
java -jar student-results-api.jar
```

Startup sequence:

```text
Main()

↓

SpringApplication.run()

↓

ApplicationContext

↓

Component Scan

↓

Bean Creation

↓

Dependency Injection

↓

Embedded Tomcat

↓

Application Ready
```

---

# 🌐 Request Processing

Suppose:

```http
GET /students/1051110244
```

Execution:

```text
DispatcherServlet

↓

HandlerMapping

↓

StudentController

↓

StudentService

↓

StudentRepository

↓

PostgreSQL

↓

Student Entity

↓

StudentResponse

↓

Jackson

↓

JSON
```

Spring coordinates every application component.

---

# 📦 Spring Boot Modules

Spring Boot includes many modules.

```text
Spring Boot

├── Spring MVC

├── Spring Data JPA

├── Spring Security

├── Validation

├── Scheduling

├── Actuator

├── WebSocket

├── Cache

├── Messaging

└── Batch
```

Each module integrates seamlessly with the others.

---

# 🍃 Student Results API Architecture

```text
Student Results API

├── StudentController

├── StudentService

├── StudentRepository

├── Student Entity

├── StudentResponse DTO

├── PostgreSQL

├── Jackson

├── Validation

└── Exception Handling
```

Every component is managed by Spring.

---

# 🔄 Complete Request Flow

```text
Browser
      │
      ▼
Linux TCP Stack
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
StudentController
      │
      ▼
StudentService
      │
      ▼
StudentRepository
      │
      ▼
Hibernate
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
JSON Response
```

This is the complete Spring Boot request flow.

---

# 🐳 Docker Perspective

Inside Docker:

```text
Container

↓

Java Process

↓

Spring Boot

↓

ApplicationContext

↓

Beans

↓

Tomcat

↓

Controllers
```

The entire Spring Boot application runs inside one JVM process in the container.

---

# ☸️ Kubernetes Perspective

Inside Kubernetes:

```text
Ingress

↓

Service

↓

Pod

↓

Container

↓

Spring Boot

↓

Tomcat

↓

ApplicationContext
```

Kubernetes manages the Pod lifecycle.

Spring Boot manages the application lifecycle inside the container.

---

# 🧪 Hands-on Lab

## Start the Application

```bash
./mvnw spring-boot:run
```

Observe:

```text
Started StudentResultsApplication in 3.4 seconds
```

---

## View Bean Count

Enable Actuator:

```properties
management.endpoints.web.exposure.include=beans
```

Then run:

```bash
curl http://localhost:8080/actuator/beans
```

Observe hundreds of automatically created Spring Beans.

---

## Display Request Mappings

```bash
curl http://localhost:8080/actuator/mappings
```

View every registered controller endpoint.

---

## Display Environment

```bash
curl http://localhost:8080/actuator/env
```

Inspect configuration properties loaded by Spring Boot.

---

## Display Health

```bash
curl http://localhost:8080/actuator/health
```

Verify that Tomcat, the database, and the application are healthy.

---

# 📈 Complete Spring Boot Architecture

```text
                    Browser
                        │
                        ▼
                 HTTP Request
                        │
                        ▼
                    Tomcat
                        │
                        ▼
               DispatcherServlet
                        │
                        ▼
              ApplicationContext
                        │
     ┌────────────┬────────────┬────────────┐
     ▼            ▼            ▼
Controller     Service     Repository
     │            │            │
     └────────────┴────────────┘
                  │
                  ▼
              Hibernate
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
             JSON Response
```

---

# 💡 Key Takeaways

✅ Spring Boot is built on top of the Spring Framework and provides auto-configuration, embedded servers, and production-ready defaults.

✅ The Spring IoC Container creates, manages, and wires application components called **Beans**.

✅ Dependency Injection removes the need for manual object creation and promotes loose coupling.

✅ Spring Boot automatically configures components such as Tomcat, Jackson, DataSource, Hibernate, and Spring MVC based on the dependencies on the classpath.

✅ Every HTTP request flows through DispatcherServlet, Controllers, Services, and Repositories before reaching the database.

✅ The ApplicationContext is the heart of every Spring Boot application and manages the complete object lifecycle.

✅ Docker containers host the JVM and Spring Boot application, while Kubernetes manages deployment, scaling, and availability at the infrastructure level.

---

# ➡️ Next Chapter

📘 **`06-SpringBoot/02-ApplicationContext.md`**

In the next chapter, we'll dive into the **ApplicationContext**, the heart of the Spring Framework.

We'll explore:

* 🧠 What the IoC Container is
* 📦 Bean creation and registration
* 🔍 Component scanning
* ⚙️ BeanFactory vs ApplicationContext
* 🔄 Bean lifecycle
* 📋 Singleton vs Prototype scope
* 🧩 How `@Autowired` actually works

By the end of the next chapter, you'll understand how Spring Boot creates every object in your application before the first HTTP request is ever processed.
