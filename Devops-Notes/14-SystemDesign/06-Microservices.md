📘 Chapter 122 — Microservices

📂 File: student-results-api-notes/14-SystemDesign/06-Microservices.md

This chapter is one of the most important chapters in modern backend architecture because it explains how companies break a huge application into many small independent services.

Until now, your Student Results API looks like this:

Browser
      │
      ▼
Spring Boot
      │
      ▼
PostgreSQL

Everything is inside one application.

As the system grows:

Student Management
Authentication
Results
Notifications
Payments
Analytics
Reports

Putting everything into one application becomes difficult.

Another important question appears:

Why should one application do everything?

Instead:

                API Gateway
                     │
      ┌──────────────┼──────────────┐
      ▼              ▼              ▼
 Student API    Result API    Auth API
      │              │              │
      ▼              ▼              ▼
 Student DB     Result DB     User DB

Each service owns one business capability.

This architecture is called Microservices.

🌍 Introduction

In previous chapters we learned:

Scalability
Load Balancing
Caching
Message Queues

Now another important question appears:

🤔 How do very large applications remain maintainable as they continue to grow?

The answer is:

🧩 Microservices

Instead of building one huge application, we divide the system into multiple small, independently deployable services.

🎯 Learning Objectives

After completing this chapter you will understand:

🧩 What Microservices are
🏢 Monolith vs Microservices
📦 Service Decomposition
🌐 API Gateway
🔄 Synchronous vs Asynchronous Communication
🔍 Service Discovery
🗄 Database Per Service
☸️ Microservices on Kubernetes
❓ What is a Monolith?

A monolith is a single application containing all business logic.

Example:

Browser
      │
      ▼
Spring Boot
 ├── Login
 ├── Students
 ├── Results
 ├── Reports
 ├── Notifications
 └── Admin
      │
      ▼
PostgreSQL

Everything is packaged and deployed together.

Problems with a Monolith

As the application grows:

Longer build times
Slower deployments
Larger codebase
Difficult scaling
Teams working in the same codebase
One failure can affect the whole application
What are Microservices?

Instead of one application:

One Big Application

We create:

Student Service

Result Service

Authentication Service

Notification Service

Report Service

Each service has a single business responsibility.

Student Results API Example

Instead of:

Student API
      │
      ▼
One Database

Split into:

                API Gateway
                     │
      ┌──────────────┼──────────────┐
      ▼              ▼              ▼
 Student API    Result API    Auth API
      │              │              │
      ▼              ▼              ▼
 Student DB     Result DB     User DB

Each service owns its own data.

Why Microservices?

Advantages:

Independent deployment
Independent scaling
Smaller codebases
Fault isolation
Technology flexibility
Smaller development teams
Independent Deployment

Suppose only the Notification Service changes.

Monolith:

Deploy Entire Application

Microservices:

Deploy Notification Service Only

This reduces deployment risk.

Independent Scaling

Suppose:

Result API

1000 Requests/sec

Authentication:

20 Requests/sec

Scale only:

Result API

instead of the whole application.

Database per Service

Avoid:

Student API

↓

Shared Database

↑

Auth API

Instead:

Student API

↓

Student DB
Auth API

↓

User DB

Each service owns its data.

Why?

Loose coupling
Independent schema evolution
Better isolation
Independent deployment
API Gateway

Clients should not call every service directly.

Instead:

Browser
      │
      ▼
API Gateway
      │
 ┌────┼────┐
 ▼    ▼    ▼
Auth Student Results

The gateway provides:

Authentication
Routing
Rate limiting
Request logging
TLS termination
Service Communication

Microservices communicate using:

Synchronous
REST

gRPC

Request waits for a response.

Asynchronous
Kafka

RabbitMQ

Services exchange events instead of blocking requests.

Example Flow

Teacher updates marks.

Teacher
      │
      ▼
Result Service
      │
      ▼
Database
      │
      ▼
Kafka
      │
 ┌────┼────┐
 ▼    ▼    ▼
Email Analytics Audit

The Result Service does not need to know how Email or Analytics works.

Service Discovery

Suppose:

Student Service

10 Pods

Pods start and stop dynamically.

Instead of hardcoding IP addresses:

10.0.0.12

Services discover each other using names.

Kubernetes example:

student-service.default.svc.cluster.local

Kubernetes DNS resolves the current Pod IPs behind the Service.

Kubernetes Architecture
Browser
      │
      ▼
Ingress
      │
      ▼
API Gateway
      │
 ┌────┼──────────┬─────────┐
 ▼    ▼          ▼         ▼
Auth Student  Result  Notification
 │      │         │          │
 ▼      ▼         ▼          ▼
DB     DB        DB        Queue

Each service runs as its own Deployment and can scale independently.

Challenges of Microservices

Microservices solve many problems but introduce new ones:

Network latency
Distributed transactions
Observability
Service discovery
Data consistency
More operational complexity

Microservices are not automatically better than a monolith.

Distributed Transactions

Suppose:

Payment Service

↓

Success

Then:

Order Service

↓

Failure

There is no single database transaction spanning both services in most microservice architectures.

Patterns such as Saga are commonly used to coordinate distributed business operations.

Observability

With one application:

One Log

With twenty services:

20 Logs

20 Metrics

20 Traces

Distributed tracing and centralized logging become essential.

Student Results API Evolution
Version 1
Browser

↓

Spring Boot

↓

PostgreSQL
Version 2
Browser

↓

API Gateway

↓

Student API

↓

Student DB
Version 3
Browser

↓

API Gateway

↓

Student API

↓

Kafka

↓

Notification Service
Version 4
Browser

↓

API Gateway

↓

Multiple Services

↓

Redis

↓

Kafka

↓

Independent Databases

Each component can evolve independently.

Hands-on Lab
Create Two Services
Student Service
Result Service

Run each on a different port.

Call Another Service

Example:

RestTemplate

or

WebClient

Retrieve student information from another service.

Add Kafka

Publish:

RESULT_UPDATED

Consume the event in the Notification Service.

Deploy to Kubernetes

Create:

Deployment
Service
Ingress

Verify that services communicate using Kubernetes Service names.

Common Mistakes
❌ Starting with Microservices Too Early

A small application often benefits from starting as a modular monolith.

Introduce microservices when there is a clear business or operational need.

❌ Sharing One Database

Multiple services writing directly to the same database creates tight coupling.

Prefer database ownership by service.

❌ Making Every Call Synchronous

Long chains of synchronous service calls increase latency and reduce resilience.

Use asynchronous messaging where appropriate.

❌ Ignoring Observability

Microservices require:

Centralized logging
Metrics
Distributed tracing
Correlation IDs

Without them, debugging becomes difficult.

Monolith vs Microservices
Monolith	Microservices
One application	Many independent services
One deployment	Independent deployments
Usually one database	Database per service
Simpler initially	More operational complexity
Scale entire application	Scale individual services
Easier to start	Better for large evolving systems
Microservice Request Flow
Browser
    │
    ▼
API Gateway
    │
 ┌──┼─────────┐
 ▼  ▼         ▼
Auth Student Result
 │    │         │
 ▼    ▼         ▼
DB   Kafka   Redis
💡 Key Takeaways

✅ Microservices divide a large application into small, independently deployable services.

✅ Each service should own a specific business capability and typically its own database.

✅ API Gateways provide a single entry point for routing, authentication, and cross-cutting concerns.

✅ Services can communicate synchronously (REST, gRPC) or asynchronously (Kafka, RabbitMQ).

✅ Microservices improve scalability and deployment flexibility but introduce additional operational complexity, making observability, service discovery, and resilience essential.

➡️ Next Chapter

📘 14-SystemDesign/07-DistributedTransactions.md

In the next chapter, you'll learn one of the most challenging topics in distributed systems:

🔄 Why distributed transactions are difficult
⚖️ ACID vs distributed systems
🎭 Saga Pattern
↩️ Compensating transactions
📨 Event choreography vs orchestration
☸️ Distributed transactions in Spring Boot, Kafka, and Kubernetes

By the end of that chapter, you'll understand how large systems maintain business consistency when a single operation spans multiple independent microservices.
