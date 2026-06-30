# 📘 Chapter 95 — JVM `jstack`

> 📂 File: `student-results-api-notes/11-Observability/03-jstack.md`

This chapter introduces one of the most important JVM troubleshooting tools.

So far in the Observability section, you've learned how to monitor Linux processes using:

ps
↓

top

These tools answer questions like:

Is the Java process running?
How much CPU is it using?
How much memory is it consuming?

But another important question appears:

What is the Java process actually doing?

Suppose your Spring Boot application stops responding.

Browser

↓

GET /students

↓

Loading...

CPU usage is low.

Memory usage looks normal.

The Java process is still alive.

Yet the application is frozen.

Linux tools such as ps and top cannot answer:

Which thread is blocked?
Is there a deadlock?
Which method is executing?
Which SQL query is waiting?
Which thread owns a lock?
What is Tomcat doing?
Which HTTP request is stuck?

The answer is:

jstack

jstack captures a thread dump of a running JVM.

It shows every Java thread, its current state, the methods it is executing, and the locks it owns or is waiting for.

For Java production support, jstack is one of the first tools used to diagnose:

Deadlocks
Hung applications
High CPU threads
Blocked requests
Thread pool exhaustion
Lock contention

This chapter explains jstack from JVM threads down to real Spring Boot troubleshooting.

---

# 🌍 Introduction

In the previous chapters we learned:

```text
ps

↓

Linux Processes
```

and

```text
top

↓

Real-Time CPU & Memory
```

These tools observe the operating system.

But another important question appears:

> 🤔 **What is happening inside the JVM?**

Suppose:

```text
Java Process

↓

Running

↓

Application Frozen
```

Linux only knows:

```text
PID 2451

java
```

It has no knowledge of:

* Java threads
* Stack frames
* Locks
* Monitors
* Deadlocks

The JVM provides:

# ☕ jstack

`jstack` captures a snapshot of every thread inside a running JVM.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* ☕ What `jstack` is
* 🧵 JVM Threads
* 📚 Stack Frames
* 🔒 Locks & Monitors
* 💥 Deadlocks
* ⏳ Blocked Threads
* 🌐 Tomcat Worker Threads
* 🍃 Spring Boot Debugging
* 🐳 Docker Usage
* ☸️ Kubernetes Usage

---

# ❓ What Is `jstack`?

`jstack` is a JDK diagnostic tool.

It connects to a running JVM and prints:

* All Java threads
* Native threads
* Thread states
* Stack traces
* Lock ownership
* Deadlock information

Example:

```bash
jstack <PID>
```

---

# 🏗️ JVM Architecture

```text
Java Process
      │
      ▼
JVM
      │
      ▼
Thread 1

Thread 2

Thread 3

GC Thread

Compiler Thread
```

Each thread has its own stack.

---

# 🧵 JVM Threads

Example Spring Boot application:

```text
JVM

├── main

├── http-nio-8080-exec-1

├── http-nio-8080-exec-2

├── GC Thread

├── Compiler Thread

└── Finalizer
```

Every thread appears in a thread dump.

---

# 📚 Stack Frames

Suppose:

```java
StudentController

↓

StudentService

↓

StudentRepository
```

The stack looks like:

```text
StudentRepository.find()

↓

StudentService.getStudent()

↓

StudentController.getStudent()
```

`jstack` prints the complete call stack for each thread.

---

# 🔒 Thread States

Common JVM thread states:

| State         | Meaning                                 |
| ------------- | --------------------------------------- |
| RUNNABLE      | Running or ready to run                 |
| BLOCKED       | Waiting to acquire a monitor lock       |
| WAITING       | Waiting indefinitely for another thread |
| TIMED_WAITING | Waiting with a timeout                  |
| TERMINATED    | Thread has completed execution          |

Example:

```text
http-nio-8080-exec-3

↓

BLOCKED
```

This often indicates lock contention.

---

# 🌐 Tomcat Worker Threads

Suppose five users send requests.

```text
Browser

↓

Tomcat

↓

Worker Threads
```

Thread pool:

```text
http-nio-8080-exec-1

http-nio-8080-exec-2

http-nio-8080-exec-3

http-nio-8080-exec-4

http-nio-8080-exec-5
```

`jstack` shows what every worker thread is doing.

---

# 🍃 Student Results API Example

Suppose:

```text
GET /students/1051110001
```

Execution:

```text
Controller

↓

Service

↓

Repository

↓

PostgreSQL
```

Thread dump:

```text
http-nio-8080-exec-2

↓

StudentRepository.findByRollNumber()

↓

JDBC Driver

↓

Socket.read()
```

This immediately tells you the thread is waiting for the database.

---

# 🔒 Deadlock Example

Thread A:

```text
Lock Student

↓

Waiting Order
```

Thread B:

```text
Lock Order

↓

Waiting Student
```

Neither thread can continue.

`jstack` reports:

```text
Found one Java-level deadlock:
```

along with the threads and locks involved.

---

# ⚡ High CPU Investigation

Suppose:

```text
top

↓

java

↓

CPU 100%
```

Steps:

1. Find the Java PID:

```bash
ps -ef | grep java
```

2. Capture a thread dump:

```bash
jstack <PID> > thread_dump.txt
```

3. Look for:

* RUNNABLE threads
* Infinite loops
* Busy computations

A common workflow is to correlate a high-CPU native thread from `top -H` with the corresponding Java thread in the thread dump.

---

# 🐳 Docker Example

Find the Java process:

```bash
docker exec -it <container-id> ps -ef
```

Capture the dump:

```bash
docker exec -it <container-id> jstack <PID>
```

The JDK (or equivalent diagnostic tooling) must be present in the container.

---

# ☸️ Kubernetes Example

Get the Pod:

```bash
kubectl get pods
```

Open a shell:

```bash
kubectl exec -it student-api-pod -- sh
```

Find the PID:

```bash
ps -ef | grep java
```

Capture:

```bash
jstack <PID>
```

Or redirect it:

```bash
jstack <PID> > /tmp/thread_dump.txt
```

Copy it locally:

```bash
kubectl cp student-api-pod:/tmp/thread_dump.txt .
```

---

# 📊 Example Thread Dump

```text
"http-nio-8080-exec-3"

RUNNABLE

at StudentRepository.find()

at StudentService.getStudent()

at StudentController.getStudent()
```

Reading from bottom to top shows how the thread reached its current method.

---

# 📊 Thread Relationships

```text
JVM

├── main

├── GC

├── Compiler

├── http-nio-8080-exec-1

├── http-nio-8080-exec-2

└── Finalizer
```

Every thread has:

* Thread ID
* State
* Stack frames
* Lock information

---

# 🧪 Hands-on Lab

## Find Java Process

```bash
ps -ef | grep java
```

---

## Capture Thread Dump

```bash
jstack <PID>
```

---

## Save Thread Dump

```bash
jstack <PID> > thread_dump.txt
```

Open the file:

```bash
less thread_dump.txt
```

---

## Search Worker Threads

```bash
grep "http-nio" thread_dump.txt
```

---

## Search BLOCKED Threads

```bash
grep BLOCKED thread_dump.txt
```

---

## Search Deadlocks

```bash
grep deadlock thread_dump.txt
```

---

# 🚫 Common Mistakes

## ❌ Thinking `jstack` Shows CPU Usage

`jstack` shows **thread execution state**, not CPU utilization.

Use:

```text
top

+

jstack
```

together for performance analysis.

---

## ❌ Thinking Every WAITING Thread Is a Problem

Many JVM threads spend most of their time waiting.

For example:

* Thread pools waiting for work
* Garbage collection helper threads
* Scheduler threads

This is usually normal.

---

## ❌ Assuming Thread Dumps Change the Application

`jstack` is a diagnostic tool.

Capturing a thread dump is generally safe and does not modify application behavior.

---

# 📊 Common Commands

| Command                   | Purpose                       |
| ------------------------- | ----------------------------- |
| `jstack <PID>`            | Print thread dump             |
| `jstack <PID> > dump.txt` | Save thread dump              |
| `ps -ef \| grep java`     | Find Java PID                 |
| `top -H -p <PID>`         | View JVM threads in real time |
| `kubectl exec`            | Run `jstack` inside a Pod     |

---

# 📈 Linux vs JVM Observability

```text
ps
↓

Process Exists

----------------

top
↓

CPU & Memory

----------------

jstack
↓

What Every Java Thread Is Doing
```

Each tool answers a different layer of the troubleshooting stack.

---

# 💡 Key Takeaways

✅ `jstack` captures a snapshot of every thread in a running JVM.

✅ A thread dump includes thread states, stack frames, lock ownership, and deadlock information.

✅ `jstack` is invaluable for diagnosing hung applications, deadlocks, blocked threads, and request processing issues.

✅ Tomcat worker threads, Spring Boot application threads, garbage collection threads, and JVM internal threads all appear in the thread dump.

✅ Combining `ps`, `top`, and `jstack` provides a powerful workflow for Java production troubleshooting.

---

# ➡️ Next Chapter

📘 **`11-Observability/04-jmap.md`**

In the next chapter, we'll explore **`jmap`**.

We'll answer questions such as:

* 💾 How much heap memory is the JVM using?
* 🗂️ Which Java objects occupy the most memory?
* 🧠 How do you generate a heap dump?
* 🐞 How do you investigate memory leaks using Eclipse MAT or VisualVM?

By the end of the chapter, you'll understand how to analyze JVM memory usage and diagnose memory-related production issues.
