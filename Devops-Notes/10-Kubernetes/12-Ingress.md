# 📘 Chapter 89 — Kubernetes Ingress

> 📂 File: `student-results-api-notes/10-Kubernetes/12-Ingress.md`

This chapter explains how production Kubernetes applications are exposed to the outside world.

After learning about Services, another important question appears:

How do users on the Internet access applications running inside Kubernetes?

For example:

Browser

↓

https://student.example.com

↓

???

Your application is running inside the cluster:

Pods

↓

Service

↓

ClusterIP

But ClusterIP is only accessible inside the cluster.

Should every Service use a separate LoadBalancer?

Student API

↓

LoadBalancer

------------

Payment API

↓

LoadBalancer

------------

Order API

↓

LoadBalancer

This becomes expensive and difficult to manage.

Instead, Kubernetes provides:

Ingress

Ingress allows one external entry point to route traffic to many Services based on:

Host name
URL path
TLS certificate
HTTP/HTTPS rules

Ingress works much like Nginx or Apache Virtual Hosts, but is managed declaratively by Kubernetes

---

# 🌍 Introduction

In the previous chapter, we learned about **Services**.

Architecture:

```text id="ing001"
Client

↓

Service

↓

Pods
```

But another important question appears:

> 🤔 **How does traffic from the Internet reach a Service?**

A Service of type `ClusterIP` is accessible only from inside the cluster.

Production applications need:

* HTTPS
* Host-based routing
* Path-based routing
* TLS termination
* A single public entry point

The answer is:

# 🌐 Kubernetes Ingress

Ingress provides HTTP and HTTPS routing from outside the cluster to internal Services.

---

## Mermaid Snapshot (From deep-dive)

```mermaid
flowchart LR
Client-->Ingress-->Service-->kubeProxy[kube-proxy]-->Pod-->Container
```

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🌐 What Ingress is
* 🚪 Ingress Controller
* 🛣️ Host-Based Routing
* 📂 Path-Based Routing
* 🔒 TLS Termination
* 📡 Ingress Rules
* 🎯 Default Backend
* 🔀 Request Flow
* 🌍 DNS Integration
* ☸️ Complete External Traffic Flow

---

# ❓ What Is Ingress?

Ingress is a Kubernetes API resource that defines HTTP and HTTPS routing rules.

It does **not** forward traffic by itself.

An **Ingress Controller** reads the Ingress resource and configures a reverse proxy.

Architecture:

```text id="ing002"
Browser

↓

Ingress Controller

↓

Service

↓

Pods
```

---

# ⚠️ Ingress vs Ingress Controller

Many beginners confuse these.

### Ingress

A Kubernetes object.

Example:

```yaml id="ing003"
kind: Ingress
```

Stores routing rules.

---

### Ingress Controller

A running application.

Examples:

* NGINX Ingress Controller
* HAProxy Ingress
* Traefik
* Kong

The controller watches Ingress resources and updates its routing configuration.

---

# 🏗️ High-Level Architecture

```text id="ing004"
Internet
     │
     ▼
Load Balancer
     │
     ▼
Ingress Controller
     │
     ▼
Service
     │
     ▼
Pods
```

---

# 🌍 Why Not Use LoadBalancer for Every Service?

Suppose a cluster contains:

```text id="ing005"
Student API

Payment API

Order API

Notification API
```

Creating four cloud load balancers means:

* Higher cost
* More public IP addresses
* More certificates
* More DNS records

Instead:

```text id="ing006"
One Load Balancer

↓

Ingress Controller

↓

Many Services
```

---

# 🛣️ Host-Based Routing

Example:

```text id="ing007"
student.example.com

↓

Student Service

---------------------

payment.example.com

↓

Payment Service
```

The hostname determines the destination Service.

---

# 📂 Path-Based Routing

Example:

```text id="ing008"
/students

↓

Student Service

---------------------

/payments

↓

Payment Service

---------------------

/orders

↓

Order Service
```

The URL path determines the backend Service.

---

# 🔒 TLS Termination

Example:

```text id="ing009"
HTTPS

↓

TLS Handshake

↓

Ingress Controller

↓

HTTP

↓

Service
```

TLS is terminated at the Ingress Controller.

Backend Services often communicate using plain HTTP inside the trusted cluster network.

---

# 📄 Ingress YAML

Example:

```yaml id="ing010"
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
  name: student-api

spec:

  rules:

  - host: student.example.com

    http:

      paths:

      - path: /

        pathType: Prefix

        backend:

          service:

            name: student-service

            port:

              number: 80
```

This rule maps requests for `student.example.com` to `student-service`.

---

# 🎯 Default Backend

Suppose a request arrives:

```text id="ing011"
unknown.example.com
```

No rule matches.

Ingress Controller forwards to:

```text id="ing012"
Default Backend

↓

404
```

This prevents unmatched requests from being routed incorrectly.

---

# 🌍 DNS Integration

DNS:

```text id="ing013"
student.example.com

↓

Public IP
```

Public IP:

```text id="ing014"
Load Balancer

↓

Ingress Controller
```

DNS resolves the hostname to the external load balancer.

---

# 🔀 Complete Request Flow

```text id="ing015"
Browser

↓

DNS

↓

Load Balancer

↓

Ingress Controller

↓

Service

↓

Pod
```

This is the complete external traffic path.

---

# 🍃 Student Results API Example

User:

```text id="ing016"
https://student.example.com/results
```

Flow:

```text id="ing017"
Browser

↓

DNS

↓

Load Balancer

↓

NGINX Ingress

↓

student-service

↓

Pod

↓

Spring Boot
```

The application never sees the public IP directly.

---

# 📊 Multiple Applications

Example:

```text id="ing018"
student.example.com

↓

Student Service

---------------------

payment.example.com

↓

Payment Service

---------------------

admin.example.com

↓

Admin Service
```

One Ingress Controller routes traffic for multiple applications.

---

# 📊 Complete Architecture

```text id="ing019"
                  Internet
                      │
                      ▼
               Public DNS
                      │
                      ▼
              Cloud Load Balancer
                      │
                      ▼
            Ingress Controller
                      │
      ┌───────────────┼───────────────┐
      ▼               ▼               ▼
 Student Service  Payment Service  Admin Service
      │               │               │
      ▼               ▼               ▼
    Pods            Pods            Pods
```

---

# 🔄 Updating Ingress

Suppose:

```yaml id="ing020"
host: reports.example.com
```

Applied:

```bash id="ing021"
kubectl apply -f ingress.yaml
```

Flow:

```text id="ing022"
Ingress Resource

↓

API Server

↓

Ingress Controller Watch

↓

Reload Configuration
```

No manual editing of NGINX configuration is required.

---

# 🚫 Common Mistakes

## ❌ Thinking Ingress Is a Reverse Proxy

Ingress is only a Kubernetes resource.

The Ingress Controller performs the actual reverse proxy work.

---

## ❌ Thinking Ingress Replaces Services

Ingress routes traffic **to Services**.

Services remain necessary because they provide stable endpoints for Pods.

---

## ❌ Thinking Ingress Works Without a Controller

Without an Ingress Controller, Ingress resources are ignored.

The routing rules exist in the API Server but nothing enforces them.

---

## ❌ Thinking Ingress Handles Non-HTTP Traffic

Ingress is designed primarily for HTTP and HTTPS.

Protocols such as raw TCP, UDP, or gRPC may require additional controller support or other Kubernetes resources.

---

# 🐳 Docker Comparison

Docker:

```text id="ing023"
Host Port

↓

Container
```

Each application often exposes its own port.

Kubernetes:

```text id="ing024"
One HTTPS Endpoint

↓

Ingress Controller

↓

Many Services
```

Ingress centralizes HTTP routing.

---

# 🧪 Hands-on Lab

## Create a Deployment

```bash id="ing025"
kubectl create deployment nginx --image=nginx
```

---

## Expose the Deployment

```bash id="ing026"
kubectl expose deployment nginx --port=80
```

---

## Create an Ingress

```yaml id="ing027"
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
  name: demo

spec:

  rules:

  - host: demo.local

    http:

      paths:

      - path: /

        pathType: Prefix

        backend:

          service:

            name: nginx

            port:

              number: 80
```

Apply:

```bash id="ing028"
kubectl apply -f ingress.yaml
```

---

## View the Ingress

```bash id="ing029"
kubectl get ingress
```

Observe:

* Hosts
* Address
* Rules

---

## Describe the Ingress

```bash id="ing030"
kubectl describe ingress demo
```

Inspect:

* Host rules
* Backend Services
* Events

---

## Test with Minikube

Enable the NGINX Ingress Controller:

```bash id="ing031"
minikube addons enable ingress
```

Find the cluster IP:

```bash id="ing032"
minikube ip
```

Add a hosts file entry:

```text id="ing033"
<MINIKUBE_IP> demo.local
```

Visit:

```text id="ing034"
http://demo.local
```

---

# 📈 Complete External Request Flow

```text id="ing035"
Browser
      │
      ▼
DNS
      │
      ▼
Cloud Load Balancer
      │
      ▼
Ingress Controller
      │
      ▼
Ingress Rules
      │
      ▼
Service
      │
      ▼
Endpoints
      │
      ▼
Pod
      │
      ▼
Spring Boot
```

This is the complete path for an HTTP request entering a Kubernetes cluster.

---

# 📊 Ingress Components

| Component             | Responsibility                                      |
| --------------------- | --------------------------------------------------- |
| 🌐 Ingress            | Defines HTTP/HTTPS routing rules                    |
| 🚪 Ingress Controller | Implements the routing rules using a reverse proxy  |
| 🌍 DNS                | Maps the hostname to the external load balancer     |
| ☁️ Load Balancer      | Exposes the Ingress Controller externally           |
| 📡 Service            | Provides a stable backend endpoint                  |
| 📋 Endpoints          | Tracks healthy backend Pods                         |
| 📦 Pods               | Run the application                                 |
| 🔒 TLS                | Enables HTTPS termination at the Ingress Controller |

---

# 💡 Key Takeaways

✅ Ingress provides HTTP and HTTPS routing from outside the cluster to internal Services.

✅ An **Ingress resource** only defines routing rules; an **Ingress Controller** implements those rules.

✅ One Ingress Controller can expose many Services using host-based and path-based routing.

✅ TLS termination is commonly performed at the Ingress Controller, simplifying certificate management.

✅ DNS resolves application hostnames to the external load balancer that fronts the Ingress Controller.

✅ Services remain essential because Ingress always routes traffic to Services—not directly to Pods.

✅ Understanding Ingress completes the end-to-end networking path from an Internet client to a container running inside Kubernetes.

---

# ➡️ Next Chapter

📘 **`10-Kubernetes/13-ConfigMap.md`**

In the next chapter, we'll explore **ConfigMaps**.

We'll answer questions such as:

* ⚙️ Why shouldn't configuration be hardcoded into container images?
* 📄 How can environment variables and configuration files be injected into Pods?
* 🔄 What happens when a ConfigMap changes?
* 📂 How are ConfigMaps mounted as files or exposed as environment variables?
* 🧠 How do ConfigMaps help separate configuration from application code?

By the end of the chapter, you'll understand how Kubernetes manages application configuration independently of container images.
