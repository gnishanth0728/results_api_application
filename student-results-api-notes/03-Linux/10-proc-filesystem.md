# 📘 Chapter 25 — The Linux `/proc` Filesystem

This is an excellent chapter to end the Linux fundamentals because /proc is where everything you've learned becomes visible.

After studying processes, threads, memory, scheduling, sockets, epoll, file descriptors, and context switching, /proc lets you inspect all of them from a running system.

Your Student Results API becomes the perfect real-world example.

> 📂 File: `student-results-api-notes/03-Linux/10-proc-filesystem.md`

---

# 🌍 Introduction

Throughout this handbook, we've explored many Linux concepts:

* ⚙️ Processes
* 🧵 Threads
* 🧠 Virtual Memory
* ☕ Heap & Stack
* 📄 File Descriptors
* 🔌 Sockets
* ⚡ epoll
* 🔄 Context Switching

But one question remains:

> 🤔 **How can we actually see all of this on a running Linux system?**

The answer is:

# 📂 `/proc`

The `/proc` filesystem is a **virtual filesystem** created by the Linux kernel.

It does **not** exist on disk.

Instead, the kernel generates its contents dynamically whenever you access it.

Almost every Linux monitoring tool reads information from `/proc`.

Examples:

* `ps`
* `top`
* `htop`
* `free`
* `lsof`
* `vmstat`
* `pidstat`
* `systemd`
* `docker`
* `kubelet`

Even these tools ultimately rely on data exposed through `/proc`.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📂 What `/proc` is
* 🧠 Why Linux created `/proc`
* 📁 Process directories
* 📄 Important `/proc` files
* 🧵 Thread information
* 🧠 Memory information
* 🔌 Socket information
* 📊 CPU statistics
* 🍃 Inspecting your Student Results API
* 🐳 Docker and `/proc`
* ☸️ Kubernetes and `/proc`
* 🧪 Linux debugging

---

# ❓ Why Does `/proc` Exist?

Suppose Linux had no `/proc`.

How would you discover:

* Which processes are running?
* How much memory a process uses?
* How many threads it owns?
* Which sockets are open?
* What environment variables it received?

Without `/proc`, debugging Linux systems would be extremely difficult.

The kernel solves this by exposing internal information as files.

---

# 🏗️ What Is `/proc`?

Unlike normal filesystems:

```text
/home
/etc
/usr
```

`/proc` contains **kernel-generated files**.

```text
Application

↓

open("/proc/...")

↓

Linux Kernel

↓

Generate Data

↓

Return File Contents
```

No data is stored permanently on disk.

---

# 📂 High-Level Layout

```text
/proc

├── cpuinfo
├── meminfo
├── uptime
├── version
├── stat
├── loadavg
├── net/
├── sys/
├── self/
├── 1/
├── 7065/
├── 9201/
└── ...
```

Directories whose names are numbers correspond to **process IDs (PIDs)**.

---

# 🆔 Process Directories

Suppose your Spring Boot application is:

```text
PID = 7065
```

Linux creates:

```text
/proc/7065/
```

Everything about that process is available here.

---

# 📁 Important Files Inside a Process Directory

```text
/proc/7065/

├── cmdline
├── cwd
├── environ
├── exe
├── fd/
├── maps
├── smaps
├── mem
├── mountinfo
├── net/
├── sched
├── stat
├── status
├── task/
└── limits
```

Each file exposes a different aspect of the running process.

---

# 📄 `cmdline`

Shows the command used to start the process.

```bash
cat /proc/7065/cmdline
```

Example:

```text
java
-jar
student-results-api.jar
```

Useful when identifying running applications.

---

# 📄 `status`

One of the most useful files.

```bash
cat /proc/7065/status
```

Example output:

```text
Name: java

Pid: 7065

PPid: 6858

State: S (sleeping)

Threads: 226

VmSize: 3624956 kB

VmRSS: 306960 kB
```

This single file summarizes:

* Process state
* Memory
* Thread count
* User IDs
* Group IDs
* Capabilities

---

# 🧵 `task/`

Every Linux thread has its own directory.

```text
/proc/7065/task/

7065

7105

7106

7112

...
```

Each subdirectory represents one thread (Light Weight Process).

View them:

```bash
ls /proc/7065/task
```

This corresponds to what you saw with:

```bash
ps -Lf -p 7065
```

---

# 📄 `fd/`

Shows every open file descriptor.

```bash
ls -l /proc/7065/fd
```

Example:

```text
0 -> /dev/pts/0

1 -> /dev/pts/0

2 -> /dev/pts/0

3 -> socket:[38492]

4 -> socket:[38501]

5 -> student-results-api.jar

6 -> app.log
```

This confirms that sockets, files, and terminals all use the same file descriptor abstraction.

---

# 🧠 `maps`

Displays the virtual memory layout.

```bash
cat /proc/7065/maps
```

Typical regions:

```text
Code

Heap

Stack

Shared Libraries

Anonymous Memory
```

This corresponds to the virtual memory layout discussed in the previous chapter.

---

# 📊 `smaps`

Provides detailed memory statistics for each mapped region.

```bash
cat /proc/7065/smaps
```

Information includes:

* RSS
* PSS
* Shared memory
* Private memory
* Anonymous pages

This is useful for advanced memory analysis.

---

# 🌍 `environ`

Displays environment variables passed to the process.

```bash
cat /proc/7065/environ | tr '\0' '\n'
```

Example:

```text
JAVA_HOME=/usr/lib/jvm/java-21

PATH=/usr/bin

SPRING_PROFILES_ACTIVE=prod

DB_HOST=postgres
```

Spring Boot commonly reads configuration from these variables.

---

# 🔗 `exe`

Shows the executable file backing the process.

```bash
ls -l /proc/7065/exe
```

Example:

```text
/usr/bin/java
```

Notice that the executable is **Java**, not the JAR file.

The JAR is simply an input to the JVM.

---

# 🖥️ `cwd`

Displays the process's current working directory.

```bash
ls -l /proc/7065/cwd
```

Useful when diagnosing relative file paths.

---

# 📊 `sched`

Shows scheduler statistics.

```bash
cat /proc/7065/sched
```

Example information:

* Runtime
* Scheduling policy
* CPU execution time
* Context switches

Useful when investigating scheduling behavior.

---

# 📈 `limits`

Shows resource limits.

```bash
cat /proc/7065/limits
```

Example:

```text
Max open files

Max processes

Max stack size
```

These limits affect:

* File descriptors
* Thread creation
* Stack allocation

---

# 🌐 System-Wide `/proc` Files

Not everything in `/proc` belongs to a process.

Useful files include:

## CPU Information

```bash
cat /proc/cpuinfo
```

Shows:

* CPU model
* Cores
* Cache
* Features

---

## Memory Information

```bash
cat /proc/meminfo
```

Shows:

* Total RAM
* Free RAM
* Buffers
* Cache
* Swap

Equivalent to what `free -h` summarizes.

---

## Uptime

```bash
cat /proc/uptime
```

Shows:

* System uptime
* Idle time

---

## Load Average

```bash
cat /proc/loadavg
```

Equivalent to the load averages shown by `top`.

---

## Network Statistics

```bash
cat /proc/net/tcp
```

Displays active TCP sockets.

Most users prefer:

```bash
ss -tan
```

which formats the same information more readably.

---

# 🍃 Student Results API Walkthrough

Suppose your API PID is:

```text
7065
```

You can inspect:

```bash
cat /proc/7065/status
```

↓

```text
Threads: 226
```

↓

```bash
ls /proc/7065/task
```

↓

```text
226 Thread Directories
```

↓

```bash
ls -l /proc/7065/fd
```

↓

```text
Socket FDs

JAR

Log File
```

↓

```bash
cat /proc/7065/maps
```

↓

```text
Heap

Stack

Libraries
```

Everything you've learned throughout the Linux section is visible from `/proc`.

---

# 🐳 Docker Perspective

Containers do **not** have a separate kernel.

Inside a container:

```bash
cat /proc/self/status
```

shows information for the container's process.

Because PID namespaces are used:

Inside the container:

```text
PID = 1
```

On the host:

```text
PID = 18452
```

Both refer to the same process viewed through different PID namespaces.

---

# ☸️ Kubernetes Perspective

Inside a Pod:

```bash
kubectl exec -it student-api -- sh
```

then:

```bash
cat /proc/self/status
```

You can inspect:

* Memory
* Threads
* File descriptors
* Limits
* Scheduler statistics

This is one of the most useful debugging techniques in Kubernetes.

---

# 🧪 Hands-on Lab

## Find the Java Process

```bash
ps -ef | grep java
```

Assume PID:

```text
7065
```

---

## View Process Summary

```bash
cat /proc/7065/status
```

---

## List Threads

```bash
ls /proc/7065/task
```

---

## Inspect Open File Descriptors

```bash
ls -l /proc/7065/fd
```

---

## View Environment Variables

```bash
cat /proc/7065/environ | tr '\0' '\n'
```

---

## Display Virtual Memory Map

```bash
cat /proc/7065/maps
```

---

## View Scheduler Statistics

```bash
cat /proc/7065/sched
```

---

## View Resource Limits

```bash
cat /proc/7065/limits
```

---

## Display System Memory

```bash
cat /proc/meminfo
```

---

## Display CPU Information

```bash
cat /proc/cpuinfo
```

---

# 📈 Complete Linux Introspection Flow

```text
Student Results API

↓

Java Process (PID 7065)

↓

/proc/7065/

├── status

├── task/

├── fd/

├── maps

├── environ

├── sched

├── limits

↓

Linux Kernel

↓

Live Runtime Information
```

---

# 💡 Key Takeaways

✅ `/proc` is a virtual filesystem generated dynamically by the Linux kernel.

✅ Every running process has its own directory under `/proc/<PID>/`.

✅ Files such as `status`, `maps`, `fd`, `task`, and `environ` expose live process information.

✅ Tools like `ps`, `top`, `lsof`, `free`, and `htop` read data from `/proc`.

✅ Docker containers and Kubernetes Pods expose the same `/proc` interface, but PID namespaces can change the process IDs you see inside the container.

✅ Mastering `/proc` gives you direct visibility into how Linux manages processes, threads, memory, networking, and resources.

---

# 🎉 Linux Module Complete

Congratulations! You now understand the complete Linux execution model behind your Student Results API.

```text
Power On
    │
    ▼
Linux Kernel
    │
    ▼
Process
    │
    ▼
Threads
    │
    ▼
Virtual Memory
    │
    ▼
Heap & Stack
    │
    ▼
File Descriptors
    │
    ▼
Sockets
    │
    ▼
epoll
    │
    ▼
Scheduler
    │
    ▼
Context Switch
    │
    ▼
/proc Filesystem
    │
    ▼
Spring Boot API Running 🚀
```

---

# ➡️ Next Module

📦 **`04-JVM-Internals/01-JVM-Architecture.md`**

In the next module, you'll move from Linux into the Java Virtual Machine itself.

You'll learn:

* ☕ JVM Architecture
* 📦 Class Loader
* 🧠 Runtime Data Areas
* 🗑️ Garbage Collection
* ⚡ JIT Compiler
* 🔄 Bytecode Execution
* 🧵 JVM Thread Model
* 📊 JVM Monitoring Tools (`jcmd`, `jstack`, `jmap`, `jstat`, `jconsole`, `VisualVM`)

By combining the Linux concepts you've learned with JVM internals, you'll understand the complete path from **CPU → Linux Kernel → JVM → Spring Boot → HTTP Request**.
