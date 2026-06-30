📘 Chapter 109 — Performance Observations & Bottleneck Analysis

📂 File: student-results-api-notes/12-Performance/07-Observations.md

🌍 Introduction

In the previous chapters, we learned how to:

Generate load
Measure throughput
Tune thread pools
Tune connection pools
Optimize database queries

But another important question appears:

🤔 How do we identify the real bottleneck?

Suppose your Student Results API becomes slow.

Should you:

Increase Tomcat threads?
Increase HikariCP connections?
Add Kubernetes Pods?
Upgrade PostgreSQL?
Buy a faster server?

Not immediately.

First:

Observe the system.

Performance tuning should always be evidence-driven.

🎯 Learning Objectives

After completing this chapter you will understand:

🔍 Performance Observation
📊 Bottleneck Identification
🧵 Thread Analysis
🏊 Connection Pool Analysis
🗄️ Database Analysis
☸️ Kubernetes Scaling Observations
📈 Performance Metrics
🚀 Systematic Performance Tuning
The Performance Pyramid

Always investigate from the top down.

User Experience
        │
        ▼
API Response Time
        │
        ▼
Application
        │
        ▼
JVM
        │
        ▼
Operating System
        │
        ▼
Database
        │
        ▼
Infrastructure

A slow response at the top may originate from any lower layer.

Observation 1 — High Response Time

Suppose:

GET /students/1051110001

↓

2.5 Seconds

Question:

Where is the time being spent?

Possible causes:

Waiting for a Tomcat thread
Waiting for a database connection
Slow SQL query
External API call
Network latency
Garbage collection pause

Measure before changing configuration.

Observation 2 — CPU Is Low

Example:

CPU

15%

Yet:

API

3 Seconds

Low CPU does not mean the application is healthy.

It may indicate that threads are waiting rather than executing.

Possible reasons:

Database locks
Slow queries
External service latency
Connection pool exhaustion
Disk I/O
Observation 3 — CPU Is High

Example:

CPU

100%

Possible causes:

Excessive computation
Infinite loops
Heavy serialization
Compression
Encryption
Garbage collection activity

Investigate using:

top

top -H

jcmd <PID> Thread.print
Observation 4 — Many Waiting Threads

Suppose:

200 Tomcat Threads

Most thread dumps show:

WAITING

TIMED_WAITING

Possible reasons:

Waiting for database connections
Waiting for SQL execution
Waiting for remote APIs
Waiting on locks

More Tomcat threads will not solve these problems.

Observation 5 — Connection Pool Exhaustion

Configuration:

HikariCP

20 Connections

Traffic:

200 Concurrent Requests

Symptoms:

Increased response time
Threads blocked waiting for a connection
Connection timeout exceptions

Investigate:

Active connections
Long-running SQL
Transaction duration
Observation 6 — Slow SQL

Example:

SELECT *
FROM students
WHERE roll_number = ?;

Run:

EXPLAIN ANALYZE

If you see:

Seq Scan

instead of:

Index Scan

the missing or unused index may be the root cause.

Observation 7 — Database Connections Keep Increasing

Example:

pg_stat_activity

↓

300 Active Connections

Possible causes:

Connection leaks
Excessively large connection pools
Too many application replicas
Long-running transactions
Observation 8 — More Pods Didn't Help

Deployment:

2 Pods

↓

8 Pods

API latency remains unchanged.

Possible bottlenecks:

Database saturation
Shared storage
External API dependency
Network bandwidth

Horizontal scaling only helps when the bottleneck is inside the application tier.

Observation 9 — High Memory

Example:

Memory

90%

Determine:

JVM heap usage
Native memory usage
Thread count
Page cache
Database buffers

Use:

jcmd <PID> GC.heap_info

jmap -histo
Observation 10 — High Network Latency

Example:

Response Time

↓

4 Seconds

CPU:

10%

Database:

5 ms

Investigate:

ss

tcpdump

Wireshark

The bottleneck may be in the network.

Typical Bottlenecks
Symptom	Likely Bottleneck	First Tool
High CPU	Application code	top
High Memory	JVM / Native Memory	jcmd, jmap
Slow SQL	Database	EXPLAIN ANALYZE
Waiting Threads	Connection pool / Locks	jcmd Thread.print
Many TCP Retries	Network	tcpdump
High Error Rate	Application / Infrastructure	Logs
Low CPU + Slow API	Waiting on external resources	Thread dump + SQL analysis
End-to-End Observation Workflow
Slow API
      │
      ▼
Measure Response Time
      │
      ▼
Check CPU
      │
      ▼
Check Memory
      │
      ▼
Check Thread Dump
      │
      ▼
Check Connection Pool
      │
      ▼
Check SQL
      │
      ▼
Check Network
      │
      ▼
Identify Bottleneck
      │
      ▼
Optimize
      │
      ▼
Retest
Student Results API Case Study

Suppose a load test reports:

500 Requests/sec

↓

Average Latency

1.8 Seconds

Observation:

CPU: 18%
Memory: 45%
Tomcat Threads: 180 waiting
HikariCP: 20/20 active
PostgreSQL: Several slow queries performing sequential scans

Conclusion:

The application server is not the bottleneck.

The database layer is limiting throughput.

Correct actions:

Add or improve indexes.
Optimize slow SQL queries.
Reduce transaction duration.
Retest after each change.

Changing Tomcat's thread count alone would not solve the problem.

Performance Tuning Principles
Measure before changing anything.
Change one variable at a time.
Retest after every change.
Compare results using the same workload.
Optimize the bottleneck, not the symptom.
Common Mistakes
❌ Tuning Without Measurements

Changing configuration without baseline metrics makes it impossible to know whether performance improved.

❌ Optimizing the Wrong Layer

If SQL takes 900 ms, reducing JSON serialization from 5 ms to 2 ms has almost no impact on total response time.

Focus on the largest contributor first.

❌ Watching Only CPU

Performance depends on many resources:

CPU
Memory
Threads
Database
Network
Disk
External services
❌ Scaling Before Understanding

Adding:

More Pods
More Threads
More Database Connections

may increase resource consumption without improving throughput.

Always identify the bottleneck first.

Performance Investigation Checklist
✓ Response Time Measured

✓ Throughput Measured

✓ CPU Checked

✓ Memory Checked

✓ Thread Dump Reviewed

✓ Connection Pool Reviewed

✓ SQL Plan Reviewed

✓ Network Checked

✓ Bottleneck Confirmed

✓ Optimization Retested
Performance Observation Matrix
Observation	What It May Mean	Verify With
High response time	Bottleneck somewhere in request path	End-to-end timing
High CPU	Compute-bound workload	top, jcmd
Low CPU + Slow API	Waiting on I/O or locks	Thread dump
Full connection pool	Database contention	Hikari metrics, pg_stat_activity
Sequential scan	Missing or unsuitable index	EXPLAIN ANALYZE
High network latency	Network bottleneck	ss, tcpdump, Wireshark
Frequent GC pauses	Memory pressure	GC logs, jcmd
💡 Key Takeaways

✅ Performance tuning starts with observation, not configuration changes.

✅ A bottleneck can exist in the application, JVM, database, network, or infrastructure.

✅ CPU utilization alone is not a reliable indicator of application health.

✅ Always correlate multiple metrics before deciding on a fix.

✅ Measure → Analyze → Optimize → Retest is the core performance engineering cycle.

➡️ Next Chapter

📘 13-Security/01-Security-Fundamentals.md

The next section moves from performance to application and infrastructure security.

You'll begin with:

🔐 CIA triad (Confidentiality, Integrity, Availability)
🔑 Authentication vs Authorization
🛡️ Common attack surfaces
🌐 Security across Spring Boot, Docker, and Kubernetes
🚀 Building secure production-ready backend systems
