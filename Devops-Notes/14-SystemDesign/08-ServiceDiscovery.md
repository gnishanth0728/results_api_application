📘 Chapter 125 — Service Discovery

📂 File: student-results-api-notes/14-SystemDesign/09-ServiceDiscovery.md

This is an excellent next topic because Service Discovery is what makes Kubernetes microservices actually work.

You already know:

Docker
Kubernetes
Service
Ingress
Load Balancer
Microservices

Now another important question appears:

If Pods are constantly being created and destroyed, how do microservices find each other?

Suppose you have:

Student Service

running as:

Pod-1
10.244.1.12

After a deployment:

Pod-1 Deleted

New Pod:

Pod-2
10.244.3.27

The IP changed.

If Result Service was calling:

http://10.244.1.12:8080

everything breaks.

Another important question appears:

How can services communicate without knowing Pod IPs?

The answer is:

🔍 Service Discovery

Instead of calling Pods directly:

Result Service
      │
      ▼
student-service

Kubernetes automatically finds the current Pods.

🌍 Introduction

In previous chapters we learned:

Microservices
Kubernetes
Load Balancers

Now another important question appears:

🤔 How do microservices locate each other when Pods are constantly changing?

Containers are ephemeral.

Pods:

Start
Stop
Restart
Reschedule
Receive new IP addresses

Applications cannot rely on fixed IP addresses.

The solution is:

🔍 Service Discovery
🎯 Learning Objectives

After completing this chapter you will understand:

🔍 What Service Discovery is
📍 Why Pod IPs Cannot Be Used
🌐 Kubernetes Services
🧭 DNS-Based Service Discovery
⚖️ Load Balancing with Services
☸️ kube-dns / CoreDNS
🍃 Student Results API Example
🚀 Production Service Discovery
❓ Why is Service Discovery Needed?

Suppose:

Student Service

↓

Pod

↓

10.244.1.8

Tomorrow:

Pod Restart

New IP:

10.244.5.21

The old IP no longer exists.

Hardcoding IP addresses would constantly break communication.

Without Service Discovery
Result Service

↓

10.244.1.8

↓

Connection Failed

The Pod disappeared.

With Service Discovery
Result Service

↓

student-service

↓

Kubernetes

↓

Correct Pod

The application always uses a stable service name.

Kubernetes Service

A Service provides:

Stable IP
Stable DNS name
Load balancing
Pod discovery

Pods can change.

The Service remains the same.

Student Results API

Instead of:

Result Service

↓

10.244.3.8

Use:

http://student-service

Kubernetes resolves the name automatically.

Service Architecture
Result Service
        │
        ▼
student-service
        │
 ┌──────┼──────┐
 ▼      ▼      ▼
Pod1   Pod2   Pod3

The Service selects healthy Pods and distributes requests among them.

DNS

Every Service automatically receives a DNS name.

Example:

student-service

or the fully qualified name:

student-service.default.svc.cluster.local

Applications rarely need the full name unless communicating across namespaces.

CoreDNS

Inside Kubernetes:

Pod

↓

DNS Query

↓

CoreDNS

↓

ClusterIP

↓

Service

↓

Pod

CoreDNS resolves Service names into virtual IP addresses.

Request Journey

Suppose:

Result Service

calls:

http://student-service/api/students

Flow:

Result Service
        │
        ▼
DNS Lookup
        │
        ▼
CoreDNS
        │
        ▼
ClusterIP
        │
        ▼
Service
        │
 ┌──────┴──────┐
 ▼             ▼
Pod1         Pod2

The application never needs to know Pod IPs.

ClusterIP

Every Service gets a virtual IP.

Example:

Student Service

↓

10.96.35.8

Pods change.

ClusterIP stays the same.

Endpoint Objects

The Service maintains a list of healthy Pods.

Example:

student-service

↓

Pod1

Pod2

Pod3

When Pods change, Kubernetes updates the endpoints automatically.

Scaling

Suppose:

2 Pods

HPA scales to:

8 Pods

Service automatically updates:

student-service

↓

8 Pods

No application configuration changes are required.

Failure

Suppose:

Pod2

↓

Crash

Service removes it from the endpoint list.

Remaining Pods continue serving traffic.

Cross-Namespace Discovery

Suppose:

student-service

Namespace: backend

Another service:

Namespace: frontend

Calls:

student-service.backend.svc.cluster.local

The namespace becomes part of the DNS name.

Outside Kubernetes

Service discovery also exists outside Kubernetes.

Examples:

Consul
Eureka
ZooKeeper
etcd

Cloud platforms often provide integrated service discovery mechanisms.

Spring Boot Example

Instead of:

new URL("http://10.244.1.8:8080")

Use:

new URL("http://student-service")

The HTTP client relies on Kubernetes DNS.

Kubernetes Example

Student Service:

kind: Service

metadata:
  name: student-service

Result Service can now call:

http://student-service

No Pod IPs are required.

Complete Request Flow
Result Service
      │
      ▼
student-service
      │
      ▼
CoreDNS
      │
      ▼
ClusterIP
      │
      ▼
Service
      │
 ┌────┼────┐
 ▼    ▼    ▼
Pod1 Pod2 Pod3
Hands-on Lab
Create Deployment
kubectl create deployment student-api \
--image=student-api
Expose Service
kubectl expose deployment student-api \
--port=8080
Verify Service
kubectl get svc
Verify DNS

Run a temporary Pod:

kubectl run test \
--rm -it \
--image=busybox \
-- sh

Inside it:

nslookup student-api

Observe that Kubernetes DNS resolves the Service name.

Test Communication
wget -qO- http://student-api:8080

or

curl http://student-api:8080

The request reaches one of the Pods behind the Service.

Common Mistakes
❌ Calling Pod IPs Directly

Pod IPs are temporary.

Always communicate through a Kubernetes Service.

❌ Assuming DNS Is Slow

CoreDNS responses are cached, and Kubernetes service discovery is designed to be efficient for normal service-to-service communication.

❌ Confusing Service Discovery with Load Balancing

Service Discovery answers:

"Where is the service?"

Load Balancing answers:

"Which backend instance should receive this request?"

A Kubernetes Service provides both stable discovery and load balancing across matching Pods.

❌ Forgetting Namespaces

student-service works only within the same namespace.

Across namespaces, use the namespace-qualified name, for example:

student-service.backend

or the full FQDN when needed.

Service Discovery Workflow
Application
      │
      ▼
Service Name
      │
      ▼
CoreDNS
      │
      ▼
ClusterIP
      │
      ▼
Kubernetes Service
      │
 ┌────┼────┐
 ▼    ▼    ▼
Pod1 Pod2 Pod3
Service Discovery Comparison
Without Service Discovery	With Service Discovery
Hardcoded Pod IPs	Stable Service name
Breaks after Pod restart	Works across Pod restarts
Manual updates required	Kubernetes updates automatically
Difficult to scale	Scales transparently
Fragile	Highly resilient
💡 Key Takeaways

✅ Service Discovery allows microservices to locate each other without using Pod IP addresses.

✅ Kubernetes Services provide stable names and virtual IPs even though Pods are ephemeral.

✅ CoreDNS resolves Service names to their corresponding ClusterIP.

✅ A Service automatically updates its backend endpoints as Pods are created, deleted, or rescheduled.

✅ Applications should communicate using Service DNS names, not Pod IPs, making deployments resilient to scaling and failures.

➡️ Next Chapter

📘 14-SystemDesign/10-API-Gateway.md

In the next chapter, you'll learn why production microservice architectures place an API Gateway in front of all services.

Topics include:

🚪 What an API Gateway is
🔀 Request routing
🔐 Authentication and JWT validation
🚦 Rate limiting
📝 Request logging
🔄 Request aggregation
☸️ API Gateways in Kubernetes (Spring Cloud Gateway, Kong, NGINX, Traefik)

By the end of that chapter, you'll understand why clients almost never communicate directly with individual microservices in production.
