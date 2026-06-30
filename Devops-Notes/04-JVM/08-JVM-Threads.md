# 📘 Chapter 33 — JVM Threads

> 📂 File: `student-results-api-notes/04-JVM/08-JVM-Threads.md`

This chapter connects everything you've learned about Linux threads with how the JVM implements Java threads.

It's one of the most practical chapters because it explains exactly what happened when you ran:

ab -n 50000 -c 200 http://localhost:8080/students/1051110244

and observed:

http-nio-8080-exec-*
GC Thread
VM Thread
Reference Handler
Finalizer
top -H
ps -Lf
jstack

After this chapter, a reader should be able to correlate every Java thread with the Linux thread executing it

---

# 🌍 Introduction

Earlier in the Linux module we learned:

* 🧵 Linux Threads
* ⚖️ Linux Scheduler
* 🔄 Context Switching
* ⚡ epoll
* 📂 `/proc/<PID>/task`

Now let's answer an important question:

> 🤔 **How are Java threads related to Linux threads?**

Suppose you start your Student Results API:

```bash
java -jar student-results-api.jar
```

Initially Linux creates:

```text
One Java Process
```

Inside that process the JVM creates many threads.

Later when Tomcat starts:

```text
http-nio-8080-exec-1

http-nio-8080-exec-2

...

http-nio-8080-exec-200
```

But Linux only understands **native threads**.

So where do Java threads actually execute?

That is the purpose of this chapter.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🧵 Java Threads
* 🖥️ Native Threads
* 🔄 JVM Thread Model
* ⚙️ Thread Lifecycle
* 🍃 Tomcat Worker Threads
* 🗑️ GC Threads
* ⚡ JIT Compiler Threads
* 💤 Thread States
* 📊 Thread Dumps
* 🐳 Docker
* ☸️ Kubernetes
* 🧪 Thread Debugging

---

# ❓ What Is a Java Thread?

A Java thread is an execution path inside the JVM.

Example:

```java
new Thread(() -> {

    System.out.println("Hello");

}).start();
```

Every thread executes independently.

Each thread owns:

* 🧵 Java Stack
* 📍 Program Counter
* 🧠 CPU Registers (through the native thread)
* 📝 Local Variables

All threads share:

* ☕ Heap
* 📚 Metaspace
* 🗑️ Garbage Collector

---

# 🏗️ JVM Thread Architecture

```text
                    JVM

+------------------------------------------------+

      Thread 1

      Stack

---------------------------------------------

      Thread 2

      Stack

---------------------------------------------

      Thread 3

      Stack

---------------------------------------------

           Shared Heap

---------------------------------------------

          Shared Metaspace

+------------------------------------------------+
```

Every thread executes independently while sharing application objects.

---

# 🖥️ JVM Threads vs Linux Threads

Modern JVMs use a **1:1 threading model**.

```text
Java Thread

↓

Native Thread

↓

Linux Scheduler

↓

CPU Core
```

Each Java thread maps directly to one operating system thread.

---

# 📊 One-to-One Mapping

Suppose:

```java
ExecutorService executor =
Executors.newFixedThreadPool(4);
```

JVM creates:

```text
Java Thread 1

↓

Linux Thread 7105

-----------------------

Java Thread 2

↓

Linux Thread 7106

-----------------------

Java Thread 3

↓

Linux Thread 7109

-----------------------

Java Thread 4

↓

Linux Thread 7112
```

Linux schedules these native threads exactly like any other process.

---

# 🍃 Tomcat Worker Threads

During your load test:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Tomcat created threads similar to:

```text
http-nio-8080-exec-1

http-nio-8080-exec-2

...

http-nio-8080-exec-200
```

Each worker thread:

```text
Browser Request

↓

Tomcat Thread

↓

Controller

↓

Service

↓

Repository

↓

PostgreSQL

↓

JSON Response
```

Every concurrent request is processed by one worker thread.

---

# 📈 Thread Lifecycle

```text
NEW

↓

RUNNABLE

↓

RUNNING

↓

WAITING

↓

RUNNABLE

↓

TERMINATED
```

The scheduler continuously moves threads between these states.

---

# 💤 Common Thread States

| State         | Meaning                        |
| ------------- | ------------------------------ |
| NEW           | Thread created but not started |
| RUNNABLE      | Ready to execute               |
| BLOCKED       | Waiting for a monitor lock     |
| WAITING       | Waiting indefinitely           |
| TIMED_WAITING | Waiting with timeout           |
| TERMINATED    | Execution finished             |

These states appear in `jstack` thread dumps.

---

# 🍃 Request Processing Example

Suppose:

```http
GET /students/1051110244
```

Execution:

```text
Browser

↓

Tomcat Worker Thread

↓

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

While PostgreSQL is processing:

```text
Thread

↓

WAITING

↓

Linux Scheduler

↓

Runs Another Thread
```

This is why your CPU usage stayed low during the load test.

---

# 🗑️ JVM Internal Threads

The JVM creates many threads automatically.

Typical examples:

```text
Reference Handler

Finalizer

Signal Dispatcher

Attach Listener

VM Thread

GC Thread

Compiler Thread

Service Thread
```

You did not create these threads.

The JVM uses them internally.

---

# ⚡ Compiler Threads

The JIT compiler runs in dedicated background threads.

```text
Application Thread

↓

Method Gets Hot

↓

Compiler Thread

↓

Native Machine Code
```

This allows compilation without blocking application requests.

---

# 🗑️ Garbage Collector Threads

GC also runs on its own threads.

```text
Application

↓

Creates Objects

↓

Heap Grows

↓

GC Thread

↓

Reclaims Memory
```

Modern collectors often use multiple GC threads in parallel.

---

# 📊 Thread Dump

A thread dump displays every thread.

Example:

```bash
jstack <PID>
```

Output:

```text
"http-nio-8080-exec-23"

RUNNABLE

↓

StudentController

↓

StudentService

↓

StudentRepository
```

Thread dumps are one of the most useful debugging tools.

---

# 🧠 Thread Stack Example

During request execution:

```text
Top

Repository()

↓

Service()

↓

Controller()

↓

DispatcherServlet()

↓

Tomcat()

Bottom
```

Each method call creates one stack frame.

---

# 🍃 Your Load Test

You observed:

```bash
top -H -p 7065
```

Output:

```text
http-nio-8080-exec-7

0.7%

http-nio-8080-exec-8

0.3%

VM Thread

GC Thread
```

Interpretation:

* Some worker threads were actively executing requests.
* Many worker threads were sleeping, waiting for work.
* JVM background threads handled compilation and garbage collection.
* Linux scheduled all of these native threads.

---

# 🔄 JVM Threads and Linux Scheduler

Execution pipeline:

```text
Java Thread

↓

Native Thread

↓

Linux Scheduler

↓

Context Switch

↓

CPU

↓

Execute Bytecode

↓

JIT Machine Code
```

The JVM creates the threads.

Linux decides when they run.

---

# 🐳 Docker Perspective

Inside Docker:

```text
Container

↓

Java Process

↓

JVM Threads

↓

Linux Native Threads

↓

Host Scheduler
```

Containers do **not** provide a separate scheduler.

The host Linux kernel schedules every thread.

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

Linux Scheduler

↓

CPU
```

Kubernetes schedules Pods to nodes.

Linux schedules threads to CPU cores.

These are two different scheduling layers.

---

# 🧪 Hands-on Lab

## Display Java Threads

```bash
jstack <PID>
```

---

## Print Thread Dump

```bash
jcmd <PID> Thread.print
```

Observe:

* Thread names
* States
* Stack traces

---

## Display Linux Threads

```bash
ps -Lf -p <PID>
```

Compare the number of native threads with the Java thread dump.

---

## Monitor Threads

```bash
top -H -p <PID>
```

Observe per-thread CPU usage.

---

## Count Threads

```bash
ls /proc/<PID>/task | wc -l
```

The number should closely match the thread count reported by `jstack`.

---

## Run Concurrent Requests

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

During the test:

```bash
jstack <PID>
```

Observe many `http-nio-8080-exec-*` threads serving requests concurrently.

---

# 📈 Complete Thread Journey

```text
Browser
      │
      ▼
HTTP Request
      │
      ▼
Tomcat Accept Thread
      │
      ▼
Tomcat Worker Thread
      │
      ▼
Java Stack
      │
      ▼
Controller
      │
      ▼
Service
      │
      ▼
Repository
      │
      ▼
PostgreSQL
      │
      ▼
JSON Response
      │
      ▼
Thread Returns to Pool
```

This cycle repeats for every incoming request.

---

# 💡 Key Takeaways

✅ Every Java thread maps to one native operating system thread.

✅ Each thread owns its own Java Stack and Program Counter.

✅ All threads share the Heap and Metaspace.

✅ The JVM creates internal threads for Garbage Collection, JIT compilation, and runtime management.

✅ Tomcat processes concurrent HTTP requests using a pool of worker threads.

✅ Linux—not the JVM—decides when each native thread runs on a CPU core.

✅ `jstack`, `jcmd`, `top -H`, `ps -Lf`, and `/proc/<PID>/task` are essential tools for understanding thread behavior in real applications.

---

# ➡️ Next Chapter

📘 **`04-JVM/09-JVM-Monitoring.md`**

In the next chapter, we'll learn how to inspect a live JVM in production.

We'll explore:

* 🔍 `jps`
* 📊 `jcmd`
* 🧵 `jstack`
* ☕ `jmap`
* 📈 `jstat`
* 🖥️ VisualVM
* 📉 Java Flight Recorder (JFR)
* 📋 Thread dumps
* 💾 Heap dumps
* 🔥 Performance troubleshooting

By the end of the next chapter, you'll be able to diagnose CPU spikes, memory leaks, deadlocks, excessive GC, and thread contention in your Student Results API using the JVM's built-in diagnostic tools.
