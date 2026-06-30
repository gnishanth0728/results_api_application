# 📘 Chapter 79 — Kubernetes API Server

> 📂 File: `student-results-api-notes/10-Kubernetes/02-API-Server.md`
This chapter explains the most important component in Kubernetes.

Every Kubernetes operation starts here.

Whether you run:

kubectl get pods
kubectl apply -f deployment.yaml
kubectl delete pod
kubectl scale deployment

all of them first communicate with one component:

The Kubernetes API Server

If the API Server is unavailable, the cluster cannot be managed.

It is the front door and central coordinator of Kubernetes.

This chapter explains the API Server from the HTTP request level all the way down to etcd, admission controllers, authentication, authorization, and watch notifications.

---

# 🌍 Introduction

In the previous chapter, we learned the Kubernetes architecture.

The Control Plane consists of:

```text
API Server

↓

etcd

↓

Scheduler

↓

Controller Manager
```

But another important question appears:

> 🤔 **Why does every Kubernetes command first go to the API Server?**

For example:

```bash
kubectl apply -f deployment.yaml
```

does **not** communicate with:

* kubelet
* Scheduler
* Worker Nodes

Instead it communicates only with:

```text
API Server
```

The API Server is the single entry point into the Kubernetes control plane.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📡 What the API Server is
* 🌐 REST API
* 🔐 Authentication
* 🛡️ Authorization
* ✅ Admission Controllers
* 📋 Object Validation
* 💾 etcd Storage
* 👀 Watch API
* 🔄 Control Plane Communication
* ☸️ Kubernetes Request Flow

---

# ❓ What Is the API Server?

The API Server is the central management component of Kubernetes.

Every operation passes through it.

Architecture:

```text
kubectl

↓

REST API

↓

API Server

↓

Cluster
```

The API Server is the only component that directly reads from and writes to etcd.

---

# 🏗️ Kubernetes Control Plane

```text
            API Server

        ┌──────┼──────────┐

        ▼      ▼          ▼

     etcd   Scheduler   Controllers

                     ▲

                     │

                 kubelet
```

Every component communicates through the API Server.

Components do **not** communicate directly with each other.

---

# 🌐 API Server Is a REST Server

The API Server exposes an HTTPS REST API.

Example:

```http
GET /api/v1/pods

POST /apis/apps/v1/deployments

DELETE /api/v1/pods/student-api
```

Internally:

```text
HTTP Request

↓

REST Handler

↓

Kubernetes Object
```

Everything in Kubernetes is represented as an API object.

---

# 🚀 Example Request

Command:

```bash
kubectl get pods
```

Flow:

```text
kubectl

↓

HTTPS Request

↓

API Server

↓

Read etcd

↓

JSON Response

↓

kubectl Output
```

The API Server retrieves the latest cluster state from etcd.

---

# 🔐 Authentication

Before processing a request, the API Server verifies the client's identity.

Possible authentication methods:

* Client certificates
* Bearer tokens
* Service Accounts
* OpenID Connect (OIDC)
* Webhook authentication

Flow:

```text
Request

↓

Authentication

↓

Identity Established
```

If authentication fails, the request is rejected.

---

# 🛡️ Authorization

After authentication:

```text
User

↓

Authorization

↓

Allowed?

│

├── Yes

└── No
```

Authorization mechanisms include:

* RBAC (Role-Based Access Control)
* ABAC
* Node authorization
* Webhook authorization

Only authorized users can perform specific actions.

---

# ✅ Admission Controllers

Even an authenticated and authorized request may be modified or rejected.

Example flow:

```text
Authenticated

↓

Authorized

↓

Admission Controller

↓

Accept

or

Reject
```

Admission controllers can:

* Enforce security policies
* Inject default values
* Validate objects
* Mutate objects

---

# 📋 Object Validation

Suppose:

```yaml
apiVersion: apps/v1
kind: Deployment
```

The API Server validates:

* API version
* Required fields
* Object schema
* Data types

Invalid objects are rejected before they reach etcd.

---

# 💾 Writing to etcd

Suppose:

```bash
kubectl apply -f deployment.yaml
```

Execution:

```text
kubectl

↓

API Server

↓

Validation

↓

etcd

↓

Deployment Stored
```

etcd becomes the source of truth for the cluster.

---

# 👀 Watch API

Controllers continuously monitor the API Server.

Instead of polling repeatedly:

```text
Every Second

↓

GET Request
```

they use:

```text
Watch

↓

Stream Updates
```

Whenever an object changes:

```text
Deployment Updated

↓

API Server

↓

Notify Scheduler

↓

Notify Controllers

↓

Notify kubelet
```

This event-driven model makes Kubernetes efficient.

---

# 🔄 Complete Request Lifecycle

Suppose:

```bash
kubectl apply -f deployment.yaml
```

Complete flow:

```text
kubectl

↓

HTTPS

↓

Authentication

↓

Authorization

↓

Admission Controllers

↓

Validation

↓

etcd

↓

Watch Notification

↓

Scheduler

↓

Controller Manager

↓

kubelet
```

Everything begins with the API Server.

---

# 🍃 Student Results API Example

Deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: student-api
spec:
  replicas: 3
```

Execution:

```text
kubectl apply

↓

API Server

↓

Authenticate User

↓

Authorize Request

↓

Validate Deployment

↓

Store in etcd

↓

Notify Deployment Controller

↓

Scheduler

↓

Worker Nodes
```

---

# 📊 API Server Architecture

```text
                 kubectl
                     │
                     ▼
               HTTPS REST API
                     │
                     ▼
             Kubernetes API Server
                     │
       ┌─────────────┼─────────────┐
       ▼             ▼             ▼
Authentication  Authorization  Admission
       │             │             │
       └─────────────┼─────────────┘
                     ▼
               Object Validation
                     │
                     ▼
                    etcd
                     │
                     ▼
              Watch Notifications
                     │
      ┌──────────────┼──────────────┐
      ▼              ▼              ▼
 Scheduler   Controller Manager   kubelet
```

---

# 🌐 Kubernetes API Groups

The API Server organizes resources into API groups.

Examples:

```text
Core API

/api/v1

Pods

Services

ConfigMaps

----------------------

Apps API

/apis/apps/v1

Deployments

ReplicaSets

StatefulSets
```

This allows Kubernetes to evolve without breaking compatibility.

---

# 🚫 Common Mistakes

## ❌ Thinking kubectl Talks to Worker Nodes

`kubectl` communicates only with the API Server.

Worker Nodes never receive commands directly from users.

---

## ❌ Thinking Controllers Modify etcd Directly

Controllers always use the API Server.

Only the API Server reads and writes etcd.

---

## ❌ Thinking kubelet Watches etcd

kubelet watches the API Server.

It never communicates directly with etcd.

---

# 🐳 Docker Comparison

Docker:

```text
docker CLI

↓

dockerd

↓

Container
```

Kubernetes:

```text
kubectl

↓

API Server

↓

Entire Cluster
```

The API Server is analogous to Docker's daemon, but it manages an entire cluster rather than a single host.

---

# 🧪 Hands-on Lab

## View API Resources

```bash
kubectl api-resources
```

Observe the resource types managed by the API Server.

---

## View API Versions

```bash
kubectl api-versions
```

Observe the supported API groups and versions.

---

## Query the API Server

```bash
kubectl get --raw /api/v1
```

Observe the raw JSON returned by the API Server.

---

## Inspect Cluster Information

```bash
kubectl cluster-info
```

Locate the API Server endpoint.

---

## View Component Status

```bash
kubectl get componentstatuses
```

> **Note:** This command is deprecated in newer Kubernetes versions. In modern clusters, inspect control plane Pods in the `kube-system` namespace instead:

```bash
kubectl get pods -n kube-system
```

---

# 📈 Complete API Request Flow

```text
kubectl
    │
    ▼
HTTPS Request
    │
    ▼
API Server
    │
    ├── Authentication
    ├── Authorization
    ├── Admission Controllers
    ├── Validation
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

This is the complete lifecycle of every Kubernetes API request.

---

# 📊 API Server Responsibilities

| Responsibility          | Description                                                      |
| ----------------------- | ---------------------------------------------------------------- |
| 🌐 REST API             | Exposes Kubernetes resources over HTTPS                          |
| 🔐 Authentication       | Verifies client identity                                         |
| 🛡️ Authorization       | Checks permissions using RBAC or other mechanisms                |
| ✅ Admission Controllers | Validates and optionally mutates requests                        |
| 📋 Object Validation    | Ensures resource definitions are valid                           |
| 💾 etcd Access          | Sole component responsible for reading and writing cluster state |
| 👀 Watch API            | Streams object changes to Kubernetes components                  |

---

# 💡 Key Takeaways

✅ The API Server is the single entry point for every Kubernetes operation.

✅ All Kubernetes components—including the Scheduler, Controller Manager, and kubelet—communicate through the API Server.

✅ Every request passes through authentication, authorization, admission control, and validation before being stored in etcd.

✅ The API Server is the only component that directly accesses etcd.

✅ Controllers and kubelets use the Watch API to receive real-time updates instead of constantly polling.

✅ Kubernetes is fundamentally an API-driven system where every resource is represented as an API object.

✅ Understanding the API Server is essential before learning etcd, controllers, scheduling, reconciliation, and the complete Pod lifecycle.

---

# ➡️ Next Chapter

📘 **`10-Kubernetes/03-etcd.md`**

In the next chapter, we'll explore **etcd**, the distributed key-value database that stores the entire desired state of a Kubernetes cluster.

We'll learn:

* 💾 Why etcd is called the source of truth
* 🔑 How Kubernetes objects are stored
* 📦 What happens when a Deployment is created
* 🔄 How watch operations work internally
* 🛡️ Why etcd requires backups
* 🌍 How distributed consensus keeps cluster state consistent

By the end of the chapter, you'll understand why etcd is one of the most critical components in every Kubernetes cluster.
