# 📘 Chapter 92 — Kubernetes Horizontal Pod Autoscaler (HPA)

> 📂 File: `student-results-api-notes/10-Kubernetes/15-HPA.md`

This chapter explains how Kubernetes automatically scales applications based on workload.

So far you've learned:

Deployment

↓

ReplicaSet

↓

Pods

You can manually scale an application:

kubectl scale deployment student-api --replicas=10

But another important question appears:

How does Kubernetes know when to scale automatically?

Suppose:

3 Pods

↓

CPU = 95%

Should an administrator continuously monitor CPU usage and run:

kubectl scale

every few minutes?

Of course not.

Instead, Kubernetes provides:

Horizontal Pod Autoscaler (HPA)

HPA continuously monitors metrics such as:

CPU utilization
Memory utilization
Custom metrics
External metrics

It automatically increases or decreases the number of Pod replicas by updating the Deployment or ReplicaSet.

This chapter explains HPA from metrics collection all the way down to ReplicaSet scaling.

---

# 🌍 Introduction

In the previous chapter, we learned how Kubernetes networking works using CNI.

Applications can now receive traffic.

But another important question appears:

> 🤔 **What happens when traffic suddenly increases?**

Suppose:

```text id="hpa001"
3 Pods

↓

10,000 Users
```

CPU usage becomes:

```text id="hpa002"
95%
```

Should an administrator manually create more Pods?

The answer is:

# 📈 Horizontal Pod Autoscaler (HPA)

HPA automatically changes the number of Pod replicas based on workload metrics.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📈 What HPA is
* 📊 Metrics Server
* ❤️ CPU Metrics
* 💾 Memory Metrics
* 📦 Replica Scaling
* ⚙️ HPA Controller
* 📉 Scale Down
* 📈 Scale Up
* 🔄 Complete Autoscaling Flow
* ☸️ Production Autoscaling

---

# ❓ What Is HPA?

HPA automatically adjusts the number of Pod replicas.

Instead of:

```bash id="hpa003"
kubectl scale deployment student-api --replicas=10
```

HPA continuously evaluates metrics and updates the target resource automatically.

---

# 🏗️ High-Level Architecture

```text id="hpa004"
Users

↓

Pods

↓

Metrics Server

↓

HPA

↓

Deployment

↓

ReplicaSet

↓

Pods
```

---

# 📊 Metrics Server

HPA requires metrics.

Flow:

```text id="hpa005"
kubelet

↓

CPU

Memory

↓

Metrics Server
```

Metrics Server collects resource usage from kubelets through the Metrics API.

It is **not** installed by default in every Kubernetes cluster.

---

# ❤️ CPU Utilization

Example HPA target:

```yaml id="hpa006"
targetCPUUtilizationPercentage: 70
```

Suppose:

```text id="hpa007"
Current

90%
```

Desired:

```text id="hpa008"
70%
```

HPA increases the replica count.

---

# 💾 Memory Utilization

Modern HPA commonly uses the `autoscaling/v2` API.

Example:

```yaml id="hpa009"
metrics:

- type: Resource

  resource:

    name: memory
```

Memory can also be used as a scaling signal.

---

# 📈 Scale Up

Suppose:

```text id="hpa010"
Replicas

3
```

CPU:

```text id="hpa011"
95%
```

HPA computes:

```text id="hpa012"
Need More Pods

↓

Replicas = 6
```

The Deployment is updated.

ReplicaSet creates the additional Pods.

---

# 📉 Scale Down

Traffic decreases.

Current:

```text id="hpa013"
CPU

15%
```

Replicas:

```text id="hpa014"
6
```

HPA computes:

```text id="hpa015"
Scale Down

↓

Replicas = 3
```

ReplicaSet removes excess Pods gradually.

---

# ⚙️ HPA Controller

The HPA Controller runs inside the Kubernetes Controller Manager.

Loop:

```text id="hpa016"
Read Metrics

↓

Compare Target

↓

Calculate Replicas

↓

Update Deployment
```

This reconciliation repeats continuously.

---

# 📄 HPA YAML

Example:

```yaml id="hpa017"
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler

metadata:
  name: student-api

spec:

  scaleTargetRef:

    apiVersion: apps/v1

    kind: Deployment

    name: student-api

  minReplicas: 3

  maxReplicas: 10

  metrics:

  - type: Resource

    resource:

      name: cpu

      target:

        type: Utilization

        averageUtilization: 70
```

This configuration maintains average CPU utilization around 70%.

---

# 🔄 Complete Scaling Flow

Suppose CPU rises.

Flow:

```text id="hpa018"
Users

↓

More Requests

↓

Higher CPU

↓

Metrics Server

↓

HPA

↓

Deployment

↓

ReplicaSet

↓

New Pods
```

Scaling happens automatically.

---

# 📉 Scaling Formula

HPA approximately calculates:

```text id="hpa019"
Desired Replicas

=

Current Replicas

×

Current Metric

/

Target Metric
```

Example:

```text id="hpa020"
Current Replicas

3

CPU

90%

Target

45%
```

Result:

```text id="hpa021"
3 × 90 / 45

=

6 Pods
```

The controller rounds appropriately and respects configured minimum and maximum replicas.

---

# 🍃 Student Results API Example

Normal traffic:

```text id="hpa022"
3 Pods

↓

CPU 35%
```

Peak traffic:

```text id="hpa023"
CPU 92%
```

HPA:

```text id="hpa024"
Deployment

↓

Replicas = 7
```

ReplicaSet:

```text id="hpa025"
Create 4 Pods
```

Traffic later decreases:

```text id="hpa026"
CPU 20%

↓

Replicas = 3
```

---

# 📊 Complete Architecture

```text id="hpa027"
              User Requests
                    │
                    ▼
                  Pods
                    │
                    ▼
                 kubelet
                    │
                    ▼
             Metrics Server
                    │
                    ▼
            HPA Controller
                    │
                    ▼
               Deployment
                    │
                    ▼
               ReplicaSet
                    │
                    ▼
                  New Pods
```

---

# 📈 HPA vs Manual Scaling

Manual:

```text id="hpa028"
Administrator

↓

kubectl scale
```

Automatic:

```text id="hpa029"
Metrics

↓

HPA

↓

Deployment
```

HPA eliminates the need for manual scaling during normal workload fluctuations.

---

# 🌍 Custom Metrics

HPA can also scale using:

* HTTP requests per second
* Queue length
* Kafka lag
* Prometheus metrics
* Cloud provider metrics

These require additional metrics adapters.

---

# 🚫 Common Mistakes

## ❌ Thinking HPA Creates Pods

HPA only updates the replica count.

ReplicaSet creates or removes Pods.

---

## ❌ Thinking HPA Reads Metrics from Pods

HPA obtains metrics through the Kubernetes Metrics API, typically provided by Metrics Server or a custom metrics adapter.

---

## ❌ Thinking HPA Works Without Resource Requests

CPU-based HPA depends on CPU **requests** because utilization is calculated relative to the requested CPU.

Without CPU requests, CPU utilization scaling cannot work correctly.

---

## ❌ Thinking HPA Reacts Instantly

HPA evaluates metrics periodically.

Scaling decisions also include stabilization windows and policies to avoid rapid oscillation.

---

# 🐳 Docker Comparison

Docker:

```text id="hpa030"
High CPU

↓

Administrator

↓

docker run
```

Kubernetes:

```text id="hpa031"
High CPU

↓

HPA

↓

Deployment

↓

ReplicaSet

↓

Pods
```

Autoscaling is built into Kubernetes.

---

# 🧪 Hands-on Lab

## Install Metrics Server (if needed)

```bash id="hpa032"
kubectl get deployment metrics-server -n kube-system
```

Verify that Metrics Server is running.

---

## View Resource Usage

```bash id="hpa033"
kubectl top pods

kubectl top nodes
```

Observe CPU and memory usage.

---

## Create an HPA

```bash id="hpa034"
kubectl autoscale deployment nginx \
  --cpu-percent=70 \
  --min=2 \
  --max=10
```

---

## View HPA

```bash id="hpa035"
kubectl get hpa
```

Inspect:

* Current CPU
* Target CPU
* Current replicas
* Desired replicas

---

## Generate Load

Run a temporary load generator:

```bash id="hpa036"
kubectl run load-generator \
  --rm -it \
  --image=busybox \
  --restart=Never \
  -- sh
```

Inside the container:

```bash id="hpa037"
while true; do
  wget -q -O- http://nginx
done
```

Watch scaling:

```bash id="hpa038"
kubectl get hpa -w

kubectl get pods -w
```

---

# 📈 Complete Autoscaling Flow

```text id="hpa039"
User Requests
      │
      ▼
Pods
      │
      ▼
kubelet
      │
      ▼
Metrics Server
      │
      ▼
HPA Controller
      │
      ▼
Deployment
      │
      ▼
ReplicaSet
      │
      ▼
New Pods
      │
      ▼
Scheduler
      │
      ▼
kubelet
```

This is the complete HPA lifecycle.

---

# 📊 HPA Components

| Component         | Responsibility                   |
| ----------------- | -------------------------------- |
| 📈 HPA            | Defines autoscaling policy       |
| 📊 Metrics Server | Provides CPU and memory metrics  |
| ❤️ kubelet        | Reports resource usage           |
| ⚙️ HPA Controller | Calculates desired replica count |
| 🚀 Deployment     | Receives updated replica count   |
| 📄 ReplicaSet     | Creates or removes Pods          |
| 🖥️ Scheduler     | Places new Pods onto nodes       |

---

# 💡 Key Takeaways

✅ HPA automatically scales applications by changing the number of Pod replicas.

✅ The HPA Controller uses metrics from the Kubernetes Metrics API, most commonly provided by Metrics Server.

✅ CPU-based autoscaling requires CPU resource requests to calculate utilization correctly.

✅ HPA updates the Deployment (or another scalable resource); the ReplicaSet performs the actual Pod creation or removal.

✅ HPA supports CPU, memory, custom metrics, and external metrics through the `autoscaling/v2` API.

✅ Stabilization windows and scaling policies help prevent rapid scaling fluctuations.

✅ HPA provides horizontal scaling—adding or removing Pods—rather than increasing CPU or memory for existing Pods.

---

# ➡️ Next Chapter

📘 **`10-Kubernetes/16-VPA.md`**

In the next chapter, we'll explore the **Vertical Pod Autoscaler (VPA)**.

We'll answer questions such as:

* 📈 What is vertical scaling?
* 💾 How does VPA recommend CPU and memory requests?
* 🔄 How does VPA update running workloads?
* ⚖️ When should you choose HPA, VPA, or both?
* 🧠 What are the limitations of VPA?

By the end of the chapter, you'll understand the differences between horizontal and vertical autoscaling and when to use each approach in production Kubernetes environments.
