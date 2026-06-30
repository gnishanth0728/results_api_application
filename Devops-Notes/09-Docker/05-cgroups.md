# 📘 Chapter 73 — Linux cgroups (Control Groups)

> 📂 File: `student-results-api-notes/09-Docker/05-cgroups.md`

This chapter explains the second half of container isolation.

In the previous chapter, you learned that Namespaces isolate what a process can see.

But namespaces do not limit resource usage.

For example, without resource control, one container could:

Consume 100% CPU
Allocate all available RAM
Spawn millions of processes
Crash the host

So another important question appears:

How does Docker prevent one container from consuming the entire machine?

The answer is:

Linux Control Groups (cgroups)

Namespaces provide isolation.

cgroups provide resource control.

Together they make containers possible.

---

# 🌍 Introduction

In the previous chapter, we learned about **Linux Namespaces**.

Namespaces isolate:

* Processes
* Networking
* Filesystems
* Hostnames
* IPC
* Users

Example:

```text id="a7n4p2"
Container A

↓

PID 1

↓

localhost

↓

Own Filesystem
```

But another important question appears:

> 🤔 **What prevents Container A from using all CPU and memory on the host?**

Namespaces cannot answer this.

The answer is:

# 💾 Linux cgroups

cgroups (Control Groups) limit, account for, and monitor how many system resources a process or group of processes can use.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 💾 What cgroups are
* ⚙️ cgroup v1 vs cgroup v2
* 🧠 CPU Limits
* 🧮 Memory Limits
* 📀 Block I/O Limits
* 🆔 PID Limits
* 📊 Resource Accounting
* 🐳 Docker Resource Limits
* ☸️ Kubernetes Requests & Limits

---

# ❓ What Are cgroups?

A **control group (cgroup)** is a Linux kernel mechanism that manages resources for one or more processes.

Without cgroups:

```text id="k3m8q6"
Container A

↓

Unlimited CPU

Unlimited RAM

Unlimited Processes
```

With cgroups:

```text id="d9p2v5"
CPU

↓

2 cores

----------------

Memory

↓

2 GB

----------------

Processes

↓

500
```

Every process in the group must obey these limits.

---

# 🏗️ Namespaces vs cgroups

These two kernel features work together.

```text id="t6r4n1"
Namespaces

↓

Isolation

-------------------

cgroups

↓

Resource Limits
```

Think of it like this:

| Feature       | Responsibility                 |
| ------------- | ------------------------------ |
| 🐧 Namespaces | "What the process can see"     |
| 💾 cgroups    | "How much the process can use" |

Docker always uses both.

---

# 🚀 Docker Container Creation

Suppose:

```bash id="v8m3q7"
docker run student-api
```

Internally:

```text id="u5k1p9"
Docker CLI

↓

dockerd

↓

containerd

↓

runc

↓

Namespaces

↓

cgroups

↓

Java Process
```

The application starts only after both isolation and resource limits are configured.

---

# 🧠 CPU Controller

Suppose a host has:

```text id="g4n9r2"
8 CPU Cores
```

Run:

```bash id="c7p5v1"
docker run --cpus=2 student-api
```

The container receives:

```text id="m2v8k4"
CPU

↓

Maximum

2 Cores
```

The Linux scheduler ensures the process does not exceed the configured CPU allocation.

---

# 🧮 Memory Controller

Run:

```bash id="x5q1n8"
docker run -m 512m student-api
```

Container:

```text id="j8r3p6"
Memory

↓

512 MB Maximum
```

If the process attempts:

```text id="n4m7v2"
700 MB
```

The kernel may invoke the **OOM Killer**.

---

# 💥 Out of Memory (OOM)

Example:

```text id="p1k6q9"
Container

↓

512 MB Limit

↓

Application Uses

700 MB

↓

OOM Killer

↓

Process Terminated
```

Docker reports:

```text id="y9v2m5"
Exited (137)
```

Exit code **137** usually indicates the process was killed after exceeding its memory limit.

---

# 🆔 PID Controller

Containers can also limit the number of processes.

Example:

```bash id="b3n8r4"
docker run --pids-limit=200 student-api
```

Result:

```text id="q7m5v1"
Maximum

200 Processes
```

This protects the host from fork bombs or runaway process creation.

---

# 📀 Block I/O Controller

cgroups can influence disk I/O usage.

Example:

```text id="h6p2k8"
Container A

↓

High Priority

-------------------

Container B

↓

Low Priority
```

This helps prevent one workload from monopolizing storage bandwidth.

---

# 🌐 Network Resource Control

Traditional cgroups do **not** directly limit bandwidth.

Docker relies on Linux networking features such as:

* Traffic Control (tc)
* qdiscs
* Network namespaces

to shape network traffic when required.

---

# 📊 Resource Accounting

cgroups continuously track resource usage.

Example:

```text id="z2r9m6"
CPU

45%

----------------

Memory

380 MB

----------------

Processes

15
```

Docker uses this information to display container statistics.

---

# 🍃 Student Results API Example

Run:

```bash id="w8m4q2"
docker run \
--cpus=1 \
-m=1g \
--pids-limit=150 \
student-api
```

Internally:

```text id="f5n7k3"
Java Process

↓

PID Namespace

↓

Memory Limit

↓

CPU Limit

↓

Process Limit

↓

Application Running
```

Even if the application misbehaves, it cannot exceed these configured limits.

---

# 📊 cgroup Hierarchy

Linux organizes cgroups in a hierarchy.

```text id="a4q8v1"
Root cgroup
      │
      ├── system.slice
      │
      ├── user.slice
      │
      └── docker
             │
             ├── Container A
             │
             ├── Container B
             │
             └── Container C
```

Each container has its own cgroup directory.

---

# 🧠 cgroup v1 vs cgroup v2

Modern Linux distributions use **cgroup v2**.

Comparison:

| Feature                | cgroup v1            | cgroup v2               |
| ---------------------- | -------------------- | ----------------------- |
| Hierarchy              | Multiple             | Unified                 |
| Resource Control       | Separate controllers | Unified controller tree |
| Simplicity             | More complex         | Simpler administration  |
| Current Recommendation | Legacy               | Modern standard         |

Most recent Docker and Kubernetes installations use cgroup v2 by default.

---

# 🔄 Namespaces + cgroups

Container creation sequence:

```text id="r3k7m9"
clone()

↓

Namespaces

↓

Filesystem

↓

cgroups

↓

execve()

↓

Java Process
```

Namespaces isolate.

cgroups enforce limits.

---

# 🚫 Common Mistakes

## ❌ Thinking Namespaces Limit Resources

Namespaces provide isolation only.

They do not limit CPU or memory.

---

## ❌ Assuming Docker Implements CPU Scheduling

The Linux kernel scheduler enforces CPU limits through cgroups.

Docker only configures those limits.

---

## ❌ Ignoring Memory Limits

Without memory limits, a single container can exhaust host memory and impact other workloads.

Production containers should generally have explicit memory limits.

---

# 🐳 Docker Internal View

```text id="u7n2p5"
dockerd
      │
      ▼
containerd
      │
      ▼
runc
      │
      ├── Namespaces
      ├── cgroups
      │
      ▼
Java Process
```

Docker delegates resource control to the Linux kernel.

---

# ☸️ Kubernetes Perspective

Kubernetes translates Pod resource specifications into cgroup settings.

Example:

```yaml id="m5v8q4"
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "1"
    memory: "1Gi"
```

Container runtime:

```text id="k9r3n7"
Pod

↓

Container Runtime

↓

cgroups

↓

Linux Kernel
```

The kernel ultimately enforces the limits.

---

# 🧪 Hands-on Lab

## Run a CPU-Limited Container

```bash id="x8m2p6"
docker run \
--cpus=1 \
nginx
```

Inspect:

```bash id="j6q9v1"
docker inspect <container-id>
```

Look for CPU quota settings.

---

## Run a Memory-Limited Container

```bash id="n4k7r3"
docker run \
-m 256m \
nginx
```

Inside the container:

```bash id="c2v5m8"
cat /sys/fs/cgroup/memory.max
```

On cgroup v2 systems, this displays the configured memory limit.

---

## View Container Statistics

```bash id="p7n1q4"
docker stats
```

Observe:

* CPU usage
* Memory usage
* Network I/O
* Block I/O

These values come from cgroup accounting.

---

## Inspect cgroup Files

Find the container PID:

```bash id="f9m3k2"
docker inspect \
--format '{{.State.Pid}}' <container-id>
```

View its cgroup membership:

```bash id="w3q8v6"
cat /proc/<PID>/cgroup
```

---

## View the cgroup Filesystem

On the host:

```bash id="h5r2m9"
mount | grep cgroup

ls /sys/fs/cgroup
```

Explore the cgroup hierarchy managed by the kernel.

---

# 📈 Complete Resource Control Flow

```text id="t1k8p5"
docker run
     │
     ▼
dockerd
     │
     ▼
containerd
     │
     ▼
runc
     │
     ├── clone()
     │
     ├── Namespaces
     │
     ├── cgroups
     │
     ▼
execve()
     │
     ▼
Java Process
     │
     ▼
Linux Scheduler
     │
     ▼
CPU / Memory / I/O Enforcement
```

This is the complete lifecycle of resource control for a Docker container.

---

# 📊 cgroup Controllers

| Controller    | Controls                                   |
| ------------- | ------------------------------------------ |
| 🧠 CPU        | CPU time, quotas, scheduling weights       |
| 🧮 Memory     | RAM usage, swap behavior, OOM handling     |
| 📀 IO         | Block device throughput and priorities     |
| 🆔 PIDs       | Maximum number of processes                |
| ⚖️ CPUSet     | Which CPU cores and NUMA nodes may be used |
| 📊 Accounting | Resource usage statistics for monitoring   |

---

# 💡 Key Takeaways

✅ cgroups are Linux kernel features that control and monitor resource usage for groups of processes.

✅ Namespaces isolate what a container can see, while cgroups limit what it can consume.

✅ Docker configures cgroups during container creation, but the Linux kernel enforces all resource limits.

✅ CPU, memory, process count, and block I/O can all be constrained through cgroup controllers.

✅ Exceeding a memory limit can trigger the Linux OOM Killer, often resulting in container exit code **137**.

✅ Kubernetes converts Pod resource requests and limits into cgroup settings on the host.

✅ Understanding cgroups is essential for diagnosing container performance, preventing noisy-neighbor problems, and managing production workloads.

---

# ➡️ Next Chapter

📘 **`09-Docker/06-OverlayFS.md`**

In the next chapter, we'll explore **OverlayFS**, the filesystem technology behind Docker images and containers.

We'll answer questions such as:

* 🗂️ How are image layers merged?
* 📦 Where does the writable layer live?
* ✍️ What happens when a file is modified?
* 📄 What is Copy-on-Write (CoW)?
* 💾 Where are layers stored on disk?
* ⚡ Why are Docker images space-efficient?

By the end of the next chapter, you'll understand exactly how Docker presents multiple immutable image layers and one writable layer as a single filesystem inside every container.
