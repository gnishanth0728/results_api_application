# 📘 Chapter 7 — TCP/IP Fundamentals

> 📂 File: `student-results-api-notes/02-Network/02-TCP-IP.md`

---

# 🌍 Introduction

When you type

```text
http://50.xx.xx.xx:8080/students/1051110244
```

or

```text
http://localhost:8080/students/1051110244
```

your browser does **not** send an HTTP request directly.

Instead, the request travels through multiple networking protocols that work together to provide reliable communication.

The protocol suite responsible for this communication is called **TCP/IP**.

Almost every application on the Internet—including browsers, Spring Boot applications, Docker containers, and Kubernetes clusters—relies on TCP/IP.

This chapter explains how these protocols work together to deliver a request safely and reliably.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🌐 What TCP/IP is
* 🏗️ The TCP/IP protocol suite
* 📦 Packet encapsulation
* 🔢 IP addresses
* 🚪 Port numbers
* 🔌 TCP sockets
* ✔️ Reliability
* 🔄 Retransmissions
* 📊 Sliding windows
* 📈 Flow control
* 🚦 Congestion control
* 🐧 Linux TCP implementation
* 🐳 Docker networking
* ☸️ Kubernetes networking

---

# ❓ Why TCP/IP Exists

Imagine you want to send the message:

```text
Hello
```

to another computer.

Without a communication protocol, the receiving computer cannot know:

* Who sent the data
* Where it should go
* Whether the message arrived completely
* Whether packets were lost
* Whether packets arrived in order

TCP/IP solves these problems.

---

# 🏗️ TCP/IP Architecture

Unlike the seven-layer OSI model, the Internet primarily uses the four-layer TCP/IP model.

```text
                    TCP/IP MODEL

+---------------------------------------------+
| 🌐 Application Layer                        |
| HTTP HTTPS DNS FTP SSH MQTT                |
+---------------------------------------------+
| 🚚 Transport Layer                          |
| TCP UDP                                     |
+---------------------------------------------+
| 🗺️ Internet Layer                           |
| IPv4 IPv6 ICMP                              |
+---------------------------------------------+
| 🔌 Network Access Layer                     |
| Ethernet Wi-Fi Loopback                     |
+---------------------------------------------+
```

Every web application relies on these four layers.

---

# 🌐 Application Layer

This is the layer developers interact with most often.

Examples:

* HTTP
* HTTPS
* REST APIs
* GraphQL
* DNS
* SSH
* FTP
* MQTT

In our Student Results API the browser sends:

```http
GET /students/1051110244 HTTP/1.1
Host: 50.xx.xx.xx:8080
Accept: application/json
```

Spring Boot understands **HTTP**, not Ethernet frames or IP packets.

---

# 🚚 Transport Layer

The Transport Layer provides communication between applications.

The two primary protocols are:

* TCP
* UDP

Spring Boot uses **TCP** because it provides reliable communication.

Responsibilities:

* Reliable delivery
* Packet ordering
* Error detection
* Flow control
* Congestion control
* Connection management

---

# 🗺️ Internet Layer

The Internet Layer is responsible for routing packets between networks.

Responsibilities:

* Source IP address
* Destination IP address
* Routing
* Packet forwarding

Example:

```text
Source IP      : 192.168.1.25
Destination IP : 50.xx.xx.xx
```

Routers examine these addresses to determine where packets should travel.

---

# 🔌 Network Access Layer

This layer communicates directly with the physical network.

Examples:

* Ethernet
* Wi-Fi
* Loopback interface
* Network Interface Card (NIC)

Responsibilities:

* Frame creation
* MAC addressing
* Local network communication

---

# 📦 Encapsulation

Every layer wraps the data from the layer above.

```text
HTTP Request
      │
      ▼
TCP Segment
      │
      ▼
IP Packet
      │
      ▼
Ethernet Frame
      │
      ▼
Electrical / Radio Signal
```

Each layer adds a header containing metadata required for communication.

---

# 📤 Decapsulation

The receiving system performs the reverse process.

```text
Electrical Signal
      │
      ▼
Ethernet Frame
      │
      ▼
IP Packet
      │
      ▼
TCP Segment
      │
      ▼
HTTP Request
      │
      ▼
Spring Boot
```

Only after all lower-layer headers are removed does Tomcat receive the HTTP request.

---

# 🔢 IP Address

Every device connected to a network requires an IP address.

Example:

```text
Laptop

192.168.1.25
```

Server:

```text
50.xx.xx.xx
```

The IP address identifies **which machine** should receive the packet.

---

# 🚪 Port Number

Many applications can run on the same computer simultaneously.

Example:

| Application | Port |
| ----------- | ---- |
| HTTP        | 80   |
| HTTPS       | 443  |
| PostgreSQL  | 5432 |
| Spring Boot | 8080 |
| SSH         | 22   |

The port identifies **which application** should receive the packet.

---

# 🔌 Socket

A socket is the communication endpoint between two applications.

Conceptually:

```text
Browser

↓

TCP Socket

↓

Internet

↓

TCP Socket

↓

Spring Boot
```

The Linux kernel creates and manages sockets.

Tomcat simply uses them.

---

# 🧩 The TCP 4-Tuple

Every TCP connection is uniquely identified by four values.

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
192.168.1.25:54122

↓

50.xx.xx.xx:8080
```

Linux uses this 4-tuple to distinguish thousands of simultaneous TCP connections.

---

# ✔️ Reliable Communication

Unlike UDP, TCP guarantees:

* Packets arrive
* Packets arrive only once
* Packets arrive in order

If packet 3 is lost:

```text
Packet 1 ✔

Packet 2 ✔

Packet 3 ❌

Packet 4 ✔
```

TCP automatically retransmits packet 3 before delivering the data to the application.

Spring Boot never sees the missing packet.

---

# 🔢 Sequence Numbers

Every TCP segment contains a sequence number.

Example:

```text
Packet 1 → Sequence 1000

Packet 2 → Sequence 1500

Packet 3 → Sequence 2000
```

These numbers allow TCP to:

* Reassemble data
* Detect missing packets
* Deliver data in order

---

# ✔️ Acknowledgements (ACK)

After receiving data, the receiver sends an acknowledgement.

Example:

```text
ACK = 2500
```

Meaning:

> "I have successfully received all bytes up to 2499."

If the acknowledgement never arrives, TCP retransmits the missing data.

---

# 📊 Sliding Window

Sending one packet at a time would be very slow.

TCP uses a **Sliding Window** to send multiple packets before waiting for acknowledgements.

```text
Packet 1

Packet 2

Packet 3

Packet 4

Packet 5

↓

ACK
```

This greatly improves network performance.

---

# 📈 Flow Control

Suppose the server becomes busy.

Instead of overwhelming it, TCP allows the receiver to advertise a smaller receive window.

This mechanism slows the sender until the receiver is ready again.

---

# 🚦 Congestion Control

TCP also protects the network itself.

If routers begin dropping packets due to congestion:

* TCP reduces its transmission rate
* Gradually increases it again
* Avoids flooding the network

Algorithms such as **Slow Start** and **Congestion Avoidance** implement this behaviour.

---

# 🐧 Linux TCP Stack

When a packet reaches your EC2 instance, Linux processes it before Spring Boot.

```text
NIC Driver
      │
      ▼
Ethernet
      │
      ▼
IP Layer
      │
      ▼
TCP Layer
      │
      ▼
Socket Buffer
      │
      ▼
Tomcat
      │
      ▼
Spring Boot
```

The Linux kernel performs:

* Packet validation
* Checksum verification
* Routing
* Socket lookup
* Buffer management

Only then is the request delivered to Tomcat.

---

# 🐳 Docker Networking

Docker does not replace TCP/IP.

Instead it introduces additional networking components:

* Bridge networks
* veth pairs
* Network namespaces
* NAT
* iptables

The underlying TCP/IP protocol remains unchanged.

---

# ☸️ Kubernetes Networking

Kubernetes builds on top of TCP/IP by adding:

* Pods
* Services
* kube-proxy
* Ingress
* CoreDNS
* CNI plugins

Even in Kubernetes, every HTTP request ultimately becomes:

```text
HTTP

↓

TCP

↓

IP

↓

Ethernet

↓

Linux Kernel

↓

Application
```

---

# 🧪 Hands-on Lab

View network interfaces:

```bash
ip addr
```

View routing table:

```bash
ip route
```

List listening TCP sockets:

```bash
ss -ltn
```

Display active TCP connections:

```bash
ss -tan
```

Capture traffic:

```bash
sudo tcpdump -i any port 8080
```

Generate a request:

```bash
curl http://localhost:8080/students/1051110244
```

Observe the packets arriving while your Spring Boot application processes the request.

---

# 💡 Key Takeaways

✅ TCP/IP is the protocol suite used by the Internet.

✅ IP identifies machines.

✅ Ports identify applications.

✅ TCP provides reliable communication.

✅ Sequence numbers ensure ordered delivery.

✅ Acknowledgements confirm successful reception.

✅ Sliding windows improve throughput.

✅ Flow control and congestion control protect both the receiver and the network.

✅ Linux implements TCP/IP before Tomcat receives the request.

---

# ➡️ Next Chapter

📘 **02-Network/03-TCP-Handshake.md**

In the next chapter we'll examine the TCP three-way handshake in detail.

You'll learn:

* 🤝 SYN
* 🤝 SYN-ACK
* 🤝 ACK
* 🔌 `socket()`
* 📌 `bind()`
* 👂 `listen()`
* 🤲 `accept()`
* 🧵 How Tomcat receives new connections
* 🐧 Linux socket states
* 🔬 Live packet captures using `tcpdump`
* 📊 Connection monitoring with `ss`

By the end of the chapter you'll understand exactly how a browser establishes a TCP connection before sending the first HTTP request.
