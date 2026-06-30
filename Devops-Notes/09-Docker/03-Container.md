# 📘 Chapter 71 — Docker Containers

> 📂 File: `student-results-api-notes/09-Docker/03-Container.md`

This is one of the most important chapters in the Docker module.

Most developers know how to run:

docker run nginx

But very few know what actually happens internally.

This chapter answers one of the biggest questions:

How does a Docker Image become a running Linux process?

You'll learn the complete journey from:

📦 Image
📂 Filesystem
📝 Writable Layer
🐧 Linux Namespaces
💾 cgroups
⚙️ containerd
🏃 runc
🧬 clone()
🚀 execve()

until your Spring Boot application becomes a Linux process.

This chapter directly connects with everything you learned earlier about Linux processes.

---

# 🌍 Introduction

In the previous chapter, we learned about **Docker Images**.

We saw:

```text
Dockerfile

↓

Docker Image

↓

docker run

↓

Container
```

But another important question appears:

> 🤔 **What exactly happens when we execute `docker run`?**

How does a read-only Docker image suddenly become a running application?

The answer is:

# 📦 Docker Container

A Docker Container is a running instance of an image.

Internally, it is simply an **isolated Linux process** with its own filesystem, networking, process table, hostname, and resource limits.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📦 What a Docker Container is
* 🚀 `docker run` Internals
* 📂 Writable Layer
* 🗂️ OverlayFS
* 🏃 Process Creation
* 🐧 Linux Namespaces
* 💾 cgroups
* ⚙️ containerd
* 🧬 clone()
* 🚀 execve()

---

# ❓ What Is a Docker Container?

A container is **not**:

* ❌ A Virtual Machine
* ❌ A Mini Operating System

A container **is**:

> A Linux process running with additional isolation provided by the Linux kernel.

For example:

```bash
docker run nginx
```

Eventually becomes:

```text
PID 4821

↓

Linux Process

↓

nginx
```

The kernel treats it like any other process.

---

# 🏗️ High-Level Container Architecture

```text
Docker Image
      │
      ▼
Writable Layer
      │
      ▼
Namespaces
      │
      ▼
cgroups
      │
      ▼
Linux Process
```

Every running container follows this architecture.

---

# 🚀 What Happens During `docker run`?

Suppose we execute:

```bash
docker run student-api
```

Complete flow:

```text
docker CLI

↓

dockerd

↓

containerd

↓

Image Lookup

↓

Create Writable Layer

↓

OverlayFS

↓

runc

↓

clone()

↓

Namespaces

↓

cgroups

↓

execve()

↓

Java Process

↓

Spring Boot Starts
```

This is the entire lifecycle of container creation.

---

# 📂 Step 1 — Locate the Image

Docker first checks:

```text
Local Image Store

↓

Image Exists?

│

├── Yes → Continue

└── No → Pull Image
```

If the image is missing:

```bash
docker pull student-api
```

is performed automatically (unless disabled).

---

# 📝 Step 2 — Create the Writable Layer

Remember:

Image:

```text
Read Only
```

Container:

```text
Writable
```

Docker creates:

```text
Read-only Layers

↓

Writable Layer
```

All file modifications go into this writable layer.

---

# 🗂️ Step 3 — Overlay Filesystem

OverlayFS merges:

```text
Layer 4

↓

Layer 3

↓

Layer 2

↓

Layer 1

↓

Writable Layer
```

into:

```text
Single Root Filesystem
```

Inside the container you simply see:

```text
/

├── bin

├── etc

├── usr

├── app
```

Even though it is assembled from multiple layers.

---

# 🏃 Step 4 — runc Starts the Container

containerd calls:

```text
runc
```

`runc` performs:

```text
clone()

↓

Create Namespaces

↓

Attach cgroups

↓

Mount Filesystem

↓

execve()
```

After this:

```text
Java Process Running
```

---

# 🧬 Step 5 — clone()

Unlike a normal process:

```text
fork()

↓

Child Process
```

Docker uses:

```text
clone()
```

because `clone()` allows:

* New PID namespace
* New Network namespace
* New Mount namespace
* New IPC namespace
* New UTS namespace

All in a single system call.

---

# 🚀 Step 6 — execve()

After namespaces are ready:

```text
execve()

↓

ENTRYPOINT

↓

Java

↓

Spring Boot
```

Suppose Dockerfile:

```dockerfile
ENTRYPOINT ["java","-jar","app.jar"]
```

Eventually becomes:

```bash
java -jar app.jar
```

inside the container.

---

# 🐧 Linux Namespaces

Each container gets isolated namespaces.

```text
Container

├── PID Namespace

├── Network Namespace

├── Mount Namespace

├── IPC Namespace

├── UTS Namespace

└── User Namespace (optional)
```

The application believes it owns the entire machine.

---

# 💾 cgroups

Namespaces provide isolation.

cgroups provide resource limits.

Example:

```text
CPU

↓

2 cores

---------------

Memory

↓

1 GB

---------------

PIDs

↓

200
```

Without cgroups, one container could consume all system resources.

---

# 🍃 Student Results API Example

Run:

```bash
docker run student-api
```

Internally:

```text
Image

↓

Writable Layer

↓

Namespaces

↓

cgroups

↓

java -jar app.jar

↓

Spring Boot

↓

Tomcat

↓

Student Results API
```

Eventually:

```text
Linux Process

↓

PID 4815
```

---

# 📊 Container Lifecycle

```text
docker run
      │
      ▼
Image
      │
      ▼
Writable Layer
      │
      ▼
OverlayFS
      │
      ▼
Namespaces
      │
      ▼
cgroups
      │
      ▼
Process Created
      │
      ▼
ENTRYPOINT
      │
      ▼
Application Running
```

---

# 📂 Inside the Container

Suppose:

```bash
docker exec -it container bash
```

Filesystem:

```text
/

├── app

├── bin

├── etc

├── proc

├── sys

├── usr

└── var
```

It appears to be a complete operating system, but it is actually the merged filesystem presented by OverlayFS.

---

# 🔄 Container States

```text
Created

↓

Running

↓

Paused

↓

Stopped

↓

Removed
```

Commands:

```bash
docker create

docker start

docker stop

docker rm
```

---

# 🚫 Common Mistakes

## ❌ Thinking a Container Has Its Own Kernel

Containers always share the host Linux kernel.

---

## ❌ Thinking a Container Starts From Scratch

Containers are created from immutable Docker images.

---

## ❌ Thinking `docker exec` Creates Another Container

`docker exec` starts another process **inside the existing container**.

The container itself remains the same.

---

# 🐳 Docker Internal Architecture

```text
Docker CLI
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
      ▼
Namespaces
      │
      ▼
cgroups
      │
      ▼
OverlayFS
      │
      ▼
execve()
      │
      ▼
Java Process
```

---

# ☸️ Kubernetes Perspective

Kubernetes does **not** run images directly.

Instead:

```text
Deployment

↓

ReplicaSet

↓

Pod

↓

Container Runtime

↓

Container

↓

Java Process
```

Each Pod ultimately contains one or more Linux processes started exactly the same way.

---

# 🧪 Hands-on Lab

## Create a Container

```bash
docker run -d --name student-api student-api
```

Verify:

```bash
docker ps
```

---

## Observe the Process

```bash
docker top student-api
```

Notice the Java process running inside the container.

---

## View the Host Process

```bash
docker inspect \
--format '{{.State.Pid}}' student-api
```

Then:

```bash
ps -fp <PID>
```

Observe that the container process is a normal Linux process.

---

## Enter the Container

```bash
docker exec -it student-api bash
```

Run:

```bash
ps -ef

hostname

ip addr
```

Observe the isolated process table, hostname, and network namespace.

---

## View cgroups

```bash
cat /proc/self/cgroup
```

Observe the control groups assigned to the container.

---

# 📈 Complete Container Journey

```text
docker run
     │
     ▼
Docker CLI
     │
     ▼
dockerd
     │
     ▼
containerd
     │
     ▼
Locate Image
     │
     ▼
Create Writable Layer
     │
     ▼
OverlayFS
     │
     ▼
runc
     │
     ▼
clone()
     │
     ▼
Namespaces
     │
     ▼
cgroups
     │
     ▼
execve()
     │
     ▼
java -jar app.jar
     │
     ▼
Spring Boot
     │
     ▼
Tomcat
     │
     ▼
Student Results API
```

This is the complete lifecycle of a Docker container from command to running application.

---

# 📊 Container Components

| Component         | Responsibility                                             |
| ----------------- | ---------------------------------------------------------- |
| 📦 Image          | Immutable filesystem template                              |
| 📝 Writable Layer | Stores runtime file changes                                |
| 🗂️ OverlayFS     | Merges image layers and writable layer into one filesystem |
| 🏃 runc           | Creates the container process                              |
| 🧬 `clone()`      | Creates a process with isolated namespaces                 |
| 🚀 `execve()`     | Starts the container's ENTRYPOINT or CMD                   |
| 🐧 Namespaces     | Isolate processes, networking, mounts, IPC, and hostname   |
| 💾 cgroups        | Limit CPU, memory, and other resources                     |
| ⚙️ Linux Process  | The actual running application                             |

---

# 💡 Key Takeaways

✅ A Docker container is an isolated Linux process, not a virtual machine.

✅ `docker run` creates a writable layer on top of an immutable image before starting the process.

✅ OverlayFS merges image layers and the writable layer into a single filesystem visible inside the container.

✅ `containerd` delegates to `runc`, which uses the Linux `clone()` system call to create isolated namespaces and then `execve()` to start the application.

✅ Namespaces provide isolation, while cgroups enforce resource limits.

✅ The process started by `ENTRYPOINT` or `CMD` becomes **PID 1 inside the container**.

✅ Understanding container internals is essential before learning Docker networking, volumes, process management, and Kubernetes Pods.

---

# ➡️ Next Chapter

📘 **`09-Docker/04-Namespaces.md`**

In the next chapter, we'll explore **Linux Namespaces**, the core kernel feature that makes containers possible.

We'll answer questions such as:

* 🐧 What are namespaces?
* 👥 How can two containers both have a process with PID 1?
* 🌐 How does each container get its own network stack?
* 📂 How is the filesystem isolated?
* 🏷️ How does each container have its own hostname?

By the end of the next chapter, you'll understand how the Linux kernel creates isolated environments that make containers appear like independent machines while sharing the same host kernel.
