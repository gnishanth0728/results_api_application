📘 Chapter 117 — System Design Fundamentals

📂 File: student-results-api-notes/14-SystemDesign/01-System-Design-Fundamentals.md

🌍 Introduction

Throughout this roadmap we've focused on building a single backend application.

Now we move to a different question:

🤔 How do we design systems that remain fast, reliable, and available as traffic grows?

System Design is the process of designing software systems that satisfy both business requirements and engineering constraints.

It answers questions such as:

How should requests flow?
Where should data be stored?
How do we scale?
How do we recover from failures?
How do we keep latency low?
🎯 Learning Objectives

After completing this chapter you will understand:

🏗 What System Design is
📋 Functional Requirements
⚙️ Non-Functional Requirements
📈 Scalability
⚖️ Availability
🔄 Reliability
🚀 Performance
🍃 Student Results API Evolution
☸️ Distributed Systems
❓ What is System Design?

System Design is the process of defining:

Architecture
Components
Data flow
Communication
Scalability strategy
Reliability strategy

for an application.

Instead of writing code, we design how the entire system should work.

Small Application

Suppose we build:

Browser
      │
      ▼
Spring Boot
      │
      ▼
PostgreSQL

For:

100 Users

This architecture is usually sufficient.

Large Application

Traffic grows:

10 Million Users

Architecture becomes:

Browser
      │
      ▼
Load Balancer
      │
      ▼
Spring Boot Pods
      │
      ▼
Redis
      │
      ▼
Kafka
      │
      ▼
PostgreSQL Cluster

Every new component solves a scaling or reliability problem.

Functional Requirements

Functional requirements describe what the system must do.

Student Results API:

Student login
Search by roll number
View marks
Download report
Teacher updates marks
Administrator manages users

If a feature changes application behavior, it is usually a functional requirement.

Non-Functional Requirements

Non-functional requirements describe how well the system must perform.

Examples:

Support 100,000 concurrent users
Response time below 200 ms
99.99% availability
Secure communication
Horizontal scalability
Disaster recovery

These requirements often drive architectural decisions.

Example

Functional:

Student Can View Results

Non-functional:

Response Time

<200 ms

The feature is the same.

The performance requirement is different.

Core Design Goals

Most distributed systems aim to balance:

Scalability

Availability

Reliability

Performance

Security

Maintainability

Improving one area can sometimes make another more difficult, so system design involves trade-offs.

Scalability

Question:

Can the system continue handling more users?

Example:

100 Users

↓

10,000 Users

↓

1 Million Users

Scalability is about increasing capacity as demand grows.

Vertical Scaling

Increase resources on one machine.

4 CPU

↓

16 CPU

↓

64 GB RAM

Advantages:

Simple

Limitations:

Hardware limits
Single point of failure
Downtime may be required for upgrades
Horizontal Scaling

Instead of making one server larger:

1 Server

↓

4 Servers

↓

20 Servers

Traffic is distributed across multiple instances.

This is the preferred approach for many cloud-native applications.

Availability

Question:

Is the system accessible when users need it?

Example:

99.99%

Availability depends on:

Redundancy
Failover
Health checks
Load balancing
Reliability

Question:

Does the system consistently produce correct results?

Example:

Student Marks

↓

Correct

Every Time

A highly available system that returns incorrect data is not reliable.

Performance

Performance focuses on:

Response time
Throughput
Resource utilization

Example:

GET /students

↓

120 ms

Performance targets should be measurable.

Maintainability

Large systems evolve over time.

Good system design makes it easier to:

Add features
Fix bugs
Upgrade components
Replace services

Clear interfaces and modular design help reduce long-term complexity.

Student Results API Evolution
Version 1
Browser

↓

Spring Boot

↓

PostgreSQL
Version 2

Traffic increases.

Browser

↓

Load Balancer

↓

2 Spring Boot Pods

↓

PostgreSQL
Version 3

Database becomes busy.

Browser

↓

Load Balancer

↓

Spring Boot

↓

Redis Cache

↓

PostgreSQL
Version 4

Background processing is added.

Browser

↓

Spring Boot

↓

Kafka

↓

Email Service

Each evolution solves a new problem.

Request Journey
Browser
      │
      ▼
DNS
      │
      ▼
Load Balancer
      │
      ▼
Spring Boot
      │
      ▼
Cache
      │
      ▼
Database

Every component contributes to the final response.

Design Process

A common system design workflow:

Requirements
      │
      ▼
Estimate Scale
      │
      ▼
High-Level Design
      │
      ▼
Data Model
      │
      ▼
Component Design
      │
      ▼
Identify Bottlenecks
      │
      ▼
Optimization
Capacity Estimation

Before selecting technologies, estimate:

Daily active users
Requests per second (RPS)
Storage requirements
Bandwidth
Peak traffic

These estimates influence architectural choices.

Common Building Blocks

As systems grow, common components include:

Load Balancer
CDN
Cache (Redis)
Message Queue (Kafka/RabbitMQ)
Object Storage
Database Replicas
Monitoring
Auto Scaling

We'll study each of these in later chapters.

Hands-on Thought Exercise

Suppose your Student Results API receives:

100 Requests/sec

One year later:

10,000 Requests/sec

Ask:

Can one server handle it?
Is the database the bottleneck?
Should we add caching?
Do we need multiple application instances?
Should background work become asynchronous?

These are system design questions.

Common Mistakes
❌ Designing Without Requirements

Choosing technologies before understanding requirements often leads to unnecessary complexity.

❌ Optimizing Too Early

A simple architecture is often the right starting point.

Scale when measurements show it is necessary.

❌ Focusing Only on Scalability

A system must also be:

Secure
Reliable
Observable
Maintainable
❌ Ignoring Failure

Ask:

What happens if a server fails?
What happens if the database is unavailable?
What happens if the cache is down?

Production systems are designed with failures in mind.

System Design Checklist
✓ Functional Requirements

✓ Non-Functional Requirements

✓ Capacity Estimates

✓ Scalability Strategy

✓ Availability Plan

✓ Reliability Plan

✓ Security Requirements

✓ Monitoring Strategy

✓ Disaster Recovery Considerations
System Design Workflow
Requirements
      │
      ▼
Capacity Planning
      │
      ▼
Architecture
      │
      ▼
Implementation
      │
      ▼
Testing
      │
      ▼
Deployment
      │
      ▼
Monitoring
      │
      ▼
Continuous Improvement
Functional vs Non-Functional Requirements
Functional Requirement	Non-Functional Requirement
Student login	Response time < 200 ms
View results	99.99% availability
Update marks	Handle 50,000 concurrent users
Download report	Secure communication over HTTPS
Manage users	Recover from failures automatically
💡 Key Takeaways

✅ System Design focuses on building systems that continue to work as usage grows.

✅ Functional requirements describe what the system does, while non-functional requirements describe how well it must do it.

✅ Scalability, availability, reliability, performance, security, and maintainability are the primary architectural goals.

✅ Large systems evolve incrementally by adding components such as load balancers, caches, message queues, and replicated databases.

✅ Good system design starts with requirements and capacity estimation before selecting technologies.

➡️ Next Chapter

📘 14-SystemDesign/02-Scalability.md

In the next chapter, you'll explore Scalability in depth.

You'll learn:

📈 Horizontal vs vertical scaling
⚖️ Load balancing
☸️ Kubernetes auto scaling
📦 Stateless vs stateful applications
🗄️ Database scaling
🌍 Scaling the Student Results API from hundreds to millions of users

By the end of that chapter, you'll understand how modern distributed systems grow from a single server into globally scalable platforms.
