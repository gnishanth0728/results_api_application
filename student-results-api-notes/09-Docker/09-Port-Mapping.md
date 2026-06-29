# 📘 Chapter 77 — Docker Port Mapping

> 📂 File: `student-results-api-notes/09-Docker/09-Port-Mapping.md`

This chapter explains one of the most misunderstood Docker concepts.

Most developers know that:

docker run -p 8080:80 nginx

works.

But very few know what actually happens inside Linux.

The obvious questions are:

Why can't the browser directly access 172.17.0.2:80?
How does localhost:8080 reach the container?
What does -p actually configure?
Where does iptables come into the picture?
What is DNAT?
Why does the container still listen on port 80?

This chapter answers all of these by following the packet from your browser to the container

---

# 🌍 Introduction

In the previous chapter, we learned how containers connect to the Docker bridge using **veth pairs**.

The networking looked like this:

```text
Container
    │
    ▼
eth0
    │
    ▼
veth
    │
    ▼
docker0
    │
    ▼
Host Network
```

Containers can now communicate with each other.

But another important question appears:

> 🤔 **How does a browser on the host reach a container?**

Suppose we run:

```bash
docker run -p 8080:80 nginx
```

How does a request to:

```text
http://localhost:8080
```

arrive at:

```text
Container Port 80
```

The answer is:

# 🎯 Docker Port Mapping

Docker configures Linux networking rules that translate traffic from a host port to a container port.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🎯 What Port Mapping is
* 🔀 DNAT (Destination NAT)
* 📡 iptables
* 🌉 docker0 Bridge
* 🔌 veth Pair
* 🌐 Network Namespace
* 📦 Host Port vs Container Port
* 🌍 Browser to Container Flow
* 🐳 Docker Networking
* ☸️ Kubernetes NodePort Relationship

---

# ❓ Why Do We Need Port Mapping?

Suppose a container runs:

```text
Nginx

↓

Port 80
```

Container IP:

```text
172.17.0.2
```

Your browser cannot normally access:

```text
172.17.0.2
```

because this is a private address inside Docker's bridge network.

Instead, Docker publishes the service using a host port.

---

# 🚀 The `-p` Option

Example:

```bash
docker run -p 8080:80 nginx
```

Meaning:

```text
Host Port

8080

↓

Container Port

80
```

Important:

The application still listens on **port 80**.

Docker simply forwards traffic from host port **8080**.

---

# 🏗️ High-Level Architecture

```text
Browser

↓

localhost:8080

↓

Host Network Stack

↓

iptables

↓

docker0

↓

veth

↓

Container

↓

Nginx :80
```

---

# 🌐 Host vs Container Port

Container:

```text
eth0

172.17.0.2

↓

Port 80
```

Host:

```text
192.168.1.10

↓

Port 8080
```

These are different networking contexts.

The host never changes the port inside the container.

---

# 📡 What Happens During `docker run -p`

Suppose:

```bash
docker run -p 8080:80 nginx
```

Docker performs:

```text
Create Container

↓

Assign IP

↓

Connect veth

↓

Attach docker0

↓

Configure iptables

↓

Container Ready
```

The key step is configuring Linux firewall/NAT rules.

---

# 🔀 Destination NAT (DNAT)

Browser sends:

```text
Destination

Host:8080
```

iptables rewrites:

```text
Host:8080

↓

172.17.0.2:80
```

This process is called **Destination Network Address Translation (DNAT)**.

---

# 📊 Packet Journey

Browser:

```text
GET /
```

Complete flow:

```text
Browser

↓

TCP Socket

↓

Host TCP/IP Stack

↓

iptables DNAT

↓

docker0

↓

Host veth

↓

Container eth0

↓

Nginx

↓

HTTP Response
```

The return packet follows the reverse path.

---

# 🌉 Bridge Traversal

Packet reaches:

```text
docker0
```

Bridge forwards:

```text
MAC Address

↓

Correct veth

↓

Container
```

The bridge switches Ethernet frames exactly like a physical switch.

---

# 🔌 veth Transfer

The host-side interface receives:

```text
Packet

↓

veth Host End

════════════════════

Container eth0
```

The packet instantly appears inside the container.

---

# 🌐 Network Namespace

Inside the container:

```text
eth0

↓

172.17.0.2

↓

Port 80

↓

Nginx
```

The application has no idea the client originally connected to host port 8080.

---

# 🍃 Student Results API Example

Run:

```bash
docker run \
-p 8080:8080 \
student-api
```

Browser:

```text
http://localhost:8080/api/students
```

Journey:

```text
Browser

↓

Host

↓

iptables

↓

docker0

↓

veth

↓

Container

↓

Spring Boot

↓

Tomcat

↓

Controller
```

The request is delivered exactly as if it had arrived directly at the application.

---

# 📊 Multiple Containers

Example:

```bash
docker run -d -p 8081:80 nginx

docker run -d -p 8082:80 nginx
```

Architecture:

```text
Browser

↓

8081

↓

Container A

Port 80

--------------------

Browser

↓

8082

↓

Container B

Port 80
```

Different host ports can map to the same container port on different containers.

---

# 📊 Complete Port Mapping Architecture

```text
                Browser
                    │
                    ▼
          localhost:8080
                    │
                    ▼
          Host TCP/IP Stack
                    │
                    ▼
         iptables (DNAT Rule)
                    │
                    ▼
               docker0 Bridge
                    │
                    ▼
             Host veth Interface
══════════════════════════════════════
                    │
             Container eth0
                    │
                    ▼
              Nginx :80
```

---

# 🔍 Inspect Port Mapping

Run:

```bash
docker ps
```

Example:

```text
0.0.0.0:8080->80/tcp
```

Meaning:

```text
Host

8080

↓

Container

80
```

---

# 🧠 Docker Networking Internals

Docker creates:

* Bridge network
* veth pair
* Container IP
* Routing entries
* iptables NAT rules

The application itself is unaware of these networking components.

---

# 🚫 Common Mistakes

## ❌ Thinking `-p` Changes the Application Port

Example:

```bash
docker run -p 8080:80 nginx
```

Nginx still listens on:

```text
80
```

not 8080.

---

## ❌ Thinking Containers Automatically Expose Ports

A container can listen on port 80 internally without being reachable from the host.

Publishing with `-p` is what makes it accessible.

---

## ❌ Confusing `EXPOSE` With `-p`

Dockerfile:

```dockerfile
EXPOSE 8080
```

`EXPOSE` documents the intended listening port.

It does **not** publish the port.

Only:

```bash
docker run -p
```

creates host-to-container forwarding.

---

# 🐳 Docker Internal View

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
Host veth
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

---

# ☸️ Kubernetes Perspective

Kubernetes uses similar Linux networking concepts.

For example, a **NodePort Service** works similarly:

```text
Browser

↓

NodeIP:30080

↓

kube-proxy / Service Rules

↓

Pod IP:8080

↓

Spring Boot
```

Both Docker Port Mapping and Kubernetes NodePort rely on packet forwarding and NAT, although Kubernetes uses its own networking components.

---

# 🧪 Hands-on Lab

## Publish a Port

```bash
docker run -d \
-p 8080:80 \
nginx
```

Verify:

```bash
docker ps
```

---

## Test Connectivity

```bash
curl http://localhost:8080
```

Observe that the request reaches the Nginx container.

---

## Inspect Port Mapping

```bash
docker port <container-id>
```

Example:

```text
80/tcp -> 0.0.0.0:8080
```

---

## Inspect iptables Rules

On Linux:

```bash
sudo iptables -t nat -L -n
```

Look for Docker-created DNAT rules.

---

## Observe Listening Ports

```bash
sudo ss -ltnp
```

Observe the published host port.

---

## Compare Internal and External Access

Inside the container:

```bash
docker exec -it <container-id> bash

curl http://localhost:80
```

Outside the container:

```bash
curl http://localhost:8080
```

Notice that the application itself continues to use port 80 internally.

---

# 📈 Complete Request Flow

```text
Browser
    │
    ▼
localhost:8080
    │
    ▼
TCP Socket
    │
    ▼
Host Network Stack
    │
    ▼
iptables (DNAT)
    │
    ▼
docker0 Bridge
    │
    ▼
Host veth
════════════════════
    │
Container eth0
    │
    ▼
Tomcat
    │
    ▼
Spring Boot Controller
```

This is the complete path of an HTTP request from the browser to a Docker container.

---

# 📊 Port Mapping Components

| Component            | Responsibility                                         |
| -------------------- | ------------------------------------------------------ |
| 🌐 Host Port         | Port exposed on the Docker host                        |
| 📦 Container Port    | Port where the application listens                     |
| 🔀 iptables DNAT     | Rewrites destination address and port                  |
| 🌉 docker0           | Forwards Ethernet frames to the correct container      |
| 🔌 veth Pair         | Connects the host namespace to the container namespace |
| 🌐 Network Namespace | Provides the container's isolated network stack        |

---

# 💡 Key Takeaways

✅ Port mapping publishes a container service on a host port using `docker run -p`.

✅ The application continues listening on the container port; Docker does not modify the application's configuration.

✅ Docker configures **iptables DNAT** rules to translate traffic from the host port to the container's IP address and port.

✅ Packets travel through the host networking stack, Docker bridge, veth pair, and the container's network namespace before reaching the application.

✅ A container can listen on ports without being reachable from outside unless those ports are explicitly published.

✅ `EXPOSE` documents a port in the image, while `-p` actually makes it accessible from the host.

✅ Understanding port mapping is essential before learning Docker Compose networking, reverse proxies, Kubernetes Services, and Ingress.

---

# ➡️ Next Chapter

📘 **`09-Docker/10-Volumes.md`**

In the next chapter, we'll explore **Docker Volumes**.

We'll answer questions such as:

* 💾 Why is container storage ephemeral?
* 📂 What happens to the writable layer when a container is removed?
* 🗄️ How do Docker volumes persist data?
* 🔗 What is the difference between bind mounts and named volumes?
* 🐘 How does PostgreSQL safely store its database files?

By the end of the chapter, you'll understand how Docker separates application lifecycle from data lifecycle using persistent storage.
