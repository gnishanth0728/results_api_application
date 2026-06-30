# 📘 Chapter 74 — Docker OverlayFS

> 📂 File: `student-results-api-notes/09-Docker/06-OverlayFS.md`

This chapter explains one of Docker's most brilliant technologies.

So far you've learned:

📦 Images are read-only
📦 Containers have a writable layer
🐧 Namespaces isolate the container
💾 cgroups limit resources

Now the next question is:

How does Docker combine multiple image layers and one writable layer into a single filesystem?

When you enter a container, you see:

/

├── app

├── bin

├── etc

├── usr

└── var

But internally, those files come from many different directories.

The technology that makes this possible is:

OverlayFS

OverlayFS is one of the biggest reasons Docker is:

🚀 Fast
💾 Space efficient
⚡ Easy to build
📦 Layered

Understanding OverlayFS also explains why Docker images are immutable and how Copy-on-Write (CoW) works.

---

# 🌍 Introduction

In the previous chapter, we learned about **Linux cgroups**.

We saw that Docker containers use:

* 🐧 Namespaces for isolation
* 💾 cgroups for resource limits

Now another important question appears:

> 🤔 **How does Docker combine multiple read-only image layers with one writable container layer into a single filesystem?**

The answer is:

# 📂 OverlayFS

OverlayFS is a Linux union filesystem.

It merges multiple directories into one unified view that the container sees.

Without OverlayFS, Docker's layered image architecture would not exist.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📂 What OverlayFS is
* 📦 Image Layers
* 📝 Writable Layer
* 📋 Upper Layer
* 📚 Lower Layers
* 🔄 Copy-on-Write (CoW)
* 💾 Layer Storage
* ⚡ Build Cache
* 🐳 Docker Implementation
* ☸️ Kubernetes Relationship

---

# ❓ What Is OverlayFS?

OverlayFS is a Linux filesystem that combines several directories into a single mounted filesystem.

Suppose we have:

```text id="m7q2r8"
Layer 1

Ubuntu

----------------

Layer 2

Java

----------------

Layer 3

Spring Boot
```

OverlayFS presents:

```text id="j5v9k1"
/

├── bin

├── etc

├── app

├── usr
```

The application sees only one filesystem.

---

# 🏗️ Docker Filesystem Architecture

```text id="n4p7x5"
Writable Layer
      │
      ▼
Spring Boot Layer
      │
      ▼
Java Layer
      │
      ▼
Ubuntu Layer
```

OverlayFS merges all layers into a single root filesystem.

---

# 📚 Lower Layers

Image layers are called **Lower Layers**.

Example:

```text id="r8k3m6"
Ubuntu

↓

Java Runtime

↓

Application Files
```

Characteristics:

* Read-only
* Shared
* Immutable

Multiple containers can reuse the same lower layers.

---

# 📝 Upper Layer

Every container receives its own **Upper Layer**.

```text id="t6n1q9"
Upper Layer

↓

Writable

↓

Unique Per Container
```

All runtime changes are stored here.

Examples:

* Create files
* Delete files
* Modify files
* Write logs

The image layers remain untouched.

---

# 📂 Merged View

Internally:

```text id="c2m8v4"
Upper Layer

↓

Lower Layer 3

↓

Lower Layer 2

↓

Lower Layer 1
```

Container sees:

```text id="k9r5p2"
/

├── app

├── bin

├── etc

├── usr
```

Everything appears as one filesystem.

---

# 🔄 Copy-on-Write (CoW)

Suppose a file exists:

```text id="v7m4q1"
/etc/config.yml
```

Location:

```text id="x5p8n6"
Lower Layer
```

Application updates the file.

Docker **does not** modify the lower layer.

Instead:

```text id="a3k7r5"
Copy File

↓

Upper Layer

↓

Modify Copy
```

This is called **Copy-on-Write (CoW)**.

---

# 📊 Copy-on-Write Example

Image:

```text id="w8n2m4"
Ubuntu Layer

↓

/etc/hosts
```

Container updates:

```text id="e1p9q7"
/etc/hosts
```

Execution:

```text id="u6k3v8"
Read Lower Layer

↓

Copy File

↓

Upper Layer

↓

Modify
```

Original image remains unchanged.

---

# 📦 File Read Operation

Suppose the application opens:

```text id="b5r7n2"
/app/app.jar
```

OverlayFS searches:

```text id="f9m1q6"
Upper Layer?

│

├── Yes → Read

└── No

↓

Lower Layer 3

↓

Lower Layer 2

↓

Lower Layer 1
```

The first matching file is returned.

---

# ✍️ File Write Operation

Suppose:

```text id="y4k8p3"
/logs/app.log
```

Application writes:

```text id="d7v2m5"
Upper Layer

↓

Write File
```

The image layers are never modified.

---

# 🗑️ File Deletion

Deleting a file does **not** remove it from the image.

Instead Docker creates a **whiteout file**.

Example:

```text id="p8n5r4"
Lower Layer

↓

config.yml

-------------------

Upper Layer

↓

Whiteout File
```

Merged view:

```text id="q2m9v1"
config.yml

↓

Hidden
```

The original file still exists in the lower layer.

---

# 💾 Layer Storage

On Linux:

```text id="h7p3k6"
/var/lib/docker/
```

Typical structure:

```text id="m1q8r5"
overlay2/

↓

layer1

↓

layer2

↓

layer3

↓

container layer
```

Each layer is stored separately.

---

# ⚡ Build Cache

Suppose Dockerfile:

```dockerfile id="r5v2n7"
FROM ubuntu

RUN apt update

RUN apt install java

COPY app.jar .
```

Docker builds:

```text id="z9k4m2"
Layer 1

↓

Layer 2

↓

Layer 3

↓

Layer 4
```

If only:

```dockerfile id="j6m8p1"
COPY app.jar .
```

changes,

Docker reuses:

```text id="g3q7v5"
Layer 1

Layer 2

Layer 3
```

Only Layer 4 is rebuilt.

This makes Docker builds much faster.

---

# 🍃 Student Results API Example

Dockerfile:

```dockerfile id="t4n9k6"
FROM eclipse-temurin:21-jre

COPY student-results-api.jar app.jar

ENTRYPOINT ["java","-jar","app.jar"]
```

Image:

```text id="u1m5q8"
Ubuntu

↓

JRE

↓

Spring Boot JAR
```

Container starts:

```text id="a8r3v2"
Writable Layer

↓

logs/

↓

temp/

↓

cache/
```

Only runtime changes are stored in the writable layer.

---

# 📊 OverlayFS Architecture

```text id="n5p8m4"
             Container

                 │

                 ▼

          Merged Filesystem

                 │

        ┌────────┴────────┐

        ▼                 ▼

   Upper Layer      Lower Layers

 Writable          Read-only

                       │

          Ubuntu → Java → App
```

---

# 🚫 Common Mistakes

## ❌ Thinking Containers Modify Images

Containers never modify image layers.

All modifications go to the writable upper layer.

---

## ❌ Thinking Every Container Stores a Full Filesystem

Containers share lower layers.

Only the upper layer is unique.

This greatly reduces storage usage.

---

## ❌ Confusing Image Layers with Directories

Each layer represents a filesystem diff.

It is not simply a normal folder copied into another folder.

OverlayFS merges these filesystem diffs into one view.

---

# 🐳 Docker Internal View

```text id="s7k2m9"
Docker Image
      │
      ▼
Lower Layers
      │
      ▼
OverlayFS
      │
      ▼
Upper Layer
      │
      ▼
Merged Filesystem
      │
      ▼
Java Process
```

The application interacts only with the merged filesystem.

---

# ☸️ Kubernetes Perspective

Pods use the same layered filesystem model.

```text id="v4q8n1"
Pod

↓

Container Runtime

↓

OverlayFS

↓

Merged Filesystem

↓

Application
```

Kubernetes delegates filesystem management to the underlying container runtime.

---

# 🧪 Hands-on Lab

## Pull an Image

```bash id="k2p7m5"
docker pull nginx
```

Inspect image history:

```bash id="c8r3v9"
docker history nginx
```

Observe the image layers.

---

## Inspect Overlay Storage

On the host:

```bash id="q5m1n8"
sudo ls /var/lib/docker/overlay2
```

Observe multiple layer directories.

---

## Modify a File

Run:

```bash id="r9k4p2"
docker run -it ubuntu bash
```

Inside the container:

```bash id="f7n2v6"
echo "Hello" > /tmp/demo.txt
```

Exit the container.

Notice that the image itself remains unchanged.

---

## Compare Containers

Start two containers:

```bash id="j3p8m1"
docker run -it ubuntu

docker run -it ubuntu
```

Create different files in each container.

Observe that each container has its own writable layer.

---

## Inspect the Writable Layer

```bash id="m6v2q7"
docker inspect <container-id>
```

Look for storage driver information and layer references.

---

# 📈 Complete OverlayFS Flow

```text id="x8n5r3"
Docker Image
     │
     ▼
Lower Layer 1
     │
     ▼
Lower Layer 2
     │
     ▼
Lower Layer 3
     │
     ▼
Upper Layer
     │
     ▼
OverlayFS
     │
     ▼
Merged Filesystem
     │
     ▼
Java Process
     │
     ▼
Spring Boot
```

This is the complete filesystem architecture of a Docker container.

---

# 📊 OverlayFS Components

| Component          | Responsibility                                     |
| ------------------ | -------------------------------------------------- |
| 📚 Lower Layers    | Immutable image layers shared across containers    |
| 📝 Upper Layer     | Writable layer unique to each container            |
| 🔄 Copy-on-Write   | Copies files from lower layers before modification |
| 🗑️ Whiteout Files | Hide deleted files from lower layers               |
| 📂 Merged View     | Unified filesystem presented to the container      |
| ⚡ Build Cache      | Reuses unchanged image layers to speed up builds   |

---

# 💡 Key Takeaways

✅ OverlayFS is a Linux union filesystem that merges multiple image layers and one writable layer into a single filesystem.

✅ Image layers are immutable lower layers that can be shared across many containers.

✅ Every container receives its own writable upper layer for runtime changes.

✅ Copy-on-Write (CoW) ensures that modifying a file copies it from a lower layer into the upper layer before changes are applied.

✅ Deleting a file creates a whiteout entry, hiding the file without modifying the underlying image layer.

✅ Docker build caching relies on immutable layers, making incremental builds much faster.

✅ Understanding OverlayFS is essential for learning Docker volumes, image optimization, container storage, and Kubernetes persistent storage.

---

# ➡️ Next Chapter

📘 **`09-Docker/07-Container-Lifecycle.md`**

In the next chapter, we'll follow the **complete lifecycle of a Docker container**.

We'll learn:

* ▶️ What happens during `docker create`
* 🚀 How `docker start` differs from `docker run`
* ⏸️ Pause and unpause using the Linux freezer mechanism
* 🛑 What happens during `docker stop`
* 💀 SIGTERM vs SIGKILL
* 🗑️ What happens when a container is removed

By the end of the chapter, you'll understand every state transition a container experiences from creation to deletion.
