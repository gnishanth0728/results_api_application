# 📘 Chapter 30 — JVM Metaspace

> 📂 File: `student-results-api-notes/04-JVM/05-Metaspace.md`

This chapter is one of the most misunderstood JVM topics.

Many developers know about the Heap, but far fewer understand Metaspace—even though every Java application, including your Student Results API, depends on it.

By the end of this chapter, readers should understand:

Why StudentController.class is not stored in the Heap
Where class metadata lives
Why Java 8 removed PermGen
What causes OutOfMemoryError: Metaspace
How Spring Boot loads thousands of classes
Why Docker and Kubernetes memory limits must account for Metaspace

---

# 🌍 Introduction

In the previous chapters we learned:

* ☕ Heap stores Java **objects**
* 🧵 Stack stores **method execution**
* 📦 Class Loader loads `.class` files

Now another question appears:

> 🤔 **Once a class is loaded, where is its definition stored?**

Suppose your Student Results API contains:

```text
StudentController

StudentService

StudentRepository

Student

StudentResponse

DispatcherServlet

ObjectMapper

JpaRepository

SpringApplication
```

These are **class definitions**, not objects.

They are stored inside:

# 📚 Metaspace

Metaspace is a special JVM memory area dedicated to storing **class metadata**.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📚 What Metaspace is
* 📦 Class metadata
* 🔄 Class loading lifecycle
* 🏛️ PermGen vs Metaspace
* 🧠 Runtime Constant Pool
* 📊 Class metadata
* 💥 OutOfMemoryError: Metaspace
* 🍃 Spring Boot class loading
* 🐳 Docker memory
* ☸️ Kubernetes memory
* 🧪 JVM debugging

---

# ❓ Why Does the JVM Need Metaspace?

Imagine your application creates:

```java
Student student =
new Student();
```

The JVM must know:

* What fields does `Student` contain?
* What methods exist?
* What constructors exist?
* What interfaces does it implement?
* What annotations are present?

This information is **class metadata**.

It is **not** stored on the Heap.

Instead, it is stored in **Metaspace**.

---

# 🏗️ JVM Memory Layout

```text
                    JVM

+------------------------------------------------+

        🧵 Java Thread Stacks

--------------------------------------------------

              ☕ Heap

      Student Objects

      StudentResponse

      ArrayList

--------------------------------------------------

            📚 Metaspace

      Student.class

      StudentController.class

      DispatcherServlet.class

      ObjectMapper.class

--------------------------------------------------

           Native Memory

+------------------------------------------------+
```

Notice the difference:

* Heap → Objects
* Metaspace → Class definitions

---

# 📦 What Is Class Metadata?

Every loaded class has metadata.

Example:

```java
class Student {

    Long id;

    String name;

    int marks;

}
```

The metadata contains information such as:

```text
Class Name

Fields

Methods

Constructors

Interfaces

Annotations

Access Modifiers

Constant Pool

Bytecode References
```

The JVM consults this metadata whenever it executes code involving the class.

---

# 🔄 Class Loading Lifecycle

When you start the application:

```bash
java -jar student-results-api.jar
```

The Class Loader performs:

```text
Read Student.class

↓

Verify

↓

Link

↓

Initialize

↓

Store Metadata

↓

Metaspace
```

After this, the Execution Engine can create instances of the class on the Heap.

---

# ☕ Heap vs 📚 Metaspace

Suppose:

```java
Student student =
new Student();
```

Memory layout:

```text
                JVM

Metaspace

Student.class

↓

Contains

Fields

Methods

Constructors

----------------------------

Heap

Student Object

id = 101

name = "Alice"

marks = 95
```

The **class definition** is stored once.

Many object instances may exist on the Heap.

---

# 🧠 Runtime Constant Pool

Every class contains a Constant Pool.

Example:

```java
String message = "Student";
```

The Constant Pool stores symbolic information such as:

* Method names
* Field names
* String literals
* Type descriptors
* Numeric constants

These runtime structures are associated with the class metadata in Metaspace.

---

# 🏛️ PermGen vs Metaspace

Prior to Java 8, the JVM used **Permanent Generation (PermGen)**.

```text
Java 7

Heap

↓

PermGen
```

Problems:

* Fixed size
* Frequent tuning
* `OutOfMemoryError: PermGen`

Since Java 8:

```text
Java 8+

Heap

↓

Native Memory

↓

Metaspace
```

Metaspace uses native memory and can grow dynamically unless limited.

---

# 📈 Student Results API Startup

When you run:

```bash
java -jar student-results-api.jar
```

The JVM loads classes into Metaspace.

```text
Bootstrap Loader

↓

java.lang.String

↓

Application Loader

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

Hibernate

↓

Jackson

↓

Tomcat

↓

Metaspace
```

Large Spring Boot applications may load **thousands of classes**.

---

# 🌱 Spring Boot Example

Suppose your application contains:

```text
Controller

Service

Repository

DTO

Entity

Configuration

Security

Validation

Jackson

Hibernate

Tomcat
```

Every one of these classes contributes metadata to Metaspace.

Even if only a few objects are instantiated, the class definitions remain loaded for the life of the application (unless custom class loaders unload them).

---

# 💥 OutOfMemoryError: Metaspace

Suppose an application continuously generates new classes at runtime.

Examples:

* Dynamic proxies
* Bytecode generation
* Hot reloading
* Misbehaving custom class loaders

Eventually:

```text
Metaspace

↓

Full

↓

Cannot Load New Class

↓

java.lang.OutOfMemoryError:
Metaspace
```

Unlike Heap OOM, this error is caused by exhausting space for **class metadata**, not object storage.

---

# 📏 Configuring Metaspace

Example:

```bash
java \
-XX:MetaspaceSize=128m \
-XX:MaxMetaspaceSize=512m \
-jar student-results-api.jar
```

* `MetaspaceSize` – initial GC threshold for metaspace
* `MaxMetaspaceSize` – maximum metaspace size

If `MaxMetaspaceSize` is omitted, Metaspace can expand until constrained by available native memory or container limits.

---

# 🧵 Relationship Between Heap and Metaspace

```text
Student.class

↓

Metaspace

↓

new Student()

↓

Heap

↓

Student Object
```

A class **must** exist in Metaspace before objects of that class can be created on the Heap.

---

# 🐳 Docker Perspective

Suppose:

```bash
docker run \
--memory=1g \
student-api
```

The JVM memory consists of:

```text
Heap

+

Metaspace

+

Thread Stacks

+

Direct Buffers

+

JNI

+

GC Structures
```

Metaspace is **outside the Java Heap**, but **inside the container's memory limit**.

Ignoring it may lead to container OOM kills.

---

# ☸️ Kubernetes Perspective

Example:

```yaml
resources:
  requests:
    memory: "512Mi"
  limits:
    memory: "1Gi"
```

Memory usage includes:

```text
Heap

+

Metaspace

+

Thread Stacks

+

Native Memory
```

When sizing a JVM in Kubernetes, reserve enough space for all of these regions—not just the heap.

---

# 🧪 Hands-on Lab

## Display Metaspace Information

```bash
jcmd <PID> VM.native_memory summary
```

Look for:

```text
Metaspace

Class

Symbol

Code
```

---

## Display Class Loader Statistics

```bash
jcmd <PID> VM.classloader_stats
```

Observe:

* Number of loaded classes
* Memory used by class loaders
* Metaspace consumption

---

## Count Loaded Classes

```bash
jcmd <PID> GC.class_stats
```

(Availability depends on JVM version and options.)

This shows loaded classes and their metadata sizes.

---

## Enable Class Loading Logs

```bash
java \
-Xlog:class+load=info \
-jar student-results-api.jar
```

Watch every class loaded into Metaspace during startup.

---

## Display JVM Flags

```bash
java -XX:+PrintFlagsFinal -version | grep Meta
```

Observe default Metaspace-related JVM settings.

---

## Monitor Native Memory

```bash
jcmd <PID> VM.native_memory summary
```

Compare:

* Heap
* Metaspace
* Thread stacks
* Code cache
* Other native allocations

---

# 📈 Complete Class Lifecycle

```text
Student.java

↓

javac

↓

Student.class

↓

Class Loader

↓

Verification

↓

Linking

↓

Initialization

↓

📚 Metaspace

↓

new Student()

↓

☕ Heap

↓

Student Object
```

This illustrates how class metadata and object instances occupy different memory regions.

---

# 💡 Key Takeaways

✅ Metaspace stores **class metadata**, not Java objects.

✅ Every loaded class contributes metadata such as fields, methods, constructors, annotations, and runtime constant pools.

✅ Objects created from those classes are allocated on the Heap.

✅ Metaspace replaced PermGen in Java 8 and resides in native memory.

✅ `OutOfMemoryError: Metaspace` occurs when the JVM cannot allocate space for additional class metadata.

✅ Spring Boot applications typically load thousands of classes into Metaspace during startup.

✅ Docker and Kubernetes memory limits include Metaspace, so JVM sizing must consider heap, metaspace, thread stacks, and other native memory.

---

# ➡️ Next Chapter

📘 **`04-JVM/06-Garbage-Collection.md`**

In the next chapter, we'll answer one of the most important JVM questions:

> **How does the JVM automatically free heap memory while your Spring Boot application is running?**

We'll explore:

* 🗑️ Garbage Collection fundamentals
* 🌱 Young vs Old Generation collection
* ♻️ Minor, Major, and Full GC
* 📍 Reachability analysis
* 🧠 GC algorithms (Serial, Parallel, G1, ZGC, Shenandoah overview)
* 📊 GC logs
* 🧪 Tools such as `jstat`, `jcmd`, `jmap`, and VisualVM`

By the end of that chapter, you'll understand how the JVM keeps your Student Results API responsive even while allocating and reclaiming millions of objects.
