# 📘 Chapter 90 — Kubernetes kube-proxy

> 📂 File: `student-results-api-notes/10-Kubernetes/13-kube-proxy.md`

This chapter explains the component that makes Kubernetes Services actually work.

In the previous chapters you learned:

Deployment
      ↓
ReplicaSet
      ↓
Pods
      ↓
Service

But another important question appears:

How does a packet sent to a Service IP actually reach a Pod?

Suppose:

Service

ClusterIP

10.96.15.20

A Pod sends:

GET http://student-api

How does Linux know that:

10.96.15.20

should actually become:

10.244.1.18

or

10.244.2.9

or

10.244.3.12

There is no Linux network interface that owns the ClusterIP.

No process is listening on:

10.96.15.20

So who intercepts the packet?

Who load balances?

Who updates routing when Pods are created or deleted?

The answer is:

kube-proxy

kube-proxy watches the Kubernetes API Server and programs the Linux networking stack (iptables, IPVS, or nftables depending on the proxy mode) so that packets destined for a Service are transparently redirected to one of its backend Pods.

Without kube-proxy (or another Service proxy implementation), Services would exist only as Kubernetes objects and would not forward any traffic.

---

# 🌍 Introduction

In the previous chapter, we learned that a Service provides a stable virtual IP.

Example:

```text
student-api

↓

ClusterIP

↓

10.96.15.20
```

Applications communicate using the Service instead of Pod IPs.

But another important question appears:

> 🤔 **Who forwards packets from the Service IP to the Pods?**

The answer is:

# 🔀 kube-proxy

kube-proxy configures Linux networking so that packets sent to a Service automatically reach one of its backend Pods.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🔀 What kube-proxy is
* 👀 Watch API
* 📡 Service Virtual IP
* 📋 EndpointSlice
* ⚖️ Load Balancing
* 🛣️ iptables Mode
* 🚀 IPVS Mode
* 🧠 nftables Mode
* 🐧 Linux Packet Flow
* ☸️ Complete Service Networking

---

# ❓ What Is kube-proxy?

kube-proxy is a Kubernetes node component that implements Service networking.

It runs on **every worker node**.

Responsibilities:

* Watch Services
* Watch EndpointSlices
* Program Linux networking rules
* Load balance traffic
* Forward packets to backend Pods

It does **not** proxy traffic in user space for normal Service traffic.

Instead, it programs the Linux kernel networking stack.

---

# 🏗️ Worker Node Architecture

```text
Worker Node

├── kubelet

├── kube-proxy

├── containerd

├── CNI Plugin

└── Pods
```

kube-proxy cooperates with the Linux kernel to provide Service networking.

---

# 👀 Watching the API Server

kube-proxy continuously watches:

```text
API Server

↓

Services

↓

EndpointSlices
```

Whenever:

* Pod created
* Pod deleted
* Service created
* Service updated

kube-proxy updates the node's networking rules.

---

# 📡 Service Virtual IP

Example:

```text
ClusterIP

10.96.15.20
```

Important:

No Linux interface owns:

```text
10.96.15.20
```

Instead:

```text
Packet

↓

iptables/IPVS

↓

Backend Pod
```

The Service IP is a **virtual IP** implemented through kernel networking rules.

---

# 📋 EndpointSlice

Modern Kubernetes uses **EndpointSlice** instead of the older Endpoints object.

Example:

```text
student-api

↓

10.244.1.18

10.244.2.9

10.244.3.12
```

Each EndpointSlice contains a subset of backend Pod IPs.

kube-proxy watches these objects and updates routing accordingly.

---

# ⚖️ Load Balancing

Suppose:

```text
Pod A

Pod B

Pod C
```

Requests:

```text
Request 1

↓

Pod A

--------------

Request 2

↓

Pod B

--------------

Request 3

↓

Pod C
```

The exact algorithm depends on the proxy mode and kernel implementation, but traffic is distributed across healthy endpoints.

---

# 🛣️ iptables Mode

Historically, the default mode.

Flow:

```text
Packet

↓

iptables PREROUTING

↓

KUBE-SERVICES

↓

KUBE-SVC-xxxxx

↓

KUBE-SEP-xxxxx

↓

Pod
```

iptables performs destination NAT (DNAT) to the selected Pod IP.

---

# 🚀 IPVS Mode

IPVS uses the Linux IP Virtual Server subsystem.

Architecture:

```text
Packet

↓

IPVS Virtual Service

↓

Scheduler

↓

Backend Pod
```

Advantages:

* Efficient with large numbers of Services
* Multiple scheduling algorithms
* Lower rule management overhead

---

# 🧠 nftables Mode

Modern Linux distributions increasingly use **nftables**.

In this mode:

```text
Packet

↓

nftables Rules

↓

Pod
```

This provides a modern packet filtering framework while serving the same purpose as iptables.

---

# 🐧 Packet Flow

Suppose:

```text
Pod A

↓

student-api

↓

10.96.15.20
```

Flow:

```text
Pod

↓

Service IP

↓

Linux Kernel

↓

kube-proxy Rules

↓

DNAT

↓

Pod B
```

The application never knows the packet was redirected.

---

# 🌍 External Request Flow

Browser:

```text
https://student.example.com
```

Execution:

```text
Browser

↓

Load Balancer

↓

Ingress Controller

↓

ClusterIP

↓

kube-proxy

↓

Pod
```

kube-proxy is responsible only for forwarding packets inside the cluster after the Service has been selected.

---

# 🍃 Student Results API Example

Deployment:

```text
3 Pods
```

Service:

```text
student-api

↓

10.96.15.20
```

EndpointSlice:

```text
10.244.1.18

10.244.2.9

10.244.3.12
```

Packet flow:

```text
Frontend

↓

student-api

↓

kube-proxy

↓

Pod-2

↓

Spring Boot
```

If Pod-2 is deleted:

```text
ReplicaSet

↓

New Pod

↓

EndpointSlice Updated

↓

kube-proxy Updates Rules
```

Applications continue using the same Service address.

---

# 📊 kube-proxy Architecture

```text
                  API Server
                       │
                       ▼
           Services / EndpointSlices
                       │
                       ▼
                 kube-proxy
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
    iptables         IPVS         nftables
                       │
                       ▼
                 Linux Kernel
                       │
                       ▼
                    Pod IP
```

---

# 🔄 Pod Replacement

Suppose:

```text
Pod A

↓

Deleted
```

ReplicaSet creates:

```text
Pod D
```

Execution:

```text
EndpointSlice Updated

↓

kube-proxy Watch

↓

Rewrite Rules

↓

Traffic Continues
```

No application changes are required.

---

# 🚫 Common Mistakes

## ❌ Thinking kube-proxy Is a Traditional Proxy

kube-proxy normally does **not** relay packets through its own process.

It programs kernel networking rules that forward packets efficiently.

---

## ❌ Thinking ClusterIP Exists on a Network Interface

ClusterIP is a virtual IP.

It exists because kube-proxy installs packet processing rules in the Linux kernel.

---

## ❌ Thinking kube-proxy Watches Pods Directly

kube-proxy watches **Services** and **EndpointSlices** from the API Server.

It derives backend Pod addresses from EndpointSlices.

---

## ❌ Thinking kube-proxy Creates Services

The API Server stores Service objects.

kube-proxy only implements their networking behavior on each node.

---

# 🐳 Docker Comparison

Docker Bridge Network:

```text
Container

↓

docker0

↓

Bridge Forwarding
```

Kubernetes:

```text
Service

↓

kube-proxy

↓

Linux Kernel

↓

Pod
```

Kubernetes adds cluster-wide Service discovery and load balancing.

---

# 🧪 Hands-on Lab

## View kube-proxy

```bash
kubectl get pods -n kube-system
```

Locate the kube-proxy Pod running on each node.

---

## Inspect kube-proxy Logs

```bash
kubectl logs -n kube-system <kube-proxy-pod>
```

Observe synchronization messages for Services and EndpointSlices.

---

## View Services

```bash
kubectl get svc
```

Observe:

* ClusterIP
* Ports
* Type

---

## View EndpointSlices

```bash
kubectl get endpointslices
```

Observe backend Pod IPs associated with each Service.

---

## Inspect iptables Rules (iptables mode)

On a worker node:

```bash
sudo iptables -t nat -L -n | grep KUBE
```

Observe Kubernetes-managed NAT chains.

---

## Inspect IPVS Rules (IPVS mode)

If IPVS is enabled:

```bash
sudo ipvsadm -Ln
```

Observe virtual Services and backend Pods.

---

# 📈 Complete Service Packet Flow

```text
Application
      │
      ▼
Service DNS
      │
      ▼
CoreDNS
      │
      ▼
ClusterIP
      │
      ▼
Linux Kernel
      │
      ▼
kube-proxy Rules
      │
      ▼
DNAT
      │
      ▼
Selected Pod
      │
      ▼
Spring Boot
```

For external traffic:

```text
Browser
      │
      ▼
DNS
      │
      ▼
Load Balancer
      │
      ▼
Ingress Controller
      │
      ▼
ClusterIP
      │
      ▼
kube-proxy
      │
      ▼
Pod
```

This is the complete networking path from a Service to a running application.

---

# 📊 kube-proxy Responsibilities

| Component                  | Responsibility                           |
| -------------------------- | ---------------------------------------- |
| 🔀 kube-proxy              | Implements Kubernetes Service networking |
| 👀 Watch API               | Watches Services and EndpointSlices      |
| 📡 ClusterIP               | Implements virtual Service IP routing    |
| 📋 EndpointSlice           | Supplies backend Pod addresses           |
| ⚖️ Load Balancing          | Distributes traffic across healthy Pods  |
| 🛣️ iptables/IPVS/nftables | Programs Linux kernel packet forwarding  |
| 🐧 Linux Kernel            | Performs packet rewriting and forwarding |

---

# 💡 Key Takeaways

✅ kube-proxy runs on every Kubernetes node and implements Service networking.

✅ It watches **Services** and **EndpointSlices** through the API Server.

✅ ClusterIP addresses are virtual IPs implemented by Linux networking rules rather than physical interfaces.

✅ kube-proxy programs **iptables**, **IPVS**, or **nftables** so packets destined for a Service are redirected to backend Pods.

✅ EndpointSlices provide the current list of healthy backend Pod IPs for each Service.

✅ When Pods are created or deleted, kube-proxy updates kernel networking rules automatically.

✅ Together, Services, EndpointSlices, kube-proxy, and the Linux kernel provide transparent service discovery and load balancing inside a Kubernetes cluster.

---

# ➡️ Next Chapter

📘 **`10-Kubernetes/14-CNI.md`**

In the next chapter, we'll explore the **Container Network Interface (CNI)**.

We'll answer questions such as:

* 🌐 How does every Pod receive its own IP address?
* 🔌 What does a CNI plugin actually do?
* 🧩 How are `veth` pairs created?
* 🌉 How do Pods communicate across different nodes?
* 🚀 How do Calico, Flannel, and Cilium implement Kubernetes networking?

By the end of the chapter, you'll understand how Kubernetes networking is built from Linux networking primitives all the way up to cluster-wide Pod communication.
