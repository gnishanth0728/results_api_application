# 📘 Chapter 40 — Tomcat Thread Pool

> 📂 File: `student-results-api-notes/05-Tomcat/06-ThreadPool.md`

This is an excellent place to introduce Tomcat's Thread Pool, because readers now understand:

✅ Acceptor Thread
✅ Poller Thread
✅ Worker Thread

The next logical question is:

Where do all those http-nio-8080-exec-* threads come from?

This chapter explains the Executor, thread pool, request queue, maxThreads, minSpareThreads, acceptCount, and how Tomcat handles 10,000+ concurrent users. It also connects directly to Linux threads, JVM threads, Docker CPU limits, and Kubernetes resource limits.

---

# 🌍 Introduction

In the previous chapter, we learned that every HTTP request is processed by a **Tomcat Worker Thread**.

Example:

```text
http-nio-8080-exec-1

http-nio-8080-exec-2

http-nio-8080-exec-3

...

http-nio-8080-exec-200
```

Now another important question appears:

> 🤔 **Who creates these threads?**

Does Tomcat create:

* One thread per request?
* One thread per connection?
* One thread forever?

The answer is **No**.

Tomcat creates a **Thread Pool**.

Instead of constantly creating and destroying threads, Tomcat reuses them.

This dramatically improves performance.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 👷 What a Thread Pool is
* ⚙️ Tomcat Executor
* 🧵 Worker Thread lifecycle
* 📋 Request queue
* 📈 maxThreads
* 📉 minSpareThreads
* 📦 acceptCount
* 🚀 Thread reuse
* 🍃 Spring Boot configuration
* 🐳 Docker CPU considerations
* ☸️ Kubernetes scaling
* 🧪 Thread pool monitoring

---

# ❓ Why Does Tomcat Need a Thread Pool?

Imagine 10,000 HTTP requests arrive.

Without a thread pool:

```text
Request 1

↓

Create Thread

↓

Destroy Thread

↓

Request 2

↓

Create Thread

↓

Destroy Thread

↓

Request 3
```

Problems:

* ❌ Thread creation is expensive.
* ❌ Thread destruction is expensive.
* ❌ Frequent memory allocation.
* ❌ High CPU overhead.

Instead:

```text
Request

↓

Existing Worker Thread

↓

Execute

↓

Return Thread

↓

Next Request
```

The thread is reused many thousands of times.

---

# 🏗️ High-Level Architecture

```text
                    Browser
                        │
                        ▼
                 TCP Connection
                        │
                        ▼
                 Poller Thread
                        │
                        ▼
+-------------------------------------------------------+
|                  Tomcat Executor                      |
|-------------------------------------------------------|
|  👷 Worker Thread 1                                   |
|  👷 Worker Thread 2                                   |
|  👷 Worker Thread 3                                   |
|  👷 Worker Thread 4                                   |
|  👷 Worker Thread N                                   |
|-------------------------------------------------------|
|            Waiting Request Queue                      |
+-------------------------------------------------------+
```

The Executor manages all worker threads.

---

# 👷 Worker Thread Lifecycle

A worker thread follows this lifecycle:

```text
Created

↓

Idle

↓

Assigned Request

↓

Execute Spring Boot

↓

Response Sent

↓

Idle

↓

Next Request

↓

Eventually Destroyed
```

The thread usually lives much longer than a single HTTP request.

---

# 📋 Request Queue

Suppose:

```text
200 Worker Threads

↓

200 Busy

↓

50 New Requests
```

Where do the new requests go?

They wait in the **request queue**.

```text
Poller

↓

Executor Queue

↓

Waiting Requests

↓

Worker Becomes Free

↓

Execute Request
```

If the queue becomes full, Tomcat begins rejecting new connections.

---

# 📈 maxThreads

`maxThreads` defines the maximum number of worker threads.

Example:

```properties
server.tomcat.threads.max=200
```

Meaning:

```text
Maximum Worker Threads

=

200
```

If 200 requests are executing simultaneously:

```text
Request 201

↓

Wait Queue
```

No additional worker thread is created.

---

# 📉 minSpareThreads

Tomcat keeps a minimum number of idle worker threads ready.

Example:

```properties
server.tomcat.threads.min-spare=10
```

Meaning:

```text
10 Threads

↓

Already Waiting

↓

Ready Immediately
```

This reduces latency for new requests.

---

# 📦 acceptCount

Suppose:

```text
200 Busy Threads

+

Queue Full
```

New TCP connections enter the **accept backlog**.

Configuration:

```properties
server.tomcat.accept-count=100
```

Flow:

```text
Connection

↓

Accept Queue

↓

Wait

↓

Worker Available

↓

Execute
```

If the backlog is also full, the operating system may refuse new connections.

---

# 🌐 Complete Request Scheduling

Suppose:

```text
500 Concurrent Users
```

Tomcat:

```text
500 Requests

↓

Poller

↓

Thread Pool

↓

200 Running

↓

300 Waiting

↓

Worker Finishes

↓

Next Waiting Request
```

The Executor continuously assigns waiting requests to available worker threads.

---

# 🍃 Student Results API Example

Suppose each request performs:

```text
Controller

↓

Service

↓

Repository

↓

PostgreSQL

↓

JSON
```

During execution:

```text
Worker Thread

↓

Blocked Waiting For Database

↓

Cannot Serve Another Request
```

This is why slow database queries reduce overall throughput.

---

# 🔄 Thread Reuse

Worker Thread:

```text
Request A

↓

Controller

↓

Service

↓

Repository

↓

Finished

↓

Request B

↓

Finished

↓

Request C
```

One worker thread may process millions of requests over its lifetime.

---

# 📊 During Your Load Test

Command:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Internally:

```text
200 Concurrent Requests

↓

200 Worker Threads

↓

Requests Finish

↓

Threads Reused

↓

Next Requests Assigned
```

Notice:

Tomcat did **not** create 50,000 threads.

---

# ⚠️ What Happens When All Threads Are Busy?

Suppose:

```text
maxThreads = 200
```

Current state:

```text
200 Busy

↓

Queue

↓

acceptCount

↓

Queue Full

↓

New Connection
```

Eventually:

```text
Connection Refused

or

Timeout
```

Clients begin experiencing failures.

---

# ⚙️ Thread Pool Configuration

Example:

```properties
server.tomcat.threads.max=200
server.tomcat.threads.min-spare=10
server.tomcat.accept-count=100
server.connection-timeout=20s
```

Meaning:

* Maximum worker threads = **200**
* Keep **10** idle threads
* Accept backlog = **100**
* Idle connection timeout = **20 seconds**

---

# 🖥️ Linux Perspective

Remember:

Each Tomcat worker thread is also:

```text
Java Thread

↓

Native Thread

↓

Linux Thread

↓

Scheduled By Linux
```

Tomcat creates the threads.

Linux schedules them on CPU cores.

---

# 🐳 Docker Perspective

Suppose:

```bash
docker run \
--cpus=2 \
student-api
```

Tomcat may have:

```text
200 Worker Threads
```

But:

```text
Only 2 CPU Cores
```

Meaning:

```text
200 Threads

↓

Linux Scheduler

↓

2 CPUs

↓

Context Switching
```

More threads do **not** automatically mean higher performance.

---

# ☸️ Kubernetes Perspective

Example:

```yaml
resources:
  requests:
    cpu: "500m"
  limits:
    cpu: "2"
```

Even if Tomcat has:

```text
200 Worker Threads
```

The container can execute only as much work as the allocated CPU permits.

For increased throughput, it is often better to:

```text
4 Pods

↓

100 Threads Each
```

than:

```text
1 Pod

↓

400 Threads
```

This reduces contention and allows Kubernetes to distribute the workload across multiple nodes.

---

# 🧪 Hands-on Lab

## View Worker Threads

```bash
jstack <PID>
```

Look for:

```text
http-nio-8080-exec-1

http-nio-8080-exec-2
```

---

## Count Native Threads

```bash
ps -Lf -p <PID>
```

Compare the native thread count with Tomcat's configured worker threads.

---

## Monitor Per-Thread CPU

```bash
top -H -p <PID>
```

Watch worker threads become active during load.

---

## Generate Load

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Observe that the same worker threads continue processing requests instead of new threads being created.

---

## Display Open Connections

```bash
ss -tan | grep :8080
```

Correlate active TCP connections with thread pool activity.

---

# 📈 Complete Thread Pool Flow

```text
Browser
      │
      ▼
TCP Connection
      │
      ▼
Acceptor Thread
      │
      ▼
Poller Thread
      │
      ▼
Tomcat Executor
      │
      ▼
Idle Worker Thread
      │
      ▼
DispatcherServlet
      │
      ▼
StudentController
      │
      ▼
StudentService
      │
      ▼
StudentRepository
      │
      ▼
PostgreSQL
      │
      ▼
JSON Response
      │
      ▼
Worker Thread Returns To Pool
```

The worker thread is immediately available to process another request.

---

# 📊 Thread Pool Tuning Guidelines

| Scenario                       | Recommended Action                                                                               |
| ------------------------------ | ------------------------------------------------------------------------------------------------ |
| High CPU usage                 | Reduce thread count or add more CPU                                                              |
| Low CPU, many waiting requests | Increase `maxThreads` if downstream services can handle it                                       |
| Slow database                  | Optimize queries before increasing thread count                                                  |
| Many connection timeouts       | Increase capacity or scale horizontally                                                          |
| Kubernetes deployment          | Prefer multiple Pods with moderate thread counts over a single Pod with a very large thread pool |

---

# 💡 Key Takeaways

✅ Tomcat uses a reusable thread pool instead of creating a new thread for every request.

✅ The Executor assigns ready requests to idle worker threads.

✅ `maxThreads` limits concurrent request processing, while `minSpareThreads` keeps idle workers ready for new traffic.

✅ `acceptCount` controls how many additional connections can wait when all worker threads are busy.

✅ Every Tomcat worker thread maps to one JVM thread and one native Linux thread.

✅ Docker CPU limits and Kubernetes resource limits directly affect how effectively the thread pool can execute requests.

✅ Increasing the thread count is not always the right solution—CPU, database latency, and downstream services are often the real bottlenecks.

---

# ➡️ Next Chapter

📘 **`05-Tomcat/07-Servlet-Container.md`**

In the next chapter, we'll leave the networking layer and enter the **Servlet Container** itself.

We'll explore:

* 📦 What a Servlet is
* 🏛️ Catalina architecture
* 📨 `HttpServletRequest` and `HttpServletResponse`
* 🔄 Servlet lifecycle (`init()`, `service()`, `destroy()`)
* 🌱 How Spring Boot registers the `DispatcherServlet`
* 🚀 How Tomcat invokes your application through the Servlet API

By the end of the next chapter, you'll understand how Tomcat hands control from its networking layer to the Java Servlet infrastructure that powers every Spring Boot web application.
