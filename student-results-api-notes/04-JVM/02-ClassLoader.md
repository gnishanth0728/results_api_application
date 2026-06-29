# 📘 Chapter 27 — JVM Class Loader

> 📂 File: `student-results-api-notes/04-JVM/02-ClassLoader.md`

This chapter is one of the most important JVM chapters because it explains how your Spring Boot application comes to life.

When you run:

java -jar student-results-api.jar

nothing is loaded into memory initially except the JVM itself.

The Class Loader Subsystem gradually discovers, verifies, links, initializes, and loads every class that your application needs.

By the end of this chapter, readers should understand exactly how StudentController.class, StudentService.class, DispatcherServlet.class, and even java.lang.String are loaded into memory.
---

# 🌍 Introduction

In the previous chapter, we learned that the JVM consists of several major components:

```text
Java Source
      │
      ▼
javac
      │
      ▼
Bytecode (.class)
      │
      ▼
+------------------------------------+
|           JVM                      |
|------------------------------------|
| 📦 Class Loader                    |
| 🧠 Runtime Memory                  |
| ⚙️ Execution Engine                |
| 🗑️ Garbage Collector              |
+------------------------------------+
```

Today we'll study the **first component**:

# 📦 Class Loader

When you run:

```bash
java -jar student-results-api.jar
```

the JVM does **not** immediately load every class inside the JAR.

Instead, classes are loaded **on demand**, exactly when they are first needed.

This mechanism makes Java startup faster and memory efficient.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📦 What a Class Loader is
* 📄 What a `.class` file contains
* 📚 Bootstrap Class Loader
* 🏛️ Platform Class Loader
* 📦 Application Class Loader
* 🔄 Parent Delegation Model
* 🔗 Loading, Linking, Initialization
* 🧠 Class metadata in Metaspace
* 🍃 Spring Boot class loading
* 🐳 Docker
* ☸️ Kubernetes
* 🧪 JVM debugging

---

# ❓ Why Does Java Need Class Loaders?

Imagine a Spring Boot application containing:

```text
StudentController

StudentService

StudentRepository

Student

StudentResponse

ApplicationConfig

SecurityConfig

DispatcherServlet

ObjectMapper

...
```

There may be **thousands of classes**.

Loading every class at startup would:

* Waste memory
* Increase startup time
* Load unused code

Instead, the JVM loads classes only when required.

---

# 🏗️ High-Level Architecture

```text
student-results-api.jar
        │
        ▼
+-------------------------+
| Class Loader Subsystem  |
+-------------------------+
        │
        ▼
Verify Class
        │
        ▼
Link Class
        │
        ▼
Initialize Class
        │
        ▼
Metaspace
        │
        ▼
Execution Engine
```

Every class follows this lifecycle before it can execute.

---

# 📄 What Is a `.class` File?

When you compile:

```java
public class Student {
}
```

using:

```bash
javac Student.java
```

the compiler generates:

```text
Student.class
```

A `.class` file contains:

* Constant Pool
* Method Bytecode
* Field Definitions
* Class Metadata
* Interfaces
* Method Signatures
* Access Flags

It does **not** contain machine code.

It contains **JVM bytecode**.

---

# 📦 Three Built-in Class Loaders

The JVM provides three primary class loaders.

```text
Bootstrap Class Loader
          │
          ▼
Platform Class Loader
          │
          ▼
Application Class Loader
```

Each has a different responsibility.

---

# 🥇 Bootstrap Class Loader

The Bootstrap Class Loader loads the core Java runtime classes.

Examples:

```text
java.lang.Object

java.lang.String

java.lang.Integer

java.util.List

java.io.File
```

These classes come from the Java runtime itself.

Without them, no Java application could execute.

---

# 🏛️ Platform Class Loader

The Platform Class Loader loads standard Java platform modules.

Examples:

```text
java.sql

java.naming

java.xml

java.management
```

These libraries are part of the JDK but separate from the minimal core runtime.

---

# 📦 Application Class Loader

The Application Class Loader loads your application's classes and dependencies.

Examples:

```text
StudentResultsApiApplication

StudentController

StudentService

StudentRepository

Student.class

Spring Boot Classes

Tomcat Classes

Jackson

Hibernate
```

Everything packaged inside your application JAR (or referenced on the classpath) is typically loaded by this loader.

---

# 📊 Complete Class Loader Hierarchy

```text
                 Bootstrap
                      │
                      ▼
               Platform Loader
                      │
                      ▼
             Application Loader
                      │
                      ▼
          student-results-api.jar
                      │
                      ▼
              StudentController
                      │
                      ▼
               StudentService
```

This hierarchy follows the **Parent Delegation Model**.

---

# 🔄 Parent Delegation Model

Suppose Java needs:

```text
java.lang.String
```

The Application Class Loader does **not** load it directly.

Instead:

```text
Application Loader

↓

Platform Loader

↓

Bootstrap Loader

↓

Found

↓

Return Class
```

If the parent cannot find the class, control returns downward until the appropriate loader loads it.

This prevents duplicate definitions of core Java classes.

---

# ⚙️ Class Loading Lifecycle

Every class passes through three major phases.

```text
Load
   │
   ▼
Link
   │
   ▼
Initialize
```

Let's examine each stage.

---

# 📥 Phase 1 — Loading

The Class Loader:

* Locates the `.class` file
* Reads its bytecode
* Creates an internal class representation
* Stores metadata in Metaspace

Conceptually:

```text
StudentController.class

↓

Read Bytes

↓

Create Class Object

↓

Metaspace
```

---

# 🔗 Phase 2 — Linking

Linking consists of three sub-phases.

```text
Verification

↓

Preparation

↓

Resolution
```

### Verification

Checks that the bytecode is valid and safe.

### Preparation

Allocates memory for static fields and assigns default values.

### Resolution

Resolves symbolic references into direct references.

---

# 🚀 Phase 3 — Initialization

Finally, static initialization executes.

Example:

```java
static {
    System.out.println("Initializing...");
}
```

The JVM executes static initializers exactly once before the class is first used.

---

# 🧠 Metaspace

Loaded class metadata is stored in **Metaspace**.

```text
+----------------------------+
| Metaspace                  |
|----------------------------|
| Student.class              |
| StudentController.class    |
| StudentService.class       |
| DispatcherServlet.class    |
| ObjectMapper.class         |
+----------------------------+
```

Metaspace stores:

* Class metadata
* Method metadata
* Field metadata
* Runtime constant pools

Objects created from these classes still live on the **Heap**.

---

# 🍃 Spring Boot Startup Example

When you run:

```bash
java -jar student-results-api.jar
```

the JVM loads classes in stages.

```text
Bootstrap Loader

↓

java.lang.Object

↓

java.lang.String

↓

Application Loader

↓

StudentResultsApiApplication

↓

SpringApplication

↓

DispatcherServlet

↓

StudentController

↓

StudentService

↓

StudentRepository

↓

Tomcat

↓

Application Ready
```

Only the classes needed during startup are loaded initially.

Additional classes may be loaded later when new features are exercised.

---

# 🌐 First HTTP Request

When the browser sends:

```http
GET /students/1051110244
```

Flow:

```text
Browser

↓

Tomcat

↓

DispatcherServlet

↓

StudentController

↓

StudentService

↓

StudentRepository

↓

Student Entity

↓

JSON Response
```

If any required class has not yet been loaded, the JVM loads, links, and initializes it before continuing execution.

---

# 📈 Lazy Class Loading

Suppose your project contains:

```text
AdminController
```

but no one accesses:

```text
/admin
```

The JVM may never load:

```text
AdminController.class
```

during that execution.

This is called **lazy class loading**.

---

# 🐳 Docker Perspective

Docker does not change class loading.

```text
Docker Container
        │
        ▼
Java Process
        │
        ▼
JVM
        │
        ▼
Application Class Loader
        │
        ▼
student-results-api.jar
```

The Class Loader behaves exactly as it would on a normal Linux system.

---

# ☸️ Kubernetes Perspective

Inside Kubernetes:

```text
Pod
   │
   ▼
Container
   │
   ▼
Java Process
   │
   ▼
JVM
   │
   ▼
Class Loader
```

The JVM's class loading mechanism is independent of Kubernetes.

---

# 🧪 Hands-on Lab

## Display JAR Contents

```bash
jar tf student-results-api.jar
```

Observe:

* Application classes
* Spring Boot classes
* Libraries
* `META-INF`

---

## View a Compiled Class

```bash
javap -c Student.class
```

Displays the JVM bytecode generated by the Java compiler.

---

## Display Loaded Classes

```bash
jcmd <PID> VM.classloaders
```

Shows the active class loaders in the running JVM.

---

## Count Loaded Classes

```bash
jcmd <PID> VM.classloader_stats
```

Displays:

* Number of loaded classes
* Memory usage
* Class loader statistics

---

## Enable Class Loading Logs

Start the application with:

```bash
java -Xlog:class+load=info \
-jar student-results-api.jar
```

Watch each class being loaded during startup.

---

## Display JVM System Properties

```bash
jcmd <PID> VM.system_properties
```

Useful properties include:

```text
java.class.path

java.home

jdk.module.path
```

---

# 📈 Complete Class Loading Flow

```text
student-results-api.jar
        │
        ▼
Application Class Loader
        │
        ▼
Read StudentController.class
        │
        ▼
Verify Bytecode
        │
        ▼
Link Class
        │
        ▼
Initialize Static Members
        │
        ▼
Store Metadata in Metaspace
        │
        ▼
Execution Engine
        │
        ▼
Controller Ready
```

This sequence occurs for every class before it can be executed.

---

# 💡 Key Takeaways

✅ The Class Loader Subsystem is responsible for loading Java classes into the JVM.

✅ The JVM provides three primary class loaders: Bootstrap, Platform, and Application.

✅ The Parent Delegation Model ensures core Java classes are loaded safely and consistently.

✅ Every class passes through the phases of Loading, Linking, and Initialization.

✅ Class metadata is stored in Metaspace, while object instances are allocated on the Heap.

✅ Spring Boot loads classes lazily as they become necessary, reducing startup time and memory usage.

✅ Docker and Kubernetes do not alter the JVM's class loading mechanism—they simply provide the environment in which the JVM runs.

---

# ➡️ Next Chapter

📘 **`04-JVM/03-JVM-Memory-Model.md`**

In the next chapter, we'll dive deeper into the JVM's internal memory layout.

You'll learn:

* ☕ Heap
* 🧵 Java Stacks
* 📚 Metaspace
* 🖥️ Program Counter Registers
* 🧩 Native Method Stack
* 📦 Object allocation
* 🗑️ Garbage Collection interaction
* 🧪 Tools such as `jmap`, `jcmd`, `jstat`, and `VisualVM`

By the end of the next chapter, you'll understand exactly where every object, method frame, class definition, and thread lives inside the JVM.
