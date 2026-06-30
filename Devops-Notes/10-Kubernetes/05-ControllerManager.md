# 📘 Chapter 82 — Kubernetes Controller Manager

> 📂 File: `student-results-api-notes/10-Kubernetes/05-ControllerManager.md`

This chapter explains the heart of Kubernetes automation.

So far you've learned:

API Server receives requests.
etcd stores the desired state.
Scheduler chooses the worker node.

Now another important question appears:

Who actually makes Kubernetes self-healing?

For example:

A Pod crashes.
A worker node dies.
A Deployment is scaled from 3 to 10 replicas.
A ReplicaSet suddenly has only 2 Pods instead of 3.

Who notices this?

Who creates new Pods?

Who deletes extra Pods?

Who keeps comparing the desired state with the actual state?

The answer is:

The Kubernetes Controller Manager

The Controller Manager continuously watches the cluster and runs reconciliation loops that move the actual state toward the desired state stored in etcd.

This is what makes Kubernetes declarative rather than imperative.

Without the Controller Manager, Kubernetes would simply be a database storing YAML objects.

---

# 🌍 Introduction

In the previous chapter, we learned how the Scheduler assigns Pods to worker nodes.

The scheduling flow looked like this:

```text
Deployment

↓

Pod

↓

Scheduler

↓

Worker Node
```

But another important question appears:

> 🤔 **What happens after the Pod is running?**

Suppose:

* The Pod crashes.
* Someone deletes the Pod.
* A node suddenly goes offline.
* The Deployment is scaled from 3 replicas to 10 replicas.

Who notices?

Who creates new Pods?

Who deletes extra Pods?

The answer is:

# 🔄 Kubernetes Controller Manager

The Controller Manager continuously compares the desired state with the actual state and performs actions to make them match.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🔄 What a Controller is
* ♾️ Reconciliation Loop
* 📦 Deployment Controller
* 📄 ReplicaSet Controller
* ⚙️ Node Controller
* 💼 Job Controller
* 🕒 CronJob Controller
* 🔍 Watch Mechanism
* ☸️ Desired vs Actual State
* 🛠️ Self-Healing

---

# ❓ What Is a Controller?

A controller is a control loop.

It continuously performs three steps:

```text
Observe

↓

Compare

↓

Act
```

It never runs once.

It runs continuously for the lifetime of the cluster.

---

# 🏗️ Controller Manager

The Controller Manager is a process that runs many controllers.

```text
Controller Manager

├── Deployment Controller

├── ReplicaSet Controller

├── Node Controller

├── Job Controller

├── CronJob Controller

├── Namespace Controller

├── ServiceAccount Controller

└── Many Others
```

Each controller has one responsibility.

---

# 🔄 Reconciliation Loop

Every controller follows the same algorithm.

```text
Desired State

↓

Read Actual State

↓

Compare

↓

Different?

│

├── Yes → Fix It

└── No → Wait
```

This process repeats continuously.

This is called **reconciliation**.

---

# 🌍 Desired vs Actual State

Suppose the Deployment specifies:

```yaml
replicas: 3
```

Desired:

```text
3 Pods
```

Actual:

```text
2 Pods
```

Difference detected:

```text
Missing Pod

↓

Create New Pod
```

The controller closes the gap automatically.

---

# 👀 Watch API

Controllers do not poll every second.

Instead:

```text
API Server

↓

Watch

↓

Controller
```

Whenever a Deployment changes:

```text
Deployment Updated

↓

Watch Event

↓

Controller Receives Notification
```

This event-driven architecture reduces load and improves responsiveness.

---

# 📦 Deployment Controller

Suppose:

```yaml
kind: Deployment

replicas: 3
```

The Deployment Controller ensures a corresponding ReplicaSet exists.

Flow:

```text
Deployment

↓

ReplicaSet
```

If the ReplicaSet is missing, it is created.

---

# 📄 ReplicaSet Controller

The ReplicaSet Controller manages Pods.

Suppose:

```text
ReplicaSet

↓

Desired = 3
```

Actual:

```text
2 Pods
```

Controller action:

```text
Create One New Pod
```

If there are too many Pods:

```text
Desired = 3

Actual = 5

↓

Delete Two Pods
```

---

# ⚙️ Node Controller

The Node Controller monitors node health.

Example:

```text
Worker-2

↓

NotReady
```

Controller actions:

* Marks the node unhealthy.
* Evicts Pods after the configured timeout.
* Allows replacement Pods to be scheduled elsewhere.

---

# 💼 Job Controller

Job example:

```yaml
completions: 5
```

Suppose:

```text
Completed

↓

4
```

Controller action:

```text
Start Another Pod
```

The Job completes only when all required completions succeed.

---

# 🕒 CronJob Controller

Example:

```yaml
schedule: "0 2 * * *"
```

At 2:00 AM:

```text
CronJob

↓

Create Job

↓

Run Pod
```

The controller creates Jobs according to the defined schedule.

---

# 🍃 Student Results API Example

Deployment:

```yaml
replicas: 3
```

Current state:

```text
Pod-1

Running

Pod-2

Running

Pod-3

CrashLoopBackOff
```

The ReplicaSet Controller detects that one replica is unavailable.

If the failed Pod is deleted and the number of available replicas drops below the desired count:

```text
Desired = 3

Available = 2

↓

Create Replacement Pod
```

The Deployment eventually returns to three healthy replicas.

---

# 📊 Controller Architecture

```text
                 API Server
                      │
                      ▼
                  Watch Events
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
 Deployment     ReplicaSet      Node
 Controller     Controller    Controller
        │             │             │
        ▼             ▼             ▼
   Create RS     Create Pods    Handle Failures
```

Each controller independently watches the resources it manages.

---

# 🔄 Scaling Example

Command:

```bash
kubectl scale deployment student-api --replicas=5
```

Flow:

```text
kubectl

↓

API Server

↓

etcd

↓

Deployment Controller

↓

ReplicaSet Controller

↓

Create Two Pods
```

No administrator manually creates Pods.

---

# 💥 Self-Healing Example

Suppose:

```bash
kubectl delete pod student-api-abc123
```

Execution:

```text
Pod Deleted

↓

Watch Event

↓

ReplicaSet Controller

↓

Create New Pod
```

This is Kubernetes self-healing.

---

# 📈 Rolling Update Example

Deployment update:

```text
Version 1

↓

Version 2
```

Deployment Controller performs:

```text
New ReplicaSet

↓

Create New Pods

↓

Delete Old Pods
```

The update happens gradually according to the Deployment strategy.

---

# 🚫 Common Mistakes

## ❌ Thinking the Scheduler Replaces Failed Pods

The Scheduler only selects a node for a Pod.

Controllers decide whether new Pods need to be created.

---

## ❌ Thinking Controllers Run Once

Controllers never stop.

They continuously reconcile cluster state.

---

## ❌ Thinking Controllers Read etcd Directly

Controllers communicate only with the API Server.

They receive updates through Watch events.

---

# 🐳 Docker Comparison

Docker:

```text
Container Crashes

↓

Administrator Restarts It
```

Kubernetes:

```text
Pod Missing

↓

Controller Detects

↓

New Pod Created
```

Automation replaces manual intervention.

---

# 🧪 Hands-on Lab

## Create a Deployment

```bash
kubectl create deployment nginx --image=nginx --replicas=3
```

Observe:

```bash
kubectl get pods
```

---

## Delete a Pod

```bash
kubectl delete pod <pod-name>
```

Watch:

```bash
kubectl get pods --watch
```

Observe the replacement Pod being created automatically.

---

## Scale the Deployment

```bash
kubectl scale deployment nginx --replicas=5
```

Watch:

```bash
kubectl get pods --watch
```

Observe two additional Pods being created.

---

## Scale Down

```bash
kubectl scale deployment nginx --replicas=2
```

Observe excess Pods being terminated.

---

## View Deployment Status

```bash
kubectl describe deployment nginx
```

Inspect:

* Desired replicas
* Updated replicas
* Available replicas
* Events

---

# 📈 Complete Reconciliation Flow

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
Watch Event
      │
      ▼
Controller Manager
      │
      ▼
Compare Desired vs Actual
      │
      ▼
Create/Delete Objects
      │
      ▼
API Server
      │
      ▼
Scheduler
      │
      ▼
kubelet
      │
      ▼
Container Runtime
```

This is the complete reconciliation lifecycle.

---

# 📊 Major Controllers

| Controller                   | Responsibility                                  |
| ---------------------------- | ----------------------------------------------- |
| 📦 Deployment Controller     | Manages Deployments and creates ReplicaSets     |
| 📄 ReplicaSet Controller     | Maintains the required number of Pod replicas   |
| ⚙️ Node Controller           | Monitors node health and handles node failures  |
| 💼 Job Controller            | Ensures Jobs complete successfully              |
| 🕒 CronJob Controller        | Creates Jobs according to schedules             |
| 🗂️ Namespace Controller     | Cleans up resources when namespaces are deleted |
| 🔐 ServiceAccount Controller | Creates default ServiceAccounts for namespaces  |

---

# 💡 Key Takeaways

✅ The Controller Manager runs multiple controllers, each responsible for a specific Kubernetes resource.

✅ Controllers implement continuous **reconciliation loops**: observe, compare, and act.

✅ The desired state comes from objects stored in etcd and exposed through the API Server.

✅ Controllers use the API Server's Watch mechanism to receive real-time updates instead of polling.

✅ The Deployment Controller manages ReplicaSets, while the ReplicaSet Controller manages Pods.

✅ Self-healing, scaling, and rolling updates are all outcomes of reconciliation loops.

✅ The Scheduler chooses **where** a Pod runs, but controllers decide **whether** Pods should exist.

---

# ➡️ Next Chapter

📘 **`10-Kubernetes/06-kubelet.md`**

In the next chapter, we'll explore **kubelet**, the primary agent running on every worker node.

We'll answer questions such as:

* ⚙️ How does kubelet know a Pod has been assigned to its node?
* 📦 How does kubelet communicate with the container runtime?
* 🏃 How does a Pod become Linux processes?
* ❤️ How are liveness and readiness probes executed?
* 📊 How does kubelet report node and Pod status back to the API Server?

By the end of the chapter, you'll understand how a scheduled Pod is transformed into running containers on a worker node.
