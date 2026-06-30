# 📘 Chapter 34 — JVM Memory Model

> 📂 File: `student-results-api-notes/04-JVM/09-JVM-Memory.md`

This chapter is the capstone of the JVM memory section.

Up to this point, you've covered each memory area individually:

☕ Heap
🧵 Stack
📚 Metaspace
🗑️ Garbage Collection

Now it's time to put everything together into one complete JVM memory map.

After reading this chapter, someone should be able to answer:

When I execute GET /students/1051110244, where exactly is every byte stored inside the JVM?

This chapter should connect Linux virtual memory, JVM memory, Tomcat, Spring Boot, Docker, and Kubernetes into one complete picture.

---

# 🌍 Introduction

In the previous chapters we explored the JVM memory areas individually:

* ☕ Heap
* 🧵 Java Stack
* 📚 Metaspace
* 🗑️ Garbage Collection
* ⚡ JIT Compiler
* 🧵 JVM Threads

Now let's combine everything into one complete JVM memory model.

When you execute:

```bash
java -jar student-results-api.jar
```

Linux creates one Java process.

Inside that process, the JVM creates several memory regions, each with a different purpose.

Understanding this complete memory layout is essential for debugging:

* Memory leaks
* OutOfMemoryError
* StackOverflowError
* High GC pauses
* Container OOM kills
* Thread issues

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🧠 Complete JVM memory layout
* ☕ Heap
* 🧵 Java Stacks
* 📚 Metaspace
* 🖥️ Program Counter Registers
* 📦 Native Method Stack
* ⚡ Code Cache
* 💾 Direct Memory
* 🧩 JVM Native Memory
* 🍃 Spring Boot memory usage
* 🐳 Docker memory
* ☸️ Kubernetes memory
* 🧪 JVM memory debugging

---

# ❓ Why Does the JVM Need Multiple Memory Areas?

Suppose everything lived in one huge memory block.

That would mix together:

* Objects
* Methods
* Class definitions
* Thread execution
* Native code
* JVM metadata

Instead, the JVM separates memory by responsibility.

Each memory region is optimized for its specific purpose.

---

# 🏗️ Complete JVM Memory Architecture

```text
                    Java Process
                           │
                           ▼

+--------------------------------------------------------------+
|                      JVM Runtime                             |
|--------------------------------------------------------------|
| 🧵 Java Stack (Thread 1)                                     |
| 🧵 Java Stack (Thread 2)                                     |
| 🧵 Java Stack (Thread N)                                     |
|--------------------------------------------------------------|
| ☕ Heap                                                      |
|   🌱 Eden                                                    |
|   🌱 Survivor Spaces                                         |
|   👴 Old Generation                                          |
|--------------------------------------------------------------|
| 📚 Metaspace                                                 |
|--------------------------------------------------------------|
| 🖥️ Program Counter Registers                                 |
|--------------------------------------------------------------|
| 📦 Native Method Stack                                       |
|--------------------------------------------------------------|
| ⚡ Code Cache (JIT Compiled Machine Code)                    |
|--------------------------------------------------------------|
| 💾 Direct Memory (NIO Buffers)                               |
|--------------------------------------------------------------|
| 🔗 JNI Libraries                                             |
+--------------------------------------------------------------+
                           │
                           ▼
                    Linux Virtual Memory
                           │
                           ▼
                      Physical RAM
```

Every byte of your Java application belongs to one of these regions.

---

# ☕ Heap

Purpose:

Store Java objects.

Examples:

```java
Student

StudentResponse

ArrayList

HashMap

ObjectMapper

String
```

Shared by:

```text
All Java Threads
```

Managed by:

```text
Garbage Collector
```

---

# 🧵 Java Stack

Purpose:

Execute Java methods.

Each thread owns:

```text
Own Stack

↓

Stack Frames

↓

Local Variables

↓

Operand Stack

↓

Return Address
```

Destroyed automatically when the thread exits.

---

# 📚 Metaspace

Purpose:

Store class metadata.

Examples:

```text
Student.class

StudentController.class

DispatcherServlet.class

SpringApplication.class
```

Metaspace stores **definitions**, not object instances.

---

# 🖥️ Program Counter Register

Every Java thread owns a Program Counter (PC).

Purpose:

```text
Current Bytecode Instruction
```

Conceptually:

```text
Controller()

↓

Instruction #18

↓

Next Instruction #19
```

The PC allows a thread to resume execution after context switches.

---

# 📦 Native Method Stack

Some Java methods invoke native code through JNI.

Example:

```text
Java

↓

JNI

↓

Native C Library

↓

Linux System Call
```

Native execution uses the Native Method Stack.

---

# ⚡ Code Cache

The JIT Compiler generates native machine code.

Example:

```text
StudentService.getStudent()

↓

Hot Method

↓

Machine Code

↓

Code Cache
```

Instead of interpreting bytecode repeatedly, the JVM executes optimized native code stored here.

---

# 💾 Direct Memory

Not all memory allocations occur on the Heap.

Example:

```java
ByteBuffer.allocateDirect(...)
```

Memory:

```text
Outside Heap

↓

Native Memory
```

Common users:

* Netty
* NIO
* Tomcat
* Kafka
* PostgreSQL drivers

Direct buffers reduce data copying during I/O operations.

---

# 🧩 JVM Native Memory

The JVM itself requires native memory.

Examples:

* Thread stacks
* Metaspace
* Code Cache
* JNI
* GC structures
* Internal runtime data

These allocations are **not** part of the Java Heap.

---

# 🍃 Student Results API Example

Request:

```http
GET /students/1051110244
```

Execution:

```text
Browser

↓

Tomcat Thread

↓

Controller()

↓

Service()

↓

Repository()

↓

Hibernate

↓

PostgreSQL
```

Memory usage:

```text
Stack

↓

Method Frames

----------------------------

Heap

↓

Student

↓

StudentResponse

↓

ArrayList

----------------------------

Metaspace

↓

Student.class

↓

Controller.class

----------------------------

Code Cache

↓

Optimized Machine Code
```

All these memory areas work together to serve a single request.

---

# 🧠 Complete Memory Flow

```text
HTTP Request

↓

Tomcat Thread

↓

Java Stack

↓

Method Calls

↓

Heap Allocation

↓

Student Object

↓

Garbage Collection

↓

Response Sent
```

At the same time:

```text
Metaspace

↓

Class Metadata

-----------------------

Code Cache

↓

Optimized Machine Code

-----------------------

Direct Memory

↓

Socket Buffers
```

Everything happens inside one JVM process.

---

# 🐳 Docker Perspective

Suppose:

```bash
docker run --memory=1g student-api
```

Container memory includes:

```text
Heap

+

Metaspace

+

Thread Stacks

+

Direct Memory

+

Code Cache

+

JNI

+

GC

+

JVM Native Structures
```

Important:

```text
Container Limit

≠

Heap Size
```

If:

```text
Heap = 900 MB

+

Other JVM Memory = 250 MB
```

Then:

```text
Total = 1.15 GB

↓

OOM Kill
```

Even though the Heap itself never exceeded 900 MB.

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

Recommended sizing:

```text
1 Gi Container

↓

700 MB Heap

↓

120 MB Metaspace

↓

80 MB Thread Stacks

↓

50 MB Direct Memory

↓

30 MB Code Cache

↓

Remaining Native Memory
```

Always reserve headroom for native allocations.

---

# 🧪 Hands-on Lab

## Display Heap

```bash
jcmd <PID> GC.heap_info
```

---

## Display Native Memory

```bash
jcmd <PID> VM.native_memory summary
```

Observe:

* Heap
* Metaspace
* Code Cache
* Threads
* Class
* Compiler
* Internal

---

## Display Thread Dump

```bash
jstack <PID>
```

---

## Display Heap Histogram

```bash
jmap -histo <PID>
```

---

## Monitor Garbage Collection

```bash
jstat -gc <PID> 1000
```

---

## Display Class Loader Statistics

```bash
jcmd <PID> VM.classloader_stats
```

---

## Display JVM Flags

```bash
java -XX:+PrintFlagsFinal -version
```

Useful options include:

* `MaxHeapSize`
* `ThreadStackSize`
* `MaxMetaspaceSize`
* `ReservedCodeCacheSize`

---

# 📈 Complete JVM Memory Map

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
+---------------------------------------------------------+
|                    JVM PROCESS                          |
|---------------------------------------------------------|
| 🧵 Stack → Controller → Service → Repository            |
|---------------------------------------------------------|
| ☕ Heap → Student → StudentResponse → ArrayList         |
|---------------------------------------------------------|
| 📚 Metaspace → Student.class → Controller.class         |
|---------------------------------------------------------|
| ⚡ Code Cache → Optimized Machine Code                  |
|---------------------------------------------------------|
| 💾 Direct Memory → Socket Buffers                       |
|---------------------------------------------------------|
| 🖥️ PC Register → Current Instruction                   |
|---------------------------------------------------------|
| 📦 Native Stack → JNI                                  |
+---------------------------------------------------------+
                       │
                       ▼
                Linux Virtual Memory
                       │
                       ▼
                  Physical RAM
```

This is the complete runtime memory layout for your Student Results API.

---

# 🧪 Memory Debugging Checklist

When investigating JVM memory issues:

### ☕ Heap Problems

Use:

```bash
jmap -histo
```

or

```bash
jcmd <PID> GC.heap_info
```

---

### 📚 Metaspace Problems

Use:

```bash
jcmd <PID> VM.classloader_stats
```

---

### 🧵 Thread Problems

Use:

```bash
jstack <PID>
```

or

```bash
top -H -p <PID>
```

---

### 💾 Native Memory Problems

Use:

```bash
jcmd <PID> VM.native_memory summary
```

---

### GC Problems

Use:

```bash
jstat -gc <PID>
```

or enable:

```bash
-Xlog:gc*
```

---

# 💡 Key Takeaways

✅ The JVM divides memory into specialized regions, each with a unique purpose.

✅ The Heap stores Java objects, while Java Stacks store method execution state.

✅ Metaspace stores class metadata, and the Code Cache stores JIT-compiled native code.

✅ Direct Memory and other native allocations exist outside the Java Heap but still count toward total process memory.

✅ Every Java thread owns its own Stack and Program Counter, while all threads share the Heap and Metaspace.

✅ Docker and Kubernetes memory limits apply to the **entire JVM process**, not just the Heap.

✅ Understanding the complete JVM memory model is essential for diagnosing memory leaks, GC issues, thread problems, and container OOM events.

---

# ➡️ Next Chapter

📘 **`04-JVM/10-JVM-Execution-Journey.md`**

In the next chapter, we'll combine everything you've learned across Linux and the JVM.

We'll follow one HTTP request from:

```text
Browser
    │
    ▼
Linux TCP Socket
    │
    ▼
Tomcat
    │
    ▼
Java Thread
    │
    ▼
Class Loader
    │
    ▼
Heap
    │
    ▼
Stack
    │
    ▼
JIT-Compiled Machine Code
    │
    ▼
Garbage Collector
    │
    ▼
JSON Response
```

By the end of that chapter, you'll understand the complete execution journey—from a browser click to CPU instructions executing on the processor.
