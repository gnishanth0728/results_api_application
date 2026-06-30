📘 Chapter 97 — JVM jmap

📂 File: student-results-api-notes/11-Observability/05-jmap.md

🌍 Introduction

In previous chapters we learned:

ps

↓

Linux Processes
top

↓

CPU & Memory
jstack

↓

Threads
jcmd

↓

JVM Diagnostics

But another important question appears:

🤔 Which Java objects are consuming heap memory?

Suppose:

Java Process

↓

8 GB RAM

Where is that memory being used?

Inside:

String objects?
HashMaps?
Spring Beans?
Hibernate cache?
Student objects?

The JVM provides:

💾 jmap

jmap inspects the JVM heap and can generate heap dumps for offline analysis.

🎯 Learning Objectives

After completing this chapter you will understand:

What jmap is
JVM Heap Layout
Heap Summary
Class Histogram
Heap Dump
Memory Leak Investigation
Eclipse MAT
VisualVM
Docker Usage
Kubernetes Usage
❓ What is jmap?

jmap is a JDK diagnostic tool that reads JVM memory information.

It can:

Display heap configuration
Display class histograms
Generate heap dumps

Example:

jmap <PID>
JVM Memory

Recall the JVM memory layout:

JVM

├── Heap

├── Metaspace

├── Code Cache

└── Thread Stacks

jmap primarily focuses on the Heap.

Heap Summary

View heap configuration:

jmap -heap <PID>

Example:

Heap Configuration

Max Heap Size

2048 MB

GC Algorithm

G1

Useful information:

Initial Heap
Maximum Heap
GC algorithm
Heap generations/regions
Object Histogram

One of the most useful commands:

jmap -histo <PID>

Example:

#instances

Class

1,200,000

java.lang.String

250,000

Student

80,000

HashMap

This immediately shows:

Number of objects
Memory used
Largest consumers
Heap Dump

Generate:

jmap -dump:live,format=b,file=heap.hprof <PID>

Execution:

Running JVM

↓

Heap Snapshot

↓

heap.hprof

The heap dump can later be analyzed offline.

Heap Dump Analysis

Popular tools:

Eclipse MAT (Memory Analyzer Tool)
VisualVM
JProfiler
YourKit

These tools answer questions like:

Largest objects
Dominator tree
GC roots
Memory leaks
Retained size
Student Results API Example

Suppose:

Student Results API

↓

Memory

7 GB

Run:

jmap -histo <PID>

Example:

Student

2,000,000 Objects

This suggests that Student instances may not be getting garbage collected.

Finding Memory Leaks

Suppose:

Map<String, Student> cache

Every request adds data:

Student

↓

Cache

↓

Never Removed

Memory usage:

500 MB

↓

1 GB

↓

2 GB

↓

4 GB

Generate:

jmap -dump:live,format=b,file=heap.hprof <PID>

Open the heap dump in Eclipse MAT.

You might discover:

HashMap

↓

Student Cache

↓

3,000,000 Objects

Now you've identified the leak.

Docker Example

Find the JVM:

docker exec container ps -ef

Generate:

docker exec container \
jmap -dump:live,format=b,file=/tmp/heap.hprof <PID>

Copy it:

docker cp container:/tmp/heap.hprof .
Kubernetes Example

Open the Pod:

kubectl exec -it student-api-pod -- sh

Find Java:

ps -ef | grep java

Create dump:

jmap -dump:live,format=b,file=/tmp/heap.hprof <PID>

Copy locally:

kubectl cp \
student-api-pod:/tmp/heap.hprof .
jmap vs jcmd

Modern JDKs recommend:

jcmd <PID> GC.heap_dump heap.hprof

instead of:

jmap -dump

Similarly:

jcmd <PID> GC.class_histogram

replaces:

jmap -histo

You should know both because production systems still use jmap extensively.

Memory Investigation Workflow
Application Slow

↓

top

↓

Java Memory High

↓

jmap -histo

↓

Large Objects?

↓

Heap Dump

↓

MAT Analysis

↓

Memory Leak Found
Hands-on Lab
Find Java Process
ps -ef | grep java
Heap Summary
jmap -heap <PID>
Object Histogram
jmap -histo <PID>
Live Objects Only
jmap -histo:live <PID>

This triggers a full GC before creating the histogram, so use it carefully on production systems because it can introduce pauses.

Generate Heap Dump
jmap -dump:live,format=b,file=heap.hprof <PID>
Open with MAT

Open:

heap.hprof

Investigate:

Dominator Tree
Leak Suspects
Histogram
GC Roots
Common Mistakes
❌ Thinking RSS Equals Java Heap

Linux RSS includes:

Java Heap
Thread Stacks
Metaspace
Code Cache
Native libraries
Direct buffers

The Java heap is only one part of the process memory.

❌ Taking Heap Dumps Frequently

Heap dumps:

Can be several gigabytes
Consume disk space
May briefly pause the JVM
Should be collected thoughtfully in production
❌ Assuming the Largest Object Is Always the Leak

A large object isn't necessarily a leak.

The important question is:

Why is it still reachable?

Tools like Eclipse MAT help answer that by showing GC roots and retained size.

Useful Commands
Command	Purpose
jmap -heap <PID>	Display heap configuration
jmap -histo <PID>	Object histogram
jmap -histo:live <PID>	Histogram of live objects
jmap -dump:live,format=b,file=heap.hprof <PID>	Generate live heap dump
jcmd <PID> GC.heap_dump heap.hprof	Modern heap dump alternative
jcmd <PID> GC.class_histogram	Modern histogram alternative
Linux vs JVM Memory Tools
top
↓

Process Memory (RSS)

---------------------

jmap
↓

Java Heap Objects

---------------------

MAT

↓

Heap Analysis

Each tool answers a different layer of the memory story.

💡 Key Takeaways

✅ jmap is a JVM memory analysis tool that focuses on heap inspection.

✅ It can display heap configuration, class histograms, and generate heap dumps.

✅ Heap dumps are typically analyzed with Eclipse MAT, VisualVM, or commercial profilers to diagnose memory leaks.

✅ jmap -histo helps identify which classes consume the most heap memory.

✅ Modern JDKs provide equivalent functionality through jcmd, but jmap remains an important tool to understand because it is still widely used in production environments and documentation.

➡️ Next Chapter

📘 11-Observability/06-jstat.md

In the next chapter, we'll explore jstat, the JVM statistics monitoring tool.

You'll learn:

📊 How to monitor garbage collection in real time
🗑️ Eden, Survivor, and Old Generation utilization
⏱️ Young GC vs Full GC frequency
📈 GC performance trends
🚀 How to diagnose excessive garbage collection before an OutOfMemoryError occurs
