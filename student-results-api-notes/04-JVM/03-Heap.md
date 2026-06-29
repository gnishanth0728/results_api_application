# 📘 Chapter 28 — JVM Heap

> 📂 File: `student-results-api-notes/04-JVM/03-Heap.md`

This is one of the most important chapters in the entire handbook because almost every Java performance problem eventually comes back to the Heap.

After reading it, someone should understand:

Where every Java object lives
How objects are allocated
Why memory grows
How Garbage Collection works
Why OutOfMemoryError happens
How Spring Boot uses the heap
How Docker and Kubernetes memory limits affect the JVM

---

# 🌍 Introduction

In the previous chapter, we learned how the JVM loads classes into memory.

Now we'll study the **largest and most important memory region inside the JVM**:

# ☕ Heap Memory

Every object created by your Student Results API lives here.

Examples include:

* 👨‍🎓 Student
* 📚 StudentResponse
* 📝 SubjectResponse
* 📋 ArrayList
* 🗂️ HashMap
* 🔤 String
* 🌱 Spring Beans
* 🛢️ Hibernate Entities
* 🗄️ JDBC Objects

When a browser sends:

```http
GET /students/1051110244
```

the JVM allocates dozens of objects on the heap before sending the JSON response.

Understanding the heap is essential for writing scalable Java applications.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* ☕ What the Heap is
* 📦 Object allocation
* 🧠 Heap architecture
* 🌱 Young Generation
* 👴 Old Generation
* 🗑️ Garbage Collection
* 📈 Object lifecycle
* 💥 OutOfMemoryError
* 🍃 Spring Boot heap usage
* 🐳 Docker memory
* ☸️ Kubernetes memory
* 🧪 JVM heap debugging

---

# ❓ What Is the Heap?

The **Heap** is the JVM memory area used to store **objects**.

Every object created using:

```java
new Student()

new ArrayList<>()

new String()

new HashMap<>()
```

is allocated on the Heap.

Unlike the Java Stack:

* Heap is **shared** by all threads.
* Heap grows dynamically (within configured limits).
* Objects remain until the Garbage Collector removes them.

---

# 🏗️ High-Level Heap Architecture

```text
                    JVM

+------------------------------------------------+

           🧵 Thread Stack

           Controller()

           Service()

           Repository()

--------------------------------------------------

               ☕ HEAP

      Student Objects

      StudentResponse

      ArrayList

      HashMap

      Strings

      Spring Beans

--------------------------------------------------

             📚 Metaspace

--------------------------------------------------

      Native Memory

+------------------------------------------------+
```

The stack stores **references**, while the heap stores the **actual objects**.

---

# 📍 References vs Objects

Consider:

```java
Student student =
studentRepository.findById(id);
```

Memory layout:

```text
Thread Stack

student
   │
   ▼
0x100A

----------------------------

Heap

0x100A

Student Object
```

The variable `student` contains only a reference.

The `Student` object itself lives on the heap.

---

# 📦 Object Allocation

Suppose a request arrives:

```http
GET /students/1051110244
```

Execution:

```text
Tomcat Thread

↓

Controller()

↓

new StudentResponse()

↓

new ArrayList()

↓

new SubjectResponse()

↓

Heap Allocation
```

Every `new` operation reserves memory on the heap.

---

# 🌱 Modern Heap Layout

Modern JVMs divide the heap into generations.

```text
+------------------------------------------------------+

        🌱 Young Generation

        Eden Space

        Survivor 0

        Survivor 1

--------------------------------------------------------

        👴 Old Generation

--------------------------------------------------------

        Reserved Space

+------------------------------------------------------+
```

This organization improves Garbage Collection efficiency.

---

# 🌱 Young Generation

New objects are allocated in the **Eden Space**.

Example:

```java
StudentResponse response =
new StudentResponse();
```

Memory:

```text
Heap

↓

Young Generation

↓

Eden
```

Most objects die here because they are short-lived.

---

# 🔄 Survivor Spaces

Objects that survive a Minor GC move to Survivor spaces.

```text
Eden

↓

Minor GC

↓

Survivor 0

↓

Minor GC

↓

Survivor 1
```

Objects gradually age as they survive multiple collections.

---

# 👴 Old Generation

Long-lived objects are promoted to the Old Generation.

Examples:

* 🌱 Spring Singleton Beans
* 🗂️ Connection Pools
* 📚 Cached Objects
* 🔧 Configuration Objects

These objects remain in memory for a long time.

---

# 📈 Object Lifecycle

A typical object follows this journey:

```text
new Student()

↓

Eden

↓

Minor GC

↓

Survivor

↓

Minor GC

↓

Old Generation

↓

Major GC

↓

Memory Reclaimed
```

Not every object reaches the Old Generation—many are collected while still young.

---

# 🗑️ Garbage Collection

Suppose:

```java
StudentResponse response =
new StudentResponse();
```

After the HTTP response is sent:

```java
response = null;
```

Eventually:

```text
Heap

↓

Object Unreachable

↓

Garbage Collector

↓

Memory Reclaimed
```

Only unreachable objects are eligible for collection.

---

# 🍃 Student Results API Example

During one request:

```text
Browser

↓

StudentController

↓

StudentService

↓

StudentRepository

↓

Student Entity

↓

StudentResponse

↓

JSON
```

Heap allocations include:

```text
Student

↓

StudentMark

↓

ArrayList

↓

SubjectResponse

↓

Jackson Objects

↓

JSON Buffer
```

Most of these objects are temporary and are reclaimed quickly by Minor GC.

---

# 🌱 Spring Beans

Spring creates singleton beans at startup.

Examples:

```text
StudentController

StudentService

StudentRepository

ObjectMapper

DataSource
```

These objects remain alive for the lifetime of the application and typically reside in the Old Generation.

---

# 💥 OutOfMemoryError

Suppose:

```java
List<Student> students =
new ArrayList<>();

while(true){
    students.add(new Student());
}
```

Eventually:

```text
Heap

↓

Full

↓

Garbage Collector

↓

Still Full

↓

OutOfMemoryError
```

The JVM throws:

```text
java.lang.OutOfMemoryError:
Java heap space
```

This means the heap cannot satisfy another allocation request.

---

# 📊 Heap Size

Configure heap size when starting the JVM:

```bash
java \
-Xms512m \
-Xmx2g \
-jar student-results-api.jar
```

* `-Xms` = Initial heap size
* `-Xmx` = Maximum heap size

Choose values that fit comfortably within the available memory and any container limits.

---

# 📈 Heap Usage During Load Testing

You ran:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Typical behavior:

```text
Requests

↓

Many Objects Created

↓

Heap Usage Increases

↓

Minor GC

↓

Heap Usage Drops

↓

Repeat
```

Because most request objects are short-lived, the Young Generation handles the majority of allocations efficiently.

---

# 🐳 Docker Perspective

Suppose the container is limited to **1 GB**:

```bash
docker run \
--memory=1g \
student-api
```

If you configure:

```bash
-Xmx2g
```

the JVM may exceed the container limit.

The Linux kernel can terminate the process with an **OOM kill**.

A common practice is to leave headroom for:

* Thread stacks
* Metaspace
* Direct buffers
* Native libraries
* JVM overhead

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

The JVM heap should be configured so that:

```text
Heap

+

Metaspace

+

Thread Stacks

+

Native Memory

<

Container Limit
```

If total memory exceeds the limit, the Pod may be restarted after an OOM kill.

---

# 🧪 Hands-on Lab

## Display Heap Information

```bash
jcmd <PID> GC.heap_info
```

Shows:

* Heap size
* Young Generation
* Old Generation
* GC configuration

---

## View Heap Histogram

```bash
jmap -histo <PID>
```

Displays:

* Object types
* Instance counts
* Heap usage by class

---

## Generate a Heap Dump

```bash
jcmd <PID> GC.heap_dump heap.hprof
```

Analyze the resulting heap dump using Eclipse MAT or VisualVM.

---

## Monitor Garbage Collection

```bash
jstat -gc <PID> 1000
```

Observe:

* Eden usage
* Survivor usage
* Old Generation usage
* GC counts

---

## Observe Heap During Load

Terminal 1:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Terminal 2:

```bash
watch -n1 \
'jcmd <PID> GC.heap_info'
```

Watch heap usage grow and shrink as requests are processed and garbage collections occur.

---

## View Native Memory Summary

```bash
jcmd <PID> VM.native_memory summary
```

If Native Memory Tracking is enabled, compare heap usage with metaspace, thread stacks, and other native allocations.

---

# 📈 Complete Object Lifecycle

```text
HTTP Request
      │
      ▼
Tomcat Thread
      │
      ▼
new StudentResponse()
      │
      ▼
🌱 Eden Space
      │
      ▼
Minor GC
      │
      ▼
Survivor Space
      │
      ▼
Old Generation
      │
      ▼
Object Becomes Unreachable
      │
      ▼
Major GC
      │
      ▼
Memory Reclaimed
```

This lifecycle is repeated millions of times in a busy Spring Boot service.

---

# 💡 Key Takeaways

✅ The JVM Heap stores all Java objects.

✅ The heap is shared by every Java thread.

✅ New objects are allocated in the Young Generation, usually in Eden Space.

✅ Objects that survive multiple garbage collections are promoted to the Old Generation.

✅ The Garbage Collector automatically reclaims unreachable objects.

✅ Heap size is controlled using `-Xms` and `-Xmx`.

✅ Docker and Kubernetes memory limits must account for the entire JVM process—not just the Java heap.

---

# ➡️ Next Chapter

📘 **`04-JVM/04-Stack.md`**

In the next chapter, we'll study the **Java Thread Stack** in detail.

You'll learn:

* 🧵 Stack Frames
* 📞 Method Invocation
* 📍 Local Variables
* 🔙 Return Addresses
* ⚡ Recursive Calls
* 💥 `StackOverflowError`
* 🧪 Tools such as `jstack` and thread dumps

By the end of the next chapter, you'll understand exactly how every method call in your Spring Boot application is represented inside the JVM.
