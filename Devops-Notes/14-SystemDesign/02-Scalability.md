📘 Chapter 118 — Scalability

📂 File: student-results-api-notes/14-SystemDesign/02-Scalability.md

🌍 Introduction

In the previous chapter we learned what System Design is.

Now we focus on one of its most important goals:

📈 Scalability

Scalability answers one question:

Can the system continue serving users as demand grows?

A scalable system should be able to increase capacity while maintaining acceptable performance.

🎯 Learning Objectives

After completing this chapter you will understand:

📈 What Scalability is
⬆️ Vertical Scaling
➡️ Horizontal Scaling
⚖️ Load Balancing
🌍 Stateless Applications
💾 Stateful Applications
☸️ Kubernetes Scaling
🗄 Database Scaling
🍃 Student Results API Evolution
❓ What is Scalability?

Scalability is the ability of a system to handle increasing workload by adding resources.

Example:

100 Users

↓

10,000 Users

↓

1 Million Users

The goal is to continue serving requests efficiently as demand increases.

Small System

Initially:

Browser
      │
      ▼
Spring Boot
      │
      ▼
PostgreSQL

Works well for:

100 Users
Traffic Growth

Eventually:

100,000 Users

Problems appear:

High CPU
High memory usage
Slow database queries
Long response times
Request timeouts

Now the architecture must evolve.

Vertical Scaling

Vertical scaling means increasing the resources of a single machine.

Example:

4 CPU

↓

8 CPU

↓

16 CPU

Memory:

8 GB

↓

32 GB

↓

128 GB

Advantages:

Simple
No application changes in many cases

Limitations:

Hardware limits
Higher cost at larger sizes
Single point of failure
Vertical Scaling Example
Browser
      │
      ▼
Large Server
      │
      ▼
Spring Boot
      │
      ▼
PostgreSQL

The server becomes more powerful, but there is still only one instance.

Horizontal Scaling

Instead of making one server larger:

1 Server

↓

2 Servers

↓

10 Servers

Traffic is distributed among multiple instances.

Horizontal Scaling Example
Browser
      │
      ▼
Load Balancer
      │
 ┌────┴────┐
 ▼         ▼
App-1    App-2
      │
      ▼
PostgreSQL

The load balancer distributes requests.

Student Results API Example

Version 1:

1 Spring Boot

↓

100 Users

Version 2:

4 Spring Boot Pods

↓

10,000 Users

Traffic is shared across the Pods.

Why Horizontal Scaling?

Advantages:

Higher availability
Better fault tolerance
Easier rolling deployments
Elastic scaling
No dependence on a single server
Load Balancer

A load balancer receives requests and forwards them to application instances.

Client
      │
      ▼
Load Balancer
      │
 ┌────┼────┐
 ▼    ▼    ▼
App1 App2 App3

Common algorithms:

Round Robin
Least Connections
IP Hash
Weighted Round Robin
Stateless Applications

A stateless application keeps no user-specific request state in local memory between requests.

Example:

Request

↓

Process

↓

Response

The next request can be served by any instance.

This makes horizontal scaling straightforward.

Stateful Applications

A stateful application stores important state locally.

Example:

Session

↓

Stored In Server Memory

Now:

Request 1

↓

App-1

Request 2:

App-2

↓

Session Missing

Without shared session storage or sticky sessions, the request may fail.

Stateless vs Stateful
Stateless	Stateful
Easier to scale horizontally	Harder to scale
Any server can process requests	Requests may depend on a specific server
Preferred for REST APIs	Common for databases and some legacy applications
Kubernetes Scaling

Deployment:

Replicas

↓

2

Traffic increases.

HPA scales:

2

↓

5

↓

10 Pods

The Service distributes requests across the available Pods.

Kubernetes Architecture
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
Pod-1    Pod-2
Database Scaling

Scaling the application is often easier than scaling the database.

Options include:

Read replicas
Partitioning (sharding)
Caching
Query optimization

Example:

Application

↓

Redis

↓

Primary Database

The cache reduces database load.

Read Replicas
Application
      │
      ▼
Primary Database
      │
 ┌────┴────┐
 ▼         ▼
Replica1 Replica2

Typical pattern:

Writes → Primary
Reads → Replicas
Capacity Planning

Estimate:

Users
Requests per second
Storage
Bandwidth
Peak traffic

Example:

10,000 Users

↓

500 Requests/sec

These estimates guide scaling decisions.

Scaling Workflow
Traffic Increases
        │
        ▼
Measure
        │
        ▼
Identify Bottleneck
        │
        ▼
Scale Application
        │
        ▼
Scale Database
        │
        ▼
Retest

Scaling should be based on measurements, not guesses.

Student Results API Evolution
Stage 1
Browser

↓

Spring Boot

↓

PostgreSQL
Stage 2
Browser

↓

Load Balancer

↓

2 Pods

↓

PostgreSQL
Stage 3
Browser

↓

Load Balancer

↓

8 Pods

↓

Redis

↓

PostgreSQL
Stage 4
Browser

↓

CDN

↓

Load Balancer

↓

Application Pods

↓

Redis

↓

Kafka

↓

PostgreSQL Cluster

The architecture evolves as demand grows.

Hands-on Lab
Check Pod Count
kubectl get pods
Scale Deployment
kubectl scale deployment student-api \
--replicas=5
Verify
kubectl get pods

Confirm that five Pods are running.

Generate Load
ab -n 10000 -c 300 \
http://localhost:8080/students/1051110001

Observe whether CPU usage increases and whether additional Pods improve throughput.

Watch HPA
kubectl get hpa -w

If an HPA is configured, observe scaling decisions.

Common Mistakes
❌ Scaling Before Measuring

Always identify the bottleneck first.

Adding more application instances will not help if the database is already saturated.

❌ Assuming Horizontal Scaling Solves Everything

Some components—especially databases—cannot always scale horizontally as easily as stateless application servers.

❌ Storing Sessions in Application Memory

For horizontally scaled REST APIs, avoid storing client-specific session state in a single application instance.

Use stateless authentication (such as JWT) or shared session storage where appropriate.

❌ Ignoring Cost

Scaling improves capacity but also increases infrastructure costs.

Balance performance, availability, and budget.

Scalability Checklist
✓ Estimate Traffic

✓ Measure Performance

✓ Identify Bottleneck

✓ Scale Stateless Services

✓ Optimize Database

✓ Add Cache

✓ Load Balance

✓ Monitor Continuously
Vertical vs Horizontal Scaling
Vertical Scaling	Horizontal Scaling
Bigger server	More servers
Simple to implement	Better long-term scalability
Hardware limits	Can continue growing by adding instances
Single point of failure	Better fault tolerance
Limited elasticity	Works well with cloud platforms and Kubernetes
End-to-End Scalable Architecture
Users
     │
     ▼
DNS
     │
     ▼
Load Balancer
     │
     ▼
Ingress
     │
     ▼
Service
     │
 ┌────┼────┐
 ▼    ▼    ▼
Pod1 Pod2 Pod3
     │
     ▼
Redis
     │
     ▼
PostgreSQL
💡 Key Takeaways

✅ Scalability is the ability to handle increasing workload by adding resources.

✅ Vertical scaling increases the capacity of a single machine, while horizontal scaling adds more machines or application instances.

✅ Stateless applications are significantly easier to scale horizontally than stateful applications.

✅ Kubernetes supports horizontal scaling through Deployments, Services, and the Horizontal Pod Autoscaler (HPA).

✅ Effective scaling begins with measurement, bottleneck identification, and iterative optimization—not simply adding more hardware.

➡️ Next Chapter

📘 14-SystemDesign/03-LoadBalancer.md

In the next chapter, you'll learn how multiple application instances receive traffic.

Topics include:

⚖️ What a Load Balancer is
🌐 L4 vs L7 load balancing
🔄 Round Robin, Least Connections, and other algorithms
❤️ Health checks
☸️ Kubernetes Services and Ingress
🌍 Load balancing for Spring Boot applications running in production

By the end of that chapter, you'll understand how a single public endpoint can efficiently distribute millions of requests across many backend instances.
