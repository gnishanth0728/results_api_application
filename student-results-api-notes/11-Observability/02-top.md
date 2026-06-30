# 📘 Chapter 94 — Linux `top` Command

> 📂 File: `student-results-api-notes/11-Observability/02-top.md`

---

# 🌍 Introduction

In the previous chapter, we learned about the **`ps`** command.

`ps` shows:

```text
Current Process Table
```

But another important question appears:

> 🤔 **How do we monitor processes continuously?**

Suppose:

```text
Java

↓

CPU

20%

↓

65%

↓

90%
```

Running `ps` repeatedly is inefficient.

The answer is:

# 📊 top

`top` provides a continuously updating view of Linux processes and system resource usage.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📊 What `top` is
* ❤️ CPU Usage
* 💾 Memory Usage
* 📈 Load Average
* 🏃 Process States
* 🧵 Threads
* 🔍 Sorting Processes
* 🐳 Monitoring Containers
* ☸️ Monitoring Kubernetes Nodes
* 🚀 Performance Troubleshooting

---

# ❓ What Is `top`?

`top` is an interactive, real-time process monitoring tool.

Unlike:

```bash
ps
```

which provides a one-time snapshot,

```bash
top
```

refreshes continuously (typically every 3 seconds).

---

# 🏗️ High-Level View

Run:

```bash
top
```

Typical display:

```text
top - 10:20:01 up 5 days

Tasks: 210 total

%Cpu(s): ...

MiB Mem : ...

PID USER %CPU %MEM COMMAND
```

The screen updates automatically.

---

# ❤️ CPU Section

Example:

```text
%Cpu(s):

us

sy

ni

id

wa

hi

si

st
```

Meaning:

| Field | Description                            |
| ----- | -------------------------------------- |
| us    | User-space CPU time                    |
| sy    | Kernel (system) CPU time               |
| ni    | Nice priority CPU time                 |
| id    | Idle CPU time                          |
| wa    | Waiting for I/O                        |
| hi    | Hardware interrupt time                |
| si    | Software interrupt time                |
| st    | Stolen time (virtualized environments) |

Example:

```text
id = 95%
```

means the CPU is mostly idle.

---

# 💾 Memory Section

Example:

```text
MiB Mem

Total

Free

Used

Buff/Cache
```

Important fields:

| Field      | Meaning                                                                      |
| ---------- | ---------------------------------------------------------------------------- |
| Total      | Installed RAM                                                                |
| Free       | Completely unused RAM                                                        |
| Used       | Memory currently in use                                                      |
| Buff/Cache | Memory used for filesystem cache and buffers                                 |
| Available  | Estimate of memory available without swapping (shown on most modern systems) |

Linux intentionally uses free RAM for caching to improve performance.

---

# 📈 Load Average

Example:

```text
load average:

0.25

0.80

1.15
```

Represents the average number of runnable or uninterruptible tasks over:

* Last 1 minute
* Last 5 minutes
* Last 15 minutes

Interpretation depends on CPU count.

Example:

```text
8 CPU cores

Load = 8
```

Approximately indicates the CPUs are fully utilized.

---

# 📊 Process List

Example:

```text
PID USER %CPU %MEM COMMAND
```

Typical entry:

```text
3245 root 84.2 12.1 java
```

Columns:

| Column  | Meaning                 |
| ------- | ----------------------- |
| PID     | Process ID              |
| USER    | Process owner           |
| %CPU    | CPU utilization         |
| %MEM    | Memory utilization      |
| TIME+   | Total CPU time consumed |
| COMMAND | Executable name         |

---

# 🏃 Process States

Common states:

| State | Meaning                                      |
| ----- | -------------------------------------------- |
| R     | Running or runnable                          |
| S     | Sleeping (interruptible)                     |
| D     | Uninterruptible sleep (often waiting on I/O) |
| T     | Stopped                                      |
| Z     | Zombie                                       |

Example:

```text
java

↓

R
```

means the process is currently running or ready to run.

---

# 🔍 Sorting

Interactive keys:

| Key   | Action                       |
| ----- | ---------------------------- |
| **P** | Sort by CPU usage            |
| **M** | Sort by memory usage         |
| **T** | Sort by accumulated CPU time |
| **N** | Sort by PID                  |

These shortcuts help identify resource-intensive processes quickly.

---

# 🔎 Searching

Press:

```text
L
```

Enter:

```text
java
```

`top` highlights matching processes.

---

# 🧵 Threads

View threads:

```bash
top -H
```

Example:

```text
Java

↓

GC Thread

↓

Worker Thread

↓

HTTP Thread
```

This is useful when diagnosing multithreaded applications.

---

# 🍃 Student Results API Example

Suppose:

```text
Student Results API

↓

High Traffic
```

Run:

```bash
top
```

Observe:

```text
java

CPU

90%
```

The Java process moves to the top of the display.

---

# 🐳 Docker Example

Find the container process:

```bash
docker top <container-id>
```

On the host:

```bash
top
```

You will see the container's processes because containers are simply Linux processes.

---

# ☸️ Kubernetes Example

On a worker node:

```bash
top
```

You may observe:

```text
kubelet

containerd

java

kube-proxy
```

If a Pod receives heavy traffic, its application process will consume more CPU.

---

# 📊 Complete Process Hierarchy

```text
systemd
      │
      ▼
containerd
      │
      ▼
containerd-shim
      │
      ▼
java
      │
      ▼
JVM Threads
```

`top` shows the resource usage of these processes in real time.

---

# 🧪 Hands-on Lab

## Start `top`

```bash
top
```

Observe:

* CPU
* Memory
* Load Average
* Running Processes

Exit:

```text
q
```

---

## Sort by CPU

While `top` is running, press:

```text
P
```

Observe the highest CPU consumers.

---

## Sort by Memory

Press:

```text
M
```

Observe the highest memory consumers.

---

## View Threads

```bash
top -H
```

Notice that Java threads appear individually.

---

## Monitor Java

Open another terminal:

```bash
java -jar student-results-api.jar
```

Return to `top`.

Observe:

```text
java

CPU

Memory
```

---

## Monitor Kubernetes Node

SSH into a worker node:

```bash
top
```

Observe Kubernetes components:

* kubelet
* containerd
* java
* systemd

---

# 🚫 Common Mistakes

## ❌ Thinking High Memory Means a Memory Leak

Linux uses RAM aggressively for filesystem caches.

Always examine:

* Available memory
* Swap usage
* Process RSS

before concluding that there is a memory leak.

---

## ❌ Confusing Load Average with CPU Percentage

Load average is **not** a percentage.

It represents the average number of runnable or uninterruptible tasks.

Interpret it relative to the number of CPU cores.

---

## ❌ Assuming `top` Updates Automatically Forever

`top` refreshes until you quit it.

Press:

```text
q
```

to exit.

---

# 📊 Useful `top` Commands

| Command         | Purpose                     |
| --------------- | --------------------------- |
| `top`           | Real-time system monitoring |
| `top -H`        | Display individual threads  |
| `top -p <PID>`  | Monitor a specific process  |
| `top -u <user>` | Show processes for one user |
| `top -d 1`      | Refresh every second        |

---

# 📈 `ps` vs `top`

| `ps`                     | `top`                                |
| ------------------------ | ------------------------------------ |
| Snapshot                 | Real-time monitoring                 |
| One-time output          | Continuously updates                 |
| Good for scripting       | Good for interactive troubleshooting |
| Displays process details | Displays live resource usage         |

---

# 💡 Key Takeaways

✅ `top` is an interactive tool for real-time monitoring of Linux processes and system resources.

✅ It displays CPU usage, memory usage, load average, process states, and running processes.

✅ Interactive sorting makes it easy to identify CPU-intensive or memory-intensive processes.

✅ `top -H` is valuable for investigating multithreaded applications such as the JVM.

✅ Docker containers and Kubernetes Pods ultimately appear as ordinary Linux processes that can be monitored with `top`.

✅ `ps` and `top` complement each other: `ps` provides a snapshot, while `top` provides a live view.

---

# ➡️ Next Chapter

📘 **`11-Observability/03-htop.md`**

In the next chapter, we'll explore **`htop`**, a modern, interactive alternative to `top`.

We'll cover:

* 🎨 Color-coded CPU and memory graphs
* 🧵 Tree view of processes
* 🖱️ Interactive process management
* 🔍 Search and filtering
* 📊 Easier navigation for troubleshooting Docker and Kubernetes workloads

By the end of the chapter, you'll know when to use `top` and when `htop` provides a more efficient troubleshooting experience.
