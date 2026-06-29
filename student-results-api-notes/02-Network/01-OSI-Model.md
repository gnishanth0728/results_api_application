# 📘 Chapter 6 — OSI Model

> 📂 File: `student-results-api-notes/02-Network/01-OSI-Model.md`

---

# 🌐 Introduction

Every time you click the **Get Result** button in the Student Results application, an enormous amount of work happens before Spring Boot receives the request.

Although it appears that the browser directly communicates with your backend, the reality is very different.

The request travels through:

* ⚛️ React
* 📡 Axios
* 🌍 Browser Networking Stack
* 📦 HTTP Protocol
* 🤝 TCP Protocol
* 🌐 IP Protocol
* 🔌 Ethernet
* 💡 Physical Network
* 🐧 Linux Kernel
* 🍃 Tomcat
* ☕ Spring Boot

All of these components cooperate using one common idea:

> **Layered Communication**

The OSI Model was created to explain how this layered communication works.

Understanding the OSI model is the foundation for learning:

* TCP/IP
* Linux Networking
* Docker Networking
* Kubernetes Networking
* Cloud Networking
* Load Balancers
* Firewalls
* Reverse Proxies
* Service Meshes

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🌍 Why the OSI Model exists
* 🏗️ Layered networking
* 📦 Encapsulation
* 📤 Decapsulation
* 🌐 Application Layer
* 🔒 Presentation Layer
* 🤝 Session Layer
* 🚚 Transport Layer
* 🗺️ Network Layer
* 🔌 Data Link Layer
* ⚡ Physical Layer
* 🐧 How Linux implements these layers
* 🐳 How Docker fits into the networking stack
* ☸️ How Kubernetes builds on top of the same model

---

# ❓ Why Do We Need the OSI Model?

Imagine writing a web browser that had to know:

* HTTP
* TCP
* IP
* Ethernet
* Wi-Fi
* Fiber Optics
* Network Cards
* Switches
* Routers

Every application would have to implement every networking feature.

That would be extremely difficult.

Instead, networking is divided into layers.

Each layer performs **one responsibility** and relies on the layer below it.

This approach is known as **Separation of Concerns**, the same design principle used in your Spring Boot application's layered architecture.

---

# 🏗️ Complete OSI Model

```text
                OSI MODEL

+------------------------------------------------------+
| 7️⃣ Application Layer                               |
| HTTP HTTPS DNS FTP SMTP SSH MQTT REST GraphQL        |
+------------------------------------------------------+
| 6️⃣ Presentation Layer                              |
| JSON XML UTF-8 TLS Encryption Compression            |
+------------------------------------------------------+
| 5️⃣ Session Layer                                   |
| Authentication Session Cookies WebSocket Session     |
+------------------------------------------------------+
| 4️⃣ Transport Layer                                 |
| TCP UDP                                              |
+------------------------------------------------------+
| 3️⃣ Network Layer                                   |
| IPv4 IPv6 ICMP Routing                               |
+------------------------------------------------------+
| 2️⃣ Data Link Layer                                 |
| Ethernet Wi-Fi MAC Address ARP                       |
+------------------------------------------------------+
| 1️⃣ Physical Layer                                  |
| Copper Fiber Radio Signals                           |
+------------------------------------------------------+
```

The data moves from Layer 7 down to Layer 1 when sending a request and from Layer 1 back to Layer 7 when receiving it.

---

# 📦 Our Student Results Request

When you search for a student:

```http
GET /students/1051110244 HTTP/1.1
```

the request travels through every OSI layer.

```text
👨‍🎓 User
      │
      ▼
⚛️ React UI
      │
      ▼
7️⃣ HTTP Request
      │
      ▼
4️⃣ TCP Segment
      │
      ▼
3️⃣ IP Packet
      │
      ▼
2️⃣ Ethernet Frame
      │
      ▼
1️⃣ Electrical Signal
      │
~~~~~~~~ Internet / Network ~~~~~~~~
      │
      ▼
1️⃣ Electrical Signal
      │
      ▼
2️⃣ Ethernet Frame
      │
      ▼
3️⃣ IP Packet
      │
      ▼
4️⃣ TCP Segment
      │
      ▼
7️⃣ HTTP Request
      │
      ▼
🐧 Linux Kernel
      │
      ▼
🍃 Tomcat
      │
      ▼
☕ Spring Boot
```

Notice that **HTTP never travels directly over the wire**.

It is wrapped by multiple lower-layer protocols before reaching the network.

---

# 🎯 Layer 7 — Application Layer

The Application Layer is the only layer most software developers work with directly.

Examples include:

* HTTP
* HTTPS
* REST APIs
* GraphQL
* FTP
* SMTP
* SSH
* DNS
* MQTT

In our project, the browser sends:

```http
GET /students/1051110244 HTTP/1.1
```

Spring Boot understands HTTP, not Ethernet frames or IP packets.

---

# 🔒 Layer 6 — Presentation Layer

This layer is responsible for representing data in a format that both systems understand.

Typical responsibilities:

* JSON serialization
* XML serialization
* Character encoding (UTF-8)
* Compression (Gzip)
* Encryption (TLS)

Example:

Your Java object:

```java
StudentResponse
```

becomes:

```json
{
  "rollNumber":1051110244,
  "firstName":"Nishanth",
  "grade":"A+",
  "result":"PASS"
}
```

before being transmitted.

---

# 🤝 Layer 5 — Session Layer

The Session Layer manages long-running conversations between two systems.

Responsibilities include:

* Session establishment
* Session maintenance
* Session termination
* Authentication sessions

Examples:

* Login sessions
* HTTPS sessions
* WebSocket sessions

Many modern frameworks combine Session Layer responsibilities into higher-level protocols.

---

# 🚚 Layer 4 — Transport Layer

This is one of the most important networking layers.

Protocols:

* TCP
* UDP

Your Spring Boot application uses **TCP**.

Responsibilities:

* Reliable delivery
* Packet ordering
* Flow control
* Retransmission
* Congestion control

Without TCP, packets could arrive out of order or never arrive at all.

---

# 🗺️ Layer 3 — Network Layer

The Network Layer determines **where packets should travel**.

Responsibilities:

* Source IP Address
* Destination IP Address
* Routing
* Packet forwarding

Example:

```text
Source IP      : 192.168.1.15
Destination IP : 172.31.27.15
```

Routers operate primarily at this layer.

---

# 🔌 Layer 2 — Data Link Layer

This layer provides communication within the local network.

Responsibilities:

* Ethernet frames
* MAC addresses
* Error detection
* Local delivery

Example MAC Address:

```text
00:15:5D:A2:4C:9B
```

Switches primarily operate at this layer.

---

# ⚡ Layer 1 — Physical Layer

This is the hardware layer.

Examples:

* Copper cables
* Fiber optics
* Wi-Fi radio signals
* Electrical signals

Everything eventually becomes a stream of binary data:

```text
1011001010101010
```

travelling through a physical medium.

---

# 📦 Encapsulation

When sending data, every layer wraps the previous layer.

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
Electrical Signal
```

Each layer adds its own header containing metadata required for the next hop.

---

# 📤 Decapsulation

On the server, the reverse process occurs.

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
Tomcat
```

Only after every lower layer removes its header does Tomcat see the HTTP request.

---

# 🐧 How Linux Fits into the OSI Model

Linux implements most of the lower networking layers.

```text
Application
      │
      ▼
HTTP
      │
──────── User Space ────────
      │
──────── Kernel Space ──────
      ▼
TCP
      ▼
IP
      ▼
Ethernet
      ▼
NIC Driver
      ▼
Network Card
```

The Linux kernel is responsible for processing TCP, IP, routing, sockets, and network drivers.

---

# 🐳 Docker Networking

Docker does not replace the OSI model.

Instead, it introduces additional networking components such as:

* Bridge networks
* Virtual Ethernet pairs (veth)
* Network namespaces
* NAT
* iptables

The same OSI principles still apply inside containers.

---

# ☸️ Kubernetes Networking

Kubernetes extends networking further by introducing:

* Pods
* Services
* Ingress
* CoreDNS
* kube-proxy
* CNI plugins

Even in Kubernetes, every HTTP request ultimately travels through the same OSI layers before reaching the application.

---

# 🧪 Hands-on Lab

Display network interfaces:

```bash
ip addr
```

Display routing table:

```bash
ip route
```

Display listening TCP sockets:

```bash
ss -ltn
```

Capture packets (requires tcpdump):

```bash
sudo tcpdump -i any port 8080
```

Observe your Spring Boot application while sending a request:

```bash
curl http://localhost:8080/students/1051110244
```

---

# 💡 Key Takeaways

✅ The OSI Model divides networking into seven layers.

✅ Each layer performs one responsibility.

✅ HTTP operates at the Application Layer.

✅ TCP provides reliable transport.

✅ IP provides addressing and routing.

✅ Ethernet delivers frames on the local network.

✅ Linux implements the lower networking layers before Tomcat ever sees an HTTP request.

✅ Docker and Kubernetes build on top of the same networking principles rather than replacing them.

---

# ➡️ Next Chapter

📘 **02-Network/02-TCP-IP.md**

In the next chapter we'll move from the conceptual OSI model to the protocols actually used on the Internet.

We'll study:

* 🌍 TCP/IP architecture
* 📦 Packet structure
* 🔢 Sequence numbers
* ✔️ Acknowledgements
* 🔄 Retransmissions
* 📊 Sliding windows
* 🚀 Flow control
* 🧠 Linux TCP implementation

By the end of the next chapter you'll understand how your browser reliably communicates with your Spring Boot application over the network.
