# 📘 Chapter 70 — Docker Images

> 📂 File: `student-results-api-notes/09-Docker/02-Image.md`

This chapter explains the heart of Docker.

Everything in Docker starts with an Image.

When you run:

docker run nginx

Docker does not create the container from scratch.

Instead, it:

Finds the Docker Image
Creates a writable layer
Creates namespaces & cgroups
Starts the process

So the obvious question becomes:

What exactly is a Docker Image?

This chapter answers that question from the filesystem and Linux perspective—not just Docker commands.

---

# 🌍 Introduction

In the previous chapter, we learned Docker's architecture.

We saw:

```text
docker run

↓

Docker CLI

↓

dockerd

↓

containerd

↓

runc

↓

Linux Kernel

↓

Container
```

But another important question appears:

> 🤔 **What exactly is Docker running?**

When we execute:

```bash
docker run nginx
```

Where does **nginx** come from?

The answer is:

# 📦 Docker Image

A Docker Image is the blueprint used to create one or more containers.

It contains:

* Application files
* Libraries
* Runtime
* Configuration
* Metadata

Everything needed to run an application.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📦 What a Docker Image is
* 🧱 Image Layers
* 📝 Dockerfile
* 💾 Image Storage
* 🗂️ OverlayFS
* 🏷️ Image Tags
* 🌍 Docker Registry
* 🚀 Image Pull Process
* 🐳 Container Creation
* ☸️ Kubernetes Relationship

---

# ❓ What Is a Docker Image?

A Docker Image is a **read-only filesystem template**.

Think of it as:

```text
Blueprint

↓

Container
```

or

```text
Java Class

↓

Java Object
```

A single image can create many containers.

---

# 🏗️ High-Level Architecture

```text
Dockerfile

↓

docker build

↓

Docker Image

↓

docker run

↓

Docker Container
```

Everything starts with the Dockerfile.

---

# 📝 Dockerfile

Example:

```dockerfile
FROM eclipse-temurin:21-jre

WORKDIR /app

COPY target/student-results-api.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java","-jar","app.jar"]
```

This file describes how Docker should build the image.

---

# 🏗️ Building an Image

Command:

```bash
docker build -t student-api .
```

Flow:

```text
Dockerfile

↓

Read Instructions

↓

Execute Each Instruction

↓

Create Layers

↓

Image
```

Docker processes the Dockerfile one instruction at a time.

---

# 📦 Image Layers

Every Dockerfile instruction creates a new layer.

Example:

```dockerfile
FROM ubuntu

RUN apt update

RUN apt install nginx

COPY app /

ENTRYPOINT ["nginx"]
```

Layers:

```text
Layer 5

ENTRYPOINT

──────────────

Layer 4

COPY app

──────────────

Layer 3

Install nginx

──────────────

Layer 2

apt update

──────────────

Layer 1

Ubuntu Base Image
```

Each layer is immutable.

---

# 💾 Why Layers?

Suppose two images:

```text
Image A

Ubuntu

Java

Spring Boot

---------------

Image B

Ubuntu

Java

Tomcat
```

Shared layers:

```text
Ubuntu

↓

Java

↓

Shared

↓

Only Top Layer Different
```

Docker stores identical layers only once.

This saves:

* Disk space
* Download time
* Build time

---

# 📂 Image Storage

Docker stores images internally.

```text
Docker Image

↓

Layer

↓

Layer

↓

Layer

↓

Layer
```

On Linux:

```text
/var/lib/docker/
```

Using the Overlay2 storage driver, layers are stored separately and combined at runtime.

---

# 🗂️ Overlay Filesystem

Docker uses **OverlayFS**.

Imagine:

```text
Layer 4

↓

Layer 3

↓

Layer 2

↓

Layer 1
```

OverlayFS merges them into:

```text
Single Filesystem
```

The container sees one unified filesystem even though it is built from many layers.

---

# 🏷️ Image Tags

Example:

```bash
docker pull nginx:latest
```

Here:

```text
nginx

↓

Repository

-----------------

latest

↓

Tag
```

Tags identify different versions of the same image.

Examples:

```text
postgres:17

ubuntu:24.04

redis:8

nginx:1.29
```

---

# 🌍 Docker Registry

Images are usually stored in a registry.

Example:

```text
Docker CLI

↓

Docker Hub

↓

Image Download
```

Popular registries:

* Docker Hub
* GitHub Container Registry
* Amazon ECR
* Azure Container Registry
* Google Artifact Registry

---

# 🚀 Image Pull Process

When you execute:

```bash
docker pull nginx
```

Docker performs:

```text
Docker Hub

↓

Manifest

↓

Layer 1

↓

Layer 2

↓

Layer 3

↓

Local Image Store
```

Only missing layers are downloaded.

---

# 📦 Creating a Container

Suppose:

```bash
docker run nginx
```

Execution:

```text
Image

↓

Create Writable Layer

↓

OverlayFS

↓

Namespaces

↓

cgroups

↓

nginx Process
```

Notice:

The original image is **never modified**.

---

# 🍃 Student Results API Example

Dockerfile:

```dockerfile
FROM eclipse-temurin:21-jre

COPY student-results-api.jar app.jar

ENTRYPOINT ["java","-jar","app.jar"]
```

Build:

```bash
docker build -t student-api .
```

Image:

```text
Ubuntu Layer

↓

Java Runtime

↓

Spring Boot JAR

↓

Metadata
```

Run:

```bash
docker run student-api
```

Container:

```text
Writable Layer

↓

Java Process

↓

Spring Boot

↓

Tomcat

↓

Student Results API
```

---

# 🔄 Image vs Container

Image:

```text
Read Only

↓

Reusable

↓

Immutable
```

Container:

```text
Running

↓

Writable Layer

↓

Linux Process
```

Comparison:

| Docker Image               | Docker Container       |
| -------------------------- | ---------------------- |
| Read-only                  | Read-write             |
| Template                   | Running instance       |
| Immutable                  | Mutable                |
| Can create many containers | Created from one image |

---

# 📊 Complete Image Lifecycle

```text
Developer

↓

Dockerfile

↓

docker build

↓

Docker Image

↓

Docker Registry

↓

docker pull

↓

Local Image

↓

docker run

↓

Container
```

---

# 🚫 Common Mistakes

## ❌ Thinking an Image Is a Container

An image is **not running**.

It is only a template.

---

## ❌ Thinking Images Can Change

Images are immutable.

Any modification creates a **new image layer**.

---

## ❌ Installing Software Inside Running Containers

Running:

```bash
apt install vim
```

inside a container changes only that container's writable layer.

The image remains unchanged.

For permanent changes, modify the Dockerfile and rebuild the image.

---

# 🐳 Docker Internal View

```text
Docker CLI
      │
      ▼
Docker Image
      │
      ▼
OverlayFS
      │
      ▼
Writable Layer
      │
      ▼
Linux Process
```

The image supplies the filesystem; the container adds a writable layer and executes a process.

---

# ☸️ Kubernetes Perspective

Kubernetes never builds images.

Instead:

```text
Deployment

↓

Container Image

↓

Image Pull

↓

Container

↓

Pod
```

Kubernetes simply instructs the container runtime to pull an image and start a container.

---

# 🧪 Hands-on Lab

## Pull an Image

```bash
docker pull nginx
```

List local images:

```bash
docker images
```

---

## Inspect an Image

```bash
docker inspect nginx
```

Observe:

* Image ID
* Layers
* Entrypoint
* Environment variables

---

## View Image History

```bash
docker history nginx
```

Notice that each Dockerfile instruction corresponds to a layer.

---

## Build Your Own Image

```bash
docker build -t student-api .
```

Then verify:

```bash
docker images
```

---

## Compare Image and Container

Run:

```bash
docker run -d nginx
```

List:

```bash
docker images

docker ps
```

Observe:

* Images are templates
* Containers are running instances

---

# 📈 Complete Image Flow

```text
Dockerfile
     │
     ▼
docker build
     │
     ▼
Layer 1
     │
     ▼
Layer 2
     │
     ▼
Layer 3
     │
     ▼
Docker Image
     │
     ▼
docker run
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
Java Process
     │
     ▼
Spring Boot
```

This is the complete journey from a Dockerfile to a running container.

---

# 📊 Docker Image Components

| Component     | Responsibility                                                     |
| ------------- | ------------------------------------------------------------------ |
| 📝 Dockerfile | Defines how an image is built                                      |
| 📦 Image      | Immutable filesystem template                                      |
| 🧱 Layer      | Read-only filesystem change created by each Dockerfile instruction |
| 🗂️ OverlayFS | Merges layers into a unified filesystem                            |
| 🏷️ Tag       | Identifies a specific image version                                |
| 🌍 Registry   | Stores and distributes images                                      |
| 📦 Container  | Running instance of an image with a writable layer                 |

---

# 💡 Key Takeaways

✅ A Docker image is an immutable, read-only filesystem template.

✅ Images are built from Dockerfiles, with each instruction producing a separate layer.

✅ Docker stores identical layers only once, reducing storage and download time.

✅ OverlayFS combines multiple read-only layers with a writable container layer to present a single filesystem.

✅ Containers are created from images and add a writable layer plus an isolated Linux process.

✅ Images are versioned using tags and distributed through container registries.

✅ Understanding images and layers is essential before learning writable layers, volumes, image optimization, and Kubernetes image management.

---

# ➡️ Next Chapter

📘 **`09-Docker/03-Dockerfile.md`**

In the next chapter, we'll dive deep into the **Dockerfile** itself.

We'll answer questions like:

* 📝 How does Docker execute each Dockerfile instruction?
* 🧱 Why does every instruction create a layer?
* 💾 How does Docker cache builds?
* ⚡ Why are some builds much faster than others?
* 🎯 What are the best practices for writing production-ready Dockerfiles?

By the end of the next chapter, you'll understand exactly how Docker transforms a Dockerfile into an efficient, layered image.
