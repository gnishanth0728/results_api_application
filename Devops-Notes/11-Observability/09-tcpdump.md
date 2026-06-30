📘 Chapter 101 — Linux tcpdump

📂 File: student-results-api-notes/11-Observability/09-tcpdump.md

🌍 Introduction

In the previous chapter, we learned about strace, which traces system calls made by a process.

But another important question appears:

🤔 What happens after the kernel sends data to the network?

Suppose your Student Results API receives:

GET /students/1051110001

The request becomes:

Browser
    ↓
TCP Socket
    ↓
Linux Kernel
    ↓
Network Interface
    ↓
Ethernet

How can we observe those packets?

The answer is:

🌐 tcpdump

tcpdump captures packets directly from a network interface.

🎯 Learning Objectives

After completing this chapter you will understand:

📦 What tcpdump is
🌐 Ethernet Frames
📡 IP Packets
🤝 TCP Handshake
🌍 DNS Queries
🔒 HTTPS/TLS
🐳 Docker Networking
☸️ Kubernetes Networking
💾 Packet Capture Files
🔍 Production Troubleshooting
❓ What is tcpdump?

tcpdump is a packet capture tool.

It captures packets traveling through a network interface.

Unlike:

ss

which displays socket information,

tcpdump displays the actual packets.

🏗 Network Stack
Application

↓

Socket

↓

TCP

↓

IP

↓

Ethernet

↓

NIC

↓

Wire

tcpdump observes packets near the network interface.

Packet Structure

Example:

Ethernet Frame

↓

IP Packet

↓

TCP Segment

↓

HTTP Request

Each layer encapsulates the layer above it.

Listing Interfaces
tcpdump -D

Example:

eth0

lo

docker0

cni0

Choose the interface you want to monitor.

Capture All Traffic
sudo tcpdump

Packets immediately appear on the screen.

Capture on One Interface
sudo tcpdump -i eth0

Only traffic on eth0 is displayed.

Capture HTTP Traffic

Suppose Spring Boot listens on port 8080.

sudo tcpdump -i eth0 port 8080

Example output:

IP 10.0.0.2.52344 >

10.0.0.10.8080
Capture DNS
sudo tcpdump port 53

Example:

DNS Query

student-api.default.svc.cluster.local

Very useful in Kubernetes.

TCP Handshake

Capture:

sudo tcpdump tcp

Observe:

Client

↓

SYN

↓

Server

↓

SYN ACK

↓

Client

↓

ACK

This is the TCP three-way handshake.

Student Results API Example

Browser:

GET /students/1051110001

Flow:

Browser

↓

TCP

↓

Linux Kernel

↓

eth0

↓

tcpdump

Packet:

GET

/students/1051110001

If the connection uses HTTPS, the HTTP payload will be encrypted and you will instead observe the TLS handshake and encrypted application data.

Docker Example

Run:

docker network ls

Capture:

sudo tcpdump -i docker0

Observe traffic between:

Host
Docker Bridge
Containers

If you're using user-defined bridge networks, traffic may traverse a different bridge interface instead of docker0.

Kubernetes Example

Worker node:

ip link

Interfaces:

eth0

cni0

flannel.1

vxlan.calico

Capture Pod traffic:

sudo tcpdump -i cni0

or, depending on the CNI plugin:

sudo tcpdump -i flannel.1

or

sudo tcpdump -i vxlan.calico

The interface depends on the CNI implementation (Calico, Flannel, Cilium, etc.).

Capture by Host
sudo tcpdump host 10.244.1.25

Only packets to or from that IP are displayed.

Capture by Port
sudo tcpdump port 5432

Observe PostgreSQL traffic.

Similarly:

sudo tcpdump port 8080

Observe Spring Boot traffic.

Save Packet Capture
sudo tcpdump -w capture.pcap

Packets are saved instead of printed.

Later:

tcpdump -r capture.pcap

Read the capture offline.

Wireshark

Open:

capture.pcap

using:

Wireshark

You'll see:

Ethernet
IP
TCP
HTTP
DNS
TLS

decoded graphically.

Student Results API Request Flow
Browser
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
Network Interface
      │
      ▼
Linux Kernel
      │
      ▼
Socket
      │
      ▼
Tomcat
      │
      ▼
Spring Boot

tcpdump observes packets as they traverse the network interface.

Hands-on Lab
List Interfaces
tcpdump -D
Capture All Packets
sudo tcpdump

Press:

Ctrl+C

to stop.

Capture HTTP
sudo tcpdump port 8080

Visit:

http://localhost:8080

Observe packets.

Capture DNS
sudo tcpdump port 53

Run:

nslookup google.com

Observe DNS packets.

Save Capture
sudo tcpdump -w demo.pcap

Stop after generating traffic.

Read:

tcpdump -r demo.pcap
Kubernetes

Find interfaces:

ip link

Capture:

sudo tcpdump -i cni0

or the interface used by your CNI plugin.

Generate Pod traffic and observe packets.

Common Mistakes
❌ Thinking tcpdump Shows Application Logic

tcpdump shows network packets.

It does not show:

Java methods
Spring Controllers
SQL execution

For those, use:

jstack
jcmd
Application logs
Database tools
❌ Expecting HTTPS Payloads to Be Readable

HTTPS encrypts application data.

tcpdump can show:

TCP handshake
TLS handshake
Encrypted packets

It cannot decrypt HTTPS traffic by itself.

❌ Capturing the Wrong Interface

Modern systems may have:

eth0
ens160
docker0
cni0
flannel.1
vxlan.calico

Choose the interface carrying the traffic you want to inspect.

Useful Commands
Command	Purpose
tcpdump -D	List capture interfaces
sudo tcpdump	Capture all packets
sudo tcpdump -i eth0	Capture on a specific interface
sudo tcpdump port 8080	Capture traffic for a port
sudo tcpdump host <IP>	Capture traffic for a host
sudo tcpdump -w capture.pcap	Save packets to a file
tcpdump -r capture.pcap	Read a saved capture
ss vs strace vs tcpdump
Tool	Shows
ss	TCP/UDP sockets and connection state
strace	System calls between a process and the kernel
tcpdump	Packets on the network interface

Each tool observes a different layer of the system.

Complete Network Troubleshooting Flow
Browser
      │
      ▼
HTTP Request
      │
      ▼
ss
      │
      ▼
Socket
      │
      ▼
strace
      │
      ▼
send() / recv()
      │
      ▼
Linux Kernel
      │
      ▼
tcpdump
      │
      ▼
Ethernet
      │
      ▼
Network
💡 Key Takeaways

✅ tcpdump captures raw network packets directly from a network interface.

✅ It allows you to inspect Ethernet, IP, TCP, DNS, and (encrypted) TLS traffic.

✅ You can filter captures by interface, host, port, or protocol to focus on relevant traffic.

✅ Packet captures can be saved as .pcap files and analyzed later with tools such as Wireshark.

✅ tcpdump complements ss and strace by showing what actually travels across the network rather than sockets or system calls.

➡️ Next Chapter

📘 11-Observability/10-Wireshark.md

In the next chapter, we'll explore Wireshark, the graphical packet analyzer.

You'll learn:

🖥️ Opening and analyzing .pcap files
📦 Decoding Ethernet, IP, TCP, HTTP, DNS, and TLS packets
🔍 Applying display filters
📊 Following TCP streams
🌐 Analyzing Docker and Kubernetes network traffic visually
🚀 Troubleshooting real production network issues using packet captures

By the end of that chapter, you'll be able to move from raw packet captures to a complete visual understanding of network communication.
