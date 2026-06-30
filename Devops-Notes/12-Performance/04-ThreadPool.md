📘 Chapter 106 — Thread Pool Performance

📂 File: student-results-api-notes/12-Performance/04-ThreadPool.md

🌍 Introduction

In previous chapters we learned:

Browser
    │
    ▼
Tomcat
    │
    ▼
Worker Thread
    │
    ▼
Spring Boot

Every HTTP request is processed by a worker thread.

But another important question appears:

🤔 Where do these worker threads come from?

Does Tomcat create a new thread for every request?

No.

Creating threads is expensive.

Instead, Tomcat uses a thread pool.

🎯 Learning Objectives

After completing this chapter you will understand:

🧵 What a Thread Pool is
⚡ Why Thread Pools exist
📥 Request Queue
👷 Worker Threads
⏳ Waiting Requests
📈 Throughput
🚫 Thread Pool Exhaustion
🍃 Student Results API Example
☸️ Kubernetes Considerations
🚀 Performance Tuning
❓ What is a Thread Pool?

A thread pool is a collection of reusable worker threads.

Instead of:

Request

↓

Create Thread

↓

Destroy Thread

for every request,

Tomcat does:

Create Threads Once

↓

Reuse Forever

until shutdown.

This reduces CPU overhead and improves response time.

Why Not Create Threads Every Time?

Creating a thread requires:

Memory for the thread stack
Kernel scheduling structures
JVM bookkeeping

Doing this for every request would significantly increase overhead.

Thread pools eliminate this repeated work.

Basic Architecture
Browser
      │
      ▼
HTTP Request
      │
      ▼
Tomcat Connector
      │
      ▼
Request Queue
      │
      ▼
Worker Thread Pool
      │
      ▼
Spring Boot
Example Thread Pool

Suppose:

maxThreads = 5

Pool:

Worker-1

Worker-2

Worker-3

Worker-4

Worker-5

Requests:

R1

R2

R3

R4

R5

Every request immediately receives a thread.

Sixth Request

Now another request arrives.

R6

All workers are busy.

Worker-1 Busy

Worker-2 Busy

Worker-3 Busy

Worker-4 Busy

Worker-5 Busy

R6 waits in the connector's request queue until a worker thread becomes available.

If the queue also becomes full, new requests may be rejected or time out depending on the connector configuration.

Request Queue

Conceptually:

Incoming Requests
       │
       ▼
Request Queue
       │
       ▼
Available Worker

The queue smooths short traffic bursts without creating unlimited threads.

Student Results API Example

Suppose:

200 Worker Threads

Traffic:

250 Requests

Execution:

200 Processing

50 Waiting

When a worker finishes:

Worker Free

↓

Next Waiting Request
Throughput

Suppose one request requires:

100 ms

With:

100 Threads

The application can process many requests concurrently.

However, increasing the thread count indefinitely does not guarantee better throughput.

Eventually:

CPU becomes saturated.
Context switching increases.
Memory consumption grows.
Database connections become the bottleneck.
Thread Pool Exhaustion

Suppose:

maxThreads

=

200

Traffic:

10,000 Concurrent Requests

Results:

200 Processing

↓

Queue Filling

↓

Timeouts

↓

503 Errors

This condition is commonly referred to as thread pool exhaustion.

Tomcat Configuration

Typical connector settings:

<Connector
    port="8080"
    maxThreads="200"
    acceptCount="100"
    maxConnections="8192"/>

Meaning:

Property	Description
maxThreads	Maximum request-processing threads
acceptCount	Maximum queued requests after all worker threads are busy
maxConnections	Maximum simultaneous network connections accepted by the connector
Spring Boot Configuration

Using embedded Tomcat:

server.tomcat.threads.max=200
server.tomcat.accept-count=100

Spring Boot passes these settings to the embedded Tomcat connector.

Thread Pool vs CPU

Suppose:

CPU

4 Cores

Config:

500 Threads

Does:

500 Threads

=

500 CPUs

No.

Only a limited number of threads can execute simultaneously—roughly one runnable thread per CPU core (per hardware thread). The operating system scheduler rapidly switches between runnable threads.

Too many runnable threads increase context-switch overhead.

Thread Pool vs Database

Suppose:

Tomcat

200 Threads

Database connection pool:

20 Connections

Execution:

200 Threads

↓

20 Database Connections

180 threads may wait for database connections if every request requires database access.

The database pool can become the bottleneck even when Tomcat has idle capacity.

Load Testing Example

Run:

ab -n 10000 -c 300 \
http://localhost:8080/students/1051110001

Observe:

Worker Threads

↓

Busy

Monitor:

jcmd <PID> Thread.print

Look for:

http-nio-8080-exec-*

These are Tomcat worker threads.

Kubernetes Example

Suppose:

2 Pods

↓

200 Threads Each

Total processing capacity is influenced by:

Available CPU
Available memory
Database capacity
External services

Adding Pods often improves throughput more effectively than continually increasing thread counts within a single Pod.

Performance Tuning

Avoid simply increasing:

maxThreads

↓

1000

Instead investigate:

CPU utilization
Database performance
Slow queries
Blocking I/O
External API latency
JVM garbage collection
Connection pool sizing
Hands-on Lab
View Current Threads
jcmd <PID> Thread.print

Search:

http-nio
Generate Load
ab -n 5000 -c 300 \
http://localhost:8080/students/1051110001
Observe CPU
top
Observe Connections
ss -tn
Watch Kubernetes
kubectl top pods

If HPA is enabled, observe whether additional Pods are created under sustained CPU load.

Common Mistakes
❌ Thinking More Threads Always Increase Performance

Beyond a certain point:

Context switching increases.
Memory usage grows.
Lock contention increases.
CPU efficiency decreases.

More threads are not always better.

❌ Ignoring Downstream Bottlenecks

Increasing Tomcat threads does not help if:

The database connection pool is exhausted.
The database is slow.
An external API is slow.

Always identify the true bottleneck first.

❌ Confusing Connections with Threads

A server may accept many TCP connections, but only a limited number of requests can execute concurrently based on available worker threads and the connector configuration.

Thread Pool Workflow
Client Request
       │
       ▼
TCP Connection
       │
       ▼
Tomcat Connector
       │
       ▼
Worker Thread Pool
       │
       ▼
Spring Boot
       │
       ▼
Database
       │
       ▼
Response
Useful Configuration
Setting	Purpose
server.tomcat.threads.max	Maximum Tomcat worker threads
server.tomcat.accept-count	Maximum queued requests
maxConnections	Maximum accepted connections
top	Monitor CPU usage
jcmd <PID> Thread.print	Inspect Tomcat worker threads
💡 Key Takeaways

✅ Tomcat uses a reusable thread pool rather than creating a new thread for every request.

✅ Incoming requests are processed by worker threads; excess requests wait in a queue until a worker becomes available.

✅ Thread pool size should be tuned based on workload characteristics, CPU resources, and downstream dependencies.

✅ Increasing the thread count alone does not guarantee better performance and can reduce efficiency if taken too far.

✅ Database connection pools, external services, CPU limits, and Kubernetes scaling all influence overall application throughput.

➡️ Next Chapter

📘 12-Performance/05-ConnectionPool.md

In the next chapter, we'll explore database connection pools.

You'll learn:

🗄️ Why opening a database connection for every request is expensive
🏊 How HikariCP manages reusable database connections
🔄 Connection acquisition and release
⏳ Pool exhaustion and timeouts
⚖️ How to size the connection pool relative to Tomcat worker threads
☸️ Best practices for Spring Boot applications running in Docker and Kubernetes
