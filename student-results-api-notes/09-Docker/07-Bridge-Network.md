# 📘 Chapter 75 — Docker Bridge Network

> 📂 File: `student-results-api-notes/09-Docker/07-Bridge-Network.md`

This chapter is where Docker networking truly begins.

Up to this point, you've learned:

📦 Containers are Linux processes
🐧 Namespaces isolate networking
💾 cgroups control resources
📂 OverlayFS provides the filesystem

Now another important question appears:

If every container has its own network namespace, how do containers communicate with each other?

For example:

Spring Boot Container
        │
        ▼
PostgreSQL Container

How does the Spring Boot application connect to PostgreSQL?

How does your browser reach a container?

How does a container reach the Internet?

The answer begins with Docker's default network:

Bridge Network

This chapter explains how Docker networking works from the Linux kernel perspective, including:

🌉 Linux Bridge
🔌 veth (Virtual Ethernet Pair)
🌐 Network Namespace
📡 Routing
🔀 NAT
🎯 Port Mapping
📦 Docker Bridge (docker0)

Understanding this chapter is essential before learning Docker Compose networking and Kubernetes CNI networking

---

# 🌍 Introduction

In the previous chapter, we learned that every container receives its own **Network Namespace**.

Inside a container we can run:

```bash
ip addr
```

Output:

```text
eth0

127.0.0.1
```

Every container has its own:

* Network interfaces
* Routing table
* Loopback interface
* IP address

But another important question appears:

> 🤔 **How do isolated containers communicate with each other?**

How does:

* Spring Boot connect to PostgreSQL?
* Browser connect to Nginx?
* Container access the Internet?

The answer is:

# 🌉 Docker Bridge Network

Docker creates a virtual Layer-2 network using Linux networking primitives.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🌉 Linux Bridge
* 🔌 Virtual Ethernet (veth)
* 🌐 Network Namespace
* 📦 docker0
* 📡 Routing
* 🔀 NAT
* 🎯 Port Mapping
* 🌍 Internet Access
* 🐳 Docker Networking
* ☸️ Kubernetes Networking

---

# ❓ What Is the Docker Bridge Network?

When Docker starts, it creates a virtual bridge called:

```text
docker0
```

Architecture:

```text
               docker0

          ┌───────────────┐

Container A         Container B

172.17.0.2          172.17.0.3
```

The bridge behaves like a virtual Ethernet switch.

---

# 🏗️ High-Level Architecture

```text
Browser

↓

Host Network

↓

docker0 Bridge

↓

Container Network Namespace

↓

Spring Boot
```

Every container connects to the bridge.

---

# 🧠 Linux Bridge

A Linux Bridge works similarly to a physical Ethernet switch.

```text
      docker0

+----------------------+

|       Bridge         |

+----------------------+

    │            │

    ▼            ▼

Container A   Container B
```

The bridge forwards Ethernet frames based on MAC addresses.

---

# 🔌 Virtual Ethernet Pair (veth)

A container cannot connect directly to the bridge.

Docker creates a **veth pair**.

```text
Host Side

veth123

────────────

Container Side

eth0
```

Think of a veth pair as a virtual Ethernet cable.

Anything entering one end exits the other end.

---

# 🌐 Network Namespace Connection

Container creation:

```text
Container

↓

Network Namespace

↓

eth0

↓

veth

↓

docker0

↓

Host Network
```

Each container gets its own veth pair.

---

# 📦 docker0 Bridge

Verify:

```bash
ip addr show docker0
```

Example:

```text
docker0

172.17.0.1/16
```

Typical container IPs:

```text
172.17.0.2

172.17.0.3

172.17.0.4
```

These addresses are assigned by Docker's IP Address Management (IPAM).

---

# 📊 Container Communication

Suppose:

```text
Spring Boot

172.17.0.2
```

PostgreSQL:

```text
172.17.0.3
```

Communication:

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

Packets never leave the host.

---

# 🌍 Internet Access

How does a container reach:

```text
google.com
```

Flow:

```text
Container

↓

docker0

↓

Host

↓

iptables NAT

↓

Internet
```

Docker configures source NAT (masquerading) so that outbound packets appear to come from the host.

---

# 🔀 NAT (Network Address Translation)

Container:

```text
172.17.0.2
```

Cannot be routed on the public Internet.

Docker performs:

```text
172.17.0.2

↓

Host IP

↓

Internet
```

When replies return, Docker translates them back to the container.

---

# 🎯 Port Mapping

Suppose:

```bash
docker run -p 8080:80 nginx
```

Meaning:

```text
Host

8080

↓

Container

80
```

Browser:

```text
localhost:8080

↓

Host

↓

iptables DNAT

↓

docker0

↓

Container

↓

Port 80
```

Port mapping publishes a container service to the host.

---

# 📡 Packet Flow

Suppose:

```text
Browser

↓

localhost:8080
```

Complete journey:

```text
Browser

↓

TCP Socket

↓

Host Network Stack

↓

iptables

↓

docker0

↓

veth

↓

Container eth0

↓

Nginx
```

The response travels back through the same path.

---

# 🍃 Student Results API Example

Run:

```bash
docker run \
-p 8080:8080 \
student-api
```

Flow:

```text
Browser

↓

localhost:8080

↓

Host

↓

docker0

↓

Container

↓

Spring Boot

↓

Tomcat
```

Database:

```text
Spring Boot

↓

docker0

↓

PostgreSQL Container
```

Both containers communicate over the bridge network.

---

# 📊 Complete Bridge Architecture

```text
                    Host

+------------------------------------------+

|                docker0                   |

|                                          |

|   veth1              veth2               |

|     │                  │                 |

+-----┼------------------┼-----------------+

      │                  │

      ▼                  ▼

 Spring Boot        PostgreSQL

172.17.0.2         172.17.0.3
```

---

# 🚫 Common Mistakes

## ❌ Thinking Containers Share the Host Network

Each container has its own network namespace.

Only the bridge connects them.

---

## ❌ Assuming localhost Refers to the Host

Inside a container:

```text
localhost
```

refers only to that container.

It never refers to the Docker host.

---

## ❌ Assuming Port Mapping Changes the Container Port

```bash
-p 8080:80
```

does **not** change the application's listening port.

It only maps a host port to the container port.

---

# 🐳 Docker Internal Networking

```text
Browser
     │
     ▼
Host TCP/IP Stack
     │
     ▼
iptables (DNAT)
     │
     ▼
docker0
     │
     ▼
veth Pair
     │
     ▼
Network Namespace
     │
     ▼
eth0
     │
     ▼
Java Process
```

---

# ☸️ Kubernetes Perspective

Kubernetes networking uses a different implementation but the same Linux concepts.

```text
Pod

↓

Network Namespace

↓

veth

↓

CNI Bridge / Overlay Network

↓

Other Pods
```

Instead of Docker Bridge, Kubernetes typically uses a **CNI plugin** (Calico, Flannel, Cilium, etc.) to connect Pods across nodes.

---

# 🧪 Hands-on Lab

## View Docker Networks

```bash
docker network ls
```

Observe the default `bridge` network.

---

## Inspect the Bridge

```bash
docker network inspect bridge
```

Observe:

* Subnet
* Gateway
* Connected containers

---

## View docker0

```bash
ip addr show docker0
```

Observe the bridge IP address.

---

## Run Two Containers

```bash
docker run -d --name app nginx

docker run -d --name db postgres
```

Inspect:

```bash
docker inspect app

docker inspect db
```

Observe each container's IP address.

---

## Inspect veth Interfaces

On the host:

```bash
ip link
```

Look for interfaces similar to:

```text
veth8c1d2

veth45ab7
```

Each corresponds to one end of a container's virtual Ethernet pair.

---

## Test Port Mapping

Run:

```bash
docker run -d -p 8080:80 nginx
```

Then:

```bash
curl http://localhost:8080
```

Observe that the request reaches the Nginx container through Docker's networking stack.

---

# 📈 Complete Networking Flow

```text
Browser
    │
    ▼
Host TCP/IP Stack
    │
    ▼
iptables (DNAT)
    │
    ▼
docker0 Bridge
    │
    ▼
veth Pair
    │
    ▼
Container Network Namespace
    │
    ▼
eth0
    │
    ▼
Spring Boot
    │
    ▼
Tomcat
```

This is the complete journey of a packet from the browser to a Docker container.

---

# 📊 Docker Bridge Components

| Component            | Responsibility                                             |
| -------------------- | ---------------------------------------------------------- |
| 🌉 docker0           | Virtual Linux bridge connecting containers                 |
| 🔌 veth Pair         | Virtual Ethernet cable between host and container          |
| 🌐 Network Namespace | Isolated network stack for each container                  |
| 📡 Routing Table     | Determines packet forwarding inside the namespace          |
| 🔀 iptables NAT      | Performs outbound masquerading and inbound port forwarding |
| 🎯 Port Mapping      | Publishes container ports on the host                      |

---

# 💡 Key Takeaways

✅ Docker Bridge is Docker's default network for standalone containers.

✅ Every container receives its own network namespace and a virtual Ethernet (`veth`) interface.

✅ The host-side veth interface connects to the `docker0` Linux bridge, allowing containers on the same host to communicate.

✅ Docker uses **NAT (masquerading)** so containers with private IP addresses can access external networks.

✅ Port publishing (`-p hostPort:containerPort`) uses destination NAT to forward traffic from the host into the container.

✅ `localhost` inside a container refers only to that container's own network namespace.

✅ Understanding Docker Bridge networking is essential before learning user-defined networks, Docker Compose networking, Kubernetes Services, and CNI-based networking.
