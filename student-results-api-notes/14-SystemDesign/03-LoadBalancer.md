📘 Chapter 119 — Load Balancer

📂 File: student-results-api-notes/14-SystemDesign/03-LoadBalancer.md

🌍 Introduction

In the previous chapter we learned that horizontal scaling creates multiple application instances.

Another important question appears:

🤔 How do incoming requests get distributed among those instances?

The answer is:

⚖️ Load Balancer

A Load Balancer receives client requests and forwards them to healthy backend servers.

🎯 Learning Objectives

After completing this chapter you will understand:

⚖️ What a Load Balancer is
🌐 Why Load Balancers are Needed
🔄 Load Balancing Algorithms
❤️ Health Checks
🌍 Layer 4 vs Layer 7 Load Balancing
☸️ Kubernetes Service & Ingress
🍃 Student Results API Example
🚀 High Availability
❓ What is a Load Balancer?

A Load Balancer sits between clients and backend servers.

Instead of:

Browser

↓

Spring Boot

we have:

Browser

↓

Load Balancer

↓

Spring Boot

The client knows only the Load Balancer's address.

Why Do We Need One?

Suppose:

3 Spring Boot Servers

Without a Load Balancer:

User

↓

Server-1

Server-1 becomes overloaded while:

Server-2

Idle

Server-3

Idle

Resources are wasted.

With a Load Balancer
Browser
      │
      ▼
Load Balancer
      │
 ┌────┼────┐
 ▼    ▼    ▼
App1 App2 App3

Traffic is distributed across all healthy instances.

Student Results API Example

Suppose:

10,000 Requests/sec

The Load Balancer distributes traffic:

App-1

3,300
App-2

3,300
App-3

3,400

The exact distribution depends on the selected balancing algorithm.

Load Balancing Algorithms

Common algorithms include:

Round Robin
Least Connections
Weighted Round Robin
IP Hash

Each algorithm has different trade-offs.

Round Robin

Requests are distributed sequentially.

R1

↓

App1

R2

↓

App2

R3

↓

App3

R4

↓

App1

Advantages:

Simple
Even distribution when servers have similar capacity
Least Connections

The Load Balancer forwards the next request to the server handling the fewest active connections.

Example:

App1

50 Connections
App2

12 Connections

Next request:

App2

Useful when requests vary significantly in duration.

Weighted Round Robin

Suppose:

App1

Weight 2
App2

Weight 1

Traffic:

App1

66%
App2

34%

Larger servers can receive more requests.

IP Hash

Requests from the same client IP are consistently routed to the same backend.

Example:

192.168.1.20

↓

App2

Useful in some scenarios involving session affinity, although stateless applications often do not require it.

Health Checks

A Load Balancer should not send traffic to unhealthy servers.

Health check:

GET /actuator/health

Healthy:

200 OK

Unhealthy:

503

The Load Balancer temporarily removes unhealthy instances from rotation until they recover.

Failure Scenario
App1

Down

Without health checks:

User

↓

App1

↓

Failure

With health checks:

User

↓

App2

Users continue to receive successful responses.

Layer 4 Load Balancer

Works at the transport layer.

TCP

↓

Backend

Decisions are typically based on:

IP address
TCP/UDP port

Examples include cloud network load balancers.

Layer 7 Load Balancer

Works at the application layer.

HTTP

↓

Path

↓

Backend

Can make routing decisions based on:

URL path
Host name
HTTP headers
Cookies
Path-Based Routing

Example:

/students

↓

Student Service
/teachers

↓

Teacher Service

One public endpoint can route requests to multiple backend services.

Kubernetes

In Kubernetes:

Browser
      │
      ▼
Ingress
      │
      ▼
Service
      │
 ┌────┴────┐
 ▼         ▼
Pod1     Pod2

The responsibilities are:

Ingress: HTTP(S) routing, TLS termination, path/host rules.
Service: Stable virtual IP and load balancing across Pods.
Kubernetes Service

Example:

kind: Service

The Service provides:

Stable ClusterIP
Pod discovery
Load balancing across matching Pods

Applications talk to the Service rather than individual Pods.

Kubernetes Ingress

Example:

results.example.com

↓

Ingress

↓

Student Service

The Ingress exposes HTTP(S) traffic to services inside the cluster.

High Availability

Suppose:

App2

Fails

Remaining servers continue serving requests.

App1

App3

High availability requires redundancy and health checking.

Complete Request Flow
Browser
      │
DNS
      │
HTTPS
      │
Load Balancer
      │
Ingress
      │
Service
      │
Pod
      │
Spring Boot
      │
Database
Hands-on Lab
Scale Deployment
kubectl scale deployment student-api \
--replicas=3
View Pods
kubectl get pods
View Service
kubectl get svc
Generate Traffic
ab -n 5000 -c 100 \
http://localhost:8080/students/1051110001

Observe traffic distribution.

Check Health
curl http://localhost:8080/actuator/health

Verify the application reports its health correctly.

Common Mistakes
❌ Assuming More Servers Automatically Improve Performance

If the bottleneck is:

Database
Cache
External API

adding more application instances may not improve throughput.

❌ Ignoring Health Checks

A Load Balancer without health checks may continue sending traffic to failed servers.

❌ Using Sticky Sessions Unnecessarily

Stateless applications using JWT generally do not require sticky sessions, making horizontal scaling simpler.

❌ Confusing Service and Ingress

In Kubernetes:

Service load-balances traffic to Pods.
Ingress exposes HTTP(S) applications and performs routing based on hosts and paths.

They solve different problems.

Load Balancer Checklist
✓ Multiple Application Instances

✓ Load Balancer

✓ Health Checks

✓ Routing Algorithm

✓ Stateless Application

✓ HTTPS

✓ Monitoring

✓ Auto Scaling
Layer 4 vs Layer 7
Layer 4	Layer 7
Operates on TCP/UDP	Operates on HTTP/HTTPS
Routes using IP and port	Routes using URL, host, headers, cookies
Faster, less protocol-aware	More flexible routing
Cannot inspect HTTP paths	Supports path- and host-based routing
Common Load Balancer Products
Product	Typical Use
NGINX	Reverse proxy and Layer 7 load balancer
HAProxy	High-performance Layer 4/7 load balancing
Envoy	Service mesh and modern proxy
AWS Application Load Balancer (ALB)	Managed Layer 7 load balancer
AWS Network Load Balancer (NLB)	Managed Layer 4 load balancer
Kubernetes Ingress Controller	HTTP(S) routing into Kubernetes
💡 Key Takeaways

✅ A Load Balancer distributes client requests across multiple backend instances.

✅ Health checks ensure traffic is sent only to healthy servers.

✅ Different algorithms such as Round Robin and Least Connections distribute traffic in different ways.

✅ Layer 4 load balancers route based on transport-layer information, while Layer 7 load balancers understand HTTP and can perform advanced routing.

✅ In Kubernetes, the Service balances traffic across Pods, while the Ingress provides external HTTP(S) access and routing.

➡️ Next Chapter

📘 14-SystemDesign/04-Caching.md

In the next chapter, you'll learn one of the biggest performance optimizations used in large-scale systems:

⚡ Why caching is essential
🧠 Cache hit vs cache miss
🔴 Redis architecture
⏱️ TTL (Time-To-Live)
🔄 Cache invalidation strategies
☸️ Using Redis with Spring Boot and Kubernetes

By the end of that chapter, you'll understand how systems reduce database load and achieve millisecond response times using caching.
