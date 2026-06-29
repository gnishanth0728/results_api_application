# 📘 Chapter 17 — Linux Threads

> 📂 File: `student-results-api-notes/03-Linux/02-Linux-Thread.md`

---

# 🌍 Introduction

In the previous chapter we learned:

```text
student-results-api.jar

↓

Java Process (PID 7065)
```

Only **one Java process** was running.

However, during your load test:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

you observed dozens of threads:

```text
http-nio-8080-exec-1
http-nio-8080-exec-2
http-nio-8080-exec-3
...
http-nio-8080-exec-200
```

This raises an important question:

> 🤔 If there is only one Java process, how can hundreds of requests execute simultaneously?

The answer is:

# 🧵 Threads

A thread is the **smallest unit of execution** that the Linux scheduler can run.

A process owns resources.

Threads perform the work.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🧵 What a thread is
* ⚙️ Process vs Thread
* 🧠 Linux thread implementation
* ☕ JVM thread model
* 🍃 Tomcat worker threads
* 🗂️ Thread stacks
* 🧠 Shared heap
* 🔄 Context switching
* ⚖️ Linux scheduler
* 🖥️ CPU cores
* 🧪 Linux thread debugging
* 🐳 Threads inside containers
* ☸️ Kubernetes thread execution

---

# ❓ Why Threads Exist

Imagine a Spring Boot application without threads.

```text
Browser

↓

Request 1

↓

Java Process

↓

Controller

↓

Database

↓

Response

↓

Request 2

↓

Request 3

↓

Request 4
```

Every request would wait for the previous one to finish.

One slow database query would block every user.

This is unacceptable for a web server.

Threads solve this problem.

---

# 🏗️ Process vs Thread

## Process

Owns resources:

* Virtual memory
* Heap
* File descriptors
* Environment variables
* Sockets

```text
Java Process

↓

Heap

↓

Files

↓

Sockets
```

---

## Thread

Executes instructions.

```text
Thread

↓

Run Java Code

↓

Controller

↓

Service

↓

Repository
```

Many threads can exist inside one process.

---

# 🧠 Process with Multiple Threads

Your Spring Boot application looks like this:

```text
                 Java Process (PID 7065)

+------------------------------------------------+

🧠 JVM Heap (Shared)

─────────────────────────────────────────────────

🧵 Main Thread

🧵 GC Thread

🧵 JIT Compiler Thread

🧵 Reference Handler

🧵 Signal Dispatcher

🧵 http-nio-8080-exec-1

🧵 http-nio-8080-exec-2

🧵 http-nio-8080-exec-3

🧵 http-nio-8080-exec-...

+------------------------------------------------+
```

All worker threads belong to the same Java process.

---

# 📦 Shared vs Private Memory

Threads share most resources.

```text
                 Process

+--------------------------------------+

Shared Heap

Shared File Descriptors

Shared Sockets

Shared Environment

----------------------------------------

Thread 1 Stack

Thread 2 Stack

Thread 3 Stack

+--------------------------------------+
```

Shared:

* Heap
* Objects
* Database connections
* Static variables

Private:

* Stack
* CPU registers
* Program counter

---

# 🧱 Thread Stack

Every thread receives its own stack.

```text
Thread 1

+---------------------+

Method A

Method B

Local Variables

Return Address

+---------------------+

Thread 2

+---------------------+

Method X

Method Y

Local Variables

+---------------------+
```

Local variables are **not shared** between threads.

This prevents one request from overwriting another request's local variables.

---

# ☕ JVM Thread Model

The JVM creates many threads automatically.

Typical thread types:

```text
Main Thread

↓

GC Threads

↓

JIT Compiler Threads

↓

Signal Dispatcher

↓

Reference Handler

↓

Tomcat Worker Threads
```

Even before the first HTTP request arrives, the JVM is already multi-threaded.

---

# 🍃 Tomcat Thread Pool

When Spring Boot starts:

```text
Tomcat Started on Port 8080
```

Tomcat creates a thread pool.

Conceptually:

```text
Incoming Request

↓

Accept Queue

↓

Thread Pool

↓

http-nio-8080-exec-1

↓

Controller
```

Each request is assigned to an available worker thread.

---

# 🔄 One Request = One Worker Thread

Suppose five users access the API simultaneously.

```text
Request 1

↓

exec-1

↓

StudentController

────────────────────────────

Request 2

↓

exec-2

↓

StudentController

────────────────────────────

Request 3

↓

exec-3

↓

StudentController
```

Each request executes independently.

---

# 🖥️ Threads and CPU Cores

Threads do **not** run automatically.

The Linux scheduler decides which thread gets CPU time.

Example:

```text
CPU Core 0

↓

exec-1

↓

exec-2

↓

GC Thread

↓

exec-5
```

If multiple CPU cores exist:

```text
Core 0 → exec-1

Core 1 → exec-2

Core 2 → GC

Core 3 → exec-3
```

Several threads can truly execute in parallel.

---

# ⚖️ Linux Scheduler

Linux maintains a queue of runnable threads.

```text
Runnable Queue

↓

Thread A

↓

Thread B

↓

Thread C

↓

Thread D
```

The scheduler selects the next thread to execute based on scheduling policies and priorities.

---

# 🔄 Context Switching

Suppose Thread A is running.

The scheduler interrupts it.

```text
Thread A

↓

Save CPU Registers

↓

Load Thread B Registers

↓

Thread B Runs
```

This operation is called a **context switch**.

Although very fast, excessive context switching reduces performance.

---

# 📊 Real ApacheBench Example

During your test:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

You observed:

```text
http-nio-8080-exec-1

http-nio-8080-exec-2

http-nio-8080-exec-3

...

http-nio-8080-exec-200
```

Each worker thread processed one request at a time.

As requests completed, those threads were reused for new requests.

---

# 🔄 Thread Lifecycle

```text
NEW
 │
 ▼
RUNNABLE
 │
 ▼
RUNNING
 │
 ├────────► WAITING
 │              │
 ▼              │
TERMINATED ◄────┘
```

Examples:

* Waiting for database I/O
* Waiting for network data
* Sleeping
* Blocked on locks

---

# 🔒 Thread Safety

Because threads share the heap, shared objects require careful synchronization.

Example:

```java
private int counter = 0;
```

If two threads execute:

```java
counter++;
```

simultaneously, one update may be lost.

Solutions include:

* `synchronized`
* `ReentrantLock`
* `AtomicInteger`
* Concurrent collections

Fortunately, Spring Controllers are typically stateless, making them naturally thread-safe.

---

# 🧪 Hands-on Lab

## Find Java Process

```bash
ps -ef | grep java
```

---

## Display Threads

```bash
ps -Lf -p <PID>
```

Example:

```text
PID   LWP

7065 7065

7065 7105

7065 7106

7065 7112
```

`LWP` (Light Weight Process) represents a Linux thread.

---

## Monitor Individual Threads

```bash
top -H -p <PID>
```

Each row represents one thread.

During a load test you'll observe:

```text
http-nio-8080-exec-*

GC Thread

VM Thread
```

consuming CPU.

---

## Generate Load

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

In another terminal:

```bash
watch -n1 "ps -Lf -p <PID>"
```

Observe the thread count increasing as Tomcat serves concurrent requests.

---

## Capture JVM Thread Dump

```bash
jstack <PID>
```

This displays every Java thread and its current stack trace.

---

# 🐳 Docker Perspective

Inside Docker:

```text
Container

↓

Java Process

↓

Thread Pool

↓

exec-1

exec-2

exec-3
```

Threads work exactly the same way.

Docker does **not** create or manage Java threads.

The JVM creates them, and the Linux kernel schedules them.

---

# ☸️ Kubernetes Perspective

Inside Kubernetes:

```text
Pod

↓

Container

↓

Java Process

↓

Tomcat Threads

↓

HTTP Requests
```

The Pod schedules the container.

The JVM manages threads.

The Linux scheduler runs those threads on the node's CPUs.

---

# 📈 Complete Execution Flow

```text
Browser

↓

HTTP Request

↓

Tomcat Accept Thread

↓

Thread Pool

↓

http-nio-8080-exec-17

↓

DispatcherServlet

↓

StudentController

↓

StudentService

↓

Repository

↓

PostgreSQL

↓

JSON Response
```

Every incoming request follows this pattern.

---

# 💡 Key Takeaways

✅ A process owns resources; threads perform execution.

✅ All Tomcat worker threads belong to the same Java process.

✅ Threads share the heap but have separate stacks.

✅ The Linux scheduler decides which thread runs on which CPU core.

✅ Context switching allows many threads to share CPUs efficiently.

✅ Tomcat uses a thread pool to process HTTP requests concurrently.

✅ Docker and Kubernetes do not change the thread model—they run ordinary Linux processes and threads.

---

# ➡️ Next Chapter

📘 **`03-Linux/03-Linux-Scheduler.md`**

In the next chapter we'll dive even deeper into the Linux kernel and answer:

> **How does Linux decide which thread runs next?**

We'll explore:

* ⚖️ Completely Fair Scheduler (CFS)
* 🧮 Virtual Runtime (`vruntime`)
* 🏃 Run Queues
* 🖥️ CPU Affinity
* 🔄 Context Switch Internals
* 📊 CPU Time Slices
* ⚡ Scheduler classes
* 🧪 Tools such as `top`, `htop`, `perf`, `pidstat`, and `/proc/sched_debug`

By the end of the next chapter, you'll understand how the Linux kernel schedules the Tomcat worker threads that processed your Student Results API requests under heavy load.
