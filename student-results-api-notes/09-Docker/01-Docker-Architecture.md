# 📘 Chapter 69 — Docker Architecture

> 📂 File: `student-results-api-notes/09-Docker/01-Docker-Architecture.md`

This is the beginning of the Docker module, and it connects everything you've learned so far.

Until now, you've followed a request through:

🌐 Network
🐧 Linux
☕ JVM
🐱 Tomcat
🌱 Spring Boot
🏛️ Hibernate
🐘 PostgreSQL

Now comes the next question:

Where are all these components actually running?

The answer is:

Inside a Docker Container.

This chapter explains Docker from the operating system perspective—not just Docker commands.

It answers questions like:

Why was Docker invented?
How is a container different from a VM?
What actually happens during docker run?
What Linux features make containers possible?
Where does containerd fit?
What is runc?
How does a Docker container become a Linux process?

This chapter lays the foundation for the rest of the Docker module.

---

# 🌍 Introduction

So far, we've followed an HTTP request through every layer of a modern backend application.

```text
Browser
    │
    ▼
Network
    │
    ▼
Linux
    │
    ▼
JVM
    │
    ▼
Tomcat
    │
    ▼
Spring Boot
    │
    ▼
Hibernate
    │
    ▼
PostgreSQL
```

But another important question appears:

> 🤔 **Where is this entire application actually running?**

Is it:

* Directly on Linux?
* Inside a Virtual Machine?
* Inside Docker?
* Inside Kubernetes?

Today, almost every backend application runs inside a **Docker Container**.

To understand Kubernetes, we must first understand Docker.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🐳 Why Docker Exists
* 🏗️ Docker Architecture
* 📦 Images
* 📦 Containers
* ⚙️ Docker Engine
* 🚀 containerd
* 🏃 runc
* 🐧 Linux Namespaces
* 💾 cgroups
* ☸️ Kubernetes Relationship

---

# ❓ Why Was Docker Created?

Before Docker:

```text
Application A

↓

Ubuntu VM

↓

Hypervisor

↓

Server
```

Another application:

```text
Application B

↓

Ubuntu VM

↓

Hypervisor

↓

Server
```

Each VM required:

* Full Operating System
* Kernel
* RAM
* CPU
* Storage

VMs were:

* Heavy
* Slow to start
* Resource intensive

---

# 🖥️ Virtual Machine Architecture

```text
+---------------------------+
| Application               |
+---------------------------+
| Guest OS                  |
+---------------------------+
| Hypervisor                |
+---------------------------+
| Host Operating System     |
+---------------------------+
| Hardware                  |
+---------------------------+
```

Each VM contains its own operating system.

---

# 🐳 Docker Architecture

Docker removes the guest operating system.

```text
+---------------------------+
| Application               |
+---------------------------+
| Docker Container          |
+---------------------------+
| Docker Engine             |
+---------------------------+
| Host Linux Kernel         |
+---------------------------+
| Hardware                  |
+---------------------------+
```

All containers share the host Linux kernel.

This makes containers lightweight and fast.

---

# 🚀 High-Level Docker Architecture

```text
Developer
      │
docker CLI
      │
      ▼
Docker Engine
      │
      ▼
containerd
      │
      ▼
runc
      │
      ▼
Linux Kernel
      │
      ▼
Container Process
```

Every `docker run` follows this path.

---

# 🏗️ Docker Components

```text
Docker CLI
      │
      ▼
Docker Daemon (dockerd)
      │
      ▼
containerd
      │
      ▼
runc
      │
      ▼
Linux Kernel
```

Each component has a specific responsibility.

---

# 💻 Docker CLI

The Docker CLI is the command-line tool.

Example:

```bash
docker run nginx
```

The CLI does **not** create containers.

Instead:

```text
docker CLI

↓

REST API

↓

Docker Daemon
```

The daemon performs the work.

---

# ⚙️ Docker Daemon (dockerd)

The Docker Daemon manages:

* Images
* Containers
* Networks
* Volumes
* Build operations

Architecture:

```text
Docker CLI

↓

dockerd

↓

Docker API
```

It is the main Docker service running on the host.

---

# 🚀 containerd

The Docker Daemon delegates container lifecycle management to **containerd**.

Responsibilities:

* Pull images
* Manage snapshots
* Start containers
* Stop containers
* Monitor containers

Flow:

```text
dockerd

↓

containerd

↓

Container
```

---

# 🏃 runc

`runc` is a low-level OCI runtime.

Its job is simple:

```text
containerd

↓

runc

↓

clone()

↓

Namespaces

↓

cgroups

↓

exec()
```

After starting the container process, `runc` exits.

The container continues running independently.

---

# 🐧 Linux Kernel

Docker is **not** virtualization.

Docker relies on Linux kernel features.

Main features:

* Namespaces
* cgroups
* Overlay Filesystem
* Capabilities
* seccomp

The Linux kernel provides the isolation that makes containers possible.

---

# 📦 What Is a Container?

A container is **not** a virtual machine.

A container is simply:

> **A Linux process with additional isolation provided by the kernel.**

For example:

```bash
docker run nginx
```

Eventually becomes:

```text
Linux Process

↓

PID 4821

↓

Namespaces

↓

cgroups

↓

nginx
```

A container is just another process from the host kernel's perspective.

---

# 📦 Image vs Container

Image:

```text
Read Only

↓

Template

↓

Filesystem
```

Container:

```text
Running Process

+

Writable Layer
```

Relationship:

```text
Docker Image

↓

docker run

↓

Docker Container
```

Multiple containers can be created from the same image.

---

# 🍃 Student Results API Example

Suppose we run:

```bash
docker run student-results-api
```

Execution:

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
Java Process
      │
      ▼
Spring Boot
      │
      ▼
Tomcat
```

Eventually, your Spring Boot application is just a Linux process.

---

# 📊 Complete Docker Flow

```text
docker run

      │

      ▼

Docker CLI

      │

      ▼

Docker Daemon

      │

      ▼

containerd

      │

      ▼

runc

      │

      ▼

Linux clone()

      │

      ▼

Namespaces

      │

      ▼

cgroups

      │

      ▼

Java Process

      │

      ▼

Container Running
```

This is the complete lifecycle of starting a container.

---

# 🚫 Common Mistakes

## ❌ Thinking Containers Are Virtual Machines

Containers share the host kernel.

VMs have their own kernel.

---

## ❌ Thinking Docker Creates Processes

The Linux kernel creates processes.

Docker simply instructs the kernel how to create an isolated process.

---

## ❌ Thinking containerd Runs Applications

containerd manages the container lifecycle.

The application itself runs as a normal Linux process.

---

# 🐳 Docker Internal Architecture

```text
+----------------------------------------+
| Docker CLI                             |
+----------------------------------------+
               │
               ▼
+----------------------------------------+
| Docker Daemon (dockerd)                |
+----------------------------------------+
               │
               ▼
+----------------------------------------+
| containerd                             |
+----------------------------------------+
               │
               ▼
+----------------------------------------+
| runc                                   |
+----------------------------------------+
               │
               ▼
+----------------------------------------+
| Linux Kernel                           |
|  • Namespaces                          |
|  • cgroups                             |
|  • OverlayFS                           |
+----------------------------------------+
               │
               ▼
+----------------------------------------+
| Container Process                      |
+----------------------------------------+
```

---

# 🧪 Hands-on Lab

## View Docker Processes

```bash
ps -ef | grep -E "dockerd|containerd"
```

Observe the Docker daemon and containerd processes.

---

## Run a Container

```bash
docker run -d nginx
```

Then inspect the running processes:

```bash
ps -ef | grep nginx
```

Notice that the container is backed by normal Linux processes.

---

## Inspect a Container

```bash
docker inspect <container-id>
```

Observe:

* Process ID (PID)
* Network configuration
* Mounts
* cgroup settings

---

## View Container Runtime

```bash
docker info
```

Look for:

```text
Runtimes:
    runc
```

---

## Observe the Process Tree

```bash
pstree -p
```

Example:

```text
systemd
 └── dockerd
      └── containerd
            └── containerd-shim
                  └── java
```

This demonstrates the relationship between Docker components and the application process.

---

# 📈 Complete Architecture Summary

```text
Developer

│

▼

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

runc

│

▼

Linux Kernel

│

├── Namespaces

├── cgroups

├── OverlayFS

│

▼

Java Process

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

This is the complete architecture behind every Docker container.

---

# 📊 Docker Component Summary

| Component       | Responsibility                                                  |
| --------------- | --------------------------------------------------------------- |
| 🖥️ Docker CLI  | Sends commands to the Docker daemon                             |
| ⚙️ dockerd      | Manages images, containers, networks, and volumes               |
| 🚀 containerd   | Manages the container lifecycle                                 |
| 🏃 runc         | Creates the container process using Linux kernel features       |
| 🐧 Linux Kernel | Provides namespaces, cgroups, OverlayFS, and process management |
| 📦 Image        | Read-only filesystem template                                   |
| 📦 Container    | Running isolated Linux process with a writable layer            |

---

# 💡 Key Takeaways

✅ Docker containers are **not virtual machines**; they are isolated Linux processes.

✅ The Docker CLI communicates with the Docker Daemon (`dockerd`), which orchestrates container creation.

✅ `containerd` manages container lifecycle operations, while `runc` creates the actual container process using Linux kernel primitives.

✅ Docker relies on Linux technologies such as **namespaces**, **cgroups**, and **OverlayFS** instead of hardware virtualization.

✅ Every container shares the host kernel but has isolated views of processes, networking, filesystems, and resources.

✅ A Docker image is a read-only template, while a container is a running instance of that image with its own writable layer.

✅ Understanding Docker architecture is essential before learning images, layers, networking, storage, and Kubernetes.

---

# ➡️ Next Chapter

📘 **`09-Docker/02-Docker-Image.md`**

In the next chapter, we'll explore **Docker Images** in depth.

We'll answer questions such as:

* 📦 What exactly is a Docker image?
* 🧱 How are image layers created?
* 📝 How does a Dockerfile become an image?
* 💾 Where are image layers stored?
* 🔄 Why are layers shared across images?
* ⚡ How does Docker build images efficiently?

By the end of the next chapter, you'll understand how a simple `Dockerfile` is transformed into an optimized, layered image that can be shared and executed anywhere Docker is available.
