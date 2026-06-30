📘 Chapter 103 — Complete Production Debugging Workflow

📂 File: student-results-api-notes/11-Observability/11-Complete-Debugging-Workflow.md

🌍 Introduction

Imagine it's 2:00 AM.

Your monitoring system sends an alert.

🚨 Production Incident

Student Results API

Status:
503 Service Unavailable

Users cannot access:

GET /students/1051110001

Where do you begin?

Should you immediately:

jstack

No.

Should you restart Kubernetes?

No.

Should you restart PostgreSQL?

No.

Production debugging always starts with collecting evidence, not guessing.

🎯 Learning Objectives

After completing this chapter you will understand:

A systematic debugging methodology
How to troubleshoot from the outside in
Which tool to use at each layer
Common production scenarios
Docker debugging
Kubernetes debugging
JVM debugging
Network debugging
Memory debugging
CPU debugging
The Seven-Layer Debugging Model

Always think in layers.

User
    │
    ▼
Network
    │
    ▼
Container
    │
    ▼
Process
    │
    ▼
JVM
    │
    ▼
Application
    │
    ▼
Database

Never skip layers.

Production Workflow
Incident

↓

Reproduce

↓

Collect Evidence

↓

Locate Layer

↓

Verify Root Cause

↓

Fix

↓

Validate

↓

Monitor

Never jump directly to the fix.

Scenario 1 — Application Is Down

Users report:

503 Service Unavailable
Step 1

Can the server be reached?

ping

curl

traceroute

If the server itself is unreachable:

Stop.

It is not a Java problem.

Step 2

Is the port listening?

ss -ltnp

Expected:

8080

java

No listening socket?

Application isn't running.

Step 3

Is Java running?

ps -ef | grep java

No process?

Application crashed.

Step 4

Check logs.

journalctl

docker logs

kubectl logs

Never troubleshoot blindly.

Scenario 2 — High CPU

Monitoring:

CPU

100%

Workflow:

top

↓

Find Java PID

↓

top -H -p <PID>

↓

Find busy thread

↓

jcmd <PID> Thread.print

(or jstack <PID>)

↓

Locate infinite loop or expensive computation.

Scenario 3 — High Memory

Symptoms:

Java

RSS

12 GB

Workflow:

top

↓

jcmd <PID> GC.heap_info

↓

jmap -histo

↓

Heap Dump

↓

MAT

↓

Find leak.

Remember:

High RSS

≠

Heap Leak

Investigate heap, native memory, and thread count before drawing conclusions.

Scenario 4 — Application Hangs

Symptoms:

No response

CPU:

5%

Workflow:

ps

↓

Java exists?

↓

jcmd Thread.print

↓

Blocked threads?

↓

Deadlock?

↓

Database waiting?

Scenario 5 — Port Already Used

Application:

8080 already in use

Run:

sudo lsof -i :8080

Output:

java

PID 5201

Now:

stop that process if appropriate, or
change the application's listening port.
Scenario 6 — Database Connection Failure

Application:

Connection refused

Check:

ss -tn

↓

tcpdump port 5432

↓

strace

Observe:

connect()

↓

ECONNREFUSED

Now you know the operating system rejected the connection.

Scenario 7 — Configuration Missing

Application:

application.properties

not found

Run:

strace -e trace=file

Output:

ENOENT

Now you know exactly which path the application attempted to access.

Scenario 8 — Kubernetes Pod Restarting
kubectl get pods

↓

CrashLoopBackOff

Check:

kubectl describe pod

↓

kubectl logs

↓

If OOMKilled:

jcmd

jmap

↓

If probe failure:

ss

curl

logs
Scenario 9 — Docker Container Starts Then Exits
docker ps -a

↓

docker logs

↓

docker inspect

↓

Entry point?

↓

CMD?

↓

Application exception?

Scenario 10 — Slow API

Workflow:

curl

↓

top

↓

jcmd Thread.print

↓

Database

↓

tcpdump

↓

Wireshark

Determine whether the delay is:

CPU
Lock contention
Database
Network
External service
Which Tool Should I Use?
Problem	First Tool	Then
Process missing	ps	Logs
High CPU	top	top -H, jcmd Thread.print
High Memory	top	jcmd GC.heap_info, jmap
Thread hang	jcmd Thread.print	Thread analysis
Port issue	ss, lsof	tcpdump
Network	ss	tcpdump, Wireshark
Missing file	strace	File permissions
Memory leak	jmap	MAT
Deadlock	jcmd Thread.print	Lock analysis
Kubernetes restart	kubectl describe, kubectl logs	JVM/Linux tools
Complete End-to-End Flow
User
    │
    ▼
Browser
    │
    ▼
DNS
    │
    ▼
TCP
    │
    ▼
Ingress
    │
    ▼
Service
    │
    ▼
Pod
    │
    ▼
Container
    │
    ▼
Java Process
    │
    ▼
JVM
    │
    ▼
Tomcat
    │
    ▼
Spring Boot
    │
    ▼
Hibernate
    │
    ▼
PostgreSQL

You now know how to observe every layer.

Production Checklist

Before changing anything, ask:

Is the process running?
Is the application listening?
Are logs available?
Is CPU high?
Is memory high?
Are threads blocked?
Is the database reachable?
Is DNS working?
Is Kubernetes healthy?
Is Docker healthy?
Is the filesystem accessible?

Evidence first.

Hypotheses second.

Fixes last.

Common Mistakes
❌ Restarting Before Collecting Data

A restart often destroys valuable evidence such as logs, thread states, and process information.

Capture diagnostics first whenever practical.

❌ Looking Only at One Layer

A Java application may appear healthy while:

PostgreSQL is unavailable
DNS is failing
The network path is broken
A Kubernetes readiness probe is failing

Always examine the entire request path.

❌ Assuming the First Error Is the Root Cause

Many log messages are secondary effects.

Look for the earliest meaningful error and confirm it with additional evidence.

The Debugging Pyramid
           User Symptoms
                 │
                 ▼
          Application Logs
                 │
                 ▼
          JVM Diagnostics
                 │
                 ▼
          Linux Processes
                 │
                 ▼
          Network
                 │
                 ▼
          Kernel/System Calls

Work downward until you find the layer where reality no longer matches expectations.

The Complete Toolset
Layer	Tool
Process	ps
CPU	top
JVM Threads	jcmd Thread.print / jstack
JVM Memory	jcmd, jmap
Network Sockets	ss
Open Files	lsof
System Calls	strace
Packets	tcpdump
Packet Analysis	Wireshark
Containers	docker, docker logs, docker inspect
Kubernetes	kubectl, kubectl logs, kubectl describe
💡 Final Takeaways

✅ Effective production debugging is a structured investigation, not trial and error.

✅ Start from the symptom and move layer by layer until you identify the root cause.

✅ Use the right tool for the right layer:

ps for processes
top for CPU and memory
jcmd/jstack for JVM threads
jmap for heap analysis
ss and lsof for sockets and files
strace for kernel interactions
tcpdump and Wireshark for network traffic

✅ Collect evidence before making changes whenever possible.

✅ Corroborate findings across multiple tools before concluding you've found the root cause.

🎉 End of the Course

By completing this roadmap, you've followed the full execution path of a backend request:

User
   ↓
Browser
   ↓
HTTP
   ↓
DNS
   ↓
TCP/IP
   ↓
Ingress
   ↓
Service
   ↓
Pod
   ↓
Container
   ↓
Linux Process
   ↓
JVM
   ↓
Tomcat
   ↓
Spring Boot
   ↓
Controller
   ↓
Service
   ↓
Repository
   ↓
Hibernate
   ↓
PostgreSQL
   ↓
Storage

You also learned how to observe and debug each layer using the appropriate Linux, JVM, Docker, and Kubernetes tools. This provides a solid foundation for diagnosing real-world production issues in modern Java backend systems.
