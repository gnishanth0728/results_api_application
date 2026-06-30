📘 Chapter 126 — API Gateway

📂 File: student-results-api-notes/14-SystemDesign/10-API-Gateway.md

This chapter connects everything you've learned about Microservices, Load Balancers, Service Discovery, Authentication, and Kubernetes.

Suppose your Student Results System has these services:

Student Service

Result Service

Auth Service

Notification Service

Report Service

Without an API Gateway, the frontend must know every service.

Browser
   │
   ├── student-service:8080
   ├── result-service:8081
   ├── auth-service:8082
   ├── report-service:8083
   └── notification-service:8084

Problems:

Frontend must know every URL
Every service validates JWT
Every service configures CORS
Every service implements rate limiting
Changing service URLs breaks clients

Another important question appears:

Can the client talk to only one endpoint while the backend routes requests to the correct service?

Yes.

That's the purpose of an API Gateway.

Browser
      │
      ▼
API Gateway
      │
 ┌────┼─────────┬──────────┐
 ▼    ▼         ▼          ▼
Auth Student  Result  Notification

The client only knows the API Gateway.

🌍 Introduction

As applications grow into dozens or hundreds of microservices, another problem appears:

🤔 Should every client communicate directly with every microservice?

Usually the answer is No.

Instead, all client requests pass through an API Gateway.

The gateway acts as the single entry point into the system.

🎯 Learning Objectives

After completing this chapter you will understand:

🚪 What an API Gateway is
🔀 Request Routing
🔐 Authentication
🎟 JWT Validation
🚦 Rate Limiting
📝 Logging
📊 Monitoring
🔄 Request Aggregation
☸️ API Gateway in Kubernetes
🍃 Student Results API Example
❓ What is an API Gateway?

An API Gateway is a server that sits between clients and backend services.

Instead of:

Browser

↓

Student Service

we use:

Browser

↓

API Gateway

↓

Student Service

Clients communicate only with the gateway.

Without API Gateway
Browser
   │
   ├── Auth Service
   ├── Student Service
   ├── Result Service
   ├── Report Service
   └── Notification Service

Problems:

Many endpoints
Complex frontend
Duplicate security logic
Difficult versioning
With API Gateway
Browser
      │
      ▼
API Gateway
      │
 ┌────┼──────────┬─────────┐
 ▼    ▼          ▼         ▼
Auth Student   Result   Report

The gateway hides the internal architecture.

Student Results API

Frontend calls:

GET /api/students/1051110001

Gateway routes:

/api/students

↓

Student Service

Another request:

POST /api/login

Gateway routes:

Auth Service
Request Routing

Example routing table:

URL	Destination
/api/login	Auth Service
/api/students/**	Student Service
/api/results/**	Result Service
/api/reports/**	Report Service

The client never sees internal service addresses.

Authentication

Instead of every service validating usernames and passwords:

Browser

↓

API Gateway

↓

Authentication

The gateway authenticates requests before forwarding them.

Note: In many production systems, the gateway validates the JWT, while backend services may still verify the token and enforce their own authorization rules. Do not assume the gateway completely replaces service-level security.

JWT Validation

Browser sends:

Authorization:
Bearer eyJhb...

Gateway:

Validate JWT

↓

Forward Request

Invalid token:

401 Unauthorized

The request never reaches backend services.

Rate Limiting

Suppose one client sends:

100,000 Requests

Gateway policy:

100 Requests/Minute

Excess requests:

429 Too Many Requests

This helps protect backend services from abuse.

Logging

Gateway logs every request.

Example:

GET /students

200

120 ms

Useful for:

Auditing
Troubleshooting
Monitoring
Request Aggregation

Suppose the frontend needs:

Student
Results
Attendance

Without aggregation:

Browser

↓

3 Requests

Gateway can aggregate:

Browser

↓

1 Request

↓

Gateway

↓

3 Services

The gateway combines responses before returning them.

Service Discovery

Gateway routes using service names.

Example:

student-service

instead of:

10.244.2.14

The gateway relies on Kubernetes Service Discovery.

Kubernetes Architecture
Browser
      │
HTTPS
      │
Ingress
      │
API Gateway
      │
 ┌────┼──────────┬─────────┐
 ▼    ▼          ▼         ▼
Auth Student  Result  Report

Ingress exposes the gateway.

The gateway routes to internal services.

Complete Request Flow
Browser
      │
DNS
      │
HTTPS
      │
Ingress
      │
API Gateway
      │
JWT Validation
      │
Service Discovery
      │
Student Service
      │
Database
Spring Cloud Gateway

Spring provides:

Spring Cloud Gateway

Features:

Routing
JWT support
Filters
Rate limiting
Circuit breaker integration
Request rewriting
Common API Gateway Products
Product	Common Use
Spring Cloud Gateway	Spring Boot ecosystems
Kong	Kubernetes and cloud-native APIs
NGINX	Reverse proxy and API gateway
Traefik	Kubernetes ingress and routing
Envoy	Service mesh and API gateway
AWS API Gateway	Managed cloud API gateway
Gateway Filters

Every request passes through filters.

Request

↓

Authentication

↓

Logging

↓

Rate Limiting

↓

Routing

↓

Response

Each filter performs one responsibility.

Versioning

Gateway can expose:

/api/v1

/api/v2

Different backend versions can coexist while clients migrate gradually.

High Availability

Deploy multiple gateway instances.

Browser
      │
Load Balancer
      │
 ┌────┴────┐
 ▼         ▼
Gateway1 Gateway2

This avoids making the gateway a single point of failure.

Hands-on Lab
Create Gateway

Create a Spring Cloud Gateway application.

Add Route
routes:
  - id: student-service

Forward requests to:

student-service
Verify Routing

Call:

GET /api/students/1051110001

Confirm the request reaches the Student Service.

Enable JWT Filter

Configure a filter that validates JWTs before forwarding requests.

Verify:

Valid token → forwarded
Invalid token → 401 Unauthorized
Apply Rate Limiting

Configure:

100 Requests/Minute

Exceed the limit and verify:

429 Too Many Requests
Common Mistakes
❌ Letting Clients Call Internal Services

Clients should generally communicate through the API Gateway rather than directly accessing internal microservices.

❌ Putting Business Logic in the Gateway

The gateway should handle cross-cutting concerns such as routing, authentication, and rate limiting.

Business logic belongs inside the appropriate microservice.

❌ Trusting Only the Gateway

Even if the gateway validates JWTs, backend services should still protect sensitive endpoints and perform authorization checks.

❌ Creating a Single Gateway Instance

A production gateway should be deployed redundantly and monitored like any other critical service.

API Gateway Workflow
Browser
    │
    ▼
Ingress
    │
    ▼
API Gateway
    │
 ┌──┼──────────┐
 ▼  ▼          ▼
Auth Student Result
    │
    ▼
Database
API Gateway vs Load Balancer
Load Balancer	API Gateway
Distributes traffic	Routes API requests
Works at L4 or L7	Primarily L7 (HTTP/HTTPS)
Balances requests across instances	Can route to different services
Performs health checks	Can authenticate, rate limit, log, transform requests
Typically unaware of business APIs	API-aware
💡 Key Takeaways

✅ An API Gateway provides a single entry point for clients in a microservice architecture.

✅ It centralizes routing, authentication, rate limiting, logging, and other cross-cutting concerns.

✅ The gateway works with Kubernetes Service Discovery to locate backend services using stable service names.

✅ API Gateways simplify clients by hiding the internal structure of the system.

✅ Backend services should still enforce authorization and protect their own resources, even when a gateway performs authentication.


