# 📘 Chapter 13 — Ports

> 📂 File: `student-results-api-notes/02-Network/08-Port.md`

---

# 🌍 Introduction

When your Student Results API starts, one of the first log messages is:

```text
Tomcat started on port(s): 8080 (http)
```

Most developers immediately think:

> "Tomcat owns port 8080."

That is a simplified explanation.

The actual sequence is:

```text
Spring Boot

↓

Embedded Tomcat

↓

socket()

↓

bind(0.0.0.0:8080)

↓

Linux Kernel

↓

Port 8080 Reserved

↓

LISTEN Socket Created
```

Notice that **the Linux kernel owns the port**.

Tomcat simply requests Linux to reserve it.

---

# 🎯 Learning Objectives

After this chapter you will understand:

* 🚪 What a port really is
* 🔢 Why ports exist
* 🌍 Well-known, registered, and ephemeral ports
* 🔌 Relationship between ports and sockets
* 🧠 Linux port management
* ☕ Tomcat and port 8080
* 🐳 Docker port publishing
* ☸️ Kubernetes Services and NodePorts
* 🧪 Linux tools for investigating ports

---

# ❓ Why Do Ports Exist?

Imagine one computer running:

* 🌐 Nginx
* ☕ Spring Boot
* 🐘 PostgreSQL
* 🔐 SSH Server
* 📦 Redis

All of them use the **same network interface** and the **same IP address**.

Example:

```text
EC2 Instance

IP Address

50.17.121.255
```

If a packet arrives:

```text
Destination IP = 50.17.121.255
```

Linux still doesn't know:

> "Which application should receive this packet?"

Ports solve this problem.

---

# 🏗️ IP vs Port

An IP address identifies a **machine**.

A port identifies an **application endpoint** on that machine.

```text
Internet

↓

50.17.121.255

↓

Port 8080

↓

Java Process

↓

Tomcat

↓

Spring Boot
```

Think of it like a large office building:

```text
IP Address

↓

Office Building

↓

Port Number

↓

Room Number

↓

Application
```

The building tells you where to go.

The room tells you who to meet.

---

# 📊 Port Number Range

TCP and UDP ports are 16-bit integers.

```text
0

↓

65535
```

Total possible ports:

```text
65,536
```

---

# 📂 Port Categories

## 1️⃣ Well-Known Ports (0–1023)

Reserved for common protocols.

| Port | Service     |
| ---: | ----------- |
|   20 | FTP Data    |
|   21 | FTP Control |
|   22 | SSH         |
|   25 | SMTP        |
|   53 | DNS         |
|   80 | HTTP        |
|  110 | POP3        |
|  143 | IMAP        |
|  443 | HTTPS       |

Most require elevated privileges to bind on Unix-like systems.

---

## 2️⃣ Registered Ports (1024–49151)

Typically used by user applications.

Examples:

| Port | Application          |
| ---: | -------------------- |
| 1521 | Oracle               |
| 3306 | MySQL                |
| 5432 | PostgreSQL           |
| 5672 | RabbitMQ             |
| 6379 | Redis                |
| 8080 | Tomcat / Spring Boot |
| 9092 | Kafka                |

Your Student Results API uses:

```text
8080
```

---

## 3️⃣ Ephemeral Ports (49152–65535)

These are temporary client ports.

Example:

```text
Browser

54122

↓

Server

8080
```

The browser automatically receives an ephemeral port from the operating system.

---

# 🔄 One HTTP Request

Example connection:

```text
Client

192.168.1.25:54122

↓

Server

50.17.121.255:8080
```

Notice:

| Component   | Value |
| ----------- | ----- |
| Client Port | 54122 |
| Server Port | 8080  |

The client port changes for each connection.

The server port remains constant.

---

# 🔌 Ports vs Sockets

This is one of the most misunderstood concepts.

## Port

A logical communication number.

Example:

```text
8080
```

A port by itself cannot send or receive data.

---

## Socket

A socket is an actual communication endpoint.

Example:

```text
192.168.1.25:54122

↓

50.17.121.255:8080
```

Sockets use ports.

Ports do not use sockets.

---

# 🧠 Linux Port Table

Internally, the Linux kernel maintains data structures that associate listening ports with sockets.

Conceptually:

```text
Port Table

+---------+--------------------+
| Port    | Socket             |
+---------+--------------------+
| 22      | SSH                |
| 5432    | PostgreSQL         |
| 8080    | Java LISTEN Socket |
+---------+--------------------+
```

When a packet arrives:

```text
Destination Port = 8080
```

Linux looks up:

```text
8080

↓

Listening Socket

↓

Java Process

↓

Tomcat
```

This lookup happens entirely inside the kernel.

---

# 🍃 Tomcat and Port 8080

Tomcat requests Linux to listen on port 8080.

Conceptually:

```c
socket()

↓

bind(...8080)

↓

listen()
```

After this:

```bash
ss -ltnp
```

may show:

```text
LISTEN 0 100 *:8080 users:(("java",pid=7065))
```

Meaning:

* Port 8080 is reserved.
* A listening socket exists.
* The socket belongs to the Java process.

---

# 🚫 What Happens if Another Process Uses 8080?

Suppose another application already owns port 8080.

Linux refuses the request.

Spring Boot fails to start.

Typical error:

```text
Port 8080 was already in use.
```

The second application cannot bind to the same IP/port combination.

---

# 🔄 One Port, Thousands of Connections

A single listening port can serve many clients simultaneously.

```text
              Port 8080

                   │

      Listening Socket

      │      │      │

      ▼      ▼      ▼

 Socket1 Socket2 Socket3

      ▼      ▼      ▼

 Thread1 Thread2 Thread3
```

The listening port stays constant.

Each client receives its own connected socket.

---

# 📦 TCP 4-Tuple

Linux identifies each connection using:

```text
Source IP

+

Source Port

+

Destination IP

+

Destination Port
```

Example:

```text
192.168.1.25

54122

↓

50.17.121.255

8080
```

Because the client port changes, thousands of users can communicate with the same server port simultaneously.

---

# 🐳 Docker Port Publishing

Suppose your Spring Boot application runs inside a container.

```bash
docker run -p 8080:8080 student-api
```

Flow:

```text
Browser

↓

Host Port 8080

↓

Docker NAT

↓

Container Port 8080

↓

Tomcat
```

Docker forwards traffic from the host port to the container port.

---

# ☸️ Kubernetes Ports

Kubernetes introduces additional networking layers.

```text
Browser

↓

NodePort (30080)

↓

Service (8080)

↓

Pod (8080)

↓

Tomcat
```

Or with an Ingress:

```text
Browser

↓

Ingress

↓

Service

↓

Pod

↓

Tomcat
```

The application still listens on the same container port.

Kubernetes simply routes traffic to it.

---

# 🧪 Hands-on Lab

## View Listening Ports

```bash
ss -ltn
```

---

## View Listening Ports with Process Information

```bash
sudo ss -ltnp
```

---

## Find Which Process Uses Port 8080

```bash
sudo lsof -i :8080
```

or

```bash
sudo fuser 8080/tcp
```

---

## Monitor Connections

```bash
watch -n1 "ss -tan | grep :8080"
```

Generate traffic:

```bash
ab -n 10000 -c 100 http://localhost:8080/students/1051110244
```

Observe many connections entering the `ESTABLISHED` state while the listening socket remains on port 8080.

---

# 🔍 Relationship Summary

```text
Application
      │
      ▼
Socket
      │
      ▼
Port
      │
      ▼
TCP
      │
      ▼
IP
      │
      ▼
Network Interface
```

Each layer has a distinct responsibility.

---

# 💡 Key Takeaways

✅ An IP address identifies a machine.

✅ A port identifies an application endpoint on that machine.

✅ The Linux kernel manages ports, not Tomcat.

✅ Tomcat creates a listening socket bound to port 8080.

✅ One listening port can serve thousands of simultaneous client connections.

✅ Each client receives a unique connected socket identified by the TCP 4-tuple.

✅ Docker and Kubernetes route traffic to ports but do not change how TCP ports fundamentally work.

---

# 🎉 Networking Section Status

You now understand:

* ✅ OSI Model
* ✅ TCP/IP
* ✅ TCP Three-Way Handshake
* ✅ HTTP Requests
* ✅ DNS
* ✅ IP Routing
* ✅ Linux Sockets
* ✅ Ports

These concepts form the complete networking foundation required to understand how a request reaches your Spring Boot application.

---

# ➡️ Next Chapter

📘 **02-Network/09-Network-Packet-Journey.md**

In the next chapter we'll combine everything you've learned and follow **one single packet** from:

```text
React Button Click

↓

Axios

↓

Browser

↓

DNS

↓

TCP Handshake

↓

HTTP Request

↓

Linux Kernel

↓

Socket

↓

Tomcat

↓

Spring Boot

↓

PostgreSQL

↓

JSON Response

↓

Browser Rendering
```

We'll inspect every transformation, every kernel boundary, every protocol header, and every software component involved in the complete end-to-end journey of a single request.
