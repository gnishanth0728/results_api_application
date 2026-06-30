# 📘 Chapter 86 — Kubernetes ReplicaSet

> 📂 File: `student-results-api-notes/10-Kubernetes/09-ReplicaSet.md`

This chapter explains the component that actually keeps Pods alive.

After learning about Pods, the next obvious question is:

If a Pod is deleted, who creates a new one?

For example:

kubectl delete pod student-api-abc123

A few seconds later:

student-api-x7k92

appears automatically.

Why?

Who created it?

Similarly:

If a Pod crashes, who replaces it?
If a node fails, who recreates the Pods elsewhere?
If you scale from 3 replicas to 10 replicas, who creates the extra Pods?

Many beginners answer:

Deployment

This is not correct.

The real answer is:

ReplicaSet

A Deployment manages ReplicaSets.

A ReplicaSet manages Pods.

Understanding this relationship is essential because it explains almost every self-healing behavior in Kubernetes.

---

# 🌍 Introduction

In the previous chapter, we learned that a **Pod** is the smallest deployable unit in Kubernetes.

Example:

```yaml
kind: Pod
```

But another important question appears:

> 🤔 **Who ensures a Pod always exists?**

Suppose:

```text
Pod

↓

Deleted
```

A few seconds later:

```text
New Pod
```

appears automatically.

Who created it?

The answer is:

# 📄 ReplicaSet

A ReplicaSet continuously ensures that the required number of Pod replicas are running.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📄 What a ReplicaSet is
* 🔄 Desired vs Actual State
* ♾️ Reconciliation Loop
* 👀 Label Selectors
* 📦 Pod Templates
* 📈 Scaling
* 💥 Self-Healing
* 🏷️ Owner References
* 🛠️ ReplicaSet Controller
* ☸️ Deployment Relationship

---

# ❓ What Is a ReplicaSet?

A ReplicaSet is a Kubernetes resource that maintains a specified number of identical Pods.

Example:

```yaml
replicas: 3
```

ReplicaSet continuously ensures:

```text
Running Pods = 3
```

If the actual number differs, it creates or removes Pods until the desired count is restored.

---

# 🏗️ High-Level Architecture

```text
Deployment
      │
      ▼
 ReplicaSet
      │
      ▼
 ┌────┼────┐
 ▼    ▼    ▼
Pod  Pod  Pod
```

Important:

Deployment does **not** create Pods directly.

It creates a ReplicaSet.

The ReplicaSet creates Pods.

---

# 🌍 Desired vs Actual State

Suppose:

Desired:

```text
3 Pods
```

Actual:

```text
2 Pods
```

ReplicaSet detects:

```text
Difference

↓

Create One Pod
```

If:

Desired:

```text
3 Pods
```

Actual:

```text
5 Pods
```

ReplicaSet:

```text
Delete Two Pods
```

---

# 👀 Label Selector

ReplicaSets identify Pods using labels.

Example Pod:

```yaml
labels:
  app: student-api
```

ReplicaSet:

```yaml
selector:
  matchLabels:
    app: student-api
```

Only Pods with matching labels belong to the ReplicaSet.

---

# 📦 Pod Template

ReplicaSet contains a complete Pod template.

Example:

```yaml
template:

  metadata:

    labels:

      app: student-api

  spec:

    containers:
```

When a new Pod is needed, ReplicaSet creates it from this template.

---

# ♾️ Reconciliation Loop

ReplicaSet Controller continuously executes:

```text
Watch API

↓

Read Pods

↓

Compare Replica Count

↓

Different?

↓

Create/Delete Pods
```

This loop never stops.

---

# 📈 Scaling

Suppose:

```bash
kubectl scale deployment student-api --replicas=5
```

Eventually:

ReplicaSet:

```text
Desired = 5

Actual = 3

↓

Create Two Pods
```

Scaling is simply another reconciliation event.

---

# 💥 Self-Healing

Suppose:

```bash
kubectl delete pod student-api-abc123
```

Execution:

```text
Pod Deleted

↓

ReplicaSet Notices

↓

Desired = 3

Actual = 2

↓

Create Replacement Pod
```

Notice:

The replacement Pod has:

* New UID
* New name
* Usually a new IP address

Pods are never "repaired."

They are replaced.

---

# 🏷️ Owner References

Every Pod created by a ReplicaSet contains:

```yaml
ownerReferences:
```

Example:

```text
Pod

↓

ReplicaSet
```

Kubernetes knows:

"If the ReplicaSet is deleted, these Pods should also be deleted."

This mechanism is called **garbage collection**.

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

student-api-abc

↓

Pod-1

Pod-2

Pod-3
```

Suppose:

```text
Pod-2

↓

Crash
```

ReplicaSet:

```text
Desired = 3

Actual = 2

↓

Create Pod-4
```

The Deployment itself does nothing at this point.

The ReplicaSet performs the reconciliation.

---

# 📊 ReplicaSet Architecture

```text
                Deployment
                     │
                     ▼
               ReplicaSet
                     │
           Desired Replicas
                     │
      ┌──────────────┼──────────────┐
      ▼              ▼              ▼
     Pod            Pod            Pod
        ▲                            │
        └──────── Watch ─────────────┘
                 ReplicaSet Controller
```

---

# 📋 ReplicaSet YAML

Example:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: student-api-rs

spec:

  replicas: 3

  selector:
    matchLabels:
      app: student-api

  template:

    metadata:
      labels:
        app: student-api

    spec:
      containers:

      - name: student-api

        image: student-api:1.0
```

In practice, Deployments usually generate ReplicaSets automatically.

---

# 🔄 ReplicaSet vs Deployment

ReplicaSet responsibilities:

* Maintain Pod replicas
* Replace failed Pods
* Scale Pods

Deployment responsibilities:

* Create ReplicaSets
* Rolling updates
* Rollbacks
* Version management

Architecture:

```text
Deployment

↓

ReplicaSet

↓

Pods
```

---

# 📦 Pod Replacement vs Restart

Suppose:

```text
Java Process Crash
```

kubelet:

```text
Restart Container
```

No new Pod is created.

Suppose:

```text
Pod Deleted
```

ReplicaSet:

```text
Create New Pod
```

These are different responsibilities.

| Failure                | Component Responsible                        |
| ---------------------- | -------------------------------------------- |
| Container exits        | kubelet (restart according to restartPolicy) |
| Pod deleted or missing | ReplicaSet Controller                        |
| Node failure           | Node Controller + Scheduler + ReplicaSet     |

---

# 🚫 Common Mistakes

## ❌ Thinking Deployment Creates Pods

Deployment creates ReplicaSets.

ReplicaSets create Pods.

---

## ❌ Thinking ReplicaSet Performs Rolling Updates

ReplicaSet only maintains Pod count.

Deployment manages rolling updates by creating and managing multiple ReplicaSets.

---

## ❌ Thinking Deleted Pods Return

A deleted Pod never comes back.

ReplicaSet creates an entirely new Pod.

---

# 🐳 Docker Comparison

Docker:

```text
Container Deleted

↓

Gone Forever
```

Kubernetes:

```text
Pod Deleted

↓

ReplicaSet

↓

New Pod
```

This automatic replacement is a key feature of Kubernetes.

---

# 🧪 Hands-on Lab

## Create a Deployment

```bash
kubectl create deployment nginx --image=nginx --replicas=3
```

Observe:

```bash
kubectl get deployments
kubectl get replicasets
kubectl get pods
```

Notice the hierarchy.

---

## Describe the ReplicaSet

```bash
kubectl describe rs
```

Inspect:

* Selector
* Desired replicas
* Current replicas
* Owner references
* Events

---

## Delete a Pod

```bash
kubectl delete pod <pod-name>
```

Watch:

```bash
kubectl get pods --watch
```

Observe a replacement Pod being created.

---

## Scale the Deployment

```bash
kubectl scale deployment nginx --replicas=5
```

Observe:

```bash
kubectl get rs
kubectl get pods
```

Notice the ReplicaSet adjusting the number of Pods.

---

## View Labels

```bash
kubectl get pods --show-labels
```

Compare with:

```bash
kubectl get rs -o yaml
```

Observe how the selector matches the Pod labels.

---

# 📈 Complete ReplicaSet Flow

```text
kubectl apply
      │
      ▼
API Server
      │
      ▼
Deployment
      │
      ▼
ReplicaSet
      │
      ▼
Watch Pods
      │
      ▼
Desired vs Actual
      │
      ▼
Create/Delete Pods
      │
      ▼
Scheduler
      │
      ▼
kubelet
      │
      ▼
Running Pods
```

This is the complete lifecycle of ReplicaSet reconciliation.

---

# 📊 ReplicaSet Components

| Component                | Responsibility                                          |
| ------------------------ | ------------------------------------------------------- |
| 📄 ReplicaSet            | Maintains the desired number of Pod replicas            |
| 👀 Label Selector        | Determines which Pods belong to the ReplicaSet          |
| 📦 Pod Template          | Blueprint used to create new Pods                       |
| ♾️ Reconciliation Loop   | Continuously compares desired and actual state          |
| 🏷️ Owner References     | Links Pods to their ReplicaSet for lifecycle management |
| 🔄 ReplicaSet Controller | Creates or removes Pods as needed                       |

---

# 💡 Key Takeaways

✅ A ReplicaSet ensures that a specified number of identical Pods are always running.

✅ ReplicaSets identify their Pods using **label selectors**, not Pod names.

✅ New Pods are created from the ReplicaSet's embedded **Pod template**.

✅ Self-healing occurs because the ReplicaSet Controller continuously reconciles the desired and actual number of Pods.

✅ When a Pod is deleted, Kubernetes creates a **new Pod**, not the old one.

✅ Deployments manage ReplicaSets, while ReplicaSets manage Pods.

✅ Understanding ReplicaSets is essential before learning Deployments, rolling updates, rollbacks, and advanced workload management.

---

# ➡️ Next Chapter

📘 **`10-Kubernetes/10-Deployment.md`**

In the next chapter, we'll explore **Deployments**, the workload resource most commonly used in production.

We'll answer questions such as:

* 🚀 Why use a Deployment instead of a ReplicaSet directly?
* 🔄 How do rolling updates work?
* ⏪ How does Kubernetes perform rollbacks?
* 📈 How are application versions managed?
* 🧠 Why does a Deployment create multiple ReplicaSets during updates?

By the end of the chapter, you'll understand how Kubernetes performs zero-downtime deployments and version management using Deployments.
