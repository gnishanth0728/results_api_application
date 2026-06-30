# 📘 Chapter 19 — Linux Virtual Memory

> 📂 File: `student-results-api-notes/03-Linux/04-Virtual-Memory.md`

---

# 🌍 Introduction

When you started your Student Results API:

```bash
java -jar student-results-api.jar
```

Linux created a Java process.

During your experiments you observed:

```bash
ps -p 7065 -o pid,%cpu,%mem,rss,vsz,nlwp
```

Example output:

```text
PID   %CPU %MEM    RSS      VSZ
7065   2.4  7.6 306960 3624956
```

You probably noticed something surprising.

```text
RSS = 306 MB

VSZ = 3.6 GB
```

Your EC2 instance only had about **4 GB RAM**, so why does the Java process appear to use **3.6 GB**?

The answer is one of the most important operating system concepts:

# 🧠 Virtual Memory

Virtual memory allows every process to believe it owns a large, private address space, even though physical RAM is limited and shared.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🧠 What virtual memory is
* 💾 Physical memory (RAM)
* 🗺️ Virtual address space
* 📄 Memory pages
* 📑 Page tables
* 🔄 Address translation
* ⚡ Page faults
* 📦 JVM heap allocation
* 💽 Swap memory
* 📊 VSZ vs RSS
* 🐳 Docker memory limits
* ☸️ Kubernetes memory management
* 🧪 Linux memory debugging

---

# ❓ Why Virtual Memory Exists

Imagine three processes running:

```text
Java

PostgreSQL

Nginx
```

Without virtual memory:

```text
RAM

↓

All processes

↓

Same addresses
```

One process could overwrite another process's memory.

That would be a security disaster.

Virtual memory solves this by giving every process its own private address space.

---

# 🏗️ High-Level Architecture

```text
                Java Process

+--------------------------------------+

Virtual Address Space

0x0000....

↓

Heap

↓

Stack

↓

Libraries

↓

Code

+--------------------------------------+

              │

              ▼

Linux Kernel

              │

              ▼

Physical RAM
```

The process never accesses RAM directly.

All memory access goes through the kernel and the CPU's Memory Management Unit (MMU).

---

# 💾 Physical Memory (RAM)

Physical memory is the actual hardware installed in your machine.

Example:

```text
EC2 Instance

↓

4096 MB RAM
```

RAM stores:

* Running processes
* Kernel data
* Page cache
* Buffers

RAM is limited.

---

# 🗺️ Virtual Address Space

Each process receives its own virtual address space.

Conceptually:

```text
Java Process

+----------------------------+

0xFFFFFFFFFFFFFFFF

↓

Stack

↓

Shared Libraries

↓

Heap

↓

Data

↓

Code

0x0000000000000000

+----------------------------+
```

Even if two processes use the same virtual address, they are mapped to different physical pages.

---

# 🧱 Process Memory Layout

A Java process typically looks like:

```text
 High Addresses
+---------------------------+
| 🧵 Thread Stack           |
+---------------------------+
| 📚 Shared Libraries       |
+---------------------------+
| ☕ JVM Heap               |
+---------------------------+
| 📦 Data Segment           |
+---------------------------+
| ⚙️ Code Segment           |
+---------------------------+
 Low Addresses
```

Each region has a different purpose.

---

# 📄 Memory Pages

Linux does not manage memory byte by byte.

Instead, memory is divided into fixed-size **pages**.

Typical page size:

```text
4096 Bytes

(4 KB)
```

Example:

```text
Page 0

Page 1

Page 2

Page 3
```

Every virtual address belongs to one page.

---

# 📑 Page Tables

Each process has a page table.

```text
Virtual Page

↓

Physical Page
```

Example:

```text
Virtual Page 20

↓

Physical Page 510
```

The page table is maintained by the Linux kernel and consulted by the MMU.

---

# ⚡ Memory Management Unit (MMU)

The CPU contains dedicated hardware called the **MMU**.

Its job is to translate virtual addresses into physical addresses.

```text
Java

↓

Virtual Address

↓

MMU

↓

Page Table

↓

Physical Address

↓

RAM
```

This translation happens on every memory access, but modern CPUs cache translations using the TLB for speed.

---

# 📦 JVM Heap

When you start the JVM:

```bash
java -Xms512m -Xmx2g \
-jar student-results-api.jar
```

the JVM reserves a virtual heap.

Example:

```text
Reserved Heap

2 GB
```

Initially, only part of that heap may consume physical RAM.

This is why VSZ can be much larger than RSS.

---

# 📊 VSZ vs RSS

During your experiments you observed:

```text
VSZ = 3.6 GB

RSS = 300 MB
```

### VSZ (Virtual Size)

The total virtual address space reserved by the process.

Includes:

* Heap reservation
* Libraries
* Memory mappings
* Unused reserved space

### RSS (Resident Set Size)

The amount of memory currently resident in physical RAM.

This is the memory actually consuming RAM.

---

# ⚡ Demand Paging

Linux does **not** allocate all physical pages immediately.

Example:

```text
JVM Reserves

2 GB

↓

Touches First Page

↓

Allocate 4 KB
```

Physical memory is allocated only when a page is accessed.

This technique is called **demand paging**.

---

# 🚨 Page Fault

Suppose the JVM accesses a page that is not yet mapped.

```text
Read Address

↓

Page Missing

↓

Page Fault

↓

Kernel

↓

Allocate Physical Page

↓

Resume Execution
```

A page fault is a normal mechanism used to lazily allocate memory.

---

# 💽 Swap Memory

If RAM becomes scarce, Linux can move inactive pages to disk.

```text
RAM

↓

Swap
```

Swap is much slower than RAM, so excessive swapping hurts performance.

Your EC2 instance showed:

```text
Swap = 0 MB
```

which means no swap space was configured.

---

# 📂 Memory Maps

Every process exposes its memory layout through `/proc`.

View it:

```bash
cat /proc/<PID>/maps
```

Example regions:

```text
Code

Heap

Stack

Shared Libraries

Anonymous Memory
```

This file shows the complete virtual memory map of the process.

---

# 📈 Real Student Results API Example

During your load test:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

You observed:

```text
RSS

≈ 300 MB
```

Although 200 requests were active, memory usage remained relatively stable because:

* Worker threads reused existing stacks.
* Tomcat reused thread objects.
* The JVM heap was already allocated.
* Most requests were short-lived.

---

# 🐳 Docker Perspective

Containers do **not** have their own virtual memory implementation.

The host Linux kernel manages memory for all processes.

Docker uses **cgroups** to enforce limits.

Example:

```bash
docker run \
--memory=512m \
student-api
```

The Java process still has virtual memory, but the kernel prevents it from exceeding the configured limit.

---

# ☸️ Kubernetes Perspective

Kubernetes also relies on Linux memory management.

Example Pod:

```yaml
resources:
  requests:
    memory: "512Mi"
  limits:
    memory: "1Gi"
```

The kubelet configures cgroups, and the Linux kernel enforces those limits.

The JVM still uses virtual memory exactly as it would on a normal Linux system.

---

# 🧪 Hands-on Lab

## Display Memory Usage

```bash
free -h
```

Observe:

* Total RAM
* Used
* Free
* Buffers/Cache
* Swap

---

## View Process Memory

```bash
ps -p <PID> -o pid,rss,vsz,%mem
```

Compare RSS and VSZ.

---

## View Detailed Memory Maps

```bash
cat /proc/<PID>/maps
```

---

## View Memory Statistics

```bash
cat /proc/<PID>/smaps
```

This provides per-region memory usage, including RSS and page information.

---

## Summarize Memory

```bash
pmap -x <PID>
```

or

```bash
smem -p
```

These tools provide human-readable summaries of process memory.

---

## Monitor Memory During Load

Terminal 1:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Terminal 2:

```bash
watch -n1 \
'ps -p <PID> -o pid,rss,vsz,%mem'
```

Observe how RSS changes during heavy request processing.

---

# 💡 Key Takeaways

✅ Every process receives its own private virtual address space.

✅ Virtual addresses are translated into physical RAM by the MMU using page tables.

✅ Linux manages memory in pages, typically 4 KB in size.

✅ VSZ represents reserved virtual memory, while RSS represents memory actually resident in RAM.

✅ Physical pages are allocated lazily using demand paging.

✅ Page faults occur when a process first accesses an unmapped page.

✅ Docker and Kubernetes do not replace virtual memory—they rely on the Linux kernel and use cgroups to limit memory usage.

---

# ➡️ Next Chapter

📘 **`03-Linux/05-Linux-File-System.md`**

In the next chapter we'll explore how Linux stores data and how your Spring Boot application interacts with the filesystem.

We'll cover:

* 📁 VFS (Virtual File System)
* 💾 Inodes
* 📂 Directories
* 🔗 Hard and symbolic links
* 📄 File descriptors
* 📦 JAR files on disk
* 📝 Log files
* 🐳 Docker OverlayFS
* ☸️ Kubernetes volumes
* 🧪 Tools such as `ls`, `stat`, `df`, `du`, `mount`, `findmnt`, and `/proc/<PID>/fd`

By the end of that chapter, you'll understand how Linux represents files, directories, and mounted filesystems—and how your Java process interacts with them during application startup and request processing.
