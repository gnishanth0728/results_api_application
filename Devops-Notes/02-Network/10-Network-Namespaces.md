# 📘 Chapter 15 — Linux Network Namespaces

> 📂 File: `student-results-api-notes/02-Network/10-Network-Namespaces.md`

---

# 🌍 Introduction

So far we've studied networking from the perspective of a single Linux machine.

The picture looked like this:

```text
Internet
    │
    ▼
Linux Kernel
    │
    ▼
Socket
    │
    ▼
Tomcat
    │
    ▼
Spring Boot
```

This works perfectly for one application.

But modern servers don't run only one application.

A single machine may run:

* 🐳 500 Docker containers
* ☸️ Hundreds of Kubernetes Pods
* 🌐 Nginx
* ☕ Spring Boot APIs
* 🐘 PostgreSQL
* 📦 Redis
* 📡 Kafka

A question immediately appears:

> **How can every container believe it owns its own network?**

The answer is one of Linux's most powerful features:

# 🌐 Network Namespaces

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🌐 What a Network Namespace is
* 🧠 Why namespaces exist
* 🔒 Network isolation
* 📡 Virtual network interfaces
* 🔗 veth pairs
* 🌉 Linux bridges
* 🐳 Docker networking
* ☸️ Kubernetes Pod networking
* 📦 CNI plugins
* 🧪 Namespace debugging

---

# ❓ Why Network Namespaces Exist

Imagine two applications:

```text
Spring Boot API

Port 8080
```

and

```text
Another Spring Boot API

Port 8080
```

Normally Linux reports:

```text
BindException

Port already in use
```

because both applications share the same network stack.

But Docker allows:

```text
Container A

Port 8080
```

and

```text
Container B

Port 8080
```

to coexist.

How?

Each container has **its own network namespace**.

---

# 🏗️ What Is a Network Namespace?

A network namespace is an isolated copy of the Linux networking stack.

Each namespace contains its own:

* 🌐 Network interfaces
* 📍 IP addresses
* 🛣️ Routing table
* 🔌 Socket table
* 🚪 Port numbers
* 🔥 iptables rules
* 📦 ARP table

Think of it as a completely separate virtual computer.

---

# 🏛️ Default Linux Network Namespace

A normal Linux system starts with one network namespace.

```text
                Host Namespace

+-------------------------------------+

eth0

lo

Routing Table

Port 22

Port 5432

Port 8080

Socket Table

+-------------------------------------+
```

Every normal process shares this networking environment.

---

# 🌐 Multiple Network Namespaces

With namespaces:

```text
                    Linux Kernel

        +-----------------------------+

Namespace A

eth0

lo

Port 8080

Socket Table

-----------------------------

Namespace B

eth0

lo

Port 8080

Socket Table

-----------------------------

Namespace C

eth0

lo

Port 8080

Socket Table

+-----------------------------+
```

Notice:

Every namespace owns its own port 8080.

There is no conflict because each namespace has a separate networking stack.

---

# 🧠 Namespace Isolation

Applications inside one namespace cannot directly see:

* Interfaces
* Routes
* Sockets
* Ports

from another namespace.

Example:

```text
Namespace A

Port 8080
```

cannot see

```text
Namespace B

Port 8080
```

This isolation is implemented entirely by the Linux kernel.

---

# 🌐 Loopback Interface

Every namespace automatically contains its own loopback interface.

```text
lo

127.0.0.1
```

Inside Container A:

```text
localhost

↓

Container A
```

Inside Container B:

```text
localhost

↓

Container B
```

Even though both use:

```text
127.0.0.1
```

they refer to different network namespaces.

---

# 🔗 Virtual Ethernet Pair (veth)

Namespaces cannot communicate by themselves.

Linux connects them using **virtual Ethernet pairs**.

```text
Namespace A

eth0

│

vethA

==================

vethB

│

Host Namespace
```

Think of a veth pair as a virtual Ethernet cable.

Anything sent into one end appears immediately at the other end.

---

# 🌉 Linux Bridge

Docker normally creates a bridge named:

```bash
docker0
```

Architecture:

```text
Container A

↓

veth

↓

docker0 Bridge

↓

Host Network
```

The bridge behaves like a virtual Ethernet switch.

It forwards packets between containers and the host.

---

# 🐳 Docker Networking

When Docker starts a container:

```bash
docker run student-api
```

Docker automatically:

* Creates a network namespace
* Creates a veth pair
* Connects one end to the container
* Connects the other end to `docker0`
* Assigns an IP address
* Configures routes
* Starts the container process

The application never performs these steps itself.

---

# 📦 Docker Network Layout

```text
                 Host Namespace

eth0

docker0

│

├──────────────┐

│              │

vethA          vethB

│              │

Container 1    Container 2

eth0           eth0

10.0.0.2       10.0.0.3

Port 8080      Port 8080
```

Both containers use port **8080** without conflict because they are isolated by separate namespaces.

---

# ☸️ Kubernetes Networking

Kubernetes builds directly on Linux namespaces.

Each Pod receives:

* Network Namespace
* IP Address
* Routing Table
* Loopback Interface
* veth Pair

Unlike Docker, **all containers inside the same Pod share one network namespace**.

```text
Pod

+-----------------------------+

Container A

localhost

↓

127.0.0.1

-----------------------------

Container B

localhost

↓

127.0.0.1

+-----------------------------+
```

This is why containers in the same Pod communicate using `localhost`.

---

# 🧠 Kubernetes Node Networking

```text
Node

↓

Network Namespace

↓

CNI Plugin

↓

veth

↓

Pod Namespace

↓

Container
```

CNI plugins such as:

* Calico
* Flannel
* Cilium
* Weave

automatically create and configure Pod networking.

---

# 🧪 Hands-on Lab

## Display Existing Namespaces

```bash
ip netns
```

---

## Create a Namespace

```bash
sudo ip netns add demo
```

---

## List Namespaces

```bash
ip netns list
```

---

## Enter the Namespace

```bash
sudo ip netns exec demo bash
```

Inside the namespace:

```bash
ip addr
```

Notice only:

```text
lo
```

exists initially.

---

## Delete the Namespace

```bash
sudo ip netns delete demo
```

---

## Inspect Docker Networking

```bash
docker network ls
```

Inspect the default bridge:

```bash
docker network inspect bridge
```

---

## Inspect Container Interfaces

```bash
docker exec -it <container> ip addr
```

Notice the container has its own:

* `eth0`
* `lo`
* IP address
* Routing table

---

# 🔍 Real Student Results API Flow

When running directly on Linux:

```text
Browser

↓

Host Namespace

↓

Port 8080

↓

Tomcat
```

When running in Docker:

```text
Browser

↓

Host Namespace

↓

docker0

↓

veth Pair

↓

Container Namespace

↓

Port 8080

↓

Tomcat
```

When running in Kubernetes:

```text
Browser

↓

Ingress

↓

Service

↓

Pod Network Namespace

↓

Container

↓

Tomcat
```

The application code is identical in all three cases.

Only the networking path changes.

---

# 💡 Key Takeaways

✅ A network namespace is an isolated copy of the Linux networking stack.

✅ Every namespace has its own interfaces, routes, sockets, and ports.

✅ Multiple applications can listen on port 8080 simultaneously when they are in different namespaces.

✅ Virtual Ethernet (veth) pairs connect namespaces together.

✅ Docker creates one network namespace per container.

✅ Kubernetes creates one network namespace per Pod, shared by all containers in that Pod.

✅ CNI plugins automate namespace creation and interconnection across the cluster.

---

# 🎉 Networking Module Complete

You now understand the complete networking journey:

```text
React
   ↓
Axios
   ↓
DNS
   ↓
TCP/IP
   ↓
Routing
   ↓
NIC
   ↓
Linux Network Stack
   ↓
Socket
   ↓
Port
   ↓
Network Namespace
   ↓
Tomcat
   ↓
Spring Boot
```

You now have a production-level understanding of Linux networking and are ready to move into the operating system internals.

---

# ➡️ Next Part

📂 **03-Linux**

The next chapter is:

**📘 `03-Linux/01-Linux-Boot-Process.md`**

You'll learn how a Linux machine boots from power-on to a running Java process:

```text
Power On
   ↓
BIOS / UEFI
   ↓
GRUB
   ↓
Linux Kernel
   ↓
systemd
   ↓
Services
   ↓
Java Process
   ↓
Tomcat
   ↓
Port 8080 Ready
```

This bridges the gap between operating system internals and your Spring Boot application, completing the foundation needed to understand Docker and Kubernetes from first principles.
