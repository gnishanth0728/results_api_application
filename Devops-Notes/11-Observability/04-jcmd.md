📘 Chapter 96 — JVM jcmd

📂 File: student-results-api-notes/11-Observability/04-jcmd.md

🌍 Introduction

In the previous chapter, we learned about jstack.

jstack answers:

What are the JVM threads doing?

But another important question appears:

🤔 What if we need much more than thread dumps?

Suppose we want to know:

JVM version
Heap usage
Garbage Collector
Running threads
Loaded classes
Native memory
System properties
JVM flags
Trigger GC
Generate Heap Dump

Should we learn ten different commands?

The answer is:

☕ jcmd

jcmd is the universal JVM diagnostic command.

It communicates with a running JVM and exposes almost every internal diagnostic function.

🎯 Learning Objectives

After completing this chapter you will understand:

What jcmd is
JVM Diagnostic Commands
Heap Information
Thread Dumps
Garbage Collection
Heap Dumps
Native Memory Tracking
JVM Flags
System Properties
Spring Boot Debugging
❓ What is jcmd?

jcmd is the primary JVM diagnostic tool included with the JDK.

Instead of:

jstack
jmap
jinfo

Modern JVMs encourage:

jcmd

It sends diagnostic commands to a running JVM.

🏗 Architecture
Java Process
      │
      ▼
Diagnostic Command Interface
      │
      ▼
jcmd

Unlike ps, which talks to Linux,

jcmd talks directly to the JVM.

Finding Running JVMs

The simplest command is:

jcmd

Example output:

5421 student-results-api.jar
6152 Jps

This shows every running JVM.

JVM Version
jcmd <PID> VM.version

Example:

OpenJDK 21

Useful for verifying which Java version is actually running.

JVM Command Line
jcmd <PID> VM.command_line

Output:

java
-Xms512m
-Xmx2g
-jar student-results-api.jar

Useful for debugging startup options.

JVM Flags
jcmd <PID> VM.flags

Example:

-Xmx2G
-Xms512M
-XX:+UseG1GC

Useful for checking:

Heap size
GC algorithm
JVM tuning
System Properties
jcmd <PID> VM.system_properties

Example:

java.version

user.home

os.name

file.encoding

Equivalent to:

System.getProperties()
Heap Information
jcmd <PID> GC.heap_info

Example:

Garbage Collector

G1

Heap

1024 MB

Shows:

Heap size
Regions
GC configuration
Trigger Garbage Collection
jcmd <PID> GC.run

Execution:

jcmd

↓

JVM

↓

Run GC

Useful during troubleshooting.

Avoid running this routinely in production unless you understand the impact.

Generate Thread Dump

Instead of:

jstack <PID>

Use:

jcmd <PID> Thread.print

Output:

main

http-nio-8080-exec-1

GC Thread

This is the modern replacement for jstack.

Generate Heap Dump
jcmd <PID> GC.heap_dump heap.hprof

Execution:

Running JVM

↓

Heap Dump

↓

heap.hprof

Later analyze with:

Eclipse MAT
VisualVM
JProfiler
Native Memory Tracking
jcmd <PID> VM.native_memory summary

Example:

Java Heap

Threads

Code Cache

Class Metadata

This requires Native Memory Tracking (NMT) to be enabled when the JVM starts (typically with -XX:NativeMemoryTracking=summary or detail).

Useful for finding native memory leaks.

Loaded Classes
jcmd <PID> GC.class_histogram

Example:

java.lang.String

Student

HashMap

Shows the number of live instances and bytes consumed by each class.

Very useful when investigating memory problems.

Student Results API Example

Application:

Spring Boot

↓

Student Results API

Find JVM:

jcmd

Output:

5121 student-results-api.jar

Check heap:

jcmd 5121 GC.heap_info

Thread dump:

jcmd 5121 Thread.print

Heap dump:

jcmd 5121 GC.heap_dump heap.hprof

Everything is available from one tool.

Docker Example

Find Java:

docker exec container ps -ef

Run:

docker exec container jcmd <PID> VM.version

If the container includes only a JRE, jcmd may not be available. It is part of the JDK.

Kubernetes Example
kubectl exec -it student-api-pod -- sh

Find JVM:

jcmd

Example:

1 student-results-api.jar

Generate thread dump:

jcmd 1 Thread.print

Generate heap dump:

jcmd 1 GC.heap_dump /tmp/heap.hprof

Copy:

kubectl cp student-api-pod:/tmp/heap.hprof .
Useful Commands
Command	Purpose
jcmd	List running JVMs
jcmd <PID> VM.version	JVM version
jcmd <PID> VM.flags	JVM startup flags
jcmd <PID> VM.command_line	Startup command
jcmd <PID> VM.system_properties	System properties
jcmd <PID> Thread.print	Thread dump
jcmd <PID> GC.heap_info	Heap information
jcmd <PID> GC.class_histogram	Live object histogram
jcmd <PID> GC.heap_dump file.hprof	Heap dump
jcmd <PID> VM.native_memory summary	Native memory usage (if NMT is enabled)
jcmd vs Older JVM Tools
Tool	Primary Purpose	Modern jcmd Equivalent
jstack	Thread dump	Thread.print
jmap	Heap dump	GC.heap_dump
jmap -histo	Class histogram	GC.class_histogram
jinfo	JVM flags	VM.flags
jinfo	System properties	VM.system_properties
Complete Troubleshooting Workflow
Application Slow
       │
       ▼
ps
       │
       ▼
Find Java PID
       │
       ▼
top
       │
       ▼
High CPU?
       │
       ▼
jcmd
       ├── Thread.print
       ├── GC.heap_info
       ├── GC.class_histogram
       ├── VM.flags
       ├── VM.native_memory
       └── GC.heap_dump
Hands-on Lab
List JVMs
jcmd
View JVM Version
jcmd <PID> VM.version
View Heap
jcmd <PID> GC.heap_info
View Threads
jcmd <PID> Thread.print
View JVM Flags
jcmd <PID> VM.flags
Generate Heap Dump
jcmd <PID> GC.heap_dump heap.hprof
Common Mistakes
❌ Thinking jcmd Works with a JRE

jcmd is included with the JDK. Minimal runtime images created with jlink or JRE-only environments may not include it.

❌ Running Heap Dumps Frequently in Production

Heap dumps can be very large (hundreds of MB to several GB) and may briefly affect application performance and consume disk space.

❌ Confusing Heap Memory with Native Memory

GC.heap_info reports Java heap usage.

VM.native_memory summary reports native memory usage outside the Java heap (when NMT is enabled).

Key Takeaways

✅ jcmd is the modern, all-in-one JVM diagnostic tool.

✅ It can replace many common uses of jstack, jmap, and jinfo.

✅ It provides thread dumps, heap information, class histograms, JVM flags, system properties, and heap dumps from a single command interface.

✅ It is the preferred diagnostic tool for modern JDKs (Java 11, 17, 21 and later).

✅ Combining ps, top, and jcmd gives you a complete workflow for troubleshooting Java applications in Docker and Kubernetes.

➡️ Next Chapter

📘 11-Observability/05-jstat.md

In the next chapter, we'll explore jstat, the JVM statistics monitoring tool.

You'll learn:

📊 How to monitor garbage collection in real time
🗑️ Young vs Old Generation behavior
⏱️ GC frequency and pause analysis
📈 Heap utilization trends
🚀 Using jstat to diagnose excessive GC activity and memory pressure without generating heap dumps
