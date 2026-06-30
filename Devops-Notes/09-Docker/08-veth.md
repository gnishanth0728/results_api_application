# 📘 Chapter 76 — Virtual Ethernet (veth)

> 📂 File: `student-results-api-notes/09-Docker/08-veth.md`

This chapter explains one of the most fundamental Linux networking technologies behind Docker.

In the previous chapter, you learned that Docker uses:

Container

↓

docker0

↓

Host

But we skipped one critical component.

The obvious question is:

How is a container actually connected to the docker0 bridge?

A container has its own network namespace.

The bridge exists in the host network namespace.

Since namespaces are isolated, they cannot directly share a network interface.

The answer is:

veth (Virtual Ethernet Pair)

A veth pair behaves like a virtual Ethernet cable.

Whatever enters one end immediately appears on the other end.

This tiny Linux kernel feature is what physically connects containers to Docker networking.

Understanding veth is also essential for Kubernetes because every Pod uses veth pairs created by the CNI plugin.

---

# 🌍 Introduction

In the previous chapter, we learned about the **Docker Bridge Network**.

We saw:

```text
Container

↓

docker0

↓

Host

↓

Internet
```

But another important question appears:

> 🤔 **How is the container physically connected to the docker0 bridge?**

The container has its own network namespace.

The bridge exists in the host namespace.

Since namespaces are isolated, they cannot directly share a network interface.

The Linux kernel solves this problem using:

# 🔌 Virtual Ethernet Pair (veth)

A veth pair acts like a virtual network cable.

Packets entering one end immediately emerge from the other end.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🔌 What a veth Pair is
* 🌐 How Containers Connect to docker0
* 🐧 Network Namespaces
* 📡 Packet Flow
* 🌉 Linux Bridge
* 🔀 Packet Switching
* 🛠️ veth Creation
* 🐳 Docker Networking
* ☸️ Kubernetes Pod Networking

---

# ❓ What Is a veth Pair?

A **Virtual Ethernet Pair** is a pair of linked virtual network interfaces.

Think of it like an Ethernet cable.

```text
End A

════════════════════

End B
```

Whatever enters:

```text
End A
```

Immediately exits:

```text
End B
```

The kernel forwards Ethernet frames between the two interfaces.

---

# 🏗️ High-Level Architecture

Docker creates:

```text
Host Namespace

↓

veth123

════════════════

eth0

↓

Container Namespace
```

One end stays on the host.

The other end is moved into the container.

---

# 🌐 Why Do We Need veth?

Without a veth pair:

```text
Host Namespace

Container Namespace

↓

No Connection
```

They are isolated.

With a veth pair:

```text
Host Namespace

↓

veth123

════════════════

eth0

↓

Container Namespace
```

Communication becomes possible.

---

# 🏗️ Docker Network Creation

When Docker starts a container:

```bash
docker run nginx
```

Internally:

```text
Create Network Namespace

↓

Create veth Pair

↓

Move One End

↓

Connect Other End

↓

Container Online
```

The networking is ready before the application starts.

---

# 🔌 Two Ends of a veth Pair

Example:

```text
Host

↓

veth6ab2

══════════════

eth0

↓

Container
```

Host end:

```text
veth6ab2
```

Container end:

```text
eth0
```

Inside the container, the interface is typically renamed to `eth0`.

---

# 🌉 Connecting to docker0

The host-side interface is attached to the Linux bridge.

```text
Container

↓

eth0

↓

veth Pair

↓

veth6ab2

↓

docker0

↓

Host Network
```

The bridge forwards packets between connected interfaces.

---

# 📡 Packet Flow

Suppose:

Spring Boot:

```text
172.17.0.2
```

PostgreSQL:

```text
172.17.0.3
```

Packet flow:

```text
Spring Boot

↓

eth0

↓

veth

↓

docker0

↓

veth

↓

eth0

↓

PostgreSQL
```

The packet never leaves the host.

---

# 📊 Packet Journey

Suppose:

```http
GET /students
```

Journey:

```text
Browser

↓

Host TCP/IP Stack

↓

iptables

↓

docker0

↓

Host veth

↓

Container eth0

↓

Tomcat

↓

Spring Boot
```

The response follows the reverse path.

---

# 🌍 Internet Access

Container:

```text
172.17.0.2
```

Outgoing traffic:

```text
eth0

↓

veth

↓

docker0

↓

Host

↓

NAT

↓

Internet
```

The veth pair transports packets from the isolated namespace to the host networking stack.

---

# 🧠 Linux Kernel View

Each interface has:

* MAC address
* MTU
* TX queue
* RX queue

Example:

```text
Host

vethc18f

MAC

02:42:ac:11:00:02

══════════════════

Container

eth0

MAC

02:42:ac:11:00:03
```

Both ends behave like standard Ethernet interfaces.

---

# 🍃 Student Results API Example

Run:

```bash
docker run \
-p 8080:8080 \
student-api
```

Networking:

```text
Spring Boot

↓

eth0

↓

veth

↓

docker0

↓

Host

↓

Browser
```

Database:

```text
Spring Boot

↓

veth

↓

docker0

↓

veth

↓

PostgreSQL
```

Both containers communicate using their own veth pairs.

---

# 📊 veth Architecture

```text
                 Host

+-----------------------------------+

|             docker0               |

|                                   |

|   veth1              veth2        |

|     │                  │          |

+-----┼------------------┼----------+

      │                  │

      ▼                  ▼

 Container A       Container B

     eth0              eth0
```

Each container contributes one interface to the bridge.

---

# 🛠️ Creating a veth Pair Manually

Linux can create a veth pair without Docker.

```bash
sudo ip link add vethA type veth peer name vethB
```

Verify:

```bash
ip link show
```

Example:

```text
vethA

vethB
```

---

# 🔄 Moving One End to a Namespace

Suppose a namespace exists:

```bash
sudo ip netns add demo
```

Move one interface:

```bash
sudo ip link set vethB netns demo
```

Result:

```text
Host

↓

vethA

══════════════

vethB

↓

demo Namespace
```

This is essentially what Docker does automatically.

---

# 🚫 Common Mistakes

## ❌ Thinking eth0 Is Shared

Every container has its own private `eth0`.

The interfaces belong to different network namespaces.

---

## ❌ Thinking docker0 Connects Directly to Containers

The bridge connects only to the **host-side** end of each veth pair.

Containers connect through their own end of the pair.

---

## ❌ Assuming veth Is Docker-Specific

veth is a Linux kernel feature.

Docker, Kubernetes, Podman, LXC, and many other container technologies all use it.

---

# 🐳 Docker Internal View

```text
Browser
     │
     ▼
Host TCP/IP Stack
     │
     ▼
docker0
     │
     ▼
Host veth
     │
════════════════════
     │
Container eth0
     │
     ▼
Java Process
```

---

# ☸️ Kubernetes Perspective

Every Kubernetes Pod also uses a veth pair.

```text
Pod

↓

eth0

↓

veth Pair

↓

CNI Bridge

↓

Node Network
```

Instead of `docker0`, the host-side interface connects to the networking created by the CNI plugin (such as Calico, Flannel, or Cilium).

---

# 🧪 Hands-on Lab

## Run a Container

```bash
docker run -d --name nginx-demo nginx
```

---

## Find the Container PID

```bash
docker inspect \
--format '{{.State.Pid}}' nginx-demo
```

Example:

```text
4218
```

---

## Enter the Network Namespace

```bash
sudo nsenter \
-t 4218 \
-n
```

Run:

```bash
ip addr
```

Observe:

```text
eth0
```

---

## View Host Interfaces

```bash
ip link
```

Look for interfaces similar to:

```text
veth8a2d

vethb63f
```

---

## Show Bridge Connections

```bash
bridge link
```

Observe the veth interfaces attached to `docker0`.

---

## Capture Packets

On the host:

```bash
sudo tcpdump -i docker0
```

Generate traffic from a container and watch packets traverse the bridge.

---

# 📈 Complete Packet Flow

```text
Browser
    │
    ▼
Host TCP/IP Stack
    │
    ▼
iptables
    │
    ▼
docker0
    │
    ▼
Host veth
    │
════════════════════
    │
Container eth0
    │
    ▼
Spring Boot
    │
    ▼
Tomcat
```

This is the complete network path from the browser to a container using a veth pair.

---

# 📊 veth Components

| Component            | Responsibility                                           |
| -------------------- | -------------------------------------------------------- |
| 🔌 veth Pair         | Virtual Ethernet cable connecting two network namespaces |
| 🌐 Container `eth0`  | Network interface inside the container                   |
| 🌉 Host veth         | Interface attached to the Linux bridge                   |
| 📦 `docker0`         | Layer-2 bridge switching Ethernet frames                 |
| 📡 Network Namespace | Isolated network stack for each container                |
| 🔀 iptables          | Performs NAT and port forwarding                         |

---

# 💡 Key Takeaways

✅ A veth pair is a Linux kernel feature that creates two interconnected virtual Ethernet interfaces.

✅ One end remains in the host network namespace, while the other is moved into the container's network namespace and becomes `eth0`.

✅ The host-side interface connects to the `docker0` Linux bridge, enabling communication between containers and the host.

✅ Packets entering one end of a veth pair immediately appear on the other end, just like a physical Ethernet cable.

✅ Docker automatically creates and manages veth pairs during container startup.

✅ Kubernetes CNI plugins also rely on veth pairs to connect Pods to the node's networking.

✅ Understanding veth pairs is essential before learning advanced Docker networking, Kubernetes CNI internals, and Service networking.

---

# ➡️ Next Chapter

📘 **`09-Docker/09-Port-Mapping.md`**

In the next chapter, we'll explore **Docker Port Mapping**.

We'll answer questions such as:

* 🎯 What does `-p 8080:80` actually do?
* 🔀 How does Docker use iptables and NAT?
* 🌐 How does a browser request reach a container?
* 📡 What is DNAT (Destination NAT)?
* 🧠 Why is the container port different from the host port?

By the end of the chapter, you'll understand the complete packet journey from your browser to an application running inside a Docker container.
