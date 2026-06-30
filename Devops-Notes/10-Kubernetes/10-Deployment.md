# 📘 Chapter 87 — Kubernetes Deployment

> 📂 File: `student-results-api-notes/10-Kubernetes/10-Deployment.md`

This chapter explains the Kubernetes object used for almost every production application.

So far you've learned:

Deployment
      ↓
ReplicaSet
      ↓
Pods
      ↓
Containers

But another important question appears:

If ReplicaSet already keeps Pods alive, why do we need Deployment?

Why doesn't everyone create ReplicaSets directly?

Because ReplicaSets solve only one problem:

Maintain the required number of Pods.

Production systems require much more:

Rolling updates
Zero-downtime deployments
Rollbacks
Version history
Controlled scaling
Progressive replacement of Pods

These responsibilities belong to:

Deployment

A Deployment is a higher-level controller that manages ReplicaSets and application versions.

The Deployment never creates Pods directly.

Instead, it:

Deployment
      │
Creates & Manages
      ▼
ReplicaSets
      │
Create & Manage
      ▼
Pods

This layered design is one of the most important concepts in Kubernetes.

---

# 🌍 Introduction

In the previous chapter, we learned that a **ReplicaSet** ensures the required number of Pods are always running.

Example:

```yaml
replicas: 3
```

ReplicaSet guarantees:

```text
Running Pods = 3
```

But another important question appears:

> 🤔 **Why do almost all production applications use Deployments instead of ReplicaSets?**

ReplicaSets can maintain replicas, but they cannot safely manage application versions.

The answer is:

# 🚀 Deployment

A Deployment manages ReplicaSets and enables safe application lifecycle management.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🚀 What a Deployment is
* 📄 Deployment → ReplicaSet → Pod hierarchy
* 🔄 Rolling Updates
* ⏪ Rollbacks
* 📜 Revision History
* 📈 Scaling
* 🛡️ Zero-Downtime Deployment
* 🧠 Update Strategies
* 👀 Deployment Controller
* ☸️ Production Application Lifecycle

---

# ❓ What Is a Deployment?

A Deployment is a Kubernetes resource that manages application releases.

Responsibilities:

* Create ReplicaSets
* Update ReplicaSets
* Scale ReplicaSets
* Roll back ReplicaSets
* Maintain deployment history

Applications are usually deployed using Deployments rather than ReplicaSets directly.

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

Deployment never creates Pods directly.

---

# 📄 Why Not Use ReplicaSet Directly?

ReplicaSet can:

✅ Maintain replicas

ReplicaSet cannot:

* Perform rolling updates
* Roll back versions
* Keep revision history
* Control update strategy

Deployment provides these capabilities.

---

# 📦 Deployment YAML

Example:

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: student-api

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

Notice that the Deployment embeds a complete Pod template.

---

# 🔄 Initial Deployment

Execution:

```bash
kubectl apply -f deployment.yaml
```

Flow:

```text
Deployment

↓

ReplicaSet

↓

Pod-1

Pod-2

Pod-3
```

The Deployment Controller creates the first ReplicaSet.

---

# 🔄 Rolling Update

Suppose:

```yaml
image: student-api:2.0
```

Deployment creates:

```text
Old ReplicaSet

↓

New ReplicaSet
```

Then:

```text
Create New Pod

↓

Wait Until Ready

↓

Delete Old Pod

↓

Repeat
```

The update happens gradually to minimize downtime.

---

# 📊 Rolling Update Timeline

Version 1:

```text
RS-v1

↓

Pod

Pod

Pod
```

Update:

```text
RS-v1

↓

2 Pods

----------------

RS-v2

↓

1 Pod
```

Continue:

```text
RS-v1

↓

1 Pod

----------------

RS-v2

↓

2 Pods
```

Finally:

```text
RS-v2

↓

3 Pods
```

The old ReplicaSet remains for rollback history until it is eventually cleaned up according to the revision history limit.

---

# 🛡️ Zero-Downtime Deployment

During rolling updates:

```text
Old Pods

Running

----------------

New Pods

Starting
```

Traffic continues flowing to healthy Pods.

Only after a new Pod becomes **Ready** does Kubernetes remove an old Pod.

This prevents service interruption.

---

# ❤️ Readiness Probe Importance

Deployment waits for:

```yaml
readinessProbe:
```

Sequence:

```text
New Pod

↓

Running

↓

Ready?

│

├── No → Wait

└── Yes → Delete Old Pod
```

Without a readiness probe, traffic may be sent to an application before it is ready.

---

# ⏪ Rollback

Suppose:

Version 2 fails.

Command:

```bash
kubectl rollout undo deployment student-api
```

Execution:

```text
Deployment

↓

Previous ReplicaSet

↓

Scale Up

↓

Current ReplicaSet

↓

Scale Down
```

Rollback is achieved by promoting a previous ReplicaSet.

---

# 📜 Revision History

Deployment stores ReplicaSet revisions.

Example:

```text
Revision 1

↓

student-api:1.0

-----------------

Revision 2

↓

student-api:2.0

-----------------

Revision 3

↓

student-api:3.0
```

Inspect:

```bash
kubectl rollout history deployment student-api
```

---

# 📈 Scaling

Command:

```bash
kubectl scale deployment student-api --replicas=5
```

Flow:

```text
Deployment

↓

ReplicaSet

↓

Desired = 5

↓

Create Two Pods
```

Deployment updates the ReplicaSet's desired replica count.

---

# 🍃 Student Results API Example

Current version:

```text
student-api:1.0
```

Deployment:

```text
Deployment

↓

ReplicaSet-v1

↓

3 Pods
```

Update:

```text
student-api:2.0
```

Execution:

```text
Deployment

↓

ReplicaSet-v2

↓

Gradually Replace Pods
```

If version 2 fails:

```bash
kubectl rollout undo deployment student-api
```

Deployment restores ReplicaSet-v1.

---

# 📊 Deployment Architecture

```text
                 Deployment
                      │
         Deployment Controller
                      │
      ┌───────────────┴───────────────┐
      ▼                               ▼
ReplicaSet-v1                  ReplicaSet-v2
      │                               │
      ▼                               ▼
   Old Pods                       New Pods
```

Deployments manage multiple ReplicaSets during updates.

---

# 🔄 Deployment Strategies

Default:

```yaml
strategy:
  type: RollingUpdate
```

Other option:

```yaml
strategy:
  type: Recreate
```

RollingUpdate:

```text
Old Pods

↓

New Pods

↓

Gradual Replacement
```

Recreate:

```text
Delete All Pods

↓

Create New Pods
```

RollingUpdate is preferred for production workloads because it minimizes downtime.

---

# 🚫 Common Mistakes

## ❌ Thinking Deployment Creates Pods

Deployment creates ReplicaSets.

ReplicaSets create Pods.

---

## ❌ Thinking Rolling Updates Restart Existing Pods

Existing Pods are never modified.

New Pods are created from a new ReplicaSet.

Old Pods are removed after the new Pods become ready.

---

## ❌ Thinking Rollback Restarts Containers

Rollback changes which ReplicaSet is active.

It does not restart the existing Pods in place.

---

# 🐳 Docker Comparison

Docker:

```text
docker run

↓

Container
```

Docker has no built-in concept of rolling updates.

Kubernetes:

```text
Deployment

↓

ReplicaSets

↓

Pods
```

Kubernetes provides automated version management and controlled rollouts.

---

# 🧪 Hands-on Lab

## Create a Deployment

```bash
kubectl create deployment nginx --image=nginx:1.25
```

Observe:

```bash
kubectl get deployments
kubectl get replicasets
kubectl get pods
```

---

## Update the Image

```bash
kubectl set image deployment/nginx nginx=nginx:1.27
```

Watch:

```bash
kubectl get pods --watch
```

Observe Pods being replaced gradually.

---

## View Rollout Status

```bash
kubectl rollout status deployment/nginx
```

---

## View Revision History

```bash
kubectl rollout history deployment/nginx
```

---

## Roll Back

```bash
kubectl rollout undo deployment/nginx
```

Verify:

```bash
kubectl rollout history deployment/nginx
kubectl get replicasets
```

Observe the previous ReplicaSet becoming active again.

---

## Scale the Deployment

```bash
kubectl scale deployment nginx --replicas=5
```

Observe:

```bash
kubectl get deployments
kubectl get replicasets
kubectl get pods
```

Notice that the ReplicaSet adjusts the number of Pods.

---

# 📈 Complete Deployment Flow

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
Deployment Controller
      │
      ▼
ReplicaSet
      │
      ▼
Pods
      │
      ▼
Scheduler
      │
      ▼
kubelet
      │
      ▼
Running Containers
```

During updates:

```text
Deployment

↓

New ReplicaSet

↓

New Pods

↓

Ready

↓

Delete Old Pods
```

This is the complete Deployment lifecycle.

---

# 📊 Deployment Components

| Component           | Responsibility                                         |
| ------------------- | ------------------------------------------------------ |
| 🚀 Deployment       | Manages application lifecycle and releases             |
| 📄 ReplicaSet       | Maintains the desired number of Pod replicas           |
| 📦 Pod Template     | Defines how new Pods should be created                 |
| 🔄 Rolling Update   | Gradually replaces old Pods with new Pods              |
| ⏪ Rollback          | Restores a previous ReplicaSet revision                |
| 📜 Revision History | Tracks previous application versions                   |
| ❤️ Readiness Probe  | Ensures new Pods are ready before old Pods are removed |

---

# 💡 Key Takeaways

✅ A Deployment is the recommended Kubernetes workload resource for stateless production applications.

✅ Deployments manage **ReplicaSets**, and ReplicaSets manage **Pods**.

✅ Rolling updates create a new ReplicaSet and gradually replace old Pods with new ones.

✅ Existing Pods are never modified in place; Kubernetes creates new Pods from the updated Pod template.

✅ Readiness probes are essential for safe zero-downtime deployments because old Pods are removed only after new Pods are ready.

✅ Deployments maintain revision history, enabling simple rollbacks to previous versions.

✅ Understanding Deployments is essential before learning Services, Ingress, ConfigMaps, Secrets, StatefulSets, and production-grade Kubernetes application design.

---

# ➡️ Next Chapter

📘 **`10-Kubernetes/11-Service.md`**

In the next chapter, we'll explore **Kubernetes Services**.

We'll answer questions such as:

* 🌐 Why can't clients connect directly to Pod IPs?
* 🔄 How does Kubernetes load-balance traffic across Pods?
* 📡 What are ClusterIP, NodePort, LoadBalancer, and ExternalName Services?
* 🧠 How does kube-proxy forward packets?
* 💥 What happens when Pods are replaced but clients continue to use the same Service IP?

By the end of the next chapter, you'll understand how Kubernetes provides stable networking and service discovery despite Pods being ephemeral.
