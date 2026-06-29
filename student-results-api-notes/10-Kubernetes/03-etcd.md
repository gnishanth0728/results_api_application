# 📘 Chapter 80 — Kubernetes etcd

> 📂 File: `student-results-api-notes/10-Kubernetes/03-etcd.md`

This chapter explains the database of Kubernetes.

After learning about the API Server, the next obvious question is:

Where does Kubernetes store everything?

When you execute:

kubectl apply -f deployment.yaml

where is that Deployment stored?

Where are:

Pods
Services
Deployments
Secrets
ConfigMaps
Nodes
ReplicaSets

stored?

The answer is:

etcd

etcd is the single source of truth for the Kubernetes cluster.

If the API Server is the brain, etcd is the memory.

Without etcd, Kubernetes cannot remember the desired state of the cluster.

This chapter explains how Kubernetes stores objects, how watches work, how distributed consensus protects data, and why etcd backups are critical.

---

# 🌍 Introduction

In the previous chapter, we learned that every Kubernetes request passes through the **API Server**.

For example:

```bash id="a6m2k9"
kubectl apply -f deployment.yaml
```

Flow:

```text id="j3r8v5"
kubectl

↓

API Server
```

But another important question appears:

> 🤔 **Where does the API Server store the Deployment?**

The answer is:

# 💾 etcd

etcd is Kubernetes' distributed key-value database.

It stores the complete desired state of the cluster.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 💾 What etcd is
* 🔑 Key-Value Storage
* 📦 Kubernetes Objects
* 🌍 Source of Truth
* 👀 Watch Operations
* 🔄 Raft Consensus
* 📊 High Availability
* 🛡️ Backups
* ☸️ Cluster Recovery
* ⚙️ API Server Relationship

---

# ❓ What Is etcd?

etcd is a distributed, strongly consistent key-value database.

Every Kubernetes object is stored inside etcd.

Architecture:

```text id="s5p7n2"
API Server

↓

etcd

↓

Persistent Storage
```

The API Server is the **only** component that communicates directly with etcd.

---

# 🏗️ Kubernetes Storage Architecture

```text id="y8m3r6"
kubectl

↓

API Server

↓

etcd

↓

Cluster State
```

Worker nodes never access etcd directly.

---

# 🔑 Key-Value Database

Unlike a relational database:

```text id="v2q8m4"
Table

↓

Rows

↓

Columns
```

etcd stores:

```text id="f9k5p1"
Key

↓

Value
```

Example:

```text id="m6r2v7"
/registry/pods/default/student-api

↓

JSON Object
```

The key identifies the resource.

The value contains the serialized Kubernetes object.

---

# 📦 Kubernetes Objects

Examples stored in etcd:

```text id="q4n8k3"
/registry/pods

/registry/services

/registry/deployments

/registry/nodes

/registry/configmaps

/registry/secrets
```

Every Kubernetes resource ultimately becomes a key-value entry.

---

# 🌍 Source of Truth

Suppose:

```yaml id="h7m1p6"
replicas: 3
```

etcd stores:

```text id="x5q9r2"
Desired State

↓

3 Replicas
```

If:

```text id="k8v4m7"
Actual State

↓

2 Pods
```

Controllers detect the difference and create the missing Pod.

The desired state always comes from etcd.

---

# 🚀 Writing to etcd

Command:

```bash id="p2r7n5"
kubectl apply -f deployment.yaml
```

Execution:

```text id="b9m3q8"
kubectl

↓

API Server

↓

Validation

↓

Store Object

↓

etcd
```

The Deployment now exists in the cluster state.

---

# 👀 Watch Operations

Controllers do **not** constantly poll etcd.

Instead:

```text id="d6k2v4"
API Server

↓

Watch Stream

↓

Controller
```

Flow:

```text id="n4r8m1"
Deployment Stored

↓

etcd

↓

API Server Watch Event

↓

Deployment Controller
```

The API Server watches etcd and forwards events to interested components.

---

# 📋 Example Object

Deployment:

```yaml id="z8p5q3"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: student-api
spec:
  replicas: 3
```

Stored internally as:

```text id="u1m7k9"
Key

↓

/registry/deployments/default/student-api

↓

Value

↓

Serialized Deployment Object
```

---

# 🔄 Updating Objects

Suppose:

```bash id="v7n3p2"
kubectl scale deployment student-api --replicas=5
```

Execution:

```text id="a4k9m6"
API Server

↓

Update Object

↓

etcd

↓

Watch Event

↓

Deployment Controller

↓

Create Pods
```

The change propagates through watch notifications.

---

# 🧠 Raft Consensus

A production etcd cluster usually contains multiple members.

Example:

```text id="e5r8q1"
etcd 1

etcd 2

etcd 3
```

Updates are committed only after a majority of members agree.

This consensus algorithm is called **Raft**.

Benefits:

* Strong consistency
* Leader election
* Fault tolerance

---

# 📊 High Availability

Example:

```text id="w2n6k8"
Leader

↓

Follower

↓

Follower
```

If the leader fails:

```text id="g9m4p5"
Election

↓

New Leader

↓

Continue
```

The cluster remains available as long as a majority of members are healthy.

---

# 🛡️ Why Backups Matter

Suppose:

```text id="x3q7v9"
etcd Lost
```

Then Kubernetes loses:

* Deployments
* Pods
* Services
* Secrets
* ConfigMaps
* Nodes
* Cluster configuration

Even if containers continue running temporarily, Kubernetes no longer knows the desired state.

Regular etcd backups are essential.

---

# 🍃 Student Results API Example

Deployment:

```yaml id="c6m8r2"
replicas: 3
```

Execution:

```text id="t4p1v7"
kubectl apply

↓

API Server

↓

etcd

↓

Deployment Stored

↓

Watch Event

↓

Deployment Controller

↓

Scheduler

↓

Worker Nodes
```

Everything starts with the object stored in etcd.

---

# 📊 etcd Architecture

```text id="h8q2m4"
                 kubectl
                     │
                     ▼
               API Server
                     │
                     ▼
                  etcd
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
 Deployment    ReplicaSet      Service
     │             │              │
     ▼             ▼              ▼
Watch Events  Watch Events  Watch Events
     │             │              │
     ▼             ▼              ▼
Controllers   Scheduler     kubelet
```

---

# 🔍 Reading Objects

Command:

```bash id="q7n5k1"
kubectl get deployment student-api -o yaml
```

Flow:

```text id="p3r9v6"
kubectl

↓

API Server

↓

Read etcd

↓

Return YAML
```

The API Server reads the object from etcd and returns it to the client.

---

# 🚫 Common Mistakes

## ❌ Thinking Controllers Read etcd Directly

Controllers always communicate with the API Server.

They never access etcd directly.

---

## ❌ Thinking Worker Nodes Use etcd

Worker nodes communicate with the API Server through kubelet.

They never query etcd.

---

## ❌ Thinking etcd Stores Running Containers

etcd stores the **desired state** and object metadata.

Containers themselves run on worker nodes and are managed by the container runtime.

---

# 🐳 Docker Comparison

Docker:

```text id="k5m2p8"
Container State

↓

dockerd
```

Kubernetes:

```text id="n9r4v3"
Cluster State

↓

etcd
```

Docker manages one host.

etcd stores the desired state of an entire Kubernetes cluster.

---

# 🧪 Hands-on Lab

## View Cluster Objects

```bash id="r8q3m5"
kubectl get all
```

Observe the resources represented in the cluster state.

---

## View a Deployment

```bash id="w1n7p4"
kubectl get deployment student-api -o yaml
```

Inspect the object stored in Kubernetes.

---

## Scale a Deployment

```bash id="y6k2r9"
kubectl scale deployment student-api --replicas=5
```

Observe:

```bash id="u3m8v1"
kubectl get pods
```

Watch new Pods being created.

---

## Observe Watch Behavior

In one terminal:

```bash id="g5p4n7"
kubectl get pods --watch
```

In another terminal:

```bash id="b2r9k6"
kubectl delete pod <pod-name>
```

Notice how changes are streamed immediately without polling.

---

## Create an etcd Snapshot (Control Plane Node)

```bash id="f9m2q5"
ETCDCTL_API=3 etcdctl snapshot save backup.db
```

This creates a backup of the cluster state.

---

# 📈 Complete etcd Flow

```text id="z1k8m4"
kubectl
    │
    ▼
API Server
    │
    ▼
Authentication
    │
    ▼
Authorization
    │
    ▼
Validation
    │
    ▼
etcd
    │
    ▼
Watch Events
    │
    ├── Scheduler
    ├── Controller Manager
    └── kubelet
```

This is the complete lifecycle of storing and propagating a Kubernetes object.

---

# 📊 etcd Responsibilities

| Responsibility        | Description                                             |
| --------------------- | ------------------------------------------------------- |
| 💾 Persistent Storage | Stores the desired state of the Kubernetes cluster      |
| 🔑 Key-Value Database | Stores resources as key-value pairs                     |
| 🌍 Source of Truth    | Holds the authoritative cluster configuration           |
| 👀 Watch Support      | Generates change events consumed through the API Server |
| 🔄 Raft Consensus     | Ensures strong consistency and fault tolerance          |
| 🛡️ Backup Target     | Critical component that must be regularly backed up     |

---

# 💡 Key Takeaways

✅ etcd is the distributed key-value database that stores the entire desired state of a Kubernetes cluster.

✅ The API Server is the only component that directly reads from and writes to etcd.

✅ Every Kubernetes resource—Pods, Deployments, Services, Secrets, ConfigMaps, and Nodes—is stored as a key-value entry.

✅ Controllers, the Scheduler, and kubelets receive updates through the API Server's Watch mechanism rather than accessing etcd directly.

✅ etcd uses the Raft consensus algorithm to provide strong consistency and high availability.

✅ Regular etcd backups are essential because the cluster's desired state depends on the data stored there.

✅ Understanding etcd is fundamental before learning controllers, reconciliation loops, scheduling, and Pod lifecycle management.

---

# ➡️ Next Chapter

📘 **`10-Kubernetes/04-Scheduler.md`**

In the next chapter, we'll explore the **Kubernetes Scheduler**.

We'll answer questions such as:

* 🎯 How does Kubernetes choose a worker node?
* 🧠 What are filtering and scoring phases?
* 💻 How are CPU and memory requests considered?
* 📍 How do node affinity, taints, and tolerations influence scheduling?
* ⚖️ What happens when no suitable node exists?

By the end of the chapter, you'll understand exactly how Kubernetes decides where every Pod should run in a cluster.
