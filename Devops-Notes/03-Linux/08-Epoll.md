# 📘 Chapter 23 — Linux epoll

This is one of the most important advanced Linux networking chapters because it explains why Tomcat, Nginx, Netty, Redis, HAProxy, Envoy, and many high-performance servers can handle tens of thousands of concurrent connections without creating one thread per socket.

It also connects directly to the load tests you performed with ab.

The central question is:

How can one thread monitor 10,000 sockets without constantly checking each one?

The answer is epoll.

> 📂 File: `student-results-api-notes/03-Linux/08-Epoll.md`

---

# 🌍 Introduction

Earlier we learned:

* 🔌 Every browser connection creates a socket.
* 📄 Every socket has a file descriptor.
* 🍃 Tomcat receives HTTP requests from sockets.

Suppose your Student Results API receives:

```text
10,000 simultaneous users
```

Each user owns:

```text
1 Socket
```

That means Linux now manages:

```text
10,000 sockets
```

Now ask yourself:

> 🤔 How does Tomcat know which socket has received data?

Does it continuously check:

```text
Socket 1 ?

Socket 2 ?

Socket 3 ?

...

Socket 10,000 ?
```

That would waste enormous CPU time.

Linux solves this problem using one of its most important scalability features:

# ⚡ epoll

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* ⚡ What epoll is
* ❓ Why epoll exists
* 📄 File descriptor monitoring
* 📥 Event-driven programming
* 🔄 select()
* 🔄 poll()
* ⚡ epoll_wait()
* 🧠 Kernel event notifications
* 🍃 Tomcat NIO connector
* 🐳 Docker networking
* ☸️ Kubernetes networking
* 🧪 Linux debugging

---

# ❓ The Problem

Imagine:

```text
10,000 Client Connections
```

Every client owns:

```text
1 Socket
```

Without epoll:

```text
Thread

↓

Socket 1 ?

↓

Socket 2 ?

↓

Socket 3 ?

↓

...

↓

Socket 10,000 ?
```

This continuous scanning wastes CPU even when almost every socket is idle.

---

# 🏗️ Old Solution — select()

Older Unix systems used:

```c
select()
```

Flow:

```text
Application

↓

Pass Every FD

↓

Kernel

↓

Check Every FD

↓

Return Ready FDs
```

Problem:

Every call scans the entire descriptor set.

Complexity:

```text
O(n)
```

where `n` is the number of monitored file descriptors.

---

# 🏗️ Next Solution — poll()

`poll()` removes the descriptor-count limitation of `select()`, but still scans every descriptor.

```text
poll()

↓

Scan

↓

Scan

↓

Scan
```

Large servers still spend significant CPU time checking idle sockets.

---

# ⚡ Linux Solution — epoll

Linux introduced:

```c
epoll_create()

epoll_ctl()

epoll_wait()
```

Instead of asking:

> "Which sockets are ready?"

the application tells Linux:

> "Notify me only when something interesting happens."

---

# 🧠 epoll Architecture

```text
                USER SPACE

Tomcat

↓

epoll_wait()

=====================================

              KERNEL SPACE

epoll Instance

↓

Socket Table

↓

Ready List

↓

TCP Stack
```

The kernel maintains the state of monitored sockets.

Applications only wake when events occur.

---

# 📌 Step 1 — Create epoll Instance

Conceptually:

```c
epoll_create()
```

Linux creates an internal event manager.

```text
Tomcat

↓

epoll Instance
```

---

# 📌 Step 2 — Register Sockets

Tomcat tells Linux:

```text
Watch

Socket 1

Socket 2

Socket 3

...

Socket 10,000
```

Conceptually:

```c
epoll_ctl()
```

The kernel records interest in those sockets.

---

# 📌 Step 3 — Sleep

Tomcat simply waits.

```c
epoll_wait()
```

The worker thread sleeps.

CPU usage becomes:

```text
≈ 0%
```

No busy polling occurs.

---

# 📌 Step 4 — Packet Arrives

Suppose:

```text
Browser

↓

HTTP Request

↓

Socket #3521
```

The Linux TCP stack receives data.

Instead of waking every thread:

```text
Kernel

↓

Marks Socket Ready

↓

Adds Socket #3521

↓

Ready Queue
```

---

# 📌 Step 5 — Wake Application

Now:

```text
epoll_wait()

↓

Returns

↓

Socket #3521 Ready
```

Tomcat immediately processes that socket.

No unnecessary scanning occurs.

---

# 🔄 Complete epoll Flow

```text
Browser

↓

TCP Packet

↓

NIC

↓

Linux TCP Stack

↓

Socket Buffer

↓

epoll Ready List

↓

epoll_wait()

↓

Tomcat

↓

Spring Boot

↓

JSON Response
```

This event-driven approach is the foundation of high-performance network servers.

---

# 🍃 Tomcat NIO Connector

Modern Spring Boot uses Tomcat's **NIO connector** by default.

Architecture:

```text
Acceptor Thread

↓

Poller Thread (epoll)

↓

Worker Thread Pool

↓

DispatcherServlet

↓

Controller

↓

Service
```

### Acceptor Thread

Accepts new TCP connections.

### Poller Thread

Waits on `epoll_wait()`.

### Worker Thread

Processes HTTP requests after a socket becomes readable.

---

# 📊 Your ApacheBench Example

You executed:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Observed:

```text
CPU

≈ 2%
```

Why?

Because:

* Most sockets were idle.
* Poller threads slept inside `epoll_wait()`.
* Only sockets with data woke worker threads.
* Threads waiting on PostgreSQL yielded the CPU.

This efficient event notification is one reason modern web servers scale well.

---

# ⚖️ select() vs poll() vs epoll()

| Feature                 | select() | poll()   | epoll()   |
| ----------------------- | -------- | -------- | --------- |
| Descriptor Limit        | Yes      | No       | No        |
| Scans All FDs           | ✅        | ✅        | ❌         |
| Ready Queue             | ❌        | ❌        | ✅         |
| Event Driven            | ❌        | ❌        | ✅         |
| Large Scale Performance | Poor     | Moderate | Excellent |
| Linux Optimized         | No       | No       | Yes       |

---

# 📦 Ready Queue

Instead of scanning every socket:

```text
10,000 Sockets

↓

Ready Queue

↓

Socket 51

Socket 223

Socket 9876
```

Only ready sockets are returned.

This dramatically reduces CPU work.

---

# 🔌 epoll and File Descriptors

Remember:

```text
Socket

↓

File Descriptor
```

epoll does **not** monitor sockets directly.

It monitors **file descriptors**.

That means epoll can monitor:

* TCP sockets
* UDP sockets
* Pipes
* EventFDs
* TimerFDs
* UNIX sockets

Anything represented by a file descriptor can participate in the epoll event model.

---

# 🐳 Docker Perspective

Containers do not implement epoll.

```text
Container

↓

Java Process

↓

epoll()

↓

Host Linux Kernel
```

The host Linux kernel provides epoll services to processes inside containers.

---

# ☸️ Kubernetes Perspective

Inside Kubernetes:

```text
Pod

↓

Container

↓

Tomcat

↓

epoll

↓

Linux Kernel
```

Every Pod ultimately relies on the node's Linux kernel to provide epoll.

---

# 🧪 Hands-on Lab

## Verify Tomcat NIO Connector

Start the application:

```bash
java -jar student-results-api.jar
```

Observe startup logs:

```text
Tomcat started on port(s): 8080
```

Spring Boot uses the NIO connector by default.

---

## Display Socket Connections

```bash
ss -tan
```

---

## Generate Load

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

---

## Observe Threads

```bash
top -H -p <PID>
```

Notice:

* Poller threads spend most of their time sleeping.
* Worker threads wake only when requests are ready.

---

## Trace epoll System Calls

Attach to the Java process:

```bash
sudo strace -f -e trace=epoll_wait,epoll_ctl,epoll_create1 -p <PID>
```

During incoming traffic you'll observe calls such as:

```text
epoll_wait(...)
epoll_ctl(...)
```

These are the core system calls behind Tomcat's event-driven networking.

---

## Observe Network Activity

```bash
watch -n1 "ss -tan | grep :8080"
```

Combine this with ApacheBench to see many established connections while CPU usage remains relatively low.

---

# 📈 Complete Request Flow

```text
Browser

↓

TCP Packet

↓

NIC

↓

Linux TCP Stack

↓

Socket Buffer

↓

epoll Ready Queue

↓

Poller Thread

↓

Worker Thread

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

---

# 💡 Key Takeaways

✅ epoll is Linux's high-performance event notification mechanism.

✅ It monitors file descriptors—not just sockets.

✅ Applications register interest in events and sleep inside `epoll_wait()`.

✅ The kernel wakes the application only when monitored descriptors become ready.

✅ Tomcat's NIO connector relies on epoll to efficiently manage large numbers of concurrent connections.

✅ Docker containers and Kubernetes Pods use the same host-kernel epoll implementation because they run as ordinary Linux processes.

---

# ➡️ Next Chapter

📘 **`03-Linux/09-System-Calls.md`**

Next we'll study the boundary between **user space** and **kernel space**.

We'll explore:

* 📞 What a system call is
* 🔄 CPU privilege transitions
* ⚙️ `open()`, `read()`, `write()`, `socket()`, `accept()`, `epoll_wait()`, `fork()`, `execve()`
* 🧠 How the JVM invokes Linux kernel services
* 🧪 Observing real system calls with `strace`

By the end of the next chapter, you'll be able to trace every important interaction between your Student Results API and the Linux kernel, from opening a JAR file to waiting for network events with `epoll`.
