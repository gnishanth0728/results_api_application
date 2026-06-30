📘 Chapter 105 — Load Testing Fundamentals

📂 File: student-results-api-notes/12-Performance/02-LoadTesting.md

🌍 Introduction

In the previous chapter, we used ApacheBench to generate HTTP requests.

But another important question appears:

🤔 What kind of performance test are we running?

Suppose your Student Results API receives:

100 Users

Tomorrow:

10,000 Users

Next month:

100,000 Users

Should every test be performed the same way?

No.

Different business questions require different performance tests.

🎯 Learning Objectives

After completing this chapter you will understand:

📈 What Performance Testing is
🚀 Load Testing
💥 Stress Testing
📊 Spike Testing
⏳ Soak (Endurance) Testing
📉 Capacity Testing
🎯 Scalability Testing
📐 Performance Metrics
🍃 Student Results API Examples
☸️ Kubernetes Scaling
❓ What is Performance Testing?

Performance testing evaluates how an application behaves under different workloads.

Instead of asking:

Does the application work?

Performance testing asks:

How fast is it?
How many users can it support?
When does it fail?
How does it recover?
Can it scale?
Performance Testing Categories
Performance Testing
        │
        ├── Load Testing
        ├── Stress Testing
        ├── Spike Testing
        ├── Soak Testing
        ├── Capacity Testing
        └── Scalability Testing

Each serves a different purpose.

🚀 Load Testing

Question:

Can the application handle its expected workload?

Example:

Expected Users

↓

500

Test:

500 Concurrent Users

Goal:

The application should meet its response time and error-rate objectives under normal production traffic.

💥 Stress Testing

Question:

What happens beyond the expected limit?

Example:

Expected

500 Users

↓

Actual Test

5,000 Users

Goal:

Determine:

Breaking point
Failure mode
Recovery behavior
📊 Spike Testing

Question:

What happens if traffic increases suddenly?

Example:

100 Users

↓

5,000 Users

↓

100 Users

Examples:

Flash sales
Ticket booking
Exam results
Breaking news

Observe:

Response time
Error rate
Auto-scaling
Recovery time
⏳ Soak (Endurance) Testing

Question:

Can the application run continuously?

Example:

500 Users

↓

24 Hours

Purpose:

Find:

Memory leaks
Resource leaks
Connection leaks
Thread leaks
Gradual performance degradation
📉 Capacity Testing

Question:

How many users can the application support while still meeting performance targets?

Example:

100 Users

↓

500 Users

↓

1,000 Users

↓

2,000 Users

The result helps determine practical operating limits.

🎯 Scalability Testing

Question:

Does performance improve when resources increase?

Example:

2 Pods

↓

4 Pods

↓

8 Pods

Observe:

Requests/sec
CPU usage
Response time

Good scalability means increased capacity with additional resources, though perfect linear scaling is uncommon.

Student Results API Example

Suppose:

GET /students/{rollNumber}

Normal day:

300 Requests/sec

Exam result day:

10,000 Requests/sec

Testing helps determine whether:

More Pods are needed
Database tuning is required
Caching should be introduced
Important Performance Metrics

Common metrics include:

Metric	Meaning
Response Time	Time to complete one request
Throughput	Requests processed per second
Latency	Time before a response begins
Error Rate	Percentage of failed requests
CPU Usage	Processor utilization
Memory Usage	RAM consumption
Network Throughput	Data transferred per second
Concurrent Users	Active users during the test
Response Time

Example:

GET /students

↓

120 ms

Lower response times generally improve user experience.

Throughput

Example:

Requests/sec

↓

4,500

Higher throughput means more completed work per unit time.

Error Rate

Example:

10,000 Requests

↓

150 Errors

Error rate:

1.5%

A rising error rate under load often indicates the system is reaching its limits.

Resource Monitoring

During tests, monitor:

CPU

Memory

Disk

Network

Threads

Connections

Use tools such as:

top
jcmd
ss
kubectl top
Prometheus
Grafana
Kubernetes Example

Suppose:

Deployment

↓

3 Pods

Load increases:

CPU

90%

HPA scales:

3 Pods

↓

6 Pods

Continue measuring whether response times improve after scaling.

Common Test Workflow
Deploy Application
        │
        ▼
Generate Load
        │
        ▼
Monitor Metrics
        │
        ▼
Analyze Results
        │
        ▼
Optimize
        │
        ▼
Repeat

Performance tuning is an iterative process.

Hands-on Lab
Verify the Application
curl http://localhost:8080/students/1051110001
Run a Basic Load Test
ab -n 5000 -c 100 \
http://localhost:8080/students/1051110001
Monitor CPU
top
Monitor JVM
jcmd <PID> GC.heap_info
Monitor Connections
ss -tn
Monitor Kubernetes
kubectl top pods

kubectl get hpa -w

Observe CPU usage and any scaling activity.

Common Mistakes
❌ Confusing Load Testing with Stress Testing
Load Testing validates expected production traffic.
Stress Testing intentionally exceeds expected limits.
❌ Measuring Only Requests per Second

Always consider multiple metrics together:

Response time
Throughput
Error rate
CPU
Memory
Latency percentiles
❌ Ignoring the Database

Many bottlenecks occur in:

Database queries
Missing indexes
Connection pools
Disk I/O

The application server may not be the limiting factor.

❌ Testing Without Monitoring

Generating load without observing CPU, memory, threads, logs, and network activity makes it difficult to explain the results.

Performance Testing Types
Test Type	Goal
Load Testing	Validate expected production workload
Stress Testing	Find the breaking point
Spike Testing	Evaluate sudden traffic increases
Soak Testing	Detect long-term stability issues
Capacity Testing	Determine sustainable limits
Scalability Testing	Measure behavior as resources increase
Complete Performance Workflow
Users
      │
      ▼
Load Generator
      │
      ▼
Spring Boot
      │
      ▼
Tomcat
      │
      ▼
JVM
      │
      ▼
Database
      │
      ▼
Metrics
      │
      ▼
Analysis
      │
      ▼
Optimization
💡 Key Takeaways

✅ Performance testing evaluates how an application behaves under varying workloads.

✅ Different testing types answer different questions: load, stress, spike, soak, capacity, and scalability.

✅ Key metrics include response time, throughput, error rate, latency percentiles, CPU usage, memory usage, and concurrent users.

✅ Performance testing should always be accompanied by monitoring to identify bottlenecks.

✅ The goal is not simply to generate traffic, but to understand system behavior and improve performance based on evidence.

➡️ Next Chapter

📘 12-Performance/03-JMeter.md

In the next chapter, we'll explore Apache JMeter, a comprehensive load-testing platform.

You'll learn:

👥 Creating virtual users
🔄 Building realistic user workflows
🔐 Authentication and session handling
📊 HTML reports and graphs
📈 Stress and soak testing
☸️ Performance testing Spring Boot applications running in Docker and Kubernetes
