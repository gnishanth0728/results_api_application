# 📘 Chapter 83 — Kubernetes kubelet

> 📂 File: `student-results-api-notes/10-Kubernetes/06-Kubelet.md`

This chapter explains the most important component on every Kubernetes worker node.

So far you've learned:

API Server stores the desired state.
etcd stores Kubernetes objects.
Scheduler chooses the worker node.
Controller Manager ensures the desired state is maintained.

Now another important question appears:

Once the Scheduler assigns a Pod to a node, who actually creates the containers?

For example:

Deployment

↓

Pod

↓

Worker Node Assigned

The Pod is assigned to worker-2.

Now what?

Who:

Downloads the image?
Creates the Pod sandbox?
Starts the containers?
Monitors container health?
Executes liveness and readiness probes?
Reports Pod status back to the API Server?

The answer is:

kubelet

The kubelet is the primary agent running on every Kubernetes worker node.

It bridges the gap between the Kubernetes control plane and the Linux operating system.

Without kubelet, Pods would never become running containers.

---

# 🌍 Introduction

In the previous chapter, we learned about the **Controller Manager**.

Controllers continuously reconcile:

```text
Desired State

↓

Actual State
```

The Scheduler then assigns a Pod to a Worker Node.

Example:

```text
student-api Pod

↓

worker-2
```

But another important question appears:

> 🤔 **Who actually starts the Pod on worker-2?**

The Scheduler only chooses the node.

The Controller only ensures the Pod should exist.

The component responsible for creating and managing Pods on each node is:

# ⚙️ kubelet

Every Worker Node runs exactly one kubelet process.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* ⚙️ What kubelet is
* 👀 Watch Mechanism
* 📦 Pod Synchronization
* 🔗 CRI (Container Runtime Interface)
* 📦 Pod Sandbox
* 🏃 Container Creation
* ❤️ Liveness Probes
* ✅ Readiness Probes
* 📊 Status Reporting
* ☸️ Complete Pod Lifecycle

---

# ❓ What Is kubelet?

kubelet is the primary node agent.

Its responsibilities include:

* Watching for Pods assigned to its node
* Creating Pods
* Starting containers
* Monitoring container health
* Running health probes
* Reporting status to the API Server

Architecture:

```text
API Server

↓

kubelet

↓

containerd

↓

Linux Kernel
```

---

# 🏗️ Worker Node Architecture

Every worker node contains:

```text
Worker Node

├── kubelet

├── kube-proxy

├── containerd

├── CNI Plugins

└── Pods
```

The kubelet coordinates all Pod-related operations.

---

# 👀 Watching Assigned Pods

Suppose the Scheduler updates:

```yaml
spec:
  nodeName: worker-2
```

The kubelet on `worker-2` receives:

```text
Watch Event

↓

New Assigned Pod
```

Only the kubelet running on the assigned node reacts to that event.

---

# 📦 Pod Synchronization Loop

The kubelet continuously executes a synchronization loop.

```text
Observe

↓

Compare

↓

Create / Update / Delete

↓

Report Status

↓

Repeat
```

This loop ensures the actual containers match the Pod specification.

---

# 🔗 Container Runtime Interface (CRI)

The kubelet does **not** create containers itself.

Instead, it communicates with a container runtime through the **Container Runtime Interface (CRI)**.

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

The CRI is implemented using gRPC.

This abstraction allows Kubernetes to work with different runtimes such as:

* containerd
* CRI-O

---

# 📦 Step 1 — Create Pod Sandbox

Before application containers start, kubelet asks the runtime to create a **Pod Sandbox**.

The sandbox provides:

* Network namespace
* Shared IPC namespace
* Shared UTS namespace

Architecture:

```text
Pod Sandbox

↓

Pause Container

↓

Application Containers
```

The sandbox is represented by the small **pause container**.

---

# 🏃 Step 2 — Pull Images

If the required image does not exist locally:

```text
student-api:1.0

↓

Image Pull

↓

Container Registry
```

The runtime downloads the image before starting the container.

---

# 🏃 Step 3 — Create Containers

Once the sandbox is ready:

```text
containerd

↓

Create Container

↓

runc

↓

clone()

↓

execve()

↓

Java Process
```

Eventually:

```text
Spring Boot

↓

Tomcat

↓

Student Results API
```

becomes a normal Linux process.

---

# ❤️ Liveness Probe

Example:

```yaml
livenessProbe:
  httpGet:
    path: /actuator/health
    port: 8080
```

The kubelet periodically checks the endpoint.

```text
Probe

↓

Healthy?

│

├── Yes

└── No

↓

Restart Container
```

Liveness probes determine whether a container should be restarted.

---

# ✅ Readiness Probe

Example:

```yaml
readinessProbe:
  httpGet:
    path: /actuator/health
    port: 8080
```

The kubelet checks whether the application is ready to receive traffic.

```text
Ready?

│

├── Yes → Add to Service

└── No → Remove from Service
```

A failing readiness probe does **not** restart the container.

---

# 📊 Reporting Status

The kubelet continuously reports:

* Node health
* Pod status
* Container status
* Probe results
* Resource usage (through integrations such as Metrics Server)

Flow:

```text
Worker Node

↓

kubelet

↓

API Server

↓

Status Updated
```

---

# 🔄 Pod Lifecycle

Complete sequence:

```text
Pending

↓

Scheduled

↓

Image Pull

↓

Pod Sandbox

↓

Containers

↓

Running
```

If a container exits unexpectedly:

```text
Container Exit

↓

kubelet Detects

↓

Restart (Depending on restartPolicy)
```

---

# 🍃 Student Results API Example

Deployment:

```yaml
replicas: 3
```

Execution:

```text
Deployment

↓

ReplicaSet

↓

Pod

↓

Scheduler

↓

worker-2

↓

kubelet

↓

containerd

↓

Pause Container

↓

Java Container

↓

Spring Boot

↓

Tomcat
```

---

# 📊 kubelet Architecture

```text
                 API Server
                      │
                Watch Events
                      │
                      ▼
                  kubelet
                      │
      ┌───────────────┼────────────────┐
      ▼               ▼                ▼
  Pod Sandbox     Image Pull     Health Probes
      │               │                │
      └───────────────┼────────────────┘
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
                 Java Process
```

---

# 🧠 Pod Sandbox (Pause Container)

Every Pod starts with a small **pause container**.

Purpose:

* Owns the Pod's network namespace
* Owns the Pod's IPC namespace
* Owns the Pod's UTS namespace

Application containers join these namespaces.

Example:

```text
Pod

├── Pause Container

├── Spring Boot

└── Fluent Bit
```

All containers share the same network namespace.

---

# 💥 Container Crash Example

Suppose:

```text
Java Process

↓

Crash
```

The kubelet observes the exit event.

If the Pod's `restartPolicy` is `Always`:

```text
Container Exit

↓

kubelet

↓

containerd

↓

New Container
```

The Pod remains on the same node unless a higher-level controller replaces it.

---

# 🚫 Common Mistakes

## ❌ Thinking kubelet Schedules Pods

The Scheduler assigns Pods to nodes.

The kubelet only manages Pods already assigned to its node.

---

## ❌ Thinking kubelet Creates Containers Directly

The kubelet communicates with the container runtime through the CRI.

The runtime creates containers.

---

## ❌ Thinking Readiness and Liveness Are the Same

**Liveness Probe**

* Detects dead or stuck applications
* May restart containers

**Readiness Probe**

* Determines whether traffic should be sent
* Does not restart containers

---

# 🐳 Docker Comparison

Docker:

```text
docker run

↓

dockerd

↓

container
```

Kubernetes:

```text
kubelet

↓

CRI

↓

containerd

↓

container
```

The kubelet acts as the orchestration agent on each node.

---

# 🧪 Hands-on Lab

## View kubelet

On a worker node:

```bash
ps -ef | grep kubelet
```

Observe the kubelet process.

---

## Inspect Node Status

```bash
kubectl get nodes

kubectl describe node <node-name>
```

Notice the status reported by kubelet.

---

## View Pod Events

```bash
kubectl describe pod <pod-name>
```

Observe events such as:

* Scheduled
* Pulling image
* Pulled image
* Created container
* Started container

These events reflect kubelet activity.

---

## Watch Pod Creation

```bash
kubectl get pods --watch
```

Create a Deployment and observe the Pod move through:

```text
Pending

↓

ContainerCreating

↓

Running
```

---

## Inspect the Pause Container

On the worker node:

```bash
sudo crictl pods

sudo crictl ps
```

Observe the Pod sandbox and the application containers.

---

## View kubelet Logs

On a systemd-based node:

```bash
journalctl -u kubelet -f
```

Watch kubelet process events in real time.

---

# 📈 Complete kubelet Flow

```text
kubectl apply
      │
      ▼
API Server
      │
      ▼
Scheduler
      │
      ▼
Assign nodeName
      │
      ▼
kubelet
      │
      ├── Create Pod Sandbox
      ├── Pull Images
      ├── Create Containers
      ├── Execute Probes
      ├── Report Status
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
Java Process
      │
      ▼
Spring Boot
```

This is the complete lifecycle of a Pod after scheduling.

---

# 📊 kubelet Responsibilities

| Responsibility         | Description                                              |
| ---------------------- | -------------------------------------------------------- |
| 👀 Watch Assigned Pods | Detect Pods scheduled to its node                        |
| 📦 Pod Synchronization | Ensure actual containers match the Pod specification     |
| 🔗 CRI Communication   | Interact with the container runtime using gRPC           |
| 📦 Pod Sandbox         | Create and manage the pause container                    |
| 🏃 Container Lifecycle | Pull images, create, start, stop, and restart containers |
| ❤️ Health Probes       | Execute liveness, readiness, and startup probes          |
| 📊 Status Reporting    | Report node and Pod status to the API Server             |

---

# 💡 Key Takeaways

✅ kubelet is the primary Kubernetes agent running on every worker node.

✅ It watches the API Server for Pods assigned to its node and ensures they are running correctly.

✅ kubelet communicates with the container runtime through the **Container Runtime Interface (CRI)**.

✅ Every Pod starts with a **pause container**, which owns the shared network, IPC, and UTS namespaces.

✅ kubelet executes liveness, readiness, and startup probes and reports status back to the API Server.

✅ kubelet does not schedule Pods or create containers directly—it coordinates with the Scheduler and the container runtime.

✅ At the lowest level, kubelet ultimately causes `containerd` and `runc` to create Linux processes that run your applications.

---

# ➡️ Next Chapter

📘 **`10-Kubernetes/07-Container-Runtime.md`**

In the next chapter, we'll follow the final stage of Pod creation:

* 🔗 How kubelet communicates with `containerd`
* 📦 What CRI requests look like
* 🏃 How `containerd` invokes `runc`
* 🧬 How Linux namespaces and cgroups are configured
* 🚀 How the Spring Boot application finally becomes a running Linux process

By the end of the next chapter, you'll have traced the complete path from a Kubernetes YAML manifest to a running process in the Linux kernel.
