# 📘 Chapter 84 — Kubernetes Container Runtime

> 📂 File: `student-results-api-notes/10-Kubernetes/07-ContainerRuntime.md`

This chapter is the final piece of the entire journey you've been building from the beginning of these notes.

So far you've learned:

HTTP Request
      ↓
Linux Network Stack
      ↓
Spring Boot
      ↓
Docker Container
      ↓
Kubernetes API Server
      ↓
etcd
      ↓
Scheduler
      ↓
Controller Manager
      ↓
kubelet

Now one final question remains:

How does kubelet actually create a Linux process?

The kubelet itself cannot create containers.

Instead, it delegates that responsibility to the Container Runtime.

This chapter follows the exact sequence:

kubelet
    ↓
CRI (gRPC)
    ↓
containerd
    ↓
containerd-shim
    ↓
runc
    ↓
clone()
    ↓
Namespaces
    ↓
cgroups
    ↓
OverlayFS
    ↓
execve()
    ↓
java -jar app.jar

By the end of this chapter, the entire journey—from kubectl apply to a running Linux process—will be complete.

---

# 🌍 Introduction

In the previous chapter, we learned that **kubelet** watches for Pods assigned to its node.

When a Pod is scheduled:

```text
Scheduler

↓

worker-2

↓

kubelet
```

But another important question appears:

> 🤔 **How does kubelet actually create containers?**

The answer is:

**It doesn't.**

Instead, kubelet communicates with a **Container Runtime** using the **Container Runtime Interface (CRI)**.

The runtime creates Linux containers using technologies we've already studied:

* Namespaces
* cgroups
* OverlayFS
* runc
* clone()
* execve()

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📦 What a Container Runtime is
* 🔗 Container Runtime Interface (CRI)
* ⚙️ containerd
* 🧩 containerd-shim
* 🏃 runc
* 🐧 Linux Namespaces
* 💾 cgroups
* 📂 OverlayFS
* 🚀 execve()
* ☸️ Complete Pod Creation

---

# ❓ What Is a Container Runtime?

A container runtime is software responsible for creating and managing containers.

Examples:

* containerd
* CRI-O

Responsibilities:

* Pull container images
* Create Pod sandboxes
* Create containers
* Start and stop containers
* Report container status
* Manage container lifecycle

---

# 🏗️ Runtime Architecture

```text
API Server
      │
      ▼
kubelet
      │
      ▼
CRI (gRPC)
      │
      ▼
containerd
      │
      ▼
containerd-shim
      │
      ▼
runc
      │
      ▼
Linux Kernel
```

---

# 🔗 Container Runtime Interface (CRI)

The CRI is a gRPC API between kubelet and the runtime.

Example operations:

```text
RunPodSandbox()

CreateContainer()

StartContainer()

StopContainer()

RemoveContainer()

ListContainers()
```

This abstraction allows Kubernetes to support multiple runtimes without changing kubelet.

---

# 📦 Step 1 — Create Pod Sandbox

Suppose kubelet receives:

```yaml
kind: Pod
```

First request:

```text
RunPodSandbox()
```

containerd creates:

```text
Pause Container

↓

Network Namespace

↓

IPC Namespace

↓

UTS Namespace
```

The pause container becomes the infrastructure container for the Pod.

---

# 🌐 Why the Pause Container?

Suppose a Pod contains:

```text
Spring Boot

+

Fluent Bit

+

Istio Proxy
```

All containers share:

* Network namespace
* Loopback interface
* IP address
* IPC namespace
* UTS namespace

The pause container owns these shared namespaces.

---

# 📥 Step 2 — Pull Images

If an image is not available locally:

```text
student-api:1.0

↓

Container Registry

↓

Pull Image
```

containerd stores the image locally using the content store and snapshotter.

---

# 📂 Step 3 — Prepare Root Filesystem

containerd prepares:

```text
Image Layers

↓

OverlayFS

↓

Merged Root Filesystem
```

This creates the container's root filesystem without modifying the original image.

---

# 💾 Step 4 — Configure cgroups

Example:

```yaml
resources:

  requests:

    cpu: "1"

    memory: "512Mi"

  limits:

    cpu: "2"

    memory: "1Gi"
```

containerd configures Linux cgroups:

```text
CPU

↓

2 Cores Maximum

----------------

Memory

↓

1 GiB Maximum
```

The kernel enforces these limits.

---

# 🐧 Step 5 — Configure Namespaces

runc creates:

```text
PID Namespace

Network Namespace

Mount Namespace

IPC Namespace

UTS Namespace
```

Each Pod receives isolated kernel resources.

---

# 🧬 Step 6 — clone()

Internally:

```text
clone()

↓

New Process

↓

Namespaces
```

Unlike `fork()`, `clone()` allows the runtime to create processes with selected namespaces.

---

# 🚀 Step 7 — execve()

Suppose the container image specifies:

```dockerfile
ENTRYPOINT ["java","-jar","app.jar"]
```

Eventually:

```text
execve()

↓

java -jar app.jar
```

The JVM starts.

---

# ☕ Java Process

Execution:

```text
JVM

↓

Spring Boot

↓

Tomcat

↓

Student Results API
```

At this point, the application is simply a Linux process running inside an isolated container.

---

# 🧩 containerd-shim

Between containerd and runc sits **containerd-shim**.

Responsibilities:

* Keeps the container running after `containerd` finishes the startup request.
* Tracks the container lifecycle.
* Collects exit status.
* Manages standard input/output streams.

Architecture:

```text
containerd

↓

containerd-shim

↓

runc

↓

Container
```

Each container has its own shim process.

---

# 🍃 Student Results API Example

Complete execution:

```text
Deployment

↓

Scheduler

↓

worker-2

↓

kubelet

↓

CRI

↓

containerd

↓

RunPodSandbox()

↓

Pause Container

↓

Pull Image

↓

OverlayFS

↓

cgroups

↓

Namespaces

↓

runc

↓

clone()

↓

execve()

↓

Java

↓

Spring Boot

↓

Tomcat
```

---

# 📊 Complete Runtime Architecture

```text
                API Server
                     │
                     ▼
                  kubelet
                     │
                 CRI (gRPC)
                     │
                     ▼
                 containerd
                     │
                     ▼
              containerd-shim
                     │
                     ▼
                    runc
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
 Namespaces     cgroups     OverlayFS
        │            │            │
        └────────────┼────────────┘
                     ▼
                  clone()
                     ▼
                  execve()
                     ▼
              java -jar app.jar
                     ▼
               Spring Boot
```

---

# 🔄 Complete Pod Creation Timeline

```text
Pod Assigned

↓

kubelet

↓

RunPodSandbox()

↓

Pause Container

↓

Pull Image

↓

Prepare Filesystem

↓

Create Container

↓

Start Container

↓

Running
```

---

# 💥 Container Crash

Suppose:

```text
Java Process

↓

Exit
```

Flow:

```text
containerd-shim

↓

containerd

↓

kubelet

↓

Restart Policy

↓

Create New Container
```

If the restart policy allows it, kubelet requests a new container through the runtime.

---

# 🚫 Common Mistakes

## ❌ Thinking kubelet Creates Containers

kubelet coordinates container creation but delegates the work to the container runtime via the CRI.

---

## ❌ Thinking runc Stays Running

`runc` is a short-lived OCI runtime.

After creating the container, it exits.

`containerd-shim` remains responsible for the running container.

---

## ❌ Thinking Docker Is Required for Kubernetes

Modern Kubernetes commonly uses:

* containerd
* CRI-O

Docker Engine is no longer required because Kubernetes communicates through the CRI.

---

# 🐳 Relationship with Docker

Docker Engine internally uses containerd.

```text
Docker CLI

↓

dockerd

↓

containerd

↓

runc

↓

Linux Process
```

Kubernetes bypasses Docker Engine:

```text
kubelet

↓

CRI

↓

containerd

↓

runc

↓

Linux Process
```

---

# 🧪 Hands-on Lab

## Inspect containerd

On a worker node:

```bash
ps -ef | grep containerd
```

Observe the containerd process.

---

## Inspect shim Processes

```bash
ps -ef | grep containerd-shim
```

Notice that each running Pod typically has one shim process per container.

---

## View Running Containers

```bash
sudo crictl ps
```

Observe containers managed by the runtime.

---

## Inspect Pod Sandbox

```bash
sudo crictl pods
```

Notice the Pod sandboxes (pause containers).

---

## Inspect Container Details

```bash
sudo crictl inspect <container-id>
```

Review:

* Image
* Runtime
* PID
* Sandbox information

---

## Observe Linux Processes

Find the container PID:

```bash
sudo crictl inspect <container-id>
```

Then:

```bash
ps -fp <PID>
```

Observe the JVM process running as a normal Linux process.

---

# 📈 Complete Kubernetes Runtime Flow

```text
kubectl apply
      │
      ▼
API Server
      │
      ▼
etcd
      │
      ▼
Controller Manager
      │
      ▼
Scheduler
      │
      ▼
kubelet
      │
      ▼
CRI
      │
      ▼
containerd
      │
      ▼
containerd-shim
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
java -jar app.jar
      │
      ▼
Spring Boot
      │
      ▼
Tomcat
```

This is the complete journey from a Kubernetes manifest to a running Linux process.

---

# 📊 Container Runtime Components

| Component          | Responsibility                                              |
| ------------------ | ----------------------------------------------------------- |
| ⚙️ kubelet         | Coordinates Pod lifecycle on the node                       |
| 🔗 CRI             | Standard gRPC interface between kubelet and the runtime     |
| 📦 containerd      | Manages images, snapshots, sandboxes, and containers        |
| 🧩 containerd-shim | Supervises running containers and maintains their lifecycle |
| 🏃 runc            | OCI runtime that creates the container process              |
| 🐧 Linux Kernel    | Provides namespaces, cgroups, and process management        |
| ☕ JVM              | Executes the Java application inside the container          |

---

# 💡 Key Takeaways

✅ kubelet delegates all container operations to a container runtime through the **Container Runtime Interface (CRI)**.

✅ `containerd` manages image pulling, snapshot preparation, Pod sandboxes, and container lifecycle.

✅ Every Pod begins with a **pause container**, which owns the shared network, IPC, and UTS namespaces.

✅ `runc` is the OCI runtime responsible for creating the container process using Linux primitives such as `clone()` and `execve()`.

✅ `containerd-shim` remains with the running container after `runc` exits and reports lifecycle events back to `containerd`.

✅ Linux namespaces, cgroups, and OverlayFS are the kernel technologies that make container execution possible.

✅ A Kubernetes Pod ultimately becomes one or more ordinary Linux processes running under the control of the Linux kernel.

---

# ➡️ Next Chapter

📘 **`10-Kubernetes/08-Pod.md`**

In the next chapter, we'll study the **Pod**, the smallest deployable unit in Kubernetes.

We'll answer questions such as:

* 📦 Why does Kubernetes use Pods instead of containers?
* 🏠 What is a Pod sandbox?
* 👥 How do multiple containers share the same network namespace?
* 🌐 Why do containers in the same Pod communicate using `localhost`?
* 🗂️ How are volumes shared inside a Pod?

By the end of the chapter, you'll understand the internal architecture of Pods and why they are the fundamental execution unit in Kubernetes.
