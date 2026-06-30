# 📘 Chapter 81 — Kubernetes Scheduler

> 📂 File: `student-results-api-notes/10-Kubernetes/04-Scheduler.md`

This chapter explains how Kubernetes decides where a Pod should run.

After learning about the API Server and etcd, the next logical question is:

Once a Deployment is stored in etcd, how does Kubernetes decide which worker node should run the Pod?

Suppose you have:

Worker-1

4 CPU
8 GB RAM

------------

Worker-2

16 CPU
32 GB RAM

------------

Worker-3

8 CPU
16 GB RAM

A new Pod is created.

How does Kubernetes decide?

Does it pick a random node?
The first node?
The least busy node?
The node with the most free CPU?
The closest node?

The answer is:

The Kubernetes Scheduler

The Scheduler is one of the most intelligent components in Kubernetes.

It evaluates every worker node, filters out unsuitable ones, scores the remaining candidates, and selects the best node based on scheduling policies.

This chapter explains the Scheduler from the moment a Pod is created until it is assigned to a node.

---

# 🌍 Introduction

In the previous chapter, we learned that Kubernetes stores every object in **etcd**.

Example:

```bash id="x8n2q4"
kubectl apply -f deployment.yaml
```

Flow:

```text id="k4m7r1"
kubectl

↓

API Server

↓

etcd
```

But another important question appears:

> 🤔 **Who decides where a Pod should run?**

When a Deployment creates a Pod, the Pod initially has **no assigned node**.

Something must examine the cluster and select the most appropriate Worker Node.

That component is:

# 🎯 Kubernetes Scheduler

The Scheduler assigns unscheduled Pods to Worker Nodes.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🎯 What the Scheduler is
* 📦 Pending Pods
* 🔍 Filtering Phase
* ⭐ Scoring Phase
* 💻 CPU & Memory Requests
* 📍 Node Affinity
* 🚫 Taints & Tolerations
* ⚖️ Scheduling Decision
* ☸️ Pod Assignment
* 🖥️ Worker Node Selection

---

# ❓ What Is the Scheduler?

The Scheduler watches the API Server for Pods that do not yet have a node assigned.

Example:

```yaml id="a5p3n8"
status:

  phase: Pending
```

The Scheduler chooses the best node and updates the Pod specification.

---

# 🏗️ Scheduling Architecture

```text id="v8m4q2"
Developer

↓

kubectl

↓

API Server

↓

etcd

↓

Scheduler

↓

Worker Node
```

The Scheduler never starts containers.

It only selects the node.

---

# 📦 Pending Pod

Immediately after creation:

```text id="j2r9k5"
Pod

↓

Pending

↓

No Node
```

Example:

```bash id="w6n3m1"
kubectl get pods
```

Output:

```text id="q7p8r4"
student-api

Pending
```

The Scheduler continuously watches for these Pods.

---

# 👀 Scheduler Watch

The Scheduler subscribes to the API Server Watch API.

```text id="n4k1v7"
API Server

↓

Watch Event

↓

New Pod
```

Whenever a new unscheduled Pod appears, the scheduling process begins.

---

# 🔍 Phase 1 — Filtering

The Scheduler first removes nodes that cannot run the Pod.

Suppose:

```text id="p9m5q2"
Worker A

2 CPU Free

------------

Worker B

0 CPU Free

------------

Worker C

4 CPU Free
```

Pod requires:

```yaml id="x3r7n6"
cpu: 2
```

Filtering result:

```text id="c8v4m9"
Worker A ✔

Worker B ✖

Worker C ✔
```

Worker B is eliminated because it lacks sufficient resources.

---

# 💻 Resource Requests

Example:

```yaml id="h6p2q5"
resources:
  requests:
    cpu: "1"
    memory: "512Mi"
```

The Scheduler considers **requests**, not limits.

Available resources are compared with requested resources before assigning the Pod.

---

# 📍 Node Affinity

Some Pods should run only on specific nodes.

Example:

```yaml id="m8k3v1"
nodeSelector:
  disk: ssd
```

Or:

```yaml id="t5q9r7"
affinity:
  nodeAffinity:
```

The Scheduler removes nodes that do not satisfy the affinity rules.

---

# 🚫 Taints and Tolerations

Example node:

```text id="y4n8p6"
GPU Node

↓

NoSchedule
```

Pod:

```yaml id="g2m7k9"
tolerations:
```

Only Pods with the required toleration may run on that node.

---

# ⭐ Phase 2 — Scoring

After filtering:

```text id="r1q6m8"
Worker A

Worker C
```

The Scheduler assigns scores.

Example:

| Node     | Score |
| -------- | ----: |
| Worker A |    70 |
| Worker C |    95 |

Highest score wins.

Scoring considers many factors such as resource balance, topology preferences, image locality, and scheduling plugins.

---

# 🏆 Node Selection

Suppose:

```text id="b9k2v5"
Worker C

Score 95
```

The Scheduler updates the Pod:

```text id="w3m7r1"
spec.nodeName

↓

worker-c
```

The Pod is now assigned.

---

# 🔄 Scheduler Workflow

Complete sequence:

```text id="e8q4n2"
Pending Pod

↓

Filter Nodes

↓

Score Nodes

↓

Select Best Node

↓

Update Pod

↓

API Server
```

After this step, kubelet on the selected node notices the assignment.

---

# 🍃 Student Results API Example

Deployment:

```yaml id="k6v1p8"
replicas: 3
```

Pods:

```text id="a7m9q3"
Pod 1

Pending

Pod 2

Pending

Pod 3

Pending
```

Scheduler result:

```text id="u4r8k6"
Pod 1

↓

Worker A

------------------

Pod 2

↓

Worker B

------------------

Pod 3

↓

Worker C
```

The Scheduler spreads the workload across the cluster when appropriate.

---

# 📊 Scheduler Architecture

```text id="d5n2m7"
               API Server
                    │
                    ▼
              Pending Pod
                    │
                    ▼
               Scheduler
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
     Filtering           Scoring
          │                   │
          └─────────┬─────────┘
                    ▼
             Best Worker Node
                    │
                    ▼
          Update Pod nodeName
                    │
                    ▼
               API Server
```

---

# 🧠 What the Scheduler Considers

The Scheduler evaluates many scheduling constraints.

Examples:

* CPU requests
* Memory requests
* Node capacity
* Node affinity
* Pod affinity
* Pod anti-affinity
* Taints
* Tolerations
* Topology spread constraints
* Image locality
* Scheduling plugins

Scheduling is plugin-based and extensible.

---

# 🔄 After Scheduling

Once:

```text id="p4m8k1"
nodeName

↓

worker-a
```

The Scheduler is finished.

Next:

```text id="n7q5v9"
kubelet

↓

containerd

↓

runc

↓

Linux Process
```

The kubelet performs container creation.

---

# 🚫 Common Mistakes

## ❌ Thinking the Scheduler Starts Containers

The Scheduler only assigns a node.

The kubelet on that node starts the Pod.

---

## ❌ Thinking the Scheduler Watches Worker Nodes Directly

The Scheduler watches the API Server for Pod updates.

It does not communicate directly with worker nodes.

---

## ❌ Thinking Limits Are Used for Scheduling

The Scheduler primarily uses **resource requests** to determine whether a node has enough available capacity.

Resource limits are enforced later by the container runtime and Linux cgroups.

---

# 🐳 Docker Comparison

Docker:

```text id="z2m6r4"
docker run

↓

Current Machine
```

Kubernetes:

```text id="q9v3k8"
Create Pod

↓

Scheduler

↓

Best Machine
```

Docker runs containers on the local host.

Kubernetes decides which node in the cluster should run each Pod.

---

# 🧪 Hands-on Lab

## Create a Deployment

```bash id="s5n8q2"
kubectl create deployment nginx --image=nginx
```

Observe:

```bash id="m3r7k6"
kubectl get pods -o wide
```

Notice the assigned node.

---

## View Pod Details

```bash id="v1p4m9"
kubectl describe pod <pod-name>
```

Look for:

```text id="f6k2r8"
Node:
```

This shows where the Scheduler placed the Pod.

---

## Watch Pending Pods

Create a Pod that requests more CPU than any node can provide.

```yaml id="x8m5q1"
resources:
  requests:
    cpu: "100"
```

Observe:

```bash id="h4n9v7"
kubectl describe pod <pod-name>
```

Look for scheduling events indicating insufficient CPU.

---

## View Node Resources

```bash id="j2q6m4"
kubectl describe node <node-name>
```

Observe:

* Capacity
* Allocatable
* Resource requests
* Resource limits

---

## Label a Node

```bash id="g9r3k5"
kubectl label node <node-name> disk=ssd
```

Create a Pod with:

```yaml id="p7m1v6"
nodeSelector:
  disk: ssd
```

Observe that the Scheduler places the Pod only on the labeled node.

---

# 📈 Complete Scheduling Flow

```text id="u8k4m2"
kubectl apply
      │
      ▼
API Server
      │
      ▼
etcd
      │
      ▼
Pending Pod
      │
      ▼
Scheduler
      │
      ├── Filter Nodes
      ├── Score Nodes
      │
      ▼
Best Node
      │
      ▼
Update nodeName
      │
      ▼
API Server
      │
      ▼
kubelet
      │
      ▼
containerd
      │
      ▼
Linux Process
```

This is the complete lifecycle of Kubernetes scheduling.

---

# 📊 Scheduler Responsibilities

| Responsibility        | Description                                                              |
| --------------------- | ------------------------------------------------------------------------ |
| 👀 Watch Pending Pods | Detects Pods without an assigned node                                    |
| 🔍 Filtering          | Removes nodes that cannot satisfy scheduling constraints                 |
| ⭐ Scoring             | Ranks eligible nodes using scheduling plugins                            |
| 🏆 Node Selection     | Chooses the highest-scoring node                                         |
| 📝 Pod Binding        | Updates the Pod with the selected `nodeName`                             |
| ⚖️ Resource Awareness | Considers CPU, memory, affinity, taints, tolerations, and topology rules |

---

# 💡 Key Takeaways

✅ The Kubernetes Scheduler assigns unscheduled Pods to worker nodes.

✅ New Pods begin in the **Pending** state until a node is selected.

✅ Scheduling consists of two major phases: **Filtering** (eliminate unsuitable nodes) and **Scoring** (rank eligible nodes).

✅ The Scheduler uses **resource requests**, not limits, when determining whether a node can host a Pod.

✅ Features such as node affinity, taints, tolerations, topology constraints, and scheduling plugins influence placement decisions.

✅ After assigning a node, the Scheduler's work is complete; kubelet on the chosen node creates the containers.

✅ Understanding the Scheduler is essential before learning kubelet, Pod lifecycle, resource management, autoscaling, and advanced scheduling policies.

---

# ➡️ Next Chapter

📘 **`10-Kubernetes/05-Controller-Manager.md`**

In the next chapter, we'll explore the **Kubernetes Controller Manager**.

We'll answer questions such as:

* 🔄 What is the reconciliation loop?
* 📦 How does a Deployment create ReplicaSets and Pods?
* 💥 What happens when a Pod crashes?
* 📈 How does scaling work?
* 🎯 How do controllers continuously maintain the desired state?

By the end of the chapter, you'll understand why Kubernetes is called a **declarative** system and how it continuously keeps the cluster in the desired state.
