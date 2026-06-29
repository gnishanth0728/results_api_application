# 📘 Chapter 36 — Tomcat NIO Connector

> 📂 File: `student-results-api-notes/05-Tomcat/02-NIO-Connector.md`

This chapter is where your handbook starts connecting Linux networking with Tomcat internals.

It answers one of the most important questions in Spring Boot:

After Linux wakes the Java process because data arrived on port 8080, how does Tomcat know which socket is ready without creating one thread per connection?

The answer is the Tomcat NIO Connector.

This chapter builds directly on your earlier chapters about:

Linux epoll
TCP sockets
File descriptors
Network stack
JVM threads

and shows how Tomcat uses Java NIO to efficiently process thousands of concurrent HTTP connections.

---

# 🌍 Introduction

In the previous chapter we learned that Tomcat sits between the Linux kernel and Spring Boot.

```text
Browser
    │
    ▼
Linux TCP Stack
    │
    ▼
Tomcat
    │
    ▼
Spring Boot
```

Now another question appears:

> 🤔 **How can Tomcat handle 10,000 TCP connections using only a small number of threads?**

Imagine your Student Results API receives:

```text
10 Users

↓

100 Users

↓

500 Users

↓

5,000 Users

↓

20,000 Users
```

Creating one thread per connection would consume enormous amounts of memory and CPU.

Instead, Tomcat uses **Java NIO (Non-Blocking I/O)** together with the Linux **epoll** mechanism.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🌐 What the NIO Connector is
* 🔌 Connector architecture
* 📡 Acceptor thread
* ⚡ Poller thread
* 🧵 Worker thread pool
* 📁 Java NIO Channels
* 📂 Selectors
* ⚙️ epoll integration
* 📦 Request lifecycle
* 🍃 Spring Boot integration
* 🐳 Docker
* ☸️ Kubernetes
* 🧪 Debugging tools

---

# ❓ Why Does Tomcat Need NIO?

Suppose every client required one dedicated thread.

```text
10,000 Clients

↓

10,000 Threads
```

Problems:

* ❌ Huge memory usage
* ❌ Frequent context switching
* ❌ Poor scalability
* ❌ CPU overhead

Instead, Tomcat uses:

```text
10,000 TCP Connections

↓

1 Poller Thread

↓

200 Worker Threads
```

This is dramatically more efficient.

---

# 🏗️ High-Level NIO Connector Architecture

```text
                    Browser
                       │
                       ▼
                  TCP Connection
                       │
                       ▼
              Linux TCP Socket
                       │
                       ▼
+------------------------------------------------------+
|              Tomcat NIO Connector                    |
|------------------------------------------------------|
| 🔌 ServerSocketChannel                               |
|------------------------------------------------------|
| 🧵 Acceptor Thread                                   |
|------------------------------------------------------|
| ⚡ Poller Thread                                     |
|     Java Selector                                    |
|     Linux epoll                                      |
|------------------------------------------------------|
| 👷 Worker Thread Pool                                |
|------------------------------------------------------|
| 📦 Http11Processor                                   |
|------------------------------------------------------|
| 🚀 DispatcherServlet                                 |
+------------------------------------------------------+
```

This is the heart of Tomcat's networking model.

---

# 🌐 ServerSocketChannel

Instead of using the classic blocking `ServerSocket`, Tomcat opens a **ServerSocketChannel**.

```text
bind(8080)

↓

listen()

↓

ServerSocketChannel
```

The channel is configured in **non-blocking mode**.

This allows Tomcat to continue processing other events without waiting for a single client.

---

# 🧵 Acceptor Thread

The Acceptor thread waits for new TCP connections.

Conceptually:

```text
while (true) {

    accept()

}
```

Flow:

```text
Browser

↓

TCP SYN

↓

Linux Accept Queue

↓

accept()

↓

SocketChannel

↓

Poller
```

Responsibilities:

* Accept new connections
* Create `SocketChannel`
* Register the channel with the Poller

It **does not** process HTTP requests.

---

# ⚡ Poller Thread

The Poller is the most important component of the NIO Connector.

Responsibilities:

* Monitor thousands of sockets
* Detect readable sockets
* Detect writable sockets
* Dispatch work to worker threads

Flow:

```text
SocketChannel

↓

Selector.select()

↓

Ready Socket

↓

Worker Thread
```

The Poller blocks efficiently until Linux reports that one or more sockets are ready.

---

# 📂 Java Selector

Java NIO provides the `Selector` API.

```text
Socket 1

Socket 2

Socket 3

...

Socket 10000

↓

Selector
```

Instead of checking every socket repeatedly, the selector waits for readiness notifications.

Internally on Linux, the selector uses **epoll**.

---

# ⚙️ Linux epoll Integration

Under the hood:

```text
Tomcat Poller

↓

Java Selector

↓

epoll_wait()

↓

Linux Kernel

↓

Ready Socket Events
```

This allows one Poller thread to efficiently monitor thousands of connections.

---

# 👷 Worker Thread Pool

When a socket becomes readable:

```text
Poller

↓

Executor

↓

http-nio-8080-exec-17
```

A worker thread:

* Reads HTTP bytes
* Parses the request
* Invokes Spring Boot
* Writes the response

After completion, the thread returns to the pool.

---

# 📦 Http11Processor

Each worker thread creates (or reuses) an `Http11Processor`.

Responsibilities:

```text
Read Bytes

↓

Parse HTTP

↓

Create Request

↓

Create Response

↓

Invoke Servlet
```

It transforms raw TCP data into Java HTTP objects.

---

# 🍃 Spring Boot Integration

After parsing:

```text
Http11Processor

↓

HttpServletRequest

↓

DispatcherServlet

↓

StudentController

↓

StudentService

↓

StudentRepository
```

Spring Boot never reads sockets directly.

Tomcat handles all network communication.

---

# 🌐 Complete Connection Lifecycle

Suppose a browser sends:

```http
GET /students/1051110244 HTTP/1.1
Host: localhost:8080
```

Complete flow:

```text
Browser

↓

TCP SYN

↓

Linux Kernel

↓

ServerSocketChannel

↓

Acceptor Thread

↓

SocketChannel

↓

Poller Thread

↓

epoll_wait()

↓

Socket Ready

↓

Worker Thread

↓

Http11Processor

↓

DispatcherServlet

↓

StudentController

↓

StudentService

↓

Repository

↓

JSON

↓

SocketChannel

↓

Browser
```

---

# 🔄 Keep-Alive Connections

HTTP/1.1 enables persistent connections.

Instead of:

```text
Request

↓

Close Socket
```

Tomcat usually performs:

```text
Request 1

↓

Response

↓

Keep Socket Open

↓

Request 2

↓

Response

↓

Request 3
```

This avoids the cost of repeatedly creating TCP connections.

---

# 📊 Your Load Test

You executed:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Tomcat behavior:

```text
200 TCP Connections

↓

Acceptor

↓

Poller

↓

Worker Pool

↓

Requests Processed

↓

Threads Reused
```

Notice that Tomcat **did not create 50,000 threads**.

It reused a fixed pool of worker threads.

---

# 🐳 Docker Perspective

Inside Docker:

```text
Container

↓

Java Process

↓

Tomcat

↓

Java Selector

↓

epoll

↓

Linux Kernel
```

The NIO Connector behaves exactly the same as on a physical Linux host.

---

# ☸️ Kubernetes Perspective

Inside Kubernetes:

```text
Client

↓

Service

↓

Pod

↓

Container

↓

Tomcat NIO Connector

↓

Spring Boot
```

Kubernetes routes traffic to the Pod, but once the TCP connection reaches the container, Tomcat's NIO Connector handles it exactly as it would on any Linux system.

---

# 🧪 Hands-on Lab

## Verify Listening Port

```bash
ss -ltnp | grep 8080
```

Observe the Java process listening on port `8080`.

---

## Observe Tomcat Threads

```bash
jstack <PID>
```

Look for:

```text
http-nio-8080-Acceptor

http-nio-8080-Poller

http-nio-8080-exec-1
```

---

## Monitor Linux Threads

```bash
top -H -p <PID>
```

Watch worker threads become active during load.

---

## Generate Concurrent Requests

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Observe that the number of worker threads remains relatively stable while thousands of requests are processed.

---

## Observe TCP Connections

```bash
watch -n1 "ss -tan | grep :8080"
```

Watch TCP connections transition through states such as `ESTAB` and `TIME-WAIT`.

---

## View File Descriptors

```bash
ls -l /proc/<PID>/fd
```

Notice many socket file descriptors corresponding to active client connections.

---

# 📈 Complete NIO Connector Flow

```text
Browser
      │
      ▼
TCP SYN
      │
      ▼
Linux TCP Stack
      │
      ▼
ServerSocketChannel
      │
      ▼
Acceptor Thread
      │
      ▼
SocketChannel
      │
      ▼
Poller Thread
      │
      ▼
Java Selector
      │
      ▼
Linux epoll_wait()
      │
      ▼
Ready Socket
      │
      ▼
Worker Thread
      │
      ▼
Http11Processor
      │
      ▼
DispatcherServlet
      │
      ▼
StudentController
      │
      ▼
StudentService
      │
      ▼
StudentRepository
      │
      ▼
JSON Response
      │
      ▼
SocketChannel
      │
      ▼
Browser
```

This is the complete networking pipeline inside Tomcat.

---

# 💡 Key Takeaways

✅ Tomcat's NIO Connector uses non-blocking I/O to handle thousands of concurrent TCP connections efficiently.

✅ The Acceptor thread accepts new TCP connections but does not process HTTP requests.

✅ The Poller thread uses Java NIO `Selector`, which relies on Linux `epoll` to detect socket readiness.

✅ Worker threads process HTTP requests by parsing bytes, invoking Spring Boot, and writing responses.

✅ HTTP keep-alive allows multiple requests to reuse the same TCP connection, reducing connection overhead.

✅ Docker and Kubernetes do not change the NIO Connector architecture; they simply provide the runtime environment.

---

# ➡️ Next Chapter

📘 **`05-Tomcat/03-Acceptor-Poller-Worker.md`**

In the next chapter, we'll dive even deeper into the three most important Tomcat threads:

* 🧵 Acceptor Thread
* ⚡ Poller Thread
* 👷 Worker Thread

We'll trace one HTTP request step by step and show exactly how these threads cooperate—from `accept()` in the Linux kernel to the execution of your `StudentController` and the return of the JSON response.
