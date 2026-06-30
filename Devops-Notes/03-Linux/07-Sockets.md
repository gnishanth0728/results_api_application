# 📘 Chapter 22 — Linux Sockets (Kernel Perspective)

Perfect. This chapter is where readers realize that a socket is not just a networking concept—it is also a Linux kernel object and a file descriptor.

Earlier, in the Networking section, you learned what sockets are. Now, in the Linux section, you'll study how the kernel implements sockets, how Tomcat interacts with them, and how a browser request becomes bytes inside your Java process.

This chapter ties together:

Linux Kernel
File Descriptors
TCP
System Calls
Tomcat
Spring Boot
Docker
Kubernetes

into one complete picture.

> 📂 File: `student-results-api-notes/03-Linux/07-Sockets.md`

---

# 🌍 Introduction

Earlier in the **Networking** section, we learned:

```text
Browser
   │
   ▼
TCP
   │
   ▼
Socket
   │
   ▼
Tomcat
```

Now we're going one layer deeper.

Instead of asking:

> **"What is a socket?"**

we'll ask:

> **"How does Linux implement sockets internally?"**

When a browser sends:

```http
GET /students/1051110244 HTTP/1.1
Host: localhost:8080
```

those bytes travel through the Linux kernel before Tomcat ever sees them.

Understanding sockets at the kernel level explains how Spring Boot, Docker, PostgreSQL, Nginx, and Kubernetes all communicate over the network.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🔌 Linux socket internals
* 🧠 Kernel socket structures
* 📄 Socket file descriptors
* 📦 Send and receive buffers
* 📞 `socket()`
* 📌 `bind()`
* 👂 `listen()`
* 🤝 `accept()`
* 📨 `recv()`
* 📤 `send()`
* 🍃 Tomcat socket handling
* 🐳 Docker networking
* ☸️ Kubernetes networking
* 🧪 Socket debugging tools

---

# ❓ What Is a Linux Socket?

A socket is a **kernel-managed communication endpoint**.

Applications never communicate directly with the network card.

Instead:

```text
Application
      │
      ▼
File Descriptor
      │
      ▼
Linux Socket
      │
      ▼
TCP/IP Stack
      │
      ▼
NIC
      │
      ▼
Network
```

The socket is the bridge between user-space applications and the kernel networking stack.

---

# 🏗️ Socket Architecture

```text
                 USER SPACE
+-------------------------------------------+

🌐 Browser

↓

☕ JVM

↓

🍃 Tomcat

↓

Java Socket API

============================================
           System Call Boundary
============================================

                KERNEL SPACE

+-------------------------------------------+

🔌 Socket Object

↓

📥 Receive Queue

↓

📤 Send Queue

↓

🚚 TCP Layer

↓

🗺️ IP Layer

↓

🌐 Ethernet Layer

↓

📡 NIC Driver

↓

Network Card

+-------------------------------------------+
```

---

# 📞 Creating a Socket

Every server begins by creating a socket.

Conceptually:

```c
socket(AF_INET, SOCK_STREAM, 0);
```

Linux allocates:

* Socket object
* Receive queue
* Send queue
* TCP control structures

The socket initially exists in the **CLOSED** state.

---

# 📌 Binding the Socket

Tomcat then requests:

```c
bind(socket, 0.0.0.0:8080);
```

Linux associates:

```text
Port 8080
      │
      ▼
Listening Socket
      │
      ▼
Java Process
```

At this point, the application is reachable through TCP port **8080**.

---

# 👂 Listening for Connections

Next Tomcat calls:

```c
listen(socket);
```

The socket state changes:

```text
CLOSED
   │
   ▼
LISTEN
```

Linux creates internal queues:

```text
SYN Queue
      │
      ▼
Accept Queue
```

These queues store incoming connection requests until the application accepts them.

---

# 🤝 Accepting Connections

When the TCP three-way handshake completes:

```text
Browser
     │
     ▼
TCP Handshake
     │
     ▼
accept()
```

Linux creates a **new connected socket**.

Important distinction:

```text
Listening Socket

↓

Accept()

↓

Connected Socket #1

Connected Socket #2

Connected Socket #3
```

The listening socket remains available for new clients.

Each client receives a dedicated connected socket.

---

# 📥 Receive Queue

Every connected socket contains a receive queue.

```text
Browser

↓

TCP Packets

↓

Receive Queue

↓

Tomcat
```

Incoming bytes wait here until Tomcat reads them.

If Tomcat is busy, the kernel buffers the data.

---

# 📤 Send Queue

Responses follow the reverse path.

```text
Spring Boot

↓

Tomcat

↓

Send Queue

↓

TCP

↓

Browser
```

The kernel transmits bytes asynchronously while the application continues processing.

---

# 📄 Socket File Descriptor

Remember the previous chapter:

```bash
ls -l /proc/<PID>/fd
```

Example:

```text
3 -> socket:[38492]
```

The Java application only knows:

```text
FD = 3
```

The Linux kernel knows:

```text
FD 3
   │
   ▼
Socket Object
   │
   ▼
TCP Connection
```

This abstraction allows sockets to be used with the same `read()` and `write()` interfaces as regular files.

---

# 🍃 Student Results API Example

A browser requests:

```http
GET /students/1051110244
```

The complete flow is:

```text
Browser

↓

TCP Connection

↓

Listening Socket (8080)

↓

Connected Socket

↓

FD 8

↓

Tomcat

↓

DispatcherServlet

↓

StudentController

↓

StudentService

↓

Repository

↓

PostgreSQL

↓

JSON Response
```

Every HTTP request begins with a connected socket.

---

# 🧵 One Socket per Client

Suppose 200 users access the API.

Linux creates:

```text
Listening Socket

├── Connected Socket 1

├── Connected Socket 2

├── Connected Socket 3

├── ...

└── Connected Socket 200
```

Each connected socket contains:

* Source IP
* Destination IP
* Source Port
* Destination Port
* Receive Queue
* Send Queue
* TCP State

---

# 🔄 Socket State Machine

TCP sockets move through different states.

```text
CLOSED
   │
   ▼
LISTEN
   │
   ▼
SYN_RECEIVED
   │
   ▼
ESTABLISHED
   │
   ▼
FIN_WAIT
   │
   ▼
TIME_WAIT
   │
   ▼
CLOSED
```

These states are maintained by the Linux kernel.

---

# 🐳 Docker Perspective

Containers do not implement their own sockets.

```text
Browser

↓

Host Linux Kernel

↓

Network Namespace

↓

Socket

↓

Java Process
```

Each container has its own socket table because it has its own network namespace, but the host kernel still manages all socket objects.

---

# ☸️ Kubernetes Perspective

A Kubernetes Pod follows the same model.

```text
Browser

↓

Ingress

↓

Service

↓

Pod Network Namespace

↓

Socket

↓

Tomcat

↓

Spring Boot
```

Whether running on bare Linux, Docker, or Kubernetes, the application ultimately communicates through Linux sockets.

---

# 🧪 Hands-on Lab

## Display Listening Sockets

```bash
ss -ltnp
```

Look for:

```text
LISTEN 0 100 *:8080 users:(("java",pid=7065))
```

---

## Display Established Connections

```bash
ss -tan
```

Observe states such as:

* ESTABLISHED
* TIME-WAIT
* CLOSE-WAIT

---

## Display Open Socket File Descriptors

```bash
ls -l /proc/<PID>/fd
```

Example:

```text
socket:[38492]
socket:[38501]
```

---

## List TCP Sockets

```bash
lsof -p <PID> | grep TCP
```

---

## Capture Live Traffic

```bash
sudo tcpdump -i any port 8080
```

Watch HTTP packets arrive while generating requests.

---

## Generate Load

```bash
ab -n 10000 -c 100 \
http://localhost:8080/students/1051110244
```

In another terminal:

```bash
watch -n1 "ss -tan | grep :8080"
```

Observe dozens of simultaneous connected sockets.

---

# 📈 Complete Socket Lifecycle

```text
socket()
     │
     ▼
bind()
     │
     ▼
listen()
     │
     ▼
TCP Handshake
     │
     ▼
accept()
     │
     ▼
Connected Socket
     │
     ▼
read()/recv()
     │
     ▼
Tomcat
     │
     ▼
Spring Boot
     │
     ▼
write()/send()
     │
     ▼
close()
```

Every TCP server—including Tomcat, Nginx, PostgreSQL, Redis, and SSH—follows this lifecycle.

---

# 💡 Key Takeaways

✅ A Linux socket is a kernel-managed communication endpoint.

✅ Applications access sockets through file descriptors.

✅ `socket()`, `bind()`, `listen()`, and `accept()` create the server-side connection lifecycle.

✅ Every client connection receives its own connected socket.

✅ Each socket has independent send and receive queues.

✅ Tomcat reads HTTP requests from socket file descriptors and writes responses back through them.

✅ Docker and Kubernetes add networking layers, but the underlying communication still relies on Linux sockets managed by the host kernel.

---

# ➡️ Next Chapter

📘 **`03-Linux/08-System-Calls.md`**

In the next chapter we'll cross the boundary between **user space** and **kernel space**.

You'll learn:

* 🔄 CPU user mode vs kernel mode
* 📞 What a system call really is
* ⚙️ `read()`, `write()`, `open()`, `socket()`, `accept()`, `mmap()`, `fork()`, `execve()`
* 🧠 How Java invokes Linux through the JVM and native libraries
* 🧪 Tracing real system calls with `strace`

By the end of the next chapter, you'll be able to observe every interaction between your Spring Boot application and the Linux kernel in real time.
