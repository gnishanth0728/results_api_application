# 📘 Chapter 72 — Linux Namespaces (Docker Isolation)

> 📂 File: `student-results-api-notes/09-Docker/04-Namespaces.md`

This chapter is the foundation of Docker.

If you understand Linux Namespaces, you'll understand how Docker actually works.

Almost every container feature comes from namespaces:

🆔 PID isolation
🌐 Network isolation
📂 Filesystem isolation
🖥️ Hostname isolation
🔐 User isolation
💬 IPC isolation

Many people think Docker itself creates isolation.

It doesn't.

The Linux kernel does.

Docker simply tells the kernel:

"Create a new process with new namespaces."

This chapter explains the Linux kernel internals behind containers.

---

# 🌍 Introduction

In the previous chapter, we learned that a Docker container is simply an isolated Linux process.

The container creation flow looked like this:

```text id="n2v8k5"
docker run

↓

containerd

↓

runc

↓

clone()

↓

execve()

↓

Java Process
```

But another important question appears:

> 🤔 **How does one Linux process suddenly become an isolated machine?**

Why can two containers:

* Both have **PID 1**
* Both use **localhost**
* Both have `/etc/hosts`
* Both have different hostnames

The answer is:

# 🐧 Linux Namespaces

Namespaces are Linux kernel features that isolate different parts of the operating system.

Docker relies on them to make one process appear as an independent machine.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🐧 What Namespaces are
* 🧬 `clone()` System Call
* 🆔 PID Namespace
* 🌐 Network Namespace
* 📂 Mount Namespace
* 🖥️ UTS Namespace
* 💬 IPC Namespace
* 👤 User Namespace
* 🐳 Docker Isolation
* ☸️ Kubernetes Pods

---

# ❓ What Is a Namespace?

A namespace provides an isolated view of a kernel resource.

Without namespaces:

```text id="g5x9m2"
Linux Kernel

↓

All Processes

↓

One Global View
```

With namespaces:

```text id="k8q3r6"
Container A

↓

Own View

-------------------

Container B

↓

Own View
```

Each container believes it owns the machine.

---

# 🏗️ Container Isolation

Suppose:

```bash id="w9m4p7"
docker run nginx
```

Docker performs:

```text id="r2v7n5"
clone()

↓

New PID Namespace

↓

New Network Namespace

↓

New Mount Namespace

↓

New UTS Namespace

↓

New IPC Namespace

↓

New Process
```

The application is isolated before it starts.

---

# 🧬 clone() System Call

Unlike:

```text id="t6k1q9"
fork()
```

Docker uses:

```c id="u3m8r4"
clone()
```

because it allows selecting which namespaces should be isolated.

Example flags:

```text id="x7n5v2"
CLONE_NEWPID

CLONE_NEWNET

CLONE_NEWNS

CLONE_NEWIPC

CLONE_NEWUTS

CLONE_NEWUSER
```

Each flag creates a new namespace.

---

# 🆔 PID Namespace

Normally:

```text id="d5r8k1"
Host

PID 1

systemd

PID 2

kthreadd

PID 3000

java
```

Inside a container:

```text id="j9p4m6"
Container

PID 1

java
```

The Java process believes it is the first process in the system.

Host view:

```text id="f2k7q3"
PID 4382
```

Container view:

```text id="v6n1r8"
PID 1
```

Same process.

Different namespaces.

---

# 🌐 Network Namespace

Without namespaces:

```text id="p3m8q7"
All Processes

↓

One Network Stack
```

With Docker:

```text id="e5v2k9"
Container A

↓

eth0

↓

127.0.0.1

-------------------

Container B

↓

eth0

↓

127.0.0.1
```

Each container has its own:

* Network interfaces
* Routing table
* ARP table
* Firewall rules
* Loopback device

---

# 📂 Mount Namespace

Each container has its own filesystem view.

Host:

```text id="b7n4p1"
/home

/etc

/usr
```

Container:

```text id="a8m6q5"
/

├── app

├── bin

├── etc

├── proc

└── usr
```

OverlayFS combines the image layers with the writable layer to create this isolated root filesystem.

---

# 🖥️ UTS Namespace

UTS controls:

* Hostname
* Domain name

Host:

```text id="q2v8m4"
hostname

↓

server01
```

Container:

```text id="x9k3r6"
hostname

↓

student-api
```

Each container can have a different hostname.

---

# 💬 IPC Namespace

IPC stands for **Inter-Process Communication**.

Without namespaces:

```text id="u4n7k2"
Shared Memory

Semaphores

Message Queues

Visible To Everyone
```

With IPC namespaces:

```text id="h6p9v5"
Container A

↓

Own IPC Objects

-------------------

Container B

↓

Different IPC Objects
```

Processes in different containers cannot accidentally communicate using System V IPC or POSIX shared memory.

---

# 👤 User Namespace

User namespaces isolate user and group IDs.

Example:

Inside the container:

```text id="r8m2q7"
root

UID 0
```

On the host:

```text id="t5k1v9"
UID 100999
```

The process appears to be root inside the container while mapping to an unprivileged user on the host.

This greatly improves security.

---

# 🍃 Student Results API Example

Run:

```bash id="g7p4m2"
docker run student-api
```

Isolation:

```text id="m9r6k8"
PID Namespace

↓

Java = PID 1

-------------------

Network Namespace

↓

localhost:8080

-------------------

Mount Namespace

↓

/app/app.jar

-------------------

Hostname

↓

student-api
```

Your Spring Boot application believes it is running on its own machine.

---

# 📊 Namespace Overview

```text id="y3k7n5"
Linux Kernel
      │
      ▼
clone()
      │
      ├── PID Namespace
      ├── Network Namespace
      ├── Mount Namespace
      ├── IPC Namespace
      ├── UTS Namespace
      └── User Namespace
              │
              ▼
      Container Process
```

Every container receives one or more namespaces.

---

# 🔄 Host vs Container

Host:

```bash id="h2q9m4"
ps -ef
```

Shows:

```text id="c6v1r8"
PID 4321

java
```

Inside container:

```bash id="m4n8k2"
ps -ef
```

Shows:

```text id="z5p7q3"
PID 1

java
```

The same process has two different views depending on the namespace.

---

# 🚫 Common Mistakes

## ❌ Thinking Docker Creates Isolation

Docker does not implement isolation itself.

The Linux kernel implements namespaces.

Docker simply requests them.

---

## ❌ Thinking PID 1 Is Always systemd

Inside many containers:

```text id="j1r8v6"
PID 1

↓

java
```

or:

```text id="x4m2q9"
PID 1

↓

nginx
```

The application itself often becomes PID 1.

---

## ❌ Confusing Host Network With Container Network

Each network namespace has:

* Independent interfaces
* Independent routing tables
* Independent loopback device

`localhost` inside a container refers only to that container.

---

# 🐳 Docker Internal View

```text id="u8n5p4"
dockerd
      │
      ▼
containerd
      │
      ▼
runc
      │
      ▼
clone()
      │
      ├── PID Namespace
      ├── Network Namespace
      ├── Mount Namespace
      ├── IPC Namespace
      ├── UTS Namespace
      └── User Namespace
      │
      ▼
execve()
      │
      ▼
Java Process
```

---

# ☸️ Kubernetes Perspective

A Pod is also built using Linux namespaces.

```text id="k7r2m5"
Pod

↓

Container Runtime

↓

Namespaces

↓

Java Process
```

Multiple containers in the **same Pod** typically share some namespaces (such as the network namespace), allowing them to communicate over `localhost`.

---

# 🧪 Hands-on Lab

## View the Host PID

Run:

```bash id="b6m8q4"
docker inspect \
--format '{{.State.Pid}}' student-api
```

Observe the host PID.

---

## Enter the Container

```bash id="f2v9k1"
docker exec -it student-api bash
```

Run:

```bash id="w5n3r8"
ps -ef
```

Observe that the Java process is PID 1.

---

## View the Hostname

Inside the container:

```bash id="n7p2m6"
hostname
```

Observe the container-specific hostname.

---

## Inspect the Network

Inside the container:

```bash id="d9k4q7"
ip addr

ip route
```

Observe the isolated network namespace.

---

## Inspect Namespaces From the Host

Find the container PID:

```bash id="c1m8v5"
docker inspect \
--format '{{.State.Pid}}' student-api
```

Then inspect its namespaces:

```bash id="r4q7k2"
ls -l /proc/<PID>/ns
```

Typical output:

```text id="v8n5m1"
mnt

net

pid

ipc

uts

user
```

Each symbolic link represents a namespace associated with the container process.

---

# 📈 Complete Namespace Flow

```text id="g3r8m2"
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
     ▼
clone()
     │
     ├── PID Namespace
     ├── Network Namespace
     ├── Mount Namespace
     ├── IPC Namespace
     ├── UTS Namespace
     ├── User Namespace
     │
     ▼
execve()
     │
     ▼
java -jar app.jar
     │
     ▼
Spring Boot
```

This is the complete namespace creation sequence during container startup.

---

# 📊 Namespace Summary

| Namespace  | Isolates                                  |
| ---------- | ----------------------------------------- |
| 🆔 PID     | Process IDs and process tree              |
| 🌐 Network | Interfaces, routing, ports, loopback      |
| 📂 Mount   | Filesystem mount points                   |
| 🖥️ UTS    | Hostname and domain name                  |
| 💬 IPC     | Shared memory, semaphores, message queues |
| 👤 User    | User IDs, group IDs, privileges           |

---

# 💡 Key Takeaways

✅ Linux namespaces provide isolated views of kernel resources for processes.

✅ Docker relies on the `clone()` system call with namespace flags to create isolated container environments.

✅ PID namespaces allow each container to have its own process tree, often with the application running as PID 1.

✅ Network namespaces give every container its own network stack, including interfaces, routing tables, and loopback device.

✅ Mount, UTS, IPC, and User namespaces isolate filesystems, hostnames, inter-process communication resources, and user identities.

✅ Docker does not implement isolation itself—it orchestrates Linux kernel features to create containers.

✅ Understanding namespaces is fundamental before learning cgroups, Docker networking, volumes, and Kubernetes Pods.
