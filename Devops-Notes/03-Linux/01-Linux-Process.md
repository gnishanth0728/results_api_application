# 📘 Chapter 16 — Linux Processes

> 📂 File: `student-results-api-notes/03-Linux/01-Linux-Process.md`

---

# 🌍 Introduction

When you start your Student Results API:

```bash
java -jar student-results-api.jar
```

it may look like "Java is running."

But from the Linux kernel's perspective, something much more interesting happens.

Linux does **not** understand:

* ☕ Java
* 🐍 Python
* 🟢 Node.js
* 🦀 Rust
* 🔵 Go

Linux only understands one thing:

# ⚙️ Processes

Everything running on Linux is ultimately a process.

Whether it's:

* 🍃 Spring Boot
* 🐘 PostgreSQL
* 🌐 Nginx
* 🐳 Docker
* ☸️ kubelet
* 📦 containerd
* 🧵 systemd

they are all Linux processes.

Understanding processes means understanding the foundation of Docker and Kubernetes.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* ⚙️ What a process is
* 📄 Program vs Process
* 🚀 Process creation
* 🧠 Process memory layout
* 📂 Process Control Block (PCB)
* 🆔 Process IDs (PID)
* 👨 Parent and Child Processes
* 🧵 Threads
* 🔄 Process lifecycle
* 📁 File descriptors
* 🌍 Environment variables
* 🐳 Containers as processes
* ☸️ Kubernetes Pods and processes
* 🧪 Linux debugging tools

---

# ❓ What Is a Process?

A **program** is a file stored on disk.

Example:

```text
/usr/bin/java
```

or

```text
student-results-api.jar
```

These files are passive.

They do nothing by themselves.

When Linux loads a program into memory and begins executing it, it becomes a **process**.

---

# 📦 Program vs Process

```text
          📄 Program

student-results-api.jar

        (Stored on Disk)

                │

         java -jar

                │

                ▼

          ⚙️ Process

PID = 7065

Running in RAM
```

A useful analogy:

| Program       | Process                    |
| ------------- | -------------------------- |
| Recipe 📖     | Cooking 🍳                 |
| Blueprint 🏗️ | Building 🏢                |
| Movie File 🎬 | Movie Playing ▶️           |
| JAR File 📦   | Running Java Application ☕ |

---

# 🚀 Starting Your Spring Boot Application

When you execute:

```bash
java -jar student-results-api.jar
```

the shell (`bash`) does **not** execute the JAR directly.

The sequence is:

```text
bash

↓

fork()

↓

Child Process

↓

execve()

↓

Java Executable

↓

JVM Starts

↓

Spring Boot Starts

↓

Tomcat Starts
```

The important point:

Linux starts the **Java executable**, not the JAR.

The JAR is simply an input file passed to the JVM.

---

# 🧠 Process Creation

Linux creates a process using two important system calls.

### 1️⃣ fork()

Creates a new process.

```text
Parent Process

↓

fork()

↓

Child Process
```

Initially, the child is almost an identical copy of the parent.

---

### 2️⃣ execve()

The child replaces its memory with a new executable.

```text
Child Process

↓

execve()

↓

/usr/bin/java
```

Now the child becomes the Java Virtual Machine (JVM).

---

# 👨 Parent and Child Processes

Example:

```text
systemd (PID 1)

↓

sshd

↓

bash

↓

java

↓

Tomcat

↓

Spring Boot
```

Every process (except PID 1) has a parent.

View the hierarchy:

```bash
pstree -p
```

---

# 🆔 Process ID (PID)

Every process has a unique identifier.

Example:

```text
PID = 7065
```

View running processes:

```bash
ps -ef
```

Find Java:

```bash
ps -ef | grep java
```

Example:

```text
ubuntu 7065 ... java -jar student-results-api.jar
```

---

# 📂 Process Control Block (PCB)

The Linux kernel stores metadata about every process in an internal structure called the **Process Control Block (PCB)** (represented in Linux by `task_struct`).

Conceptually:

```text
+--------------------------------------+
| Process Control Block                |
|--------------------------------------|
| PID                                  |
| Parent PID                           |
| Process State                        |
| CPU Registers                        |
| Memory Mapping                       |
| Scheduling Information               |
| Open File Descriptors                |
| Credentials (UID/GID)                |
| Signal Handlers                      |
+--------------------------------------+
```

The PCB is how the kernel tracks and manages every running process.

---

# 🧠 Process Memory Layout

When the JVM starts, Linux allocates a virtual address space.

```text
 High Memory
+---------------------------+
| 🧱 Stack                  |
+---------------------------+
| 📚 Shared Libraries       |
+---------------------------+
| 🏞️ Heap                   |
+---------------------------+
| 📦 Data Segment           |
+---------------------------+
| ⚙️ Text (Machine Code)    |
+---------------------------+
 Low Memory
```

### ⚙️ Text Segment

Contains executable machine instructions.

### 📦 Data Segment

Stores initialized global/static variables.

### 🏞️ Heap

Dynamic memory allocated during runtime.

The JVM creates the Java heap here.

### 🧱 Stack

Each thread has its own stack.

Stores:

* Local variables
* Method calls
* Return addresses

---

# 🌍 Environment Variables

Every process receives an environment.

Example:

```bash
env
```

Typical variables:

```text
JAVA_HOME
PATH
HOME
USER
LANG
```

Spring Boot commonly uses environment variables for configuration:

```text
SPRING_PROFILES_ACTIVE=prod
DB_HOST=postgres
DB_PORT=5432
```

View a running process's environment:

```bash
cat /proc/<PID>/environ | tr '\0' '\n'
```

---

# 📁 File Descriptors

Linux treats almost everything as a file.

A process owns file descriptors such as:

```text
0 → stdin
1 → stdout
2 → stderr
3 → Socket
4 → Socket
5 → Log File
```

Inspect them:

```bash
ls -l /proc/<PID>/fd
```

You may see:

```text
socket:[38492]
socket:[38501]
```

Tomcat communicates through these socket file descriptors.

---

# 🧵 Processes vs Threads

A process owns resources.

Threads execute work inside the process.

```text
Java Process (PID 7065)

├── Main Thread
├── GC Thread
├── Compiler Thread
├── http-nio-8080-exec-1
├── http-nio-8080-exec-2
├── http-nio-8080-exec-3
└── ...
```

During your ApacheBench load test:

```bash
ab -n 50000 -c 200 http://localhost:8080/students/1051110244
```

you observed many:

```text
http-nio-8080-exec-XX
```

These are **threads**, not separate processes.

---

# 🔄 Process Lifecycle

```text
NEW
 │
 ▼
READY
 │
 ▼
RUNNING
 │
 ├────────► WAITING
 │              │
 ▼              │
TERMINATED ◄────┘
```

The Linux scheduler moves processes between these states.

---

# 📊 Process Hierarchy for Your API

```text
systemd (PID 1)
      │
      ▼
sshd
      │
      ▼
bash
      │
      ▼
java -jar student-results-api.jar
      │
      ▼
JVM
      │
      ▼
Tomcat
      │
      ▼
Spring Boot
```

Although we speak of "Tomcat" and "Spring Boot", they execute **inside the same Java process**.

---

# 🐳 Docker Perspective

This is where containers become much easier to understand.

Without Docker:

```text
Host

↓

Java Process (PID 7065)
```

With Docker:

```text
Host

↓

containerd

↓

runc

↓

Java Process

(PID inside container = 1)
```

The application is **still just a Linux process**.

Docker adds:

* Process isolation (Namespaces)
* Resource limits (cgroups)
* Filesystem isolation
* Network isolation

It does **not** invent a new execution model.

---

# ☸️ Kubernetes Perspective

Kubernetes also runs ordinary Linux processes.

```text
Node

↓

containerd

↓

Pod Sandbox

↓

Java Process

↓

Tomcat

↓

Spring Boot
```

Pods schedule and manage processes, but the kernel still executes them as standard Linux processes.

---

# 🧪 Hands-on Lab

## Start the Application

```bash
java -jar student-results-api.jar
```

---

## Find the Process

```bash
ps -ef | grep java
```

---

## Display the Process Tree

```bash
pstree -p
```

---

## Monitor the Process

```bash
top -p <PID>
```

or

```bash
htop
```

---

## View Process Status

```bash
cat /proc/<PID>/status
```

Observe:

* PID
* PPID
* Threads
* Memory usage
* Process state

---

## View Memory Maps

```bash
cat /proc/<PID>/maps
```

This displays the virtual memory regions allocated to the JVM.

---

## List File Descriptors

```bash
ls -l /proc/<PID>/fd
```

Notice:

* JAR file
* Log files
* Network sockets
* Standard input/output

---

# 💡 Key Takeaways

✅ A program is a file on disk; a process is a running instance of that program.

✅ Linux creates processes using `fork()` and `execve()`.

✅ Every process has a unique PID and a parent process.

✅ The kernel tracks processes using the Process Control Block (`task_struct`).

✅ Each process has its own virtual memory, environment variables, and open file descriptors.

✅ Threads execute inside a process and share its memory.

✅ Docker containers and Kubernetes Pods ultimately run ordinary Linux processes managed by the kernel.

---

# ➡️ Next Chapter

📘 **`03-Linux/02-Linux-Threads.md`**

In the next chapter we'll answer one of the most common interview questions:

> **How can one Java process handle hundreds of HTTP requests simultaneously?**

We'll explore:

* 🧵 What a thread is
* 🧠 Kernel threads vs user threads
* ☕ JVM thread model
* ⚙️ Linux scheduler
* 🔄 Context switching
* 🍃 Tomcat thread pools
* 🧪 Inspecting threads with `ps -Lf`, `top -H`, `jstack`, and `/proc`

By the end of the next chapter, you'll understand exactly how your Spring Boot application handled the concurrent ApacheBench load tests you ran earlier.
