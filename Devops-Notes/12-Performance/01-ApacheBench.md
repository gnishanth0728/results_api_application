📘 Chapter 104 — ApacheBench (ab)

📂 File: student-results-api-notes/12-Performance/01-ApacheBench.md

🌍 Introduction

So far in this course we've focused on correctness and observability.

Now we move to performance.

Imagine your Student Results API is deployed.

A single request succeeds:

GET /students/1051110001

↓

200 OK

But production traffic looks more like:

1 User

↓

100 Users

↓

1,000 Users

↓

10,000 Users

How do we determine whether the application can handle that load?

The answer is:

🚀 ApacheBench (ab)

ApacheBench generates many HTTP requests and measures how the server responds under load.

🎯 Learning Objectives

After completing this chapter you will understand:

🚀 What ApacheBench is
📈 Load Testing
👥 Concurrency
📊 Requests per Second
⏱️ Latency
❌ Failed Requests
🐳 Docker Testing
☸️ Kubernetes Testing
🍃 Student Results API Benchmarking
📉 Performance Interpretation
❓ What is ApacheBench?

ApacheBench (ab) is a command-line HTTP benchmarking tool distributed with the Apache HTTP Server project.

It sends multiple HTTP requests to a server and measures its performance.

Example:

ab -n 1000 http://localhost:8080/

This sends 1000 HTTP requests.

Basic Architecture
ApacheBench

↓

HTTP Requests

↓

Spring Boot

↓

Tomcat

↓

Student Results API
Installing ApacheBench

Ubuntu/Debian:

sudo apt install apache2-utils

Verify:

ab -V
First Benchmark

Run:

ab -n 100 http://localhost:8080/

Options:

Option	Meaning
-n	Total number of requests
URL	Target endpoint
Concurrency

Suppose:

100 Requests

↓

1 at a time

That isn't realistic.

Instead:

ab -n 1000 -c 50 http://localhost:8080/

Meaning:

1000 Requests

50 Concurrent Users

Concurrency represents the number of requests ApacheBench attempts to keep in flight simultaneously.

Understanding the Output

Example:

Requests per second:

1520

Meaning:

Server

↓

1520 Requests/sec

This is one of the most important metrics.

Time Per Request

Output:

Time per request:

25 ms

This is the average latency for a request.

ApacheBench also reports an adjusted value that accounts for concurrency, so read the labels carefully.

Failed Requests

Output:

Failed requests:

0

Ideal:

0

Failures may indicate:

Timeouts
Connection failures
Server errors
Network issues
Transfer Rate

Output:

Transfer rate

25 MB/sec

Measures throughput.

Student Results API Example

Endpoint:

GET

/students/1051110001

Benchmark:

ab -n 5000 -c 100 \
http://localhost:8080/students/1051110001

Observe:

Requests/sec
Failed requests
Response time
Docker Example

Container:

docker run -p 8080:8080 student-api

Benchmark:

ab -n 1000 -c 50 \
http://localhost:8080/students/1051110001

Monitor simultaneously:

top

Observe:

CPU
Memory
Kubernetes Example

Expose:

kubectl port-forward \
service/student-api \
8080:8080

Benchmark:

ab -n 5000 -c 100 \
http://localhost:8080/students/1051110001

Watch Pods:

kubectl get pods -w

If HPA is enabled, you may observe additional Pods being created as load increases, depending on the configured scaling thresholds.

Observing Performance

While ApacheBench runs:

Terminal 1:

ab -n 10000 -c 200 ...

Terminal 2:

top

Terminal 3:

jcmd <PID> Thread.print

Terminal 4:

ss -tn

You can observe:

CPU usage
Thread utilization
Network connections
Application responsiveness
Reading Percentiles

ApacheBench reports latency percentiles such as:

50%

66%

75%

80%

90%

95%

98%

99%

100%

Example:

95%

120 ms

Meaning:

95% of requests completed within 120 ms.

Percentiles are generally more informative than averages because they reveal tail latency.

Complete Performance Flow
ApacheBench
      │
      ▼
HTTP Requests
      │
      ▼
Tomcat
      │
      ▼
Worker Threads
      │
      ▼
Spring Boot
      │
      ▼
Hibernate
      │
      ▼
PostgreSQL

Every layer contributes to the observed response time.

Hands-on Lab
Verify Application
curl http://localhost:8080/students/1051110001

Ensure the endpoint responds successfully before benchmarking.

Simple Benchmark
ab -n 100 http://localhost:8080/
Concurrent Benchmark
ab -n 5000 -c 100 \
http://localhost:8080/students/1051110001
Watch CPU
top
Watch Connections
ss -tn
Watch Threads
jcmd <PID> Thread.print
Common Mistakes
❌ Thinking One Successful Request Means the System Is Fast

Applications often behave very differently under concurrent load.

Always test with realistic concurrency.

❌ Running Benchmarks from a Slow Client

The machine running ApacheBench can become the bottleneck.

Monitor both the client and the server, especially at high request rates.

❌ Using Only Average Response Time

Average latency can hide slow requests.

Always examine:

Requests/sec
Failed requests
Latency percentiles
❌ Forgetting Warm-up Effects

The first benchmark may include:

JVM JIT compilation
Class loading
Connection establishment
Database cache warm-up

Run multiple tests and compare stable results.

Useful Commands
Command	Purpose
ab -V	Show version
ab -n 100 URL	Send 100 requests
ab -n 1000 -c 50 URL	Benchmark with concurrency
ab -k -n 1000 -c 50 URL	Use HTTP Keep-Alive connections
ab -g results.tsv ...	Export results for graphing
ApacheBench vs curl
curl	ab
Single request	Many requests
Functional testing	Performance testing
Manual inspection	Load generation
Verifies correctness	Measures throughput and latency
💡 Key Takeaways

✅ ApacheBench is a lightweight HTTP benchmarking tool for load testing web applications.

✅ The most important parameters are -n (total requests) and -c (concurrency).

✅ Key metrics include requests per second, latency, failed requests, throughput, and latency percentiles.

✅ Combine ApacheBench with observability tools such as top, jcmd, ss, and kubectl to understand how your application behaves under load.

✅ ApacheBench is ideal for learning HTTP performance concepts, while more advanced tools such as wrk, k6, and JMeter are better suited for complex production load-testing scenarios.

➡️ Next Chapter

📘 12-Performance/02-JMeter.md

In the next chapter, we'll explore Apache JMeter, a full-featured load and performance testing platform.

You'll learn:

👥 Simulating thousands of virtual users
🔄 Creating realistic user journeys
🔐 Authentication and session handling
📊 HTML reports and performance graphs
☸️ Load testing Spring Boot applications running in Docker and Kubernetes
📈 Stress testing, soak testing, and spike testing

By the end of that chapter, you'll know how to build production-grade performance tests rather than simple HTTP benchmarks.
