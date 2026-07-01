# Complete Journey of One HTTP Request

> This document explains how a request travels through a Spring Boot application running:
>
> - Bare Metal / Virtual Machine
> - Docker Container
> - Kubernetes Pod

---

# Table of Contents

1. Bare Metal / VM
2. Docker
3. Kubernetes
4. Architecture Comparison
5. Docker Networking
6. Kubernetes Networking
7. Key Takeaways
8. Observability
9. Useful Commands

---

# 1. Bare Metal / VM

```mermaid
flowchart TD
A[Browser / React UI] --> B[Axios HTTP Request]
B --> C[TCP Socket]
C --> D[Linux TCP/IP Stack]
D --> E[Internet]
E --> F[Linux Network Stack]
F --> G[Port 8080]
G --> H[Java Process]
H --> I[Embedded Tomcat]
I --> J[DispatcherServlet]
J --> K[Controller]
K --> L[Service]
L --> M[Repository]
M --> N[Hibernate JPA]
N --> O[HikariCP]
O --> P[(PostgreSQL)]
P --> Q[DTO → JSON]
Q --> R[HTTP Response]
```

## Flow

1. Browser sends HTTP request.
2. Linux TCP/IP stack creates TCP connection.
3. Tomcat accepts the connection.
4. DispatcherServlet routes the request.
5. Controller calls Service.
6. Service calls Repository.
7. Hibernate executes SQL.
8. PostgreSQL returns rows.
9. Response is converted to JSON.

---

# 2. Docker

```mermaid
flowchart TD
A[Browser] --> B[Axios]
B --> C[TCP Socket]
C --> D[Host Network]
D --> E[Docker NAT]
E --> F[veth Pair]
F --> G[Container Network Namespace]
G --> H[Port 8080]
H --> I[Java Process PID 1]
I --> J[Embedded Tomcat]
J --> K[DispatcherServlet]
K --> L[Controller]
L --> M[Service]
M --> N[Repository]
N --> O[Hibernate]
O --> P[HikariCP]
P --> Q[(PostgreSQL)]
Q --> R[DTO → JSON]
R --> S[Response]
S --> T[Docker NAT]
T --> U[Browser]
```

## What Docker Adds

- Container isolation
- Network namespace
- veth pair
- Bridge networking
- Port publishing (NAT)
- Overlay filesystem

---

# 3. Kubernetes

```mermaid
flowchart TD
A[Browser]
-->B[Ingress / LoadBalancer]
-->C[Service]
-->D[kube-proxy]
-->E[CNI Network]
-->F[Pod IP]
-->G[Container Port 8080]
-->H[Java Process]
-->I[Embedded Tomcat]
-->J[DispatcherServlet]
-->K[Controller]
-->L[Service]
-->M[Repository]
-->N[Hibernate]
-->O[HikariCP]
-->P[(PostgreSQL Service)]
-->Q[(PostgreSQL Pod)]
-->R[DTO → JSON]
-->S[Response]
-->T[Service]
-->U[Ingress]
-->V[Browser]
```

## What Kubernetes Adds

- Ingress
- Service discovery
- kube-proxy
- CNI networking
- Pod abstraction
- Scheduling
- Self-healing
- Rolling updates

---

# 4. Architecture Comparison

| Feature | Bare Metal | Docker | Kubernetes |
|---------|------------|---------|------------|
| Isolation | Process | Container | Pod |
| Networking | Linux | Bridge + NAT | CNI + Service |
| Scaling | Manual | Manual | Automatic |
| Self Healing | No | No | Yes |
| Load Balancing | External | External | Built-in |
| Deployment | Manual | Docker | Declarative YAML |

---

# 5. Docker Networking

```mermaid
flowchart LR
Browser --> Host --> iptables --> DockerBridge --> veth --> Container --> SpringBoot
```

---

# 6. Kubernetes Networking

```mermaid
flowchart LR
Internet --> Ingress --> Service --> kubeProxy[kube-proxy] --> Pod --> Container --> SpringBoot --> PostgreSQL
```

---

# 7. Key Takeaways

- Application code remains unchanged across environments.
- Docker provides portability and isolation.
- Kubernetes provides orchestration.
- Services provide stable networking.
- Pods provide execution environments.
- Ingress exposes applications externally.

---

# 8. Observability

## Application

- Micrometer
- Prometheus
- Logs
- Traces

## System

- CPU
- Memory
- Disk
- Network

## Database

- pg_stat_activity
- Slow queries
- Locks

---

# 9. Useful Commands

## Linux

```bash
ps -ef
top
ss -ltnp
lsof -i
```

## Docker

```bash
docker ps
docker logs <container>
docker exec -it <container> bash
docker inspect <container>
```

## Kubernetes

```bash
kubectl get pods -o wide
kubectl describe pod <pod>
kubectl logs <pod>
kubectl exec -it <pod> -- bash
kubectl get svc
kubectl get ingress
```

---

# Summary

Bare Metal focuses on operating system processes.

Docker adds container isolation, networking, and portability.

Kubernetes orchestrates containers using Pods, Services, Ingress, scheduling, and self-healing while keeping the application code unchanged.
