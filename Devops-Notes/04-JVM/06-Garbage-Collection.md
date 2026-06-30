# 📘 Chapter 31 — JVM Garbage Collection (GC)

> 📂 File: `student-results-api-notes/04-JVM/06-Garbage-Collection.md`

This is one of the most important chapters in the entire JVM module.

Garbage Collection (GC) is the reason Java developers don't manually call malloc() or free(), yet it's also one of the biggest sources of performance problems if misunderstood.

This chapter should connect Heap, Object Allocation, Young Generation, Old Generation, Spring Boot, Docker, and Kubernetes into one complete story.

By the end of this chapter, readers should understand exactly what happens after a request to your Student Results API finishes and why memory usage goes down automatically.

---

# 🌍 Introduction

In the previous chapters we learned:

* ☕ Objects are created on the Heap.
* 🧵 Method calls execute on the Stack.
* 📚 Class metadata lives in Metaspace.

Now another important question appears:

> 🤔 **When does Java free memory?**

In C or C++, developers manually write:

```c
malloc();

free();
```

If they forget `free()`, memory leaks occur.

Java works differently.

When your Student Results API creates:

```java
StudentResponse response =
new StudentResponse();
```

you never explicitly delete it.

Instead, the JVM automatically detects when an object is no longer needed and reclaims its memory.

This automatic memory management is called:

# 🗑️ Garbage Collection (GC)

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🗑️ What Garbage Collection is
* 📦 Object lifecycle
* 📍 Reachability analysis
* 🌱 Young Generation
* 👴 Old Generation
* ♻️ Minor GC
* ♻️ Major GC
* ♻️ Full GC
* ⚙️ G1 Garbage Collector
* 💥 OutOfMemoryError
* 🍃 Spring Boot GC behavior
* 🐳 Docker memory
* ☸️ Kubernetes memory
* 🧪 GC monitoring tools

---

# ❓ Why Garbage Collection Exists?

Suppose every HTTP request creates:

```text
Student

StudentResponse

SubjectResponse

ArrayList

HashMap

String
```

After the response is sent:

```http
HTTP/1.1 200 OK
```

These temporary objects are no longer needed.

Without automatic cleanup:

```text
Request 1

↓

Objects Stay

↓

Request 2

↓

More Objects

↓

Request 3

↓

More Objects

↓

Eventually

↓

Memory Full
```

The JVM solves this automatically using Garbage Collection.

---

# 🏗️ Heap Architecture

```text
                  JVM Heap

+------------------------------------------------+

🌱 Young Generation

    Eden

    Survivor 0

    Survivor 1

--------------------------------------------------

👴 Old Generation

--------------------------------------------------

Unused Space

+------------------------------------------------+
```

Most new objects begin in the Young Generation.

---

# 📦 Object Allocation

A request arrives:

```http
GET /students/1051110244
```

Execution:

```text
Tomcat Thread

↓

Controller

↓

new StudentResponse()

↓

new ArrayList()

↓

new SubjectResponse()

↓

Eden Space
```

Every `new` operation allocates memory in Eden.

---

# 🌱 Young Generation

Most request objects are short-lived.

Example:

```text
StudentResponse

ArrayList

JSON Buffer

Hibernate Objects
```

These objects usually disappear immediately after the request completes.

The Young Generation is optimized for this allocation pattern.

---

# ♻️ Minor Garbage Collection

When Eden becomes full:

```text
Eden Full

↓

Minor GC

↓

Live Objects

↓

Survivor Space

↓

Dead Objects

↓

Removed
```

Minor GC is generally fast because most objects are already unreachable.

---

# 🔄 Survivor Spaces

Objects that survive one Minor GC are copied into a Survivor space.

```text
Eden

↓

Minor GC

↓

Survivor 0

↓

Minor GC

↓

Survivor 1

↓

Minor GC

↓

Old Generation
```

The JVM tracks an object's "age" to decide when to promote it.

---

# 👴 Old Generation

Objects that survive many collections move into the Old Generation.

Typical examples:

* 🌱 Spring Singleton Beans
* 🗄️ Database Connection Pools
* 📦 Cached Objects
* ⚙️ Configuration Objects

These objects usually remain alive for a long time.

---

# ♻️ Major Garbage Collection

When the Old Generation becomes full:

```text
Old Generation Full

↓

Major GC

↓

Find Dead Objects

↓

Free Memory
```

Major GC is slower than Minor GC because it scans a much larger portion of the heap.

---

# ♻️ Full Garbage Collection

A Full GC processes almost the entire managed heap and related runtime structures.

```text
Young Generation

+

Old Generation

+

(Some JVM metadata processing)

↓

Full GC
```

During many Full GC operations, application threads experience a stop-the-world pause, although modern collectors try to minimize this.

Frequent Full GCs usually indicate memory pressure or suboptimal tuning.

---

# 📍 Reachability Analysis

The JVM determines whether an object is still needed.

It starts from **GC Roots** such as:

* Active thread stacks
* Static fields
* JNI references
* JVM internal references

Example:

```text
GC Root

↓

StudentService

↓

StudentResponse

↓

Student
```

These objects remain alive.

Now suppose:

```text
GC Root

↓

(null)
```

The object is no longer reachable.

It becomes eligible for collection.

---

# 🧠 Object Lifecycle

A typical request object follows this journey:

```text
new StudentResponse()

↓

Eden

↓

Minor GC

↓

Survivor

↓

Minor GC

↓

Old Generation

↓

Unreachable

↓

Major GC

↓

Memory Reclaimed
```

Most request objects never reach the Old Generation.

---

# 🍃 Student Results API Example

One HTTP request:

```http
GET /students/1051110244
```

Creates:

```text
Student Entity

↓

StudentResponse

↓

ArrayList

↓

SubjectResponse

↓

Jackson JSON Objects
```

After the JSON response is written:

```text
HTTP Response Sent

↓

No References

↓

Minor GC

↓

Memory Reclaimed
```

This process repeats for every request served by your application.

---

# 🌱 Spring Boot Singleton Beans

Objects such as:

```text
StudentController

StudentService

StudentRepository

ObjectMapper

DataSource
```

remain reachable through the Spring Application Context.

Therefore, they are **not** garbage collected during normal application execution.

---

# ⚙️ G1 Garbage Collector

Modern JVMs use **G1 (Garbage-First)** by default.

Instead of dividing memory into only Young and Old regions internally, G1 manages the heap as many small regions.

Conceptually:

```text
+--------------------------------------------------+

Region 1

Region 2

Region 3

Region 4

Region 5

...

Region N

+--------------------------------------------------+
```

G1 identifies regions with the most reclaimable garbage and collects those first.

Benefits:

* Shorter pause times
* Better scalability
* Predictable performance
* Suitable for large heaps

---

# 💥 OutOfMemoryError

Suppose:

```java
while(true){
    students.add(new Student());
}
```

Eventually:

```text
Heap

↓

Full

↓

Garbage Collector Runs

↓

Nothing Can Be Freed

↓

java.lang.OutOfMemoryError:
Java heap space
```

This means the application is still holding references to objects, preventing the GC from reclaiming memory.

---

# 📊 Garbage Collection Logs

Enable GC logging:

```bash
java \
-Xlog:gc \
-jar student-results-api.jar
```

Example output:

```text
Pause Young (G1 Evacuation Pause)

Pause Full (G1 Compaction Pause)
```

GC logs are invaluable when diagnosing memory issues.

---

# 📈 Load Test Observation

You executed:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Typical lifecycle:

```text
Requests

↓

Thousands of Objects

↓

Heap Grows

↓

Minor GC

↓

Heap Shrinks

↓

Continue Serving Requests
```

Because request objects are short-lived, most memory is reclaimed by fast Minor GCs.

---

# 🐳 Docker Perspective

Suppose:

```bash
docker run \
--memory=1g \
student-api
```

The JVM process uses:

```text
Heap

+

Metaspace

+

Thread Stacks

+

Direct Buffers

+

Native Memory
```

If the total exceeds the container's memory limit:

```text
Linux OOM Killer

↓

Java Process Terminated

↓

Container Stops
```

Configure `-Xmx` with sufficient headroom for non-heap memory.

---

# ☸️ Kubernetes Perspective

Example:

```yaml
resources:
  requests:
    memory: "512Mi"
  limits:
    memory: "1Gi"
```

When the JVM exceeds the limit:

```text
OOM Kill

↓

Container Exit

↓

Pod Restart
```

Garbage Collection cannot recover memory that is still strongly referenced, so proper heap sizing and leak prevention remain essential.

---

# 🧪 Hands-on Lab

## Display Heap Information

```bash
jcmd <PID> GC.heap_info
```

---

## Monitor Garbage Collection

```bash
jstat -gc <PID> 1000
```

Observe:

* Eden usage
* Survivor usage
* Old Generation usage
* GC counts

---

## Display Heap Histogram

```bash
jmap -histo <PID>
```

Shows:

* Object counts
* Memory usage by class

---

## Generate Heap Dump

```bash
jcmd <PID> GC.heap_dump heap.hprof
```

Analyze the heap dump using Eclipse MAT or VisualVM.

---

## Enable GC Logging

```bash
java \
-Xlog:gc* \
-jar student-results-api.jar
```

Watch Minor, Major, and Full GC events as the application runs.

---

## Run Concurrent Requests

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

While the test is running:

```bash
watch -n1 \
'jstat -gc <PID> 1000 1'
```

Observe the Young Generation filling and being reclaimed repeatedly.

---

# 📈 Complete Object Lifecycle

```text
HTTP Request
      │
      ▼
new StudentResponse()
      │
      ▼
🌱 Eden
      │
      ▼
Minor GC
      │
      ▼
Survivor
      │
      ▼
Old Generation
      │
      ▼
Object Becomes Unreachable
      │
      ▼
Reachability Analysis
      │
      ▼
Major / Full GC
      │
      ▼
Memory Reclaimed
```

This cycle runs continuously while your Student Results API serves requests.

---

# 💡 Key Takeaways

✅ Garbage Collection automatically reclaims memory occupied by unreachable objects.

✅ Most request-scoped objects die young and are collected during Minor GC.

✅ Long-lived objects eventually move to the Old Generation.

✅ Reachability analysis from GC Roots determines whether an object is still alive.

✅ G1 is the default collector in modern JVMs and prioritizes collecting regions with the most reclaimable garbage.

✅ `OutOfMemoryError` occurs when the JVM cannot allocate additional memory because reachable objects still occupy the heap.

✅ Docker and Kubernetes memory limits apply to the entire JVM process, so heap sizing must account for metaspace, thread stacks, direct buffers, and other native memory.

---

# ➡️ Next Chapter

📘 **`04-JVM/07-JIT-Compiler.md`**

In the next chapter, we'll answer another fascinating question:

> **Why does a Java application become faster after it has been running for a while?**

We'll explore:

* ⚡ Interpreter vs JIT Compiler
* 🔥 Hot methods
* 🚀 Native machine code generation
* 📊 Tiered compilation (C1 and C2)
* 🧠 Inlining, escape analysis, and other JVM optimizations
* 🧪 Tools such as `jcmd`, `-XX:+PrintCompilation`, and JIT logging

By the end of the next chapter, you'll understand how the JVM transforms bytecode into highly optimized native machine code while your Spring Boot application is running.
