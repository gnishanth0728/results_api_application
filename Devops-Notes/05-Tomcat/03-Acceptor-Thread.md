# 📘 Chapter 37 — Tomcat Acceptor Thread

> 📂 File: `student-results-api-notes/05-Tomcat/03-Acceptor-Thread.md`

After the NIO Connector overview, the next chapter should zoom into one component at a time. The Acceptor Thread deserves its own deep chapter because it's the first Tomcat thread that interacts with the Linux kernel.

---

# 🌍 Introduction

In the previous chapter, we learned about the Tomcat NIO Connector.

```text
                Browser
                    │
                    ▼
              TCP Connection
                    │
                    ▼
           Tomcat NIO Connector
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
   Acceptor      Poller      Worker
```

The NIO Connector contains three important thread types:

* 🧵 Acceptor Thread
* ⚡ Poller Thread
* 👷 Worker Thread

This chapter focuses entirely on the **Acceptor Thread**.

Its responsibility is simple but extremely important:

> **Accept new TCP connections from the Linux kernel.**

It does **NOT**:

* Parse HTTP
* Execute Spring Boot
* Read request bodies
* Call your Controller

It only accepts newly established TCP connections.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🧵 What the Acceptor Thread is
* 🔌 Why Tomcat needs it
* 🌐 How `accept()` works
* ⚙️ Linux accept queue
* 📡 TCP three-way handshake
* 🔄 Connection lifecycle
* 📂 SocketChannel creation
* 📦 Registration with Poller
* 🍃 Spring Boot startup
* 🐳 Docker
* ☸️ Kubernetes
* 🧪 Debugging

---

# ❓ Why Does Tomcat Need an Acceptor Thread?

Suppose your Student Results API starts:

```bash
java -jar student-results-api.jar
```

Tomcat binds to:

```text
0.0.0.0:8080
```

Now imagine thousands of browsers trying to connect.

```text
Browser A

Browser B

Browser C

...

Browser 5000
```

Who receives these new TCP connections?

The answer is:

```text
Acceptor Thread
```

---

# 🏗️ High-Level Architecture

```text
               Browser
                   │
                   ▼
             TCP SYN Packet
                   │
                   ▼
           Linux TCP Stack
                   │
                   ▼
           SYN Queue
                   │
                   ▼
         Accept Queue
                   │
                   ▼
          accept() System Call
                   │
                   ▼
         Tomcat Acceptor Thread
                   │
                   ▼
          SocketChannel
                   │
                   ▼
             Poller Thread
```

Notice that the Acceptor Thread only participates once the TCP connection is fully established.

---

# 🌐 Before the Acceptor Runs

Suppose a browser opens:

```text
http://localhost:8080/students/1051110244
```

The browser sends:

```text
TCP SYN
```

Linux responds:

```text
SYN-ACK
```

Browser replies:

```text
ACK
```

Only after the TCP handshake completes does Linux move the connection into the **accept queue**.

---

# 📦 Linux Accept Queue

Inside the kernel:

```text
+-------------------------------------+

TCP SYN Queue

--------------------------------------

Accept Queue

Connection 1

Connection 2

Connection 3

Connection 4

+-------------------------------------+
```

The accept queue contains fully established TCP connections waiting for the application.

---

# ⚙️ The accept() System Call

The Acceptor thread repeatedly executes the equivalent of:

```java
while (true) {

    SocketChannel socket =
        serverSocketChannel.accept();

}
```

Under the hood:

```text
Java

↓

JNI

↓

accept()

↓

Linux Kernel

↓

Socket File Descriptor
```

`accept()` returns a **new socket** for each client.

The original listening socket remains open to accept additional connections.

---

# 🧵 One Listening Socket, Many Client Sockets

Suppose Tomcat listens on port **8080**.

```text
Listening Socket

0.0.0.0:8080

↓

Client 1 Socket

↓

Client 2 Socket

↓

Client 3 Socket

↓

Client 4 Socket
```

Important distinction:

* One listening socket
* Thousands of connected sockets

---

# 📡 What Happens Inside accept()?

Conceptually:

```text
Acceptor Thread

↓

accept()

↓

Kernel Checks Accept Queue

↓

Queue Empty?

↓

YES → Sleep

↓

NO → Return Socket
```

The Acceptor does **not** waste CPU continuously checking for new clients.

If no connections are waiting, it blocks efficiently inside the kernel.

---

# 📂 SocketChannel Creation

After `accept()` returns:

```text
Socket FD

↓

SocketChannel

↓

Configure Non-Blocking

↓

Register With Poller
```

Tomcat wraps the native socket in a Java NIO `SocketChannel`.

---

# 🔄 Registering with the Poller

The Acceptor immediately hands the connection to the Poller.

```text
Acceptor

↓

SocketChannel

↓

Poller Queue

↓

Selector.register()

↓

epoll
```

From this point onward, the Acceptor is finished with that connection.

The Poller now owns it.

---

# 🍃 Student Results API Example

Browser:

```http
GET /students/1051110244 HTTP/1.1
Host: localhost:8080
```

Connection flow:

```text
Browser

↓

TCP Handshake

↓

Linux Accept Queue

↓

Acceptor Thread

↓

SocketChannel

↓

Poller

↓

Worker Thread

↓

DispatcherServlet

↓

StudentController
```

Notice that the Acceptor never sees the HTTP request itself.

It only handles the TCP connection.

---

# 🚫 What the Acceptor Does NOT Do

Many beginners think the Acceptor processes requests.

It does not.

❌ It does not:

* Parse HTTP
* Read request bodies
* Execute Controllers
* Call Services
* Access PostgreSQL
* Generate JSON

Those responsibilities belong to later stages.

---

# 📈 Complete Lifecycle

```text
Browser

↓

TCP SYN

↓

Linux Kernel

↓

TCP Handshake

↓

Accept Queue

↓

accept()

↓

Acceptor Thread

↓

SocketChannel

↓

Poller Thread

↓

Worker Thread

↓

HTTP Processing
```

---

# 📊 During Your Load Test

Command:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

What happened?

```text
200 Concurrent Connections

↓

Acceptor

↓

accept()

↓

200 SocketChannels

↓

Poller

↓

Worker Pool
```

Notice:

The Acceptor was busy only while new TCP connections were being established.

Once the sockets were accepted, the Poller and Worker threads handled the actual requests.

---

# 🔄 Connection Reuse (Keep-Alive)

HTTP/1.1 enables persistent connections.

Instead of:

```text
Connection

↓

Request

↓

Close
```

Tomcat usually performs:

```text
Connection

↓

Request 1

↓

Response

↓

Request 2

↓

Response

↓

Request 3

↓

Close Later
```

This means the Acceptor is involved **once per TCP connection**, not once per HTTP request.

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

Acceptor Thread

↓

accept()

↓

Linux Kernel (Host)
```

The container has its own network namespace, but `accept()` still interacts with the Linux kernel.

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

Tomcat Acceptor

↓

accept()
```

Kubernetes routes traffic to the Pod, but once the packet reaches the container, the Acceptor behaves exactly the same.

---

# 🧪 Hands-on Lab

## Verify Listening Socket

```bash
ss -ltnp | grep 8080
```

Expected output:

```text
LISTEN 0 100 *:8080 users:(("java",pid=7065))
```

---

## Watch New Connections

```bash
watch -n1 "ss -tan | grep :8080"
```

Observe connections entering the `ESTAB` state as they are accepted.

---

## Observe Acceptor Thread

```bash
jstack <PID>
```

Look for:

```text
"http-nio-8080-Acceptor"
```

Its stack trace typically shows it waiting in `accept()` when idle.

---

## Display Open Socket File Descriptors

```bash
ls -l /proc/<PID>/fd
```

Notice:

```text
socket:[12345]

socket:[12346]

socket:[12347]
```

Each accepted connection has its own file descriptor.

---

## Run a Load Test

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

During the test:

```bash
ss -tan | grep :8080 | wc -l
```

Observe many simultaneous established connections.

---

# 📈 Complete Acceptor Flow

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
Three-Way Handshake
      │
      ▼
Accept Queue
      │
      ▼
accept()
      │
      ▼
Tomcat Acceptor Thread
      │
      ▼
Socket File Descriptor
      │
      ▼
SocketChannel
      │
      ▼
Poller Thread
```

This is the entire responsibility of the Acceptor.

After the socket is handed to the Poller, the Acceptor immediately returns to waiting for the next incoming connection.

---

# 💡 Key Takeaways

✅ The Acceptor Thread is responsible only for accepting new TCP connections.

✅ It waits on the Linux `accept()` system call, which blocks efficiently until a connection is available.

✅ Linux completes the TCP three-way handshake before placing a connection into the accept queue.

✅ Each successful `accept()` returns a new socket file descriptor, while the original listening socket remains open.

✅ Tomcat wraps the socket in a non-blocking `SocketChannel` and registers it with the Poller.

✅ The Acceptor does **not** parse HTTP or execute application code.

✅ With HTTP keep-alive, one accepted TCP connection can carry many HTTP requests.

---

# ➡️ Next Chapter

📘 **`05-Tomcat/04-Poller-Thread.md`**

In the next chapter, we'll study the **Poller Thread**, the component that makes Tomcat highly scalable.

You'll learn:

* ⚡ Java NIO `Selector`
* 🐧 Linux `epoll_wait()`
* 📡 Readable and writable socket events
* 📋 Selection keys
* 🧵 How sockets are dispatched to worker threads
* 🚀 How Tomcat efficiently monitors tens of thousands of concurrent connections using only a few threads

By the end of the next chapter, you'll understand why Tomcat can handle massive concurrency without creating one thread per client.
