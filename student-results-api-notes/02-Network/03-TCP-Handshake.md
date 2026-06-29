# 📘 Chapter 8 — TCP Three-Way Handshake

> 📂 File: `student-results-api-notes/02-Network/03-TCP-Handshake.md`

---

# 🤝 Introduction

Before your browser can send this request:

```http
GET /students/1051110244 HTTP/1.1
Host: 50.xx.xx.xx:8080
```

a TCP connection **must already exist**.

Unlike UDP, TCP is **connection-oriented**.

This means both the client and server must agree that they are ready to communicate.

That agreement is called the **TCP Three-Way Handshake**.

Without it:

* ❌ HTTP cannot be sent
* ❌ Spring Boot never receives the request
* ❌ Tomcat never creates a request object
* ❌ PostgreSQL is never queried

Everything starts with the handshake.

---

# 🎯 Learning Objectives

After this chapter you will understand:

* 🤝 Why TCP needs a handshake
* 🔌 How sockets are created
* 📌 How `bind()` works
* 👂 How `listen()` creates the accept queue
* 🤲 How `accept()` creates a new socket
* 📦 SYN packets
* 📦 SYN-ACK packets
* 📦 ACK packets
* 🔢 Initial Sequence Numbers (ISN)
* 🐧 Linux TCP state machine
* 🍃 Tomcat connection handling
* 📊 TCP connection lifecycle
* 🧪 How to observe everything using Linux tools

---

# 🌍 Our Student Results API

Your backend is listening on:

```text
50.xx.xx.xx:8080
```

or locally

```text
localhost:8080
```

When React executes:

```javascript
axios.get("/students/1051110244")
```

the browser asks the operating system:

> "Please create a TCP connection to port 8080."

The browser does **not** implement TCP itself.

Linux does.

---

# 🏗️ Before the Browser Sends Anything

Your Spring Boot application has already started.

When Spring Boot starts:

```bash
java -jar student-results-api.jar
```

Tomcat performs approximately the following steps:

```text
socket()

↓

bind()

↓

listen()

↓

Waiting...
```

At this point:

* ✅ Java process exists
* ✅ Port 8080 is open
* ✅ Linux owns the listening socket
* ✅ Tomcat waits for connections

No client is connected yet.

---

# 🐧 Step 1 — socket()

Tomcat first asks Linux to create a socket.

Conceptually:

```c
socket(AF_INET, SOCK_STREAM)
```

This tells Linux:

> Create a TCP communication endpoint.

Linux allocates:

* socket structure
* receive buffer
* send buffer
* TCP control block

The socket exists, but it is **not attached to any port**.

---

# 📌 Step 2 — bind()

Tomcat now binds the socket.

Conceptually:

```c
bind(socket, 0.0.0.0:8080)
```

Now Linux knows:

```text
Port 8080

↓

belongs to

↓

Java Process

↓

Tomcat
```

You can verify:

```bash
ss -ltnp
```

Example:

```text
LISTEN 0 100 *:8080 users:(("java",pid=7065))
```

---

# 👂 Step 3 — listen()

Next Tomcat executes:

```c
listen(socket)
```

Linux changes the socket state.

```text
CLOSED

↓

LISTEN
```

Now Linux starts accepting incoming SYN packets.

The socket is called the:

> **Listening Socket**

Important:

There is **only one listening socket** for port 8080.

---

# 🌐 Browser Creates a Client Socket

When React sends:

```javascript
axios.get(...)
```

the browser also creates a TCP socket.

Linux assigns an **ephemeral port** automatically.

Example:

```text
Client

192.168.1.25:54122

↓

Server

50.xx.xx.xx:8080
```

Notice:

Server port:

```text
8080
```

Client port:

```text
54122
```

This client port is temporary.

---

# 📦 Step 4 — SYN

The browser sends the first TCP packet.

```text
Client

──────── SYN ───────►

Server
```

This packet contains:

* Source IP
* Destination IP
* Source Port
* Destination Port
* Initial Sequence Number

Example:

```text
SYN

Seq = 1000
```

Meaning:

> "I want to establish a TCP connection."

---

# 📦 Step 5 — SYN-ACK

Linux receives the SYN packet.

The kernel checks:

* Is port 8080 open?
* Is a listening socket present?
* Is the backlog queue full?

If everything is valid:

Linux replies:

```text
Client

◄──── SYN ACK ────

Server
```

Example:

```text
Seq = 5000

ACK = 1001
```

Meaning:

> "I received your SYN. I am ready."

---

# 📦 Step 6 — ACK

The browser sends the final packet.

```text
Client

──── ACK ───►

Server
```

Example:

```text
ACK = 5001
```

Now both systems agree that the connection is established.

The TCP state becomes:

```text
ESTABLISHED
```

Only **after this step** can HTTP data be transmitted.

---

# 🎬 Complete Handshake

```text
Browser                          Spring Boot

   │                                   │
   │ -------- SYN -------------------->│
   │                                   │
   │<------ SYN + ACK -----------------│
   │                                   │
   │ -------- ACK -------------------->│
   │                                   │
   │====== Connection Established =====│
   │                                   │
   │------ HTTP GET ------------------>│
```

This entire exchange usually completes in a few milliseconds on a local network.

---

# 🧵 Listening Socket vs Connected Socket

A common misconception is that Tomcat uses the listening socket for all communication.

Actually:

```text
Listening Socket

Port 8080

↓

accept()

↓

Connected Socket #1

↓

Connected Socket #2

↓

Connected Socket #3
```

The listening socket **never handles application data**.

It only accepts new connections.

Each client receives a dedicated connected socket.

---

# 🤲 accept()

When the handshake finishes:

Linux wakes Tomcat.

Tomcat calls:

```c
accept()
```

Linux creates a brand-new connected socket.

```text
Listening Socket

↓

accept()

↓

Connected Socket
```

Now Tomcat assigns the request to one of its worker threads.

Example:

```text
http-nio-8080-exec-7
```

This thread will process the entire HTTP request.

---

# 🐧 Linux TCP States

During the connection lifecycle the socket transitions through several states.

```text
CLOSED

↓

LISTEN

↓

SYN-RECEIVED

↓

ESTABLISHED

↓

FIN-WAIT

↓

TIME-WAIT

↓

CLOSED
```

You can observe these using:

```bash
ss -tan
```

---

# 📊 TCP State Diagram

```text
Client                           Server

CLOSED                          CLOSED

   │                               │
   ▼                               ▼
SYN-SENT                    LISTEN
   │                               │
   ▼                               ▼
ESTABLISHED <──────────── ESTABLISHED
   │                               │
   ▼                               ▼
FIN-WAIT                    CLOSE-WAIT
   │                               │
   ▼                               ▼
TIME-WAIT                   CLOSED
```

---

# 🍃 Tomcat's Role

Tomcat does **not** implement TCP itself.

Linux performs:

* TCP
* Retransmissions
* Checksums
* Packet ordering
* Flow control

Tomcat simply waits for Linux to deliver a fully established socket.

Only then does Tomcat begin parsing the HTTP request.

---

# 🧪 Hands-on Lab

## Verify Tomcat is Listening

```bash
ss -ltnp | grep 8080
```

---

## Display Established Connections

```bash
ss -tan
```

---

## Watch Live Connections

```bash
watch -n 1 'ss -tan | grep 8080'
```

---

## Generate Traffic

```bash
ab -n 1000 -c 50 http://localhost:8080/students/1051110244
```

Observe how many connections enter the `ESTABLISHED` state.

---

## Capture the Handshake

```bash
sudo tcpdump -i any port 8080
```

You should see packets similar to:

```text
S

S.

.

GET /students/1051110244
```

Where:

* `S` = SYN
* `S.` = SYN-ACK
* `.` = ACK/Data

---

# 🐳 Docker Perspective

If Spring Boot runs inside Docker:

```text
Browser

↓

Host Linux TCP Stack

↓

Docker Bridge

↓

Container Network Namespace

↓

Tomcat
```

The TCP handshake still occurs.

Docker only changes the network path.

---

# ☸️ Kubernetes Perspective

Inside Kubernetes:

```text
Browser

↓

Ingress

↓

Service

↓

Pod IP

↓

Container

↓

Tomcat
```

Even though additional networking layers exist, every connection still begins with the same TCP three-way handshake.

---

# 💡 Key Takeaways

✅ Every HTTP request starts with a TCP handshake.

✅ Linux implements TCP—not Tomcat or Spring Boot.

✅ `socket()`, `bind()`, and `listen()` prepare the server before clients connect.

✅ The listening socket accepts new connections but does not carry application data.

✅ `accept()` creates a dedicated connected socket for each client.

✅ Tomcat receives an already-established connection and hands it to a worker thread.

✅ Only after the connection reaches the **ESTABLISHED** state does the browser send the HTTP request.

---

# ➡️ Next Chapter

📘 **02-Network/04-HTTP-Request.md**

In the next chapter we'll follow the **actual HTTP request**.

We'll decode every byte of:

```http
GET /students/1051110244 HTTP/1.1
Host: localhost:8080
Accept: application/json
User-Agent: Mozilla/5.0
Connection: keep-alive
```

You'll learn:

* 📨 HTTP request format
* 📋 Request line
* 🏷️ HTTP headers
* 🍪 Cookies
* 🔐 Authentication headers
* 📦 Message body
* 📏 Content-Length
* 🔄 Keep-Alive connections
* 🍃 How Tomcat parses HTTP before Spring Boot ever sees the request
