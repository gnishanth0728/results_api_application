📘 Chapter 102 — Wireshark

📂 File: student-results-api-notes/11-Observability/10-Wireshark.md

🌍 Introduction

In the previous chapter we learned:

Browser
      │
      ▼
Network Interface
      │
      ▼
tcpdump
      │
      ▼
capture.pcap

tcpdump captures packets.

But another important question appears:

🤔 How do we analyze thousands of packets efficiently?

The answer is:

🦈 Wireshark

Wireshark is a graphical packet analyzer that decodes and visualizes network traffic.

🎯 Learning Objectives

After completing this chapter you will understand:

🦈 What Wireshark is
📦 Opening PCAP files
🌐 Ethernet Analysis
📡 IP Analysis
🤝 TCP Analysis
🌍 DNS Analysis
🌐 HTTP Analysis
🔒 TLS Analysis
🐳 Docker Packet Analysis
☸️ Kubernetes Packet Analysis
❓ What is Wireshark?

Wireshark is a GUI application used to inspect network packets.

Unlike:

tcpdump

which prints packets,

Wireshark provides:

Protocol decoding
Packet coloring
Packet filtering
TCP stream reconstruction
Graphs
Statistics
Timing analysis
Architecture
Browser
     │
     ▼
Network Interface
     │
     ▼
tcpdump
     │
     ▼
capture.pcap
     │
     ▼
Wireshark
Opening a Capture

Create capture:

sudo tcpdump -w student-api.pcap

Open:

File

↓

Open

↓

student-api.pcap

Wireshark immediately displays decoded packets.

Wireshark Layout
+-----------------------------------------+
| Packet List                             |
+-----------------------------------------+
| Packet Details                          |
+-----------------------------------------+
| Packet Bytes                            |
+-----------------------------------------+
Packet List

Shows:

Packet Number
Time
Source
Destination
Protocol
Length
Information

Example:

1

10.0.0.5

10.0.0.8

TCP

SYN
Packet Details

Expand:

Ethernet

↓

IPv4

↓

TCP

↓

HTTP

Every protocol layer becomes visible.

Packet Bytes

Displays the raw packet in:

Hexadecimal
ASCII

Exactly as transmitted on the wire.

Understanding Encapsulation

Suppose:

GET /students/1051110001

Packet:

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

Wireshark lets you expand every layer independently.

Ethernet Layer

Expand:

Ethernet II

Observe:

Source MAC
Destination MAC
EtherType

Example:

Src:

00:11:22:33

Dst:

44:55:66:77
IP Layer

Expand:

Internet Protocol Version 4

Observe:

Source IP
Destination IP
TTL
Header Length
Fragmentation
DSCP

Example:

10.244.1.25

↓

10.244.2.16
TCP Layer

Expand:

Transmission Control Protocol

Observe:

Source Port
Destination Port
Sequence Number
Acknowledgment Number
Window Size
Flags

Example:

SYN

ACK

PSH

FIN
HTTP Layer

Example:

GET /students/1051110001

Expand:

Hypertext Transfer Protocol

Observe:

Method
URL
Headers
Cookies
User-Agent
Response Code
DNS Analysis

Example:

student-api.default.svc.cluster.local

Observe:

Query

↓

Answer

↓

IP Address

DNS troubleshooting becomes very simple.

TLS Analysis

For HTTPS you'll see:

TLS

↓

Client Hello

↓

Server Hello

↓

Certificate

↓

Encrypted Data

HTTP payload is encrypted.

Display Filters

One of Wireshark's most powerful features.

HTTP only:

http

DNS only:

dns

TCP only:

tcp

HTTPS:

tls

Port:

tcp.port == 8080

Host:

ip.addr == 10.244.1.25
Follow TCP Stream

Right-click:

TCP Packet

↓

Follow

↓

TCP Stream

Wireshark reconstructs the entire conversation.

Instead of individual packets you see:

GET /students

↓

HTTP/1.1 200 OK

This is extremely useful when debugging APIs.

Student Results API Example

Browser:

GET /students/1051110001

Wireshark shows:

DNS Query

↓

TCP Handshake

↓

HTTP GET

↓

HTTP 200

↓

FIN

You can observe the entire request lifecycle.

Docker Example

Capture:

sudo tcpdump -i docker0 -w docker.pcap

Open:

docker.pcap

Observe:

Container IPs
HTTP traffic
Database traffic
Kubernetes Example

Capture:

sudo tcpdump -i cni0 -w pod.pcap

or on the interface used by your CNI plugin.

Open:

pod.pcap

Observe:

Pod IPs
Service communication
DNS lookups
Overlay traffic (VXLAN, Geneve, etc., depending on the CNI)
Statistics

Wireshark provides:

Statistics

↓

Protocol Hierarchy

Displays:

TCP %
UDP %
HTTP %
DNS %

Very useful for understanding traffic composition.

Endpoints
Statistics

↓

Endpoints

Shows:

IP addresses
MAC addresses
Packet counts
Bytes transferred
Conversations
Statistics

↓

Conversations

Displays:

Client

↓

Server

↓

Packets

↓

Bytes

Useful for identifying the busiest connections.

IO Graph
Statistics

↓

IO Graph

Shows:

Packets/sec
Bandwidth
Traffic spikes

Excellent for performance analysis.

Hands-on Lab
Capture Traffic
sudo tcpdump -w demo.pcap

Generate application traffic.

Open in Wireshark
File

↓

Open

↓

demo.pcap
Filter HTTP
http

Observe requests.

Filter DNS
dns

Observe name resolution.

Filter TCP
tcp

Observe handshakes.

Follow TCP Stream

Right-click any HTTP packet.

Choose:

Follow

↓

TCP Stream

Read the complete request and response.

View Protocol Hierarchy
Statistics

↓

Protocol Hierarchy

Observe protocol distribution.

Common Mistakes
❌ Thinking Wireshark Captures Traffic

Wireshark can capture packets itself, but in production it's common to:

tcpdump

↓

PCAP

↓

Wireshark

This allows packet capture on remote servers while analysis happens on your workstation.

❌ Expecting HTTPS Contents to Be Visible

Without decryption keys:

You'll see:

TCP
TLS

You won't see:

JSON payloads
HTTP headers
REST bodies

because the application data is encrypted.

❌ Filtering Instead of Capturing

Remember:

Capture filters reduce what gets recorded.
Display filters only change what you see after packets have been captured.
Useful Display Filters
Filter	Purpose
http	HTTP packets
dns	DNS traffic
tcp	TCP packets
udp	UDP packets
tls	TLS traffic
tcp.port == 8080	Traffic on port 8080
ip.addr == 10.244.1.25	Traffic to or from a specific IP
tcpdump vs Wireshark
tcpdump	Wireshark
Command-line	Graphical interface
Packet capture	Packet analysis and capture
Lightweight	Rich protocol decoding
Excellent for servers	Excellent for detailed investigation
Saves PCAP files	Opens and analyzes PCAP files
Complete Networking Debugging Flow
Browser
      │
      ▼
HTTP Request
      │
      ▼
Socket
      │
      ▼
ss
      │
      ▼
System Calls
      │
      ▼
strace
      │
      ▼
Linux Kernel
      │
      ▼
Network Interface
      │
      ▼
tcpdump
      │
      ▼
PCAP File
      │
      ▼
Wireshark
      │
      ▼
Protocol Analysis
💡 Key Takeaways

✅ Wireshark is the industry-standard graphical network protocol analyzer.

✅ It decodes protocols such as Ethernet, IP, TCP, HTTP, DNS, and TLS into a human-readable format.

✅ Display filters allow you to quickly isolate specific traffic without modifying the captured data.

✅ Features like Follow TCP Stream, Protocol Hierarchy, Endpoints, and Conversations make troubleshooting much easier than reading raw packet dumps.

✅ A common production workflow is to capture packets with tcpdump on the server and analyze the resulting .pcap file with Wireshark on a workstation.

➡️ Next Chapter

📘 11-Observability/11-Complete-Debugging-Workflow.md

In the final chapter of the Observability section, you'll combine everything you've learned into a single end-to-end troubleshooting methodology.

You'll walk through real production incidents such as:

🚀 Spring Boot application is slow
💾 Java process is consuming excessive memory
🌐 API is unreachable
🗄️ Database connection failures
☸️ Kubernetes Pod is repeatedly restarting
🐳 Docker container starts but doesn't respond

By the end, you'll know which tool to use first, second, and third, and you'll have a complete debugging workflow spanning Linux, JVM, Docker, and Kubernet
