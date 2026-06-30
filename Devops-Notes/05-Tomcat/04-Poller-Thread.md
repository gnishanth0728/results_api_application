# 📘 Chapter 38 — Tomcat Poller Thread

> 📂 File: `student-results-api-notes/05-Tomcat/04-Poller-Thread.md`

The Poller Thread is the component that allows Tomcat to scale from 10 connections to 100,000+ concurrent connections.

This chapter connects everything you've already learned:

Linux epoll
TCP sockets
File descriptors
Java NIO
JVM threads
Tomcat Connector
Acceptor Thread

After this chapter, the reader should understand exactly how Linux wakes Tomcat only when a socket becomes ready, instead of checking every socket continuously.

---

# 🌍 Introduction

In the previous chapter, we learned how the **Acceptor Thread** accepts new TCP connections.

```text
Browser
    │
    ▼
TCP Handshake
    │
    ▼
Linux Accept Queue
    │
    ▼
Acceptor Thread
    │
    ▼
SocketChannel
```

After the Acceptor accepts a connection, another important question appears:

> 🤔 **How does Tomcat know when a client has actually sent HTTP data?**

Imagine your Student Results API has:

* 🌐 100 clients connected
* 🌐 1,000 clients connected
* 🌐 10,000 clients connected
* 🌐 50,000 clients connected

Most of these clients are **idle**.

Tomcat cannot create one thread that continuously checks every socket.

Instead, it uses one of Linux's most powerful features:

# ⚡ epoll

Through Java NIO's **Selector**, Tomcat efficiently monitors thousands of sockets using only a few threads.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* ⚡ What the Poller Thread is
* 📂 Java NIO Selector
* 🐧 Linux epoll
* 📡 Read events
* 📤 Write events
* 📁 SelectionKey
* 🧵 Worker thread dispatch
* 🚀 Request lifecycle
* 🍃 Spring Boot integration
* 🐳 Docker
* ☸️ Kubernetes
* 🧪 Debugging

---

# ❓ Why Does Tomcat Need a Poller?

Suppose 20,000 clients are connected.

Without epoll:

```text
Thread

↓

Socket 1?

↓

Socket 2?

↓

Socket 3?

↓

Socket 4?

↓

...

↓

Socket 20,000?
```

This is called **busy polling**.

Problems:

* ❌ Huge CPU usage
* ❌ Constant scanning
* ❌ Poor scalability

Instead Tomcat asks Linux:

> "Wake me only when one of these sockets becomes ready."

---

# 🏗️ High-Level Architecture

```text
                    Browser
                        │
                        ▼
                 TCP Connection
                        │
                        ▼
               Linux TCP Stack
                        │
                        ▼
                Socket File Descriptor
                        │
                        ▼
+------------------------------------------------------+
|              Tomcat Poller Thread                    |
|------------------------------------------------------|
| Java Selector                                        |
|------------------------------------------------------|
| SelectionKey                                         |
|------------------------------------------------------|
| epoll_wait()                                         |
|------------------------------------------------------|
| Ready Socket Events                                  |
|------------------------------------------------------|
| Worker Thread Dispatch                               |
+------------------------------------------------------+
```

The Poller spends almost all of its time sleeping efficiently inside `epoll_wait()`.

---

# 🔄 Complete Lifecycle

The Acceptor finishes its work:

```text
Acceptor

↓

SocketChannel
```

Then:

```text
SocketChannel

↓

Selector.register()

↓

SelectionKey

↓

Poller
```

The Poller now owns the connection.

---

# 📂 Java Selector

Java NIO provides:

```java
Selector selector =
Selector.open();
```

Conceptually:

```text
Socket 1

Socket 2

Socket 3

Socket 4

Socket 5000

↓

Selector
```

Instead of creating 5,000 threads, one Selector monitors all sockets.

---

# 🐧 Linux epoll

On Linux:

```text
Java Selector

↓

JNI

↓

epoll_create()

↓

epoll_ctl()

↓

epoll_wait()
```

The JVM internally maps Java NIO to Linux epoll.

Tomcat never directly calls `epoll_wait()`.

The JVM performs that integration.

---

# ⚙️ epoll_wait()

The Poller repeatedly performs the equivalent of:

```java
while (true) {

    selector.select();

}
```

Internally:

```text
Selector.select()

↓

epoll_wait()

↓

Kernel Sleeps

↓

Socket Ready

↓

Wake Up
```

No CPU is wasted checking idle sockets.

---

# 📡 Read Events

Suppose a browser sends:

```http
GET /students/1051110244 HTTP/1.1
```

Linux receives bytes.

```text
Network Card

↓

Linux TCP Buffer

↓

Socket Ready

↓

epoll

↓

Poller Wake-up
```

The Poller detects that the socket is **readable**.

---

# 📤 Write Events

Later:

```text
JSON Response

↓

Socket Send Buffer

↓

Writable

↓

epoll

↓

Worker Thread
```

Tomcat can also monitor writable events when sending responses.

---

# 📁 SelectionKey

Each registered socket has a `SelectionKey`.

Conceptually:

```text
SocketChannel

↓

SelectionKey

↓

Readable?

Writable?

Closed?
```

The Poller uses the key to determine what action should be taken.

---

# 👷 Dispatch to Worker Threads

When a readable socket is detected:

```text
Poller

↓

Executor

↓

http-nio-8080-exec-17
```

Only now does a worker thread begin processing the request.

---

# 🍃 Student Results API Example

Request:

```http
GET /students/1051110244
```

Flow:

```text
Browser

↓

SocketChannel

↓

Selector

↓

epoll_wait()

↓

Readable Event

↓

Poller

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
```

The Poller never parses HTTP.

It only detects socket readiness.

---

# 🚫 What the Poller Does NOT Do

The Poller **does not**:

* Parse HTTP
* Execute Controllers
* Execute Services
* Access PostgreSQL
* Serialize JSON

Its only job is detecting socket events.

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

Selector

↓

epoll

↓

Ready Socket

↓

Worker Thread

↓

Back To epoll_wait()
```

The Poller immediately returns to waiting for more socket events.

---

# ⚡ Why epoll Is Fast

Suppose:

```text
50,000 Connections

↓

Only 8 Active
```

With polling:

```text
Check

50,000

Sockets
```

With epoll:

```text
Kernel

↓

Returns Only

8 Ready Sockets
```

The Poller processes only sockets that actually need attention.

This is why Tomcat scales so well.

---

# 🔄 Poller Loop

Conceptually:

```text
while(true)

↓

selector.select()

↓

Ready Keys

↓

For Each Key

↓

Dispatch Worker

↓

Back To select()
```

This loop runs for the lifetime of the Tomcat server.

---

# 🐳 Docker Perspective

```text
Container

↓

Tomcat Poller

↓

Java Selector

↓

epoll_wait()

↓

Linux Kernel
```

Docker does not change the Poller's behavior.

The kernel inside the container namespace still provides epoll.

---

# ☸️ Kubernetes Perspective

```text
Service

↓

Pod

↓

Container

↓

Tomcat Poller

↓

epoll
```

Kubernetes routes traffic to the Pod.

Once inside the container, Tomcat's Poller behaves exactly the same as on bare Linux.

---

# 🧪 Hands-on Lab

## Display Poller Thread

```bash
jstack <PID>
```

Look for:

```text
"http-nio-8080-Poller"
```

Observe that it spends most of its time waiting for socket events.

---

## Monitor TCP Connections

```bash
watch -n1 "ss -tan | grep :8080"
```

Observe established connections.

---

## Monitor Thread Activity

```bash
top -H -p <PID>
```

The Poller thread usually consumes very little CPU unless many sockets become active simultaneously.

---

## Run Concurrent Requests

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Watch worker threads wake up while the Poller continues waiting for readiness events.

---

## View Socket File Descriptors

```bash
ls -l /proc/<PID>/fd
```

Notice that each socket monitored by the Poller corresponds to a file descriptor.

---

## Trace epoll System Calls (Advanced)

```bash
sudo strace -f -e trace=epoll_wait -p <PID>
```

Observe the JVM blocking in `epoll_wait()` and waking when socket events occur.

---

# 📈 Complete Poller Flow

```text
Browser
      │
      ▼
TCP Connection
      │
      ▼
Acceptor Thread
      │
      ▼
SocketChannel
      │
      ▼
Selector.register()
      │
      ▼
SelectionKey
      │
      ▼
Poller Thread
      │
      ▼
Selector.select()
      │
      ▼
Linux epoll_wait()
      │
      ▼
Readable Socket
      │
      ▼
Worker Thread
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
```

This is the complete responsibility of the Poller Thread.

It never executes your application code—it simply detects which sockets are ready and dispatches them for processing.

---

# 💡 Key Takeaways

✅ The Poller Thread monitors thousands of socket connections using Java NIO `Selector`.

✅ On Linux, `Selector` is implemented using the highly scalable `epoll` API.

✅ `selector.select()` blocks efficiently until the kernel reports that one or more sockets are ready.

✅ The Poller handles readiness events (such as readable sockets) but does **not** parse HTTP or execute application logic.

✅ When a socket becomes ready, the Poller hands it to a Tomcat worker thread for request processing.

✅ This event-driven architecture allows Tomcat to handle tens of thousands of concurrent connections with a relatively small number of threads.

---

# ➡️ Next Chapter

📘 **`05-Tomcat/05-Worker-Thread.md`**

In the next chapter, we'll follow the **Worker Thread**, where the real application work begins.

We'll explore:

* 👷 `http-nio-8080-exec-*` threads
* 📄 HTTP request parsing
* 📦 `Http11Processor`
* 📨 `HttpServletRequest` and `HttpServletResponse`
* 🍃 `DispatcherServlet`
* 🧵 Thread pools and request execution
* 📊 How one worker thread processes one HTTP request from start to finish

By the end of the next chapter, you'll understand exactly how a socket full of HTTP bytes becomes a call to your `StudentController.getStudent()` method.
