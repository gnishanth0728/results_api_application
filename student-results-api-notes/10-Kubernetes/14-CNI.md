# 📘 Chapter 91 — Kubernetes CNI (Container Network Interface)

> 📂 File: `student-results-api-notes/10-Kubernetes/14-CNI.md`

This chapter explains how Kubernetes gives every Pod its own IP address.

So far you've learned:

Pod
    ↓
Service
    ↓
kube-proxy

But another important question appears:

Where does the Pod IP come from?

For example:

Pod A

10.244.1.8
Pod B

10.244.2.15

How are these IPs assigned?

Who creates:

Network namespaces?
veth pairs?
Routes?
Linux bridges?
VXLAN tunnels?
BGP routes?

Who connects the Pod network to the rest of the Kubernetes cluster?

The answer is:

Container Network Interface (CNI)

The CNI is the networking layer of Kubernetes.

When kubelet creates a Pod sandbox, it asks the CNI plugin to configure networking for that Pod.

The CNI plugin is responsible for turning an isolated Linux process into a network-connected Pod that can communicate with every other Pod in the cluster.

---

# 🌍 Introduction

In the previous chapter, we learned how **kube-proxy** forwards packets from a Service to backend Pods.

Flow:

```text
Browser

↓

Ingress

↓

Service

↓

kube-proxy

↓

Pod
```

But another important question appears:

> 🤔 **How did the Pod get an IP address in the first place?**

When kubelet creates a Pod:

```text
RunPodSandbox()

↓

Pause Container
```

the Pod initially has **no networking**.

Something must:

* Create a network namespace
* Assign an IP address
* Create virtual Ethernet interfaces
* Connect the Pod to the node network
* Configure routing

That component is:

# 🌐 Container Network Interface (CNI)

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🌐 What CNI is
* 🔌 CNI Specification
* ⚙️ CNI Plugins
* 🧩 Network Namespace
* 🔗 veth Pair
* 🌉 Linux Bridge
* 📡 Pod IP Assignment
* 🌍 Cross-Node Networking
* 🚀 Popular CNI Implementations
* ☸️ Complete Pod Networking Flow

---

# ❓ What Is CNI?

CNI (Container Network Interface) is a specification that defines how container runtimes configure networking.

Kubernetes itself does **not** implement networking.

Instead:

```text
kubelet

↓

containerd

↓

CNI Plugin

↓

Linux Networking
```

The CNI plugin performs all networking operations.

---

# 🏗️ High-Level Architecture

```text
Pod

↓

Network Namespace

↓

veth Pair

↓

Linux Bridge

↓

Node Network

↓

Cluster Network
```

---

# ⚙️ CNI Plugins

Popular implementations:

* Calico
* Flannel
* Cilium
* Weave Net
* Antrea

Each plugin implements the CNI specification differently.

---

# 🔌 CNI Specification

When kubelet creates a Pod sandbox:

```text
RunPodSandbox()

↓

containerd

↓

ADD

↓

CNI Plugin
```

The CNI plugin receives:

* Pod namespace
* Container ID
* Network name
* Interface name

It returns:

* Pod IP
* Routes
* DNS configuration

---

# 🧩 Step 1 — Create Network Namespace

Every Pod gets its own network namespace.

Example:

```text
Network Namespace

↓

eth0

↓

lo
```

Initially, the namespace contains only basic interfaces.

---

# 🔗 Step 2 — Create veth Pair

Linux creates a virtual Ethernet pair.

```text
Host Side

veth123

↔

eth0

Pod Side
```

One end stays on the node.

The other end moves into the Pod network namespace.

Packets entering one interface immediately appear on the other.

---

# 🌉 Step 3 — Connect to Linux Bridge

Example:

```text
Pod

↓

veth

↓

Bridge

↓

eth0

↓

Physical Network
```

The bridge connects Pods to the node's network.

Some CNIs (such as Calico in routing mode) do not use a Linux bridge and instead rely on routing.

---

# 📡 Step 4 — Assign Pod IP

Example:

```text
Pod

↓

10.244.1.15
```

The CNI plugin allocates an IP address from the node's Pod CIDR.

The Pod now has:

```text
eth0

↓

10.244.1.15
```

---

# 🌍 Step 5 — Configure Routes

The plugin installs routes.

Example:

```text
Destination

10.244.2.0/24

↓

Gateway

Node-2
```

This enables communication between Pods on different nodes.

---

# 🚀 Cross-Node Networking

Suppose:

```text
Node A

↓

Pod

10.244.1.15

-------------------

Node B

↓

Pod

10.244.2.8
```

Traffic:

```text
Pod A

↓

Node A

↓

Cluster Network

↓

Node B

↓

Pod B
```

Exactly how this traffic is transported depends on the CNI implementation.

---

# 🌐 Calico Example

Calico commonly uses routing rather than overlays.

Architecture:

```text
Pod

↓

veth

↓

Routing Table

↓

BGP

↓

Other Nodes
```

Calico can also use VXLAN when BGP is unavailable.

---

# 🌉 Flannel Example

Flannel commonly uses VXLAN.

```text
Pod

↓

Bridge

↓

VXLAN Tunnel

↓

Other Node
```

Packets are encapsulated before crossing the physical network.

---

# ⚡ Cilium Example

Cilium uses eBPF instead of relying primarily on iptables.

Architecture:

```text
Pod

↓

eBPF

↓

Linux Kernel

↓

Other Pod
```

Cilium can also replace kube-proxy for Service load balancing.

---

# 🍃 Student Results API Example

Execution:

```text
Pod Created

↓

RunPodSandbox()

↓

CNI ADD

↓

Network Namespace

↓

veth Pair

↓

Assign IP

↓

Configure Routes

↓

Running Pod
```

Result:

```text
Student API

↓

10.244.1.15
```

---

# 📊 Complete CNI Architecture

```text
                kubelet
                    │
                    ▼
               containerd
                    │
                    ▼
                CNI Plugin
                    │
       ┌────────────┼─────────────┐
       ▼            ▼             ▼
 Network NS      veth Pair     IP Address
       │            │             │
       └────────────┼─────────────┘
                    ▼
               Linux Networking
                    │
                    ▼
                 Cluster Network
```

---

# 🔄 Complete Pod Networking Flow

```text
Pod Created

↓

RunPodSandbox()

↓

containerd

↓

CNI ADD

↓

Create Network Namespace

↓

Create veth Pair

↓

Assign IP

↓

Configure Routes

↓

Running Pod
```

---

# 🌍 Kubernetes Networking Model

Kubernetes networking follows four important rules:

1. Every Pod receives its own IP address.
2. Pods can communicate with other Pods without NAT.
3. Nodes can communicate with every Pod.
4. Pods see the same network whether they are on the same node or different nodes.

This consistent networking model is one of Kubernetes' core design principles.

---

# 🚫 Common Mistakes

## ❌ Thinking kubelet Assigns Pod IPs

kubelet invokes the CNI plugin.

The CNI plugin performs the networking configuration.

---

## ❌ Thinking Every CNI Uses a Linux Bridge

Some plugins use bridges.

Others use routing, VXLAN, Geneve, or eBPF.

The implementation varies.

---

## ❌ Thinking Pods on Different Nodes Need Manual Routes

The CNI plugin automatically configures routing or overlays so Pods can communicate across the cluster.

---

## ❌ Thinking CNI Performs Service Load Balancing

Service networking is handled by kube-proxy or an eBPF-based implementation such as Cilium.

CNI primarily provides Pod networking.

---

# 🐳 Docker Comparison

Docker Bridge:

```text
Container

↓

veth

↓

docker0

↓

Host
```

Kubernetes:

```text
Pod

↓

CNI

↓

Cluster Network
```

CNI extends container networking across an entire cluster.

---

# 🧪 Hands-on Lab

## View CNI Configuration

```bash
ls /etc/cni/net.d/
```

Observe installed CNI configuration files.

---

## View Installed CNI Binaries

```bash
ls /opt/cni/bin/
```

Examples:

* calico
* flannel
* bridge
* host-local
* loopback

---

## View Pod IPs

```bash
kubectl get pods -o wide
```

Observe Pod IP addresses.

---

## Inspect Network Interfaces

Inside a Pod:

```bash
kubectl exec -it <pod-name> -- ip addr
```

Observe:

* `eth0`
* `lo`

---

## View Host veth Interfaces

On the node:

```bash
ip link
```

Observe multiple `veth` interfaces connected to Pods.

---

## View Routing Table

```bash
ip route
```

Observe Pod CIDR routes configured by the CNI plugin.

---

# 📈 Complete Kubernetes Networking Flow

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
kubelet
      │
      ▼
containerd
      │
      ▼
CNI ADD
      │
      ├── Create Network Namespace
      ├── Create veth Pair
      ├── Assign Pod IP
      ├── Configure Routes
      │
      ▼
Running Pod
      │
      ▼
Service
      │
      ▼
kube-proxy
      │
      ▼
Other Pod
```

This is the complete networking lifecycle from Pod creation to Pod-to-Pod communication.

---

# 📊 CNI Responsibilities

| Component                 | Responsibility                                          |
| ------------------------- | ------------------------------------------------------- |
| 🌐 CNI                    | Defines the standard interface for container networking |
| ⚙️ CNI Plugin             | Implements Pod networking                               |
| 🧩 Network Namespace      | Provides isolated networking for each Pod               |
| 🔗 veth Pair              | Connects the Pod namespace to the node                  |
| 🌉 Linux Bridge / Routing | Connects Pods to the node network                       |
| 📡 IPAM                   | Allocates Pod IP addresses                              |
| 🌍 Routes / Overlay       | Enables cross-node Pod communication                    |

---

# 💡 Key Takeaways

✅ Kubernetes delegates Pod networking to CNI plugins.

✅ When a Pod is created, the container runtime invokes the CNI plugin using the CNI specification.

✅ The CNI plugin creates a network namespace, configures a `veth` pair, assigns a Pod IP, and installs routing.

✅ Every Pod receives its own unique IP address and can communicate directly with other Pods in the cluster.

✅ Different CNI implementations use different networking technologies, such as Linux bridges, routing, VXLAN, or eBPF.

✅ kube-proxy (or an eBPF replacement) provides Service networking, while the CNI plugin provides Pod networking.

✅ Understanding CNI completes the networking journey from Linux networking primitives to full Kubernetes cluster communication.

---

# ➡️ Next Chapter

📘 **`10-Kubernetes/15-Complete-Request-Flow.md`**

In the next chapter, we'll combine everything you've learned into one end-to-end walkthrough.

We'll trace a single HTTP request through every layer:

* 🌍 Browser
* ⚖️ DNS
* 🚪 Load Balancer
* 🌐 Ingress
* 🔀 kube-proxy
* 🌐 CNI
* 📦 Pod
* ☕ Spring Boot
* 🧠 JVM
* 🐧 Linux Kernel

By the end of the next chapter, you'll have a complete mental model of how a request travels from an end user all the way to a Java method running inside a Kubernetes Pod.
