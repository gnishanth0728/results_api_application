# 📘 Chapter 18 — Linux Scheduler (CFS)

> 📂 File: `student-results-api-notes/03-Linux/03-Scheduler.md`

---

# 🌍 Introduction

In the previous chapter we learned:

```text
Java Process (PID 7065)

↓

200 Tomcat Threads
```

During your ApacheBench test:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Tomcat created many worker threads.

But another question immediately appears:

> 🤔 If the server has only **2 CPU cores**, how can 200 threads run?

The answer is:

# ⚖️ Linux Scheduler

The scheduler is one of the most important components of the Linux kernel.

It decides:

* Which thread runs next
* Which CPU executes it
* How long it runs
* When it should stop
* Which waiting thread should run afterward

Without the scheduler, multitasking would not exist.

---

# 🎯 Learning Objectives

After this chapter you will understand:

* ⚖️ What a scheduler is
* 🧠 Why scheduling exists
* 🖥️ CPU cores vs threads
* 🏃 Runnable queues
* 📊 Time slicing
* 🔄 Context switching
* ⚡ Completely Fair Scheduler (CFS)
* 📈 Virtual Runtime (vruntime)
* 🎯 CPU affinity
* 💤 Sleeping threads
* 🍃 Tomcat scheduling
* 🐳 Docker scheduling
* ☸️ Kubernetes scheduling (node-level)
* 🧪 Linux scheduler debugging

---

# ❓ Why Does Linux Need a Scheduler?

Suppose your machine has:

```text
CPU Cores = 2
```

Your JVM has:

```text
Main Thread

GC Thread

Compiler Thread

Reference Handler

VM Thread

http-nio-8080-exec-1

...

http-nio-8080-exec-200
```

That's over **200 runnable threads**.

Since only two CPU cores exist, Linux must decide:

> "Who runs now?"

That decision belongs to the scheduler.

---

# 🖥️ CPU Core vs Thread

Many people confuse CPU cores with software threads.

### CPU Core

A physical execution engine.

Example:

```text
Core 0

Core 1

Core 2

Core 3
```

A core executes machine instructions.

---

### Software Thread

A sequence of instructions waiting to execute.

Example:

```text
Thread A

Thread B

Thread C

Thread D
```

Threads are created by programs.

CPU cores execute them.

---

# 🏗️ The Scheduling Problem

Suppose:

```text
CPU Cores = 2

Threads = 8
```

Impossible:

```text
Core 0

Thread 1

Thread 2

Thread 3

Thread 4

Core 1

Thread 5

Thread 6

Thread 7

Thread 8
```

Instead Linux rapidly switches between runnable threads.

To the user it appears everything runs simultaneously.

---

# 🏃 Runnable Queue

Every CPU maintains a run queue.

```text
CPU 0

Run Queue

↓

Thread A

↓

Thread B

↓

Thread C

↓

Thread D
```

The scheduler selects the next runnable thread from this queue.

---

# ⏱️ Time Slice

Linux gives each runnable thread a small amount of CPU time.

```text
Thread A

↓

5 ms

↓

Thread B

↓

5 ms

↓

Thread C

↓

5 ms
```

The exact duration depends on system load and scheduler calculations.

---

# 🔄 Context Switching

When a thread's time slice ends, Linux performs a context switch.

```text
Thread A Running

↓

Save Registers

↓

Save Stack Pointer

↓

Load Thread B Registers

↓

Thread B Running
```

The CPU does not lose the work done by Thread A—it simply saves its state and resumes it later.

---

# ⚡ Completely Fair Scheduler (CFS)

Modern Linux uses the **Completely Fair Scheduler (CFS)** for normal tasks.

Its goal is simple:

> Every runnable thread should receive a fair share of CPU time.

CFS does **not** use a simple round-robin queue.

Instead, it tracks how much CPU time each thread has already consumed.

---

# 📈 Virtual Runtime (vruntime)

Each thread has a **virtual runtime**.

```text
Thread A

vruntime = 10

Thread B

vruntime = 20

Thread C

vruntime = 5
```

The scheduler prefers the thread with the **smallest** `vruntime`, because it has received the least CPU time so far.

This keeps CPU allocation fair across runnable threads.

---

# 🌳 Red-Black Tree

Internally, CFS stores runnable threads in a balanced Red-Black Tree.

Conceptually:

```text
          Thread B (20)

         /             \

Thread C (5)      Thread D (30)

      \

    Thread A (10)
```

The left-most node has the smallest `vruntime` and is selected to run next.

This allows efficient scheduling even with thousands of threads.

---

# 💤 Sleeping Threads

Not every thread is runnable.

Example:

```text
Thread

↓

Waiting for PostgreSQL

↓

Sleeping
```

Sleeping threads consume **no CPU time**.

During your Student Results API requests, many Tomcat threads spend most of their lifetime waiting for:

* PostgreSQL
* Disk I/O
* Network responses

This explains why your CPU usage remained low even with hundreds of concurrent requests.

---

# 🍃 Tomcat Example

Suppose 200 users access your API.

```text
Requests

↓

Tomcat Thread Pool

↓

200 Worker Threads
```

Linux may only execute a few of them simultaneously.

Most worker threads are blocked waiting for:

```text
PostgreSQL

↓

Socket Read

↓

Network

↓

Disk
```

As soon as a thread blocks, the scheduler immediately chooses another runnable thread.

---

# 🖥️ Multi-Core Scheduling

Example:

```text
Core 0

↓

exec-7

Core 1

↓

exec-19

Core 2

↓

GC Thread

Core 3

↓

exec-25
```

Different CPU cores can execute different threads in parallel.

---

# 🎯 CPU Affinity

Threads are not permanently tied to a CPU.

Linux may migrate them between cores.

Example:

```text
Core 0

↓

Thread A

↓

Core 2

↓

Thread A
```

CPU affinity controls or restricts which CPUs a thread may execute on.

Useful for:

* High-performance systems
* Databases
* Real-time workloads

---

# 📊 Real Student Results API Example

You observed:

```bash
top -H -p 7065
```

Output showed:

```text
http-nio-8080-exec-7

0.7%

http-nio-8080-exec-8

0.3%

GC Thread

0.3%
```

Why?

Because:

* Most worker threads were waiting on PostgreSQL.
* Only a few threads were actively executing Java code.
* The scheduler quickly switched between runnable threads.

---

# 🔄 Scheduler Decision Flow

```text
Runnable Thread?

        │
        ▼

Smallest vruntime?

        │
        ▼

Assign CPU Core

        │
        ▼

Execute

        │
        ▼

Time Slice Ends?

        │
        ▼

Save Context

        │
        ▼

Pick Next Thread
```

This loop runs continuously on every CPU core.

---

# 🐳 Docker Perspective

Containers do not have their own scheduler.

```text
Host Linux Scheduler

↓

Container Process

↓

Java Threads
```

All container threads are scheduled by the **host Linux kernel**.

Docker only isolates processes and can apply CPU limits using cgroups.

---

# ☸️ Kubernetes Perspective

Kubernetes has two different schedulers:

### Kubernetes Scheduler

Schedules **Pods** onto Nodes.

```text
Pod

↓

Node
```

### Linux Scheduler

Schedules **Threads** onto CPU cores.

```text
Tomcat Thread

↓

CPU Core
```

Kubernetes never schedules Java threads.

That responsibility always belongs to the Linux kernel.

---

# 🧪 Hands-on Lab

## Display Threads

```bash
ps -Lf -p <PID>
```

---

## Monitor Thread CPU Usage

```bash
top -H -p <PID>
```

---

## Observe Per-Thread Statistics

```bash
pidstat -t -p <PID> 1
```

---

## Display CPU Information

```bash
lscpu
```

Observe:

* Number of CPUs
* Threads per core
* Cores per socket
* NUMA nodes

---

## Monitor CPU Usage

```bash
mpstat -P ALL 1
```

Shows CPU utilization for each core.

---

## Generate Concurrent Requests

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

In another terminal:

```bash
top -H -p <PID>
```

Watch Tomcat worker threads consume CPU as requests are processed.

---

## View Scheduler Information

```bash
cat /proc/schedstat
```

Advanced users can inspect:

```bash
cat /proc/<PID>/sched
```

to view scheduler statistics for a specific process.

---

# 💡 Key Takeaways

✅ The Linux scheduler decides which runnable thread executes next.

✅ CPU cores execute instructions; threads are units of execution.

✅ The Completely Fair Scheduler (CFS) aims to distribute CPU time fairly using `vruntime`.

✅ Runnable threads wait in per-CPU run queues.

✅ Context switching allows many threads to share a limited number of CPU cores.

✅ Threads blocked on I/O consume little or no CPU, allowing other threads to run.

✅ Docker relies on the host Linux scheduler, while Kubernetes schedules Pods—not individual threads.

---

# ➡️ Next Chapter

📘 **`03-Linux/04-Virtual-Memory.md`**

Next we'll explore one of the most important operating system concepts:

> **How does Linux give every process the illusion that it owns all of memory?**

We'll cover:

* 🧠 Virtual vs Physical Memory
* 📄 Memory Pages
* 🗺️ Page Tables
* 🔄 Address Translation
* 📦 JVM Heap Layout
* 💾 Swap
* ⚡ Page Faults
* 🧪 Tools such as `free`, `vmstat`, `pmap`, `/proc/<PID>/maps`, and `smem`

By the end of that chapter, you'll understand how your Spring Boot application's memory is managed by the Linux kernel and how that knowledge applies directly to Docker containers and Kubernetes Pods.
