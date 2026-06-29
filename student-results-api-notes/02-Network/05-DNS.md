# 📘 Chapter 10 — DNS (Domain Name System)

> 📂 File: `student-results-api-notes/02-Network/05-DNS.md`

---

# 🌍 Introduction

Imagine opening your Student Results application and visiting:

```text
http://student-api.example.com:8080/students/1051110244
```

The browser immediately knows the domain name:

```text
student-api.example.com
```

But computers **cannot communicate using domain names**.

Networking protocols such as TCP and IP require an **IP address**.

So before the browser can:

* 🤝 Start a TCP handshake
* 📨 Send an HTTP request
* 🍃 Reach Tomcat

it must answer one question:

> **What IP address belongs to `student-api.example.com`?**

The system responsible for answering this question is **DNS (Domain Name System)**.

DNS is often described as the **phone book of the Internet**.

It converts human-friendly names into machine-friendly IP addresses.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🌍 Why DNS exists
* 🏗️ DNS Architecture
* 📖 Domain Name Structure
* 🧠 Browser DNS Cache
* 🐧 Linux DNS Resolver
* 📄 `/etc/hosts`
* 🌐 Recursive DNS Resolver
* 🌎 Root DNS Servers
* 📂 TLD DNS Servers
* 🏢 Authoritative DNS Servers
* 📦 DNS Records
* ⏱️ TTL (Time To Live)
* 🐳 Docker Embedded DNS
* ☸️ Kubernetes CoreDNS
* 🧪 DNS Debugging

---

# ❓ Why Do We Need DNS?

Imagine trying to remember the IP address of every website you visit.

Instead of:

```text
google.com
```

you would need to remember something like:

```text
142.250.72.14
```

And instead of:

```text
student-api.example.com
```

you would have to remember:

```text
50.17.121.255
```

Humans are good at remembering names.

Computers communicate using IP addresses.

DNS bridges that gap.

---

# 🏗️ High-Level DNS Architecture

```text
                    🌍 DNS Architecture

        👨‍🎓 User
              │
              ▼
      🌐 Browser
              │
              ▼
      🧠 Browser DNS Cache
              │
              ▼
      🐧 Linux Resolver
              │
              ▼
     📄 /etc/hosts File
              │
              ▼
    🌐 Recursive DNS Resolver
              │
              ▼
      🌎 Root DNS Server
              │
              ▼
       📂 TLD DNS Server
              │
              ▼
   🏢 Authoritative DNS Server
              │
              ▼
      📦 IP Address
              │
              ▼
      🌐 Browser
```

---

# 🏠 Step 1 — Browser Cache

The browser first checks its internal DNS cache.

```text
Chrome

↓

DNS Cache

↓

Found?

↓

Yes → Done

No → Continue
```

Modern browsers cache DNS responses to avoid unnecessary network requests.

---

# 🐧 Step 2 — Operating System Cache

If the browser cache misses, the operating system checks its DNS cache.

Linux may already know the answer.

```text
Browser

↓

Linux DNS Cache

↓

Found?

↓

Yes

↓

Return IP
```

---

# 📄 Step 3 — `/etc/hosts`

Before contacting any DNS server, Linux checks the local hosts file.

Location:

```bash
/etc/hosts
```

Example:

```text
127.0.0.1 localhost

50.17.121.255 student-api.example.com
```

If a matching entry exists, **DNS is skipped entirely**.

This file is commonly used for:

* Local development
* Testing
* Internal environments

---

# 🌐 Step 4 — Recursive Resolver

If the hostname is not found locally, Linux sends a DNS query to a recursive resolver.

Example:

```text
8.8.8.8
```

(Google Public DNS)

or

```text
1.1.1.1
```

(Cloudflare DNS)

The recursive resolver performs the rest of the lookup on behalf of the client.

---

# 🌎 Step 5 — Root DNS Servers

The recursive resolver asks a Root DNS server:

> "Who knows about `.com`?"

The Root server does **not** know the IP address.

Instead it replies:

```text
Ask the .com DNS servers.
```

---

# 📂 Step 6 — TLD DNS Servers

The recursive resolver then asks the `.com` Top-Level Domain (TLD) server:

> "Who knows about `example.com`?"

The TLD server responds with the Authoritative DNS server responsible for that domain.

---

# 🏢 Step 7 — Authoritative DNS Server

The recursive resolver finally asks:

```text
student-api.example.com
```

The Authoritative server returns:

```text
50.17.121.255
```

This is the definitive answer for the domain.

---

# 📦 Step 8 — IP Address Returned

The recursive resolver sends the IP address back to Linux.

Linux returns it to the browser.

Now the browser finally knows:

```text
student-api.example.com

↓

50.17.121.255
```

Only now can the TCP handshake begin.

---

# 🔄 Complete DNS Resolution Flow

```text
Browser
   │
   ▼
Browser Cache
   │
   ▼
Linux DNS Cache
   │
   ▼
/etc/hosts
   │
   ▼
Recursive Resolver
   │
   ▼
Root DNS
   │
   ▼
TLD DNS
   │
   ▼
Authoritative DNS
   │
   ▼
IP Address
   │
   ▼
TCP Handshake
   │
   ▼
HTTP Request
```

---

# 📋 Common DNS Record Types

| Record    | Purpose           | Example                                   |
| --------- | ----------------- | ----------------------------------------- |
| **A**     | Hostname → IPv4   | `student-api.example.com → 50.17.121.255` |
| **AAAA**  | Hostname → IPv6   | `2001:db8::1`                             |
| **CNAME** | Alias             | `www.example.com → example.com`           |
| **MX**    | Mail Server       | Email routing                             |
| **TXT**   | Text Metadata     | SPF, DKIM, verification                   |
| **NS**    | Name Server       | Delegates DNS authority                   |
| **SRV**   | Service Discovery | LDAP, SIP, Kubernetes                     |

---

# ⏱️ TTL (Time To Live)

DNS responses include a TTL value.

Example:

```text
TTL = 300 seconds
```

This tells caches:

> "You may reuse this answer for the next 5 minutes."

Benefits:

* Faster browsing
* Reduced DNS traffic
* Lower latency

---

# 🐧 Linux DNS Configuration

View configured DNS servers:

```bash
cat /etc/resolv.conf
```

Example:

```text
nameserver 8.8.8.8
```

On Ubuntu systems using `systemd-resolved`:

```bash
resolvectl status
```

---

# 🐳 Docker DNS

Docker provides an embedded DNS server for containers attached to the same user-defined network.

```text
Container A

↓

Docker Embedded DNS

↓

Container B
```

This allows containers to communicate using service names instead of IP addresses.

Example:

```text
postgres
```

instead of

```text
172.18.0.3
```

---

# ☸️ Kubernetes CoreDNS

Kubernetes includes **CoreDNS**, which automatically resolves Service and Pod names.

Example:

```text
student-api.default.svc.cluster.local
```

CoreDNS returns the ClusterIP for the Service.

The application does not need to know Pod IP addresses directly.

---

# 🧪 Hands-on Lab

## Check `/etc/hosts`

```bash
cat /etc/hosts
```

---

## View DNS Servers

```bash
cat /etc/resolv.conf
```

---

## Resolve a Hostname

```bash
getent hosts localhost
```

---

## Query DNS

```bash
dig google.com
```

or

```bash
nslookup google.com
```

---

## Resolve Your EC2 Instance

```bash
dig <your-public-dns-name>
```

---

## Test Local Resolution

```bash
ping localhost
```

Observe that `localhost` resolves to `127.0.0.1` via `/etc/hosts`, without contacting external DNS servers.

---

# 🧠 Student Results API Example

When a user opens:

```text
http://student-api.example.com:8080/students/1051110244
```

the actual sequence is:

```text
URL

↓

DNS Lookup

↓

IP Address

↓

TCP Handshake

↓

HTTP GET

↓

Tomcat

↓

Spring Boot

↓

PostgreSQL

↓

JSON Response
```

DNS is the **first network step** in the request lifecycle.

---

# 💡 Key Takeaways

✅ Computers communicate using IP addresses, not domain names.

✅ DNS translates domain names into IP addresses.

✅ The browser checks its cache before querying the network.

✅ Linux checks `/etc/hosts` before contacting DNS servers.

✅ Recursive resolvers perform the lookup on behalf of clients.

✅ Root, TLD, and Authoritative DNS servers work together to resolve names.

✅ Docker provides an embedded DNS service for containers.

✅ Kubernetes uses CoreDNS for service discovery.

---

# ➡️ Next Chapter

📘 **02-Network/06-IP-Routing.md**

In the next chapter we'll follow the packet **after DNS resolution**.

You'll learn:

* 🌍 How IP routing works
* 🛣️ Routing tables
* 🚪 Default gateways
* 🌐 Routers and subnets
* 📡 AWS VPC routing
* 🐧 Linux routing decisions
* 🧪 Using `ip route`, `traceroute`, and `tracepath`

By the end of the chapter you'll understand how a packet finds its way from your browser to your Spring Boot server across local networks, routers, cloud infrastructure, and the Internet.
