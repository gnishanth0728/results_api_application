# 📘 Chapter 39 — Tomcat Worker Thread

> 📂 File: `student-results-api-notes/05-Tomcat/05-Worker-Thread.md`

Everything you've learned so far has been preparation for this moment.

Until now:

Browser sent packets
Linux received packets
TCP created sockets
Tomcat accepted connections
Poller detected ready sockets

Now we finally answer:

How does raw HTTP data become a call to StudentController.getStudent()?

This is where the Tomcat Worker Thread (http-nio-8080-exec-*) takes over.

After reading this chapter, the reader should understand every single step from socket bytes to Spring Boot execution.

---

# 🌍 Introduction

In the previous chapter, we learned how the **Poller Thread** waits for socket events using Linux **epoll**.

```text
Browser
    │
    ▼
Linux TCP Stack
    │
    ▼
Socket Ready
    │
    ▼
Poller Thread
```

When the Poller detects that a socket contains HTTP data, it **does not** process the request itself.

Instead, it hands the socket to a **Worker Thread**.

Example thread names:

```text
http-nio-8080-exec-1

http-nio-8080-exec-2

http-nio-8080-exec-3

...

http-nio-8080-exec-200
```

These are the threads that actually execute your Spring Boot application.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 👷 What a Worker Thread is
* 📦 Tomcat Executor
* 📄 Http11Processor
* 📥 HTTP parsing
* 📨 HttpServletRequest
* 📨 HttpServletResponse
* 🍃 DispatcherServlet
* 🧵 Thread reuse
* 🌐 Keep-Alive processing
* 🐳 Docker
* ☸️ Kubernetes
* 🧪 Debugging

---

# ❓ What Is a Worker Thread?

A Worker Thread is a thread from Tomcat's thread pool that processes one HTTP request at a time.

Conceptually:

```text
Browser

↓

Socket Ready

↓

Worker Thread

↓

Parse HTTP

↓

Spring Boot

↓

Generate Response

↓

Return Thread To Pool
```

Unlike the Acceptor or Poller, the Worker Thread performs the real application work.

---

# 🏗️ Complete Architecture

```text
Browser
    │
    ▼
Linux TCP Stack
    │
    ▼
SocketChannel
    │
    ▼
Poller Thread
    │
    ▼
Executor
    │
    ▼
+--------------------------------------------+
| Worker Thread                              |
|--------------------------------------------|
| Http11Processor                            |
| HTTP Parser                                |
| HttpServletRequest                         |
| DispatcherServlet                          |
| Controller                                 |
| Service                                    |
| Repository                                 |
| JSON Serializer                            |
+--------------------------------------------+
```

---

# 👷 Thread Pool

Tomcat creates a reusable pool of worker threads.

Example:

```text
http-nio-8080-exec-1

http-nio-8080-exec-2

http-nio-8080-exec-3

...

http-nio-8080-exec-200
```

These threads are created once and reused for many requests.

This avoids the overhead of creating a new thread for every request.

---

# 📦 Executor

When the Poller detects a readable socket:

```text
Poller

↓

Executor

↓

Idle Worker Thread

↓

Assign Request
```

The Executor selects an available worker thread from the pool.

If all worker threads are busy, new requests wait in the connector's task queue until a thread becomes available.

---

# 📄 Http11Processor

The Worker Thread begins by creating (or reusing) an **Http11Processor**.

Responsibilities:

```text
Read Socket

↓

Read Bytes

↓

Parse HTTP

↓

Create Request

↓

Create Response
```

This component converts raw TCP bytes into Java HTTP objects.

---

# 📥 Reading Bytes

Suppose the browser sends:

```http
GET /students/1051110244 HTTP/1.1
Host: localhost:8080
Accept: application/json
Connection: keep-alive
```

Worker Thread:

```text
SocketChannel

↓

Read Bytes

↓

ByteBuffer

↓

Http11Processor
```

Initially, Tomcat only sees bytes—not Java objects.

---

# 📄 Parsing HTTP

The parser extracts:

```text
Method

GET

------------------

URI

/students/1051110244

------------------

Version

HTTP/1.1

------------------

Headers

Host

Accept

Connection
```

Tomcat validates the HTTP syntax before passing control to your application.

---

# 📨 Creating HttpServletRequest

Tomcat creates:

```java
HttpServletRequest request
```

Containing:

* HTTP Method
* URI
* Query Parameters
* Headers
* Cookies
* Request Body
* Remote Address

Everything your controller accesses through `HttpServletRequest` originates here.

---

# 📨 Creating HttpServletResponse

Tomcat also creates:

```java
HttpServletResponse response
```

Initially empty.

It will later contain:

* Status code
* Response headers
* Cookies
* Response body

---

# 🍃 Entering Spring Boot

Tomcat now invokes the Servlet API.

```text
Http11Processor

↓

ApplicationFilterChain

↓

DispatcherServlet
```

From this point onward, Spring MVC takes control.

---

# 🚀 DispatcherServlet

Spring Boot's front controller receives the request.

```text
DispatcherServlet

↓

Handler Mapping

↓

StudentController
```

DispatcherServlet determines which controller method should handle the request.

---

# 👨‍🎓 Student Results API Example

Request:

```http
GET /students/1051110244
```

Execution:

```text
Worker Thread

↓

DispatcherServlet

↓

StudentController

↓

StudentService

↓

StudentRepository

↓

PostgreSQL
```

Each method executes on the **same Worker Thread**.

No new thread is created during normal synchronous request processing.

---

# ☕ JVM Memory During Execution

While processing the request:

```text
Worker Thread

↓

Java Stack

↓

Controller()

↓

Service()

↓

Repository()

------------------------

Heap

↓

Student

↓

StudentResponse

↓

ArrayList
```

The Worker Thread owns the stack.

Objects created during execution are allocated on the Heap.

---

# 📤 Building the Response

Suppose the repository returns:

```java
StudentResponse
```

Spring uses Jackson:

```text
StudentResponse

↓

ObjectMapper

↓

JSON
```

Tomcat receives the generated JSON and writes it into the response buffer.

---

# 📡 Writing to the Socket

The Worker Thread:

```text
JSON

↓

Response Buffer

↓

SocketChannel

↓

Linux TCP Buffer

↓

NIC

↓

Browser
```

The bytes travel back through the Linux networking stack to the client.

---

# 🔄 Thread Reuse

After the response is sent:

```text
Request Complete

↓

Clear Request State

↓

Clear Response State

↓

Return Worker Thread

↓

Idle Thread Pool
```

The same Worker Thread can immediately process another request.

This reuse is critical for high throughput.

---

# 🌐 HTTP Keep-Alive

With:

```http
Connection: keep-alive
```

The TCP connection remains open.

Example:

```text
Request 1

↓

Response

↓

Same Socket

↓

Request 2

↓

Response

↓

Request 3
```

The Worker Thread finishes each request and returns to the pool, while the Poller continues monitoring the same socket for future requests.

---

# 📊 During Your Load Test

Command:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Internally:

```text
200 Connections

↓

Poller

↓

Worker Pool

↓

Controller

↓

Service

↓

Repository

↓

JSON

↓

Worker Returns
```

Tomcat reused the same worker threads thousands of times.

---

# 🚫 What the Worker Thread Does NOT Do

The Worker Thread does **not**:

* Accept TCP connections
* Monitor sockets with `epoll`
* Schedule CPU execution
* Perform TCP handshakes

Those responsibilities belong to:

* Linux Kernel
* Acceptor Thread
* Poller Thread
* Linux Scheduler

---

# 🐳 Docker Perspective

```text
Container

↓

Java Process

↓

Tomcat Worker Thread

↓

Spring Boot

↓

Heap

↓

Stack
```

Worker Threads behave identically inside containers.

---

# ☸️ Kubernetes Perspective

```text
Client

↓

Service

↓

Pod

↓

Container

↓

Worker Thread

↓

Spring Boot
```

Kubernetes delivers traffic to the Pod.

Tomcat Worker Threads process requests inside the JVM.

---

# 🧪 Hands-on Lab

## Display Worker Threads

```bash
jstack <PID>
```

Look for:

```text
http-nio-8080-exec-1

http-nio-8080-exec-2
```

---

## Monitor Thread CPU Usage

```bash
top -H -p <PID>
```

Observe worker threads consuming CPU during active requests.

---

## Generate Concurrent Load

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

During the benchmark, repeatedly run:

```bash
jstack <PID>
```

Notice different worker threads executing controller methods.

---

## Observe Thread Count

```bash
ps -Lf -p <PID>
```

Compare the total number of native threads with the number of Tomcat worker threads.

---

## Monitor TCP Connections

```bash
watch -n1 "ss -tan | grep :8080"
```

Correlate established connections with worker thread activity.

---

# 📈 Complete Worker Thread Flow

```text
Browser
      │
      ▼
TCP Packet
      │
      ▼
Linux TCP Stack
      │
      ▼
Socket Ready
      │
      ▼
Poller Thread
      │
      ▼
Worker Thread
      │
      ▼
Http11Processor
      │
      ▼
Parse HTTP
      │
      ▼
HttpServletRequest
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
PostgreSQL
      │
      ▼
StudentResponse
      │
      ▼
Jackson
      │
      ▼
JSON
      │
      ▼
HttpServletResponse
      │
      ▼
SocketChannel
      │
      ▼
Browser
```

This is the complete journey of an HTTP request through a Tomcat Worker Thread.

---

# 💡 Key Takeaways

✅ A Worker Thread is responsible for executing one HTTP request at a time.

✅ The Poller assigns ready sockets to idle Worker Threads through the Tomcat Executor.

✅ `Http11Processor` reads socket bytes, parses HTTP, and creates `HttpServletRequest` and `HttpServletResponse` objects.

✅ The Worker Thread invokes Spring MVC through `DispatcherServlet`, which routes the request to your controller.

✅ Controller, Service, Repository, and JSON serialization all execute on the same Worker Thread during synchronous processing.

✅ After the response is sent, the Worker Thread is returned to the thread pool and reused for future requests.

✅ This thread-pool architecture allows Tomcat to process very high request volumes efficiently while avoiding the cost of creating a new thread for every request.

---

# ➡️ Next Chapter

📘 **`05-Tomcat/06-HTTP-Parsing.md`**

In the next chapter, we'll zoom in on one fascinating step:

> **How does Tomcat convert raw TCP bytes into `HttpServletRequest`?**

We'll decode every byte of:

```http
GET /students/1051110244 HTTP/1.1
Host: localhost:8080
Accept: application/json
Connection: keep-alive
```

You'll learn:

* 📦 HTTP message format
* 🔤 CRLF (`\r\n`) parsing
* 📄 Request line parsing
* 🏷️ Header parsing
* 🍪 Cookie parsing
* 📥 Request body parsing
* 📏 Content-Length and chunked encoding

By the end of the next chapter, you'll understand exactly how Tomcat transforms a stream of bytes into the Java request objects used by Spring Boot.
