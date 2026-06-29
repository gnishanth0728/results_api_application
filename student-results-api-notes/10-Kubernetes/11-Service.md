# 📘 Chapter 88 — Kubernetes Service

> 📂 File: `student-results-api-notes/10-Kubernetes/11-Service.md`

This chapter explains one of the most important networking concepts in Kubernetes.

After learning about Deployments and ReplicaSets, another critical question appears:

If Pods are constantly created and destroyed, how do clients always reach the application?

For example:

Pod A

10.244.1.5

↓

Deleted

↓

Pod B

10.244.2.18

The Pod IP changes.

How can:

Browser
Frontend
Another microservice
Mobile application

continue communicating without knowing the new Pod IP?

The answer is:

Kubernetes Service

A Service provides a stable virtual IP and DNS name that never changes, even though the Pods behind it are constantly replaced.

A Service also provides:

Load balancing
Service discovery
Stable networking
Endpoint management

Without Services, Kubernetes applications would constantly lose connectivity whenever Pods are recreated.

This chapter explains Services from the Kubernetes object level down to kube-proxy, iptables/IPVS, and Linux packet forwarding.
---

# 🌍 Introduction

In the previous chapter, we learned that **Deployments** create ReplicaSets, and ReplicaSets create Pods.

Architecture:

```text id="svc001"
Deployment

↓

ReplicaSet

↓

Pods
```

But another important question appears:

> 🤔 **How do clients find Pods?**

Suppose:

```text id="svc002"
Pod-1

10.244.1.5
```

The Pod crashes.

ReplicaSet creates:

```text id="svc003"
Pod-2

10.244.2.18
```

The IP changed.

How can clients continue communicating?

The answer is:

# 🌐 Kubernetes Service

A Service provides a stable virtual endpoint in front of one or more Pods.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🌐 What a Service is
* 📡 ClusterIP
* 🚪 NodePort
* ☁️ LoadBalancer
* 🌍 ExternalName
* 🎯 Label Selectors
* 📋 Endpoints
* ⚖️ Load Balancing
* 🔀 kube-proxy
* 🐧 Linux Packet Forwarding

---

# ❓ What Is a Service?

A Service is a stable network abstraction that exposes one or more Pods.

Instead of connecting to Pod IPs:

```text id="svc004"
10.244.1.5
```

Applications connect to:

```text id="svc005"
student-api-service
```

The Service automatically forwards traffic to healthy Pods.

---

# 🏗️ High-Level Architecture

```text id="svc006"
Client
    │
    ▼
Service
    │
    ▼
┌────┼────┐
▼    ▼    ▼
Pod  Pod  Pod
```

The Service sits between clients and Pods.

---

# 🌍 Why Not Connect Directly to Pods?

Pods are **ephemeral**.

Example:

```text id="svc007"
Pod A

↓

Deleted

↓

Pod B
```

Properties that change:

* IP Address
* UID
* Name

Applications require a stable endpoint.

---

# 📡 ClusterIP

Default Service type:

```yaml id="svc008"
type: ClusterIP
```

Architecture:

```text id="svc009"
Service IP

10.96.0.15

↓

Pods
```

ClusterIP is accessible only from within the Kubernetes cluster.

---

# 🚪 NodePort

Example:

```yaml id="svc010"
type: NodePort
```

Architecture:

```text id="svc011"
Browser

↓

NodeIP:30080

↓

Service

↓

Pods
```

Every node exposes the same port.

---

# ☁️ LoadBalancer

Cloud providers create an external load balancer.

```text id="svc012"
Internet

↓

Cloud Load Balancer

↓

Service

↓

Pods
```

The external load balancer forwards traffic to the Service.

---

# 🌍 ExternalName

Example:

```yaml id="svc013"
type: ExternalName
```

Instead of forwarding packets:

```text id="svc014"
student-db

↓

database.company.com
```

Kubernetes returns a DNS CNAME record pointing to the external service.

---

# 🎯 Label Selector

Service discovers Pods using labels.

Pods:

```yaml id="svc015"
labels:
  app: student-api
```

Service:

```yaml id="svc016"
selector:
  app: student-api
```

Only matching Pods become Service endpoints.

---

# 📋 Endpoints

Suppose:

Pods:

```text id="svc017"
10.244.1.5

10.244.2.9

10.244.3.7
```

Service maintains an endpoint list:

```text id="svc018"
student-api

↓

10.244.1.5

10.244.2.9

10.244.3.7
```

When Pods change, the endpoint list is updated automatically.

---

# ⚖️ Load Balancing

Client request:

```text id="svc019"
GET /students
```

Possible routing:

```text id="svc020"
Request 1 → Pod A

Request 2 → Pod B

Request 3 → Pod C
```

The Service distributes traffic among healthy endpoints.

---

# 🔀 kube-proxy

Every worker node runs:

```text id="svc021"
kube-proxy
```

Responsibilities:

* Watches Services
* Watches Endpoints
* Programs networking rules
* Forwards packets

Architecture:

```text id="svc022"
Service

↓

kube-proxy

↓

Pod
```

---

# 🐧 Packet Flow

Browser:

```text id="svc023"
NodeIP:30080
```

Flow:

```text id="svc024"
Browser

↓

Node

↓

kube-proxy

↓

iptables/IPVS

↓

Pod IP

↓

Spring Boot
```

kube-proxy programs the Linux kernel to forward packets.

---

# 📡 Cluster DNS

Pods access Services using DNS.

Example:

```text id="svc025"
student-api.default.svc.cluster.local
```

Usually applications simply use:

```text id="svc026"
student-api
```

CoreDNS resolves the name to the Service ClusterIP.

---

# 🍃 Student Results API Example

Deployment:

```text id="svc027"
3 Pods
```

Service:

```yaml id="svc028"
selector:
  app: student-api
```

Architecture:

```text id="svc029"
Frontend

↓

student-api

↓

Service

↓

Pod-1

Pod-2

Pod-3
```

Even if Pod-2 is replaced:

```text id="svc030"
Pod-2 Deleted

↓

Pod-4 Created
```

The Service endpoint list updates automatically.

The frontend continues using the same Service name.

---

# 📊 Complete Service Architecture

```text id="svc031"
                  Browser
                      │
                      ▼
             student-api Service
                      │
                 ClusterIP
                      │
                 kube-proxy
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
     Pod A         Pod B         Pod C
```

---

# 📄 Service YAML

Example:

```yaml id="svc032"
apiVersion: v1
kind: Service

metadata:
  name: student-api

spec:

  selector:
    app: student-api

  ports:

  - port: 80
    targetPort: 8080

  type: ClusterIP
```

Meaning:

```text id="svc033"
Service Port

80

↓

Container Port

8080
```

---

# 🔄 Service Lifecycle

Deployment:

```text id="svc034"
Scale to 5 Pods
```

Service:

```text id="svc035"
Automatically Add

↓

New Endpoints
```

Delete Pods:

```text id="svc036"
Automatically Remove

↓

Endpoints
```

Clients never need to know the changes.

---

# 🚫 Common Mistakes

## ❌ Thinking Services Start Pods

Services never create Pods.

Deployments and ReplicaSets manage Pods.

Services only expose them.

---

## ❌ Thinking Service IP Is a Pod IP

A Service IP is a **virtual IP**.

No network interface actually owns it.

kube-proxy intercepts traffic destined for the Service IP and redirects it to backend Pods.

---

## ❌ Thinking NodePort Creates a Load Balancer

NodePort simply opens a port on every node.

It does not provision an external cloud load balancer.

---

## ❌ Thinking Services Select Pods by Name

Services use **label selectors**, not Pod names.

This allows Pods to be replaced transparently.

---

# 🐳 Docker Comparison

Docker:

```text id="svc037"
Container IP

↓

Application
```

Docker applications often communicate directly using container IPs or user-defined bridge DNS.

Kubernetes:

```text id="svc038"
Service

↓

Pods
```

Services provide stable networking even as Pods come and go.

---

# 🧪 Hands-on Lab

## Create a Deployment

```bash id="svc039"
kubectl create deployment nginx --image=nginx --replicas=3
```

---

## Expose the Deployment

```bash id="svc040"
kubectl expose deployment nginx \
  --port=80 \
  --target-port=80
```

---

## View the Service

```bash id="svc041"
kubectl get svc
```

Observe:

* ClusterIP
* Ports
* Type

---

## View Endpoints

```bash id="svc042"
kubectl get endpoints
```

Observe the list of Pod IPs behind the Service.

---

## Scale the Deployment

```bash id="svc043"
kubectl scale deployment nginx --replicas=5
```

Run:

```bash id="svc044"
kubectl get endpoints -w
```

Watch the endpoint list update automatically.

---

## Create a NodePort Service

```bash id="svc045"
kubectl expose deployment nginx \
  --type=NodePort \
  --port=80
```

Inspect:

```bash id="svc046"
kubectl get svc
```

Notice the allocated NodePort (typically in the range **30000–32767**).

---

# 📈 Complete Request Flow

```text id="svc047"
Browser
      │
      ▼
NodeIP:NodePort
      │
      ▼
kube-proxy
      │
      ▼
iptables/IPVS
      │
      ▼
ClusterIP
      │
      ▼
Selected Pod
      │
      ▼
Spring Boot
```

For internal traffic:

```text id="svc048"
Pod
      │
      ▼
Service DNS
      │
      ▼
ClusterIP
      │
      ▼
kube-proxy
      │
      ▼
Backend Pod
```

This is the complete networking path from a client to a Kubernetes application.

---

# 📊 Service Components

| Component         | Responsibility                                        |
| ----------------- | ----------------------------------------------------- |
| 🌐 Service        | Stable virtual endpoint for Pods                      |
| 📡 ClusterIP      | Internal virtual IP for cluster communication         |
| 🚪 NodePort       | Exposes the Service on every node                     |
| ☁️ LoadBalancer   | Integrates with cloud load balancers                  |
| 🌍 ExternalName   | Maps a Service to an external DNS name                |
| 🎯 Label Selector | Identifies backend Pods                               |
| 📋 Endpoints      | Tracks the current healthy Pod IPs                    |
| 🔀 kube-proxy     | Programs Linux networking rules for packet forwarding |
| 🧠 CoreDNS        | Resolves Service names to ClusterIP addresses         |

---

# 💡 Key Takeaways

✅ A Service provides a stable network identity for one or more Pods.

✅ Services use **label selectors** to dynamically discover backend Pods.

✅ Pod IPs are ephemeral, but Service names and ClusterIP addresses remain stable.

✅ `kube-proxy` watches Services and Endpoints and programs Linux networking (iptables or IPVS) to forward traffic.

✅ ClusterIP is the default Service type for internal communication, while NodePort and LoadBalancer expose applications externally.

✅ Applications inside the cluster should communicate using **Service DNS names**, not Pod IP addresses.

✅ Understanding Services is essential before learning Ingress, Gateway API, service meshes, and advanced Kubernetes networking.
