# 📘 Chapter 50 — Spring Dependency Injection (DI)

> 📂 File: `student-results-api-notes/06-SpringBoot/09-Dependency-Injection.md`

This chapter covers one of the core principles of the Spring Framework.

Many beginners learn to use @Autowired, but very few understand what actually happens inside Spring.

This chapter should answer:

How does Spring automatically connect StudentRepository → StudentService → StudentController without us ever calling new?

It explains the complete Dependency Injection (DI) process, from component scanning to bean resolution and injection.

---

# 🌍 Introduction

In the previous chapter, we learned about the **Spring Bean Lifecycle**.

During application startup, Spring:

* 🔍 Scans components
* 🏗️ Creates Beans
* 💉 Injects dependencies
* ⚙️ Initializes Beans

Now another important question appears:

> 🤔 **How does Spring know that `StudentController` needs a `StudentService`, and that `StudentService` needs a `StudentRepository`?**

Notice that we never write:

```java
StudentRepository repository =
    new StudentRepository();

StudentService service =
    new StudentService(repository);

StudentController controller =
    new StudentController(service);
```

Yet everything works perfectly.

The answer is:

# 💉 Dependency Injection (DI)

Dependency Injection is one of the most important features of the Spring Framework.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 💉 What Dependency Injection is
* 🧠 Inversion of Control (IoC)
* 🏗️ Constructor Injection
* 🏷️ `@Autowired`
* 📦 Bean Resolution
* ⚖️ `@Primary`
* 🏷️ `@Qualifier`
* 🔄 Circular Dependencies
* 🧩 Bean Graph
* 🚫 Common mistakes
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ What Is Dependency Injection?

A dependency is simply another object that your class needs.

Example:

```java
public class StudentService {

    private StudentRepository repository;

}
```

Here:

```text
StudentService

↓

depends on

↓

StudentRepository
```

Instead of creating the dependency itself:

```java
StudentRepository repository =
        new StudentRepository();
```

Spring creates it and injects it automatically.

---

# 🧠 What Is Inversion of Control (IoC)?

Traditionally:

```text
Application

↓

Creates Objects
```

With Spring:

```text
Application

↓

Requests Objects

↓

Spring Creates Objects
```

The control of object creation moves from your application to the Spring IoC Container.

This inversion of responsibility is called **Inversion of Control (IoC)**.

---

# 🏗️ Dependency Graph

Imagine your Student Results API:

```text
StudentController
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
DataSource
```

Spring builds this dependency graph during application startup.

It creates objects in the correct order.

---

# 💉 Constructor Injection

The recommended approach is **Constructor Injection**.

Example:

```java
@Service
public class StudentService {

    private final StudentRepository repository;

    public StudentService(
            StudentRepository repository) {

        this.repository = repository;

    }

}
```

Spring automatically:

1. Creates `StudentRepository`
2. Calls the constructor
3. Passes the repository instance
4. Stores it in the field

No `new` keyword is required.

---

# 🏷️ @Autowired

Older Spring code often uses:

```java
@Service
public class StudentService {

    @Autowired
    private StudentRepository repository;

}
```

Spring injects the dependency directly into the field.

Although this works, **constructor injection is preferred** because it:

* Makes dependencies explicit
* Supports immutable (`final`) fields
* Simplifies testing
* Prevents partially initialized objects

---

# 🔍 How Spring Resolves Dependencies

Suppose:

```java
private final StudentRepository repository;
```

Spring asks:

> "Is there a Bean of type `StudentRepository`?"

```text
ApplicationContext

├── StudentController

├── StudentService

├── StudentRepository

├── ObjectMapper

└── DataSource
```

It finds exactly one matching Bean and injects it.

---

# ⚖️ Multiple Beans Problem

Suppose two implementations exist:

```java
interface NotificationService
```

Implementations:

```java
EmailNotificationService

SmsNotificationService
```

Spring now finds:

```text
NotificationService

↓

EmailNotificationService

SmsNotificationService
```

Which one should it inject?

Spring throws:

```text
NoUniqueBeanDefinitionException
```

---

# 🌟 @Primary

You can mark one implementation as the default.

```java
@Primary
@Service
public class EmailNotificationService
        implements NotificationService {
}
```

Now Spring automatically injects:

```text
NotificationService

↓

EmailNotificationService
```

unless another implementation is explicitly requested.

---

# 🏷️ @Qualifier

Sometimes you want a specific implementation.

```java
@Service
public class StudentService {

    public StudentService(

        @Qualifier("smsNotificationService")
        NotificationService notificationService){

    }

}
```

Spring injects exactly the named Bean.

---

# 🔄 Circular Dependency

Imagine:

```text
StudentService

↓

StudentRepository

↓

StudentService
```

Neither object can be created first.

Spring reports a circular dependency.

Avoid circular references by designing clear, one-directional dependencies.

---

# 🍃 Student Results API Example

```java
@RestController
public class StudentController {

    private final StudentService service;

    public StudentController(
            StudentService service){

        this.service = service;

    }

}
```

Flow during startup:

```text
StudentRepository Created

↓

StudentService Created

↓

StudentController Created

↓

DispatcherServlet Ready
```

---

# 📊 Complete Injection Process

```text
Application Starts
        │
        ▼
Component Scan
        │
        ▼
Find StudentRepository
        │
        ▼
Create Repository Bean
        │
        ▼
Find StudentService
        │
        ▼
Inject Repository
        │
        ▼
Create Service Bean
        │
        ▼
Find StudentController
        │
        ▼
Inject Service
        │
        ▼
Create Controller Bean
        │
        ▼
Application Ready
```

---

# 🧠 Bean Dependency Tree

```text
ApplicationContext
│
├── StudentController
│      │
│      ▼
│   StudentService
│      │
│      ▼
│   StudentRepository
│      │
│      ▼
│   EntityManager
│      │
│      ▼
│   DataSource
│
├── ObjectMapper
│
├── DispatcherServlet
│
└── Jackson Converter
```

Spring maintains this dependency graph throughout the application's lifetime.

---

# 🚫 Common Mistakes

## ❌ Creating Beans Manually

```java
StudentService service =
    new StudentService();
```

Problems:

* No dependency injection
* No transactions
* No AOP
* No lifecycle callbacks

Always let Spring create managed components.

---

## ❌ Field Injection Everywhere

```java
@Autowired
private StudentRepository repository;
```

Although supported, constructor injection is generally the better choice.

---

## ❌ Static Dependencies

```java
private static StudentRepository repository;
```

Static fields are not managed by Spring and cannot participate in normal dependency injection.

---

# 🐳 Docker Perspective

```text
Docker Container
        │
        ▼
JVM
        │
        ▼
Spring Boot
        │
        ▼
ApplicationContext
        │
        ▼
Dependency Injection
        │
        ▼
Beans Ready
```

Dependency Injection works exactly the same inside containers.

---

# ☸️ Kubernetes Perspective

```text
Pod 1

↓

ApplicationContext

↓

Beans

---------------------

Pod 2

↓

ApplicationContext

↓

Beans
```

Each Pod has its own IoC Container and performs dependency injection independently.

---

# 🧪 Hands-on Lab

## Constructor Injection

Create:

```java
@Service
public class StudentService {

    private final StudentRepository repository;

    public StudentService(StudentRepository repository) {
        this.repository = repository;
    }
}
```

Run the application and verify that Spring injects the repository automatically.

---

## Test Multiple Beans

Create:

```java
EmailNotificationService

SmsNotificationService
```

Observe:

```text
NoUniqueBeanDefinitionException
```

Then resolve it using:

```java
@Primary
```

or

```java
@Qualifier
```

---

## View Bean Graph

Enable the Beans endpoint:

```properties
management.endpoints.web.exposure.include=beans
```

Run:

```bash
curl http://localhost:8080/actuator/beans
```

Observe how Spring wires dependencies between Beans.

---

## Debug Bean Creation

Set breakpoints in:

* `SpringApplication.run()`
* `DefaultListableBeanFactory`
* `StudentController`
* `StudentService`

Watch constructor injection occur during startup.

---

# 📈 Complete Dependency Injection Flow

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
Bean Definitions
      │
      ▼
Create Repository
      │
      ▼
Create Service
      │
      ▼
Inject Repository
      │
      ▼
Create Controller
      │
      ▼
Inject Service
      │
      ▼
DispatcherServlet Uses Controller
      │
      ▼
HTTP Requests Processed
```

This is the complete Dependency Injection process in a Spring Boot application.

---

# 📊 Constructor Injection vs Field Injection

| Feature                             | Constructor Injection ✅ | Field Injection ⚠️ |
| ----------------------------------- | ----------------------- | ------------------ |
| Recommended                         | ✅ Yes                   | ⚠️ Legacy style    |
| Supports `final` fields             | ✅ Yes                   | ❌ No               |
| Easy to test                        | ✅ Yes                   | ❌ Harder           |
| Immutable objects                   | ✅ Yes                   | ❌ No               |
| Dependencies visible                | ✅ Yes                   | ❌ Hidden           |
| Spring required for object creation | ❌ No                    | ✅ Yes              |

---

# 💡 Key Takeaways

✅ Dependency Injection (DI) allows Spring to create and connect application objects automatically.

✅ Inversion of Control (IoC) shifts the responsibility for object creation from your code to the Spring IoC Container.

✅ Constructor Injection is the recommended approach because it promotes immutability, testability, and explicit dependencies.

✅ Spring resolves dependencies by searching the `ApplicationContext` for matching Bean types.

✅ `@Primary` and `@Qualifier` help resolve ambiguity when multiple Beans implement the same interface.

✅ Circular dependencies indicate a design problem and should generally be avoided.

✅ Every Docker container and Kubernetes Pod has its own `ApplicationContext` that performs dependency injection independently.

---

# ➡️ Next Chapter

📘 **`06-SpringBoot/10-Auto-Configuration.md`**

In the next chapter, we'll explore one of Spring Boot's most powerful features:

* ⚙️ What Auto-Configuration is
* 📦 Starter dependencies
* 🔍 Conditional annotations (`@ConditionalOnClass`, `@ConditionalOnMissingBean`)
* 🚀 How Spring Boot configures Tomcat, Jackson, Hibernate, DataSource, and many other components automatically
* 🧠 How to customize or override auto-configured Beans

By the end of the next chapter, you'll understand why adding a single dependency such as `spring-boot-starter-web` automatically provides an embedded Tomcat server, JSON support, and a fully configured Spring MVC application.
