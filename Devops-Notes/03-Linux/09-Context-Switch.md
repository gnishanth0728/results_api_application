# 📘 Chapter 24 — Linux Context Switching

This is one of the deepest Linux kernel chapters in your handbook.

After reading it, someone should understand exactly what happens when Linux pauses one Tomcat worker thread and starts another while your Spring Boot application is handling hundreds of concurrent HTTP requests.

This chapter connects:

🖥️ CPU hardware
⚙️ Linux scheduler
🧠 CPU registers
🧵 Java threads
🍃 Tomcat worker threads
🔄 Context switching
🐳 Docker
☸️ Kubernetes

into one complete execution model.


> 📂 File: `student-results-api-notes/03-Linux/09-Context-Switch.md`

---

# 🌍 Introduction

In the previous chapter we learned:

* ⚖️ Linux Scheduler chooses which thread runs.
* ⚡ CFS tries to distribute CPU time fairly.
* 🧵 Tomcat creates many worker threads.
* 🖥️ CPU cores execute only a few threads at a time.

Now another question appears:

> 🤔 What actually happens when Linux stops one thread and starts another?

Consider your Student Results API during this load test:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Tomcat created many worker threads:

```text
http-nio-8080-exec-1

http-nio-8080-exec-2

...

http-nio-8080-exec-200
```

Yet your EC2 instance had only a few CPU cores.

How did Linux make 200 threads appear to run simultaneously?

The answer is:

# 🔄 Context Switching

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🔄 What a context switch is
* ⚙️ Why Linux performs context switches
* 🧠 CPU registers
* 📦 Process Control Block (`task_struct`)
* 🧵 Thread state
* ⚖️ Scheduler interaction
* 🖥️ CPU caches
* 📈 Context switch overhead
* 🍃 Tomcat thread switching
* 🐳 Docker
* ☸️ Kubernetes
* 🧪 Performance monitoring

---

# ❓ Why Context Switching Exists

Suppose:

```text
CPU Cores = 2

Tomcat Threads = 200
```

Clearly:

```text
200 Threads

↓

Cannot Run Together
```

Linux must constantly pause one thread and resume another.

This operation is called a **context switch**.

---

# 🏗️ High-Level Architecture

```text
               CPU Core

+------------------------------+

Running Thread

↓

CPU Registers

↓

Program Counter

↓

Stack Pointer

↓

Execution

+------------------------------+

          ▲

          │

 Linux Scheduler

          │

          ▼

Runnable Queue
```

The scheduler decides *when* to switch.

The context switch mechanism performs the actual transition.

---

# 🧠 What Is a Context?

A thread's **context** is everything required to continue execution later.

It includes:

* Program Counter (Instruction Pointer)
* Stack Pointer
* General-purpose CPU registers
* Processor flags
* Scheduling information
* Kernel stack pointer

Conceptually:

```text
Thread Context

+----------------------+

Instruction Pointer

Stack Pointer

CPU Registers

Flags

Kernel Stack

+----------------------+
```

---

# 🔄 Step-by-Step Context Switch

Imagine:

```text
Currently Running

↓

Thread A
```

Its time slice expires.

The scheduler decides to run:

```text
Thread B
```

The kernel performs:

```text
Thread A

↓

Save CPU Registers

↓

Save Program Counter

↓

Save Stack Pointer

↓

Update task_struct

↓

Load Thread B Registers

↓

Load Thread B Stack Pointer

↓

Load Thread B Program Counter

↓

Resume Thread B
```

From the application's perspective, execution appears to continue normally.

---

# 📦 `task_struct`

Linux stores thread information in the kernel using a structure called:

```text
task_struct
```

Conceptually:

```text
+----------------------------------+

PID

Thread State

Scheduling Info

CPU Registers

Stack Pointer

Memory Mapping

Open File Descriptors

Signal Handlers

CPU Affinity

+----------------------------------+
```

During a context switch, the kernel saves and restores information from this structure.

---

# 🖥️ CPU Registers

Registers are tiny, extremely fast storage locations inside the CPU.

Examples:

* General-purpose registers
* Stack Pointer (SP)
* Program Counter (PC/IP)
* Flags register

When switching threads:

```text
CPU Registers

↓

Save

↓

Load New Registers
```

Without this, the next thread would continue executing the previous thread's instructions.

---

# 🧵 Stack Pointer

Each thread owns its own stack.

Example:

```text
Thread A Stack

↓

Controller()

↓

Service()

↓

Repository()

------------------------

Thread B Stack

↓

Controller()

↓

Service()
```

The kernel restores the correct stack pointer before resuming a thread.

---

# ⚖️ Scheduler and Context Switching

The scheduler decides:

```text
Runnable Thread?

↓

Yes

↓

Smallest vruntime?

↓

Switch
```

The scheduler **does not perform** the switch itself.

Instead:

```text
Scheduler

↓

schedule()

↓

context_switch()

↓

CPU Executes New Thread
```

---

# 🍃 Student Results API Example

During:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Possible execution:

```text
CPU

↓

exec-12

↓

Database Wait

↓

Switch

↓

exec-47

↓

JSON Serialization

↓

Switch

↓

GC Thread

↓

Switch

↓

exec-18
```

Only one thread executes on a CPU core at any instant.

Linux rapidly switches among runnable threads.

---

# 💤 Blocking Reduces Context Switching

Suppose:

```text
Thread

↓

Waiting for PostgreSQL
```

The scheduler immediately selects another runnable thread.

Blocked threads:

* Do not consume CPU.
* Do not compete for CPU time until the blocking operation completes.

This is why your CPU usage stayed relatively low even with hundreds of concurrent requests.

---

# 📉 Context Switch Overhead

Context switching is necessary but not free.

The kernel must:

* Save registers
* Restore registers
* Switch kernel stacks
* Potentially invalidate or disturb CPU caches
* Update scheduling structures

Excessive context switching can reduce throughput.

---

# 🧠 CPU Cache Effects

Modern CPUs contain:

```text
CPU

↓

L1 Cache

↓

L2 Cache

↓

L3 Cache

↓

RAM
```

When switching between unrelated threads:

```text
Thread A Data

↓

Cache

↓

Switch

↓

Thread B Data

↓

Cache Miss
```

Cache misses increase memory latency.

This is one reason excessive switching impacts performance.

---

# 📊 Real Observation from Your API

During testing you observed:

```bash
top -H -p 7065
```

Example:

```text
http-nio-8080-exec-7

0.7%

http-nio-8080-exec-8

0.3%

GC Thread

0.3%
```

Interpretation:

* Most worker threads were sleeping.
* Only a handful were actively running.
* The scheduler continuously rotated runnable threads across CPU cores.

---

# 🔄 Complete Execution Flow

```text
Browser

↓

HTTP Request

↓

Tomcat Accept Thread

↓

Poller Thread (epoll)

↓

Worker Thread

↓

StudentController

↓

StudentService

↓

Repository

↓

PostgreSQL

↓

Thread Blocks

↓

Scheduler

↓

Context Switch

↓

Next Runnable Thread
```

This cycle repeats thousands of times per second on a busy server.

---

# 🐳 Docker Perspective

Containers do **not** perform context switching.

```text
Container

↓

Java Threads

↓

Host Linux Scheduler

↓

Context Switch
```

The host Linux kernel switches between threads from all containers.

---

# ☸️ Kubernetes Perspective

Kubernetes schedules Pods onto nodes.

Linux schedules threads onto CPUs.

```text
Kubernetes Scheduler

↓

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

CPU Core
```

Pod scheduling and thread scheduling are separate responsibilities.

---

# 🧪 Hands-on Lab

## Display Threads

```bash
ps -Lf -p <PID>
```

---

## Monitor Per-Thread CPU Usage

```bash
top -H -p <PID>
```

---

## Observe Context Switch Statistics

```bash
vmstat 1
```

Look at:

```text
cs
```

This column shows the number of context switches per second.

---

## View Per-Process Statistics

```bash
pidstat -w -p <PID> 1
```

Example output:

```text
cswch/s

nvcswch/s
```

* `cswch/s` = voluntary context switches (thread blocks, e.g., waiting for I/O)
* `nvcswch/s` = involuntary context switches (scheduler preempts the thread)

---

## Generate Concurrent Load

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

In another terminal:

```bash
vmstat 1
```

Watch the `cs` column increase as Linux switches between Tomcat worker threads.

---

## View Scheduler Statistics

```bash
cat /proc/<PID>/sched
```

Inspect fields related to scheduling delays and runtime.

---

## Profile with `perf`

```bash
sudo perf sched record
```

Then:

```bash
sudo perf sched latency
```

This provides advanced insight into scheduler latency and context switches.

---

# 📈 Complete Picture

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
                 StudentService
                        │
                        ▼
                  PostgreSQL
                        │
              (Thread Blocks)
                        │
                        ▼
               Linux Scheduler
                        │
                        ▼
              Save Thread Context
                        │
                        ▼
              Load Next Thread Context
                        │
                        ▼
                 CPU Executes
```

Every busy Linux server repeats this sequence continuously.

---

# 💡 Key Takeaways

✅ A context switch pauses one thread and resumes another.

✅ The Linux kernel saves and restores thread state using data stored in `task_struct`.

✅ CPU registers, the program counter, and the stack pointer are essential parts of a thread's execution context.

✅ The scheduler decides *which* thread runs; the context switch mechanism performs the transition.

✅ Blocking operations (such as waiting for PostgreSQL or network I/O) allow other runnable threads to use the CPU efficiently.

✅ Excessive context switching increases CPU overhead and can reduce performance due to cache disruption.

✅ Docker containers and Kubernetes Pods rely entirely on the host Linux kernel for thread scheduling and context switching.

---

# ➡️ Next Chapter

📘 **`03-Linux/10-System-Calls.md`**

Next we'll study the boundary between **user space** and **kernel space**.

We'll answer:

> **How does Java ask Linux to create a socket, allocate memory, read a file, or send an HTTP response?**

We'll cover:

* 📞 System calls
* 🔄 User mode vs kernel mode
* ⚙️ `read()`, `write()`, `socket()`, `accept()`, `epoll_wait()`, `fork()`, `execve()`
* 🧠 CPU privilege levels
* 🍃 Real system calls made by your Spring Boot application
* 🧪 Observing them live with `strace`

By the end of the next chapter, you'll understand every transition between your application code and the Linux kernel.
