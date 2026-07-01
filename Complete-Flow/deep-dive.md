# Complete Flow of One HTTP Request — End-to-End Deep Dive

> GitHub-native version of the architecture poster using Mermaid diagrams and Markdown.

## Table of Contents

1. Architecture Overview
2. React UI & Browser
3. HTTP Protocol
4. Internet & Network Path
5. Linux Network Stack
6. Socket & Port
7. Linux Process
8. JVM Internals
9. Embedded Tomcat
10. Spring MVC
11. Hibernate (JPA)
12. JDBC & HikariCP
13. PostgreSQL Internals
14. Response & JSON
15. Docker Deep Dive
16. Kubernetes Architecture
17. Kubernetes Request Flow
18. Pod Internals
19. Load Testing & Observability
20. Bare Metal vs Docker vs Kubernetes

---

# 1. Architecture Overview

```mermaid
flowchart LR
Browser-->HTTP
HTTP-->Internet
Internet-->Linux
Linux-->Socket
Socket-->Java
Java-->Tomcat
Tomcat-->DispatcherServlet
DispatcherServlet-->Controller
Controller-->Service
Service-->Repository
Repository-->Hibernate
Hibernate-->HikariCP
HikariCP-->PostgreSQL
PostgreSQL-->JSON
JSON-->Browser
```

## Summary

- Browser issues HTTP request.
- Linux TCP/IP receives packets.
- Tomcat accepts the socket.
- Spring MVC processes the request.
- Hibernate executes SQL.
- PostgreSQL returns rows.
- Jackson serializes JSON.
- Response travels back to the browser.

---

# 2. React UI & Browser

```mermaid
flowchart TD
User-->Button
Button-->React
React-->Axios
Axios-->HTTPRequest
HTTPRequest-->TCP
```

Topics:
- React event handling
- Axios
- Promise lifecycle
- Browser cache
- CORS
- Cookies
- DevTools

---

# 3. HTTP Protocol

```mermaid
flowchart LR
GET-->Headers-->Body
```

Topics:
- Methods
- Headers
- Status Codes
- Keep Alive
- Compression
- HTTP/1.1 vs HTTP/2

---

# 4. Internet & Network Path

```mermaid
flowchart LR
Browser-->Router-->ISP-->Internet-->Cloud-->Server
```

Topics:
- DNS
- Routing
- Public IP
- NAT
- TCP

---

# 5. Linux Network Stack

```mermaid
flowchart TD
NIC-->Ethernet-->IP-->TCP-->Socket
```

Topics:
- Kernel
- NIC
- Buffers
- Checksums
- TCP receive queue

---

# 6. Socket & Port

```mermaid
flowchart TD
Socket-->Bind-->Listen-->Accept-->ReadWrite-->Close
```

Useful commands:

```bash
ss -ltnp
lsof -i
netstat -tulnp
```

---

# 7. Linux Process

```mermaid
flowchart TD
ELF-->Process-->Threads-->Heap
```

Topics:
- PID
- Memory layout
- Threads
- File descriptors

---

# 8. JVM Internals

```mermaid
flowchart TD
Heap-->Young
Heap-->Old
Metaspace
Stack
```

---

# 9. Embedded Tomcat

```mermaid
flowchart TD
Acceptor-->Poller-->Worker
```

---

# 10. Spring MVC

```mermaid
flowchart TD
DispatcherServlet-->HandlerMapping-->Controller-->Service-->Repository
```

---

# 11. Hibernate

```mermaid
flowchart TD
Entity-->PersistenceContext-->SQL
```

---

# 12. JDBC & HikariCP

```mermaid
flowchart TD
Application-->HikariCP-->JDBC-->Database
```

---

# 13. PostgreSQL Internals

```mermaid
flowchart LR
Parser-->Planner-->Executor-->Disk
```

---

# 14. Response & JSON

```mermaid
flowchart LR
Entity-->DTO-->Jackson-->JSON-->Browser
```

---

# 15. Docker Deep Dive

```mermaid
flowchart TD
Host-->DockerEngine-->Container-->SpringBoot
```

Topics:
- Namespaces
- cgroups
- OverlayFS
- Bridge
- veth
- iptables

---

# 16. Kubernetes Architecture

```mermaid
flowchart LR
API_Server-->Scheduler
API_Server-->Controller
Scheduler-->Node
Node-->Pod
Pod-->Container
```

---

# 17. Kubernetes Request Flow

```mermaid
flowchart LR
Client-->Ingress-->Service-->kubeProxy[kube-proxy]-->Pod-->Container
```

---

# 18. Pod Internals

```mermaid
flowchart TD
Pod-->Pause
Pause-->App1
Pause-->App2
```

---

# 19. Load Testing & Observability

```mermaid
flowchart LR
ApacheBench-->SpringBoot-->Prometheus-->Grafana
```

Observe:
- CPU
- Memory
- Network
- Disk
- JVM
- PostgreSQL

---

# 20. Bare Metal vs Docker vs Kubernetes

| Feature | Bare Metal | Docker | Kubernetes |
|---|---|---|---|
| Isolation | Process | Container | Pod |
| Networking | Host | Bridge | CNI |
| Scaling | Manual | Manual | Auto |
| Self Healing | No | No | Yes |
| Scheduling | No | No | Yes |
| Load Balancing | External | External | Built-in |

---

# Useful Commands

## Linux

```bash
ps -ef
top
vmstat
iostat
ss -ltnp
```

## Docker

```bash
docker ps
docker logs
docker exec -it
docker inspect
```

## Kubernetes

```bash
kubectl get pods -o wide
kubectl describe pod
kubectl logs
kubectl exec -it
kubectl get svc
kubectl get ingress
```

---
