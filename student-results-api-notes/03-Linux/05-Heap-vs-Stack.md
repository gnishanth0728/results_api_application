# 📘 Chapter 20 — Heap vs Stack

This is an excellent place for a dedicated chapter. Although Heap and Stack were briefly introduced in the Virtual Memory chapter, they deserve their own deep dive because they are fundamental to Java, Spring Boot, JVM tuning, debugging memory leaks, Docker memory limits, and Kubernetes resource management.

This chapter should answer:

When a Spring Boot request arrives, what goes to the Stack and what goes to the Heap?

Using your Student Results API makes this concept concrete.

> 📂 File: `student-results-api-notes/03-Linux/05-Heap-vs-Stack.md`

---

# 🌍 Introduction

In the previous chapter we learned that every Linux process receives its own virtual memory.

A Java process looks like this:

```text
High Address
+-----------------------------+
| 🧵 Thread Stack             |
+-----------------------------+
| 📚 Shared Libraries         |
+-----------------------------+
| ☕ JVM Heap                 |
+-----------------------------+
| 📦 Data Segment            |
+-----------------------------+
| ⚙️ Code Segment            |
+-----------------------------+
Low Address
```

The two most important areas for Java developers are:

* 🧵 Stack Memory
* ☕ Heap Memory

Every HTTP request handled by your Student Results API uses **both**.

Understanding the difference is essential for writing correct, efficient, and thread-safe applications.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🧵 What the Stack is
* ☕ What the Heap is
* ⚖️ Stack vs Heap
* 📦 Object allocation
* 📍 References
* 🔄 Method calls
* 🧹 Garbage Collection
* 🍃 Spring Boot request execution
* 🧵 Multi-threading
* 🐳 Docker memory
* ☸️ Kubernetes memory
* 🧪 Debugging tools

---

# ❓ Why Two Different Memory Areas?

Suppose every variable was stored in one giant memory region.

Problems would include:

* ❌ Slow allocation
* ❌ Difficult cleanup
* ❌ Thread interference
* ❌ Memory fragmentation

Instead, Java divides responsibilities:

| Memory   | Purpose          |
| -------- | ---------------- |
| 🧵 Stack | Method execution |
| ☕ Heap   | Objects          |

---

# 🏗️ High-Level Architecture

```text
                  Java Process

+------------------------------------------------+

        🧵 Thread Stack (Thread Private)

        Method Frames

        Local Variables

        Parameters

        Return Addresses

--------------------------------------------------

              ☕ JVM Heap (Shared)

        Student Objects

        StudentResponse

        SubjectResponse

        ArrayList

        String Objects

--------------------------------------------------

        Code Segment

--------------------------------------------------

        Shared Libraries

+------------------------------------------------+
```

---

# 🧵 What Is the Stack?

The stack stores everything required to execute methods.

Each method call creates a **Stack Frame**.

Example:

```java
public StudentResponse getStudentResult(Long rollNumber)
```

When invoked:

```text
Thread Stack

↓

Stack Frame

↓

rollNumber

student

marks

response

total

percentage
```

These are local variables.

---

# 🧱 Stack Frame

Every method call pushes a new frame.

Example:

```text
main()

↓

getStudentResult()

↓

findById()

↓

executeQuery()
```

Memory:

```text
Top of Stack

+------------------------+

executeQuery()

--------------------------

findById()

--------------------------

getStudentResult()

--------------------------

main()

+------------------------+
```

When a method returns, its frame is removed automatically.

---

# ☕ What Is the Heap?

Objects live on the Heap.

Example:

```java
Student student = ...
```

Memory:

```text
Stack

student

──────────────►

Heap

Student Object
```

The stack stores only a **reference**.

The object itself resides on the heap.

---

# 📍 References

Consider:

```java
Student student =
studentRepository.findById(id);
```

Memory layout:

```text
Thread Stack

student

────────────► 0x100A

Heap

0x100A

Student Object
```

The variable contains an address (reference), not the object itself.

---

# 🧪 Student Results API Example

When this controller executes:

```java
@GetMapping("/students/{id}")
```

Flow:

```text
HTTP Request

↓

Tomcat Thread

↓

Controller()

↓

Service()

↓

Repository()

↓

Student Entity

↓

StudentResponse
```

---

## Stack

```text
Thread Stack

rollNumber

student

marks

response

total

percentage
```

---

## Heap

```text
Student

StudentMark List

ArrayList

StudentResponse

SubjectResponse

String Objects
```

The controller, service, and repository methods each have their own stack frames, while the objects they create are shared on the heap.

---

# 🔄 Stack Growth

Every method call pushes a frame.

```text
main()

↓

Controller()

↓

Service()

↓

Repository()

↓

JDBC Driver()
```

As methods return, frames are popped in reverse order.

This is why the stack behaves as **Last-In, First-Out (LIFO)**.

---

# ☕ Heap Growth

The heap grows as objects are created.

```java
new Student()

new StudentResponse()

new SubjectResponse()

new ArrayList<>()
```

Memory:

```text
Heap

Student

↓

ArrayList

↓

StudentResponse

↓

SubjectResponse
```

Objects remain until no reachable references exist.

---

# 🧹 Garbage Collection

Suppose:

```java
Student student = new Student();
```

Later:

```java
student = null;
```

Memory:

```text
Stack

student = null

Heap

Student Object

↓

No References

↓

Garbage Collector

↓

Memory Reclaimed
```

Garbage Collection only applies to heap memory.

Stack frames disappear automatically when methods return.

---

# 🧵 Thread Safety

Every Tomcat worker thread has its own stack.

Example:

```text
exec-1 Stack

↓

rollNumber

↓

response

------------------------

exec-2 Stack

↓

rollNumber

↓

response
```

No sharing occurs.

However:

```text
Shared Heap

↓

StudentCache

↓

Static Variables

↓

Singleton Beans
```

Objects on the heap may be accessed by multiple threads simultaneously.

---

# 🍃 Spring Boot Request Lifecycle

One HTTP request:

```text
Browser

↓

Tomcat Thread

↓

Controller()

↓

Service()

↓

Repository()

↓

StudentResponse

↓

JSON
```

Memory usage:

```text
Thread Stack

↓

Controller Frame

↓

Service Frame

↓

Repository Frame

────────────────────────────

Heap

↓

Student

↓

Marks

↓

Response DTO

↓

JSON Objects
```

---

# 🚨 Stack Overflow

Infinite recursion:

```java
void recurse() {
    recurse();
}
```

Each call creates another stack frame.

Eventually:

```text
Stack

↓

Full

↓

StackOverflowError
```

The heap may still have plenty of free memory.

---

# 🚨 Heap OutOfMemory

Suppose:

```java
while(true){
    list.add(new Student());
}
```

The heap keeps growing.

Eventually:

```text
Heap

↓

Full

↓

OutOfMemoryError
```

The stack is unaffected.

---

# ⚖️ Heap vs Stack Comparison

| Feature     | 🧵 Stack      | ☕ Heap                   |
| ----------- | ------------- | ------------------------ |
| Stores      | Method frames | Objects                  |
| Shared      | ❌ No          | ✅ Yes                    |
| Per Thread  | ✅ Yes         | ❌ No                     |
| Size        | Smaller       | Larger                   |
| Allocation  | Automatic     | Dynamic                  |
| Cleanup     | Automatic     | Garbage Collector        |
| Speed       | Very Fast     | Slower                   |
| Thread Safe | Naturally     | Requires synchronization |

---

# 🐳 Docker Perspective

When you run:

```bash
docker run \
--memory=512m \
student-api
```

The container's memory limit includes:

* JVM Heap
* Thread Stacks
* Native Memory
* Metaspace
* Direct Buffers

The JVM must fit within the container's memory limit.

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

The Linux kernel enforces the limit using cgroups.

If the JVM exceeds the limit:

```text
Container

↓

OOM Killer

↓

Process Terminated

↓

Pod Restarted
```

---

# 🧪 Hands-on Lab

## View Process Memory

```bash
ps -p <PID> -o pid,rss,vsz,%mem
```

---

## JVM Heap Information

```bash
jcmd <PID> GC.heap_info
```

---

## Generate Heap Histogram

```bash
jmap -histo <PID>
```

Observe which object types occupy the most heap.

---

## Monitor Garbage Collection

```bash
jstat -gc <PID> 1000
```

Displays heap usage and garbage collection activity every second.

---

## Inspect Thread Count

```bash
ps -Lf -p <PID>
```

Each thread contributes its own stack memory.

---

## Trigger Concurrent Requests

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

While the test runs:

```bash
top -H -p <PID>
```

Notice that many threads are active, each with its own stack, while all of them share the same heap.

---

# 📈 Complete Memory Picture

```text
                     Java Process

+------------------------------------------------------+

          🧵 Thread 1 Stack

          Controller()

          Service()

          Repository()

--------------------------------------------------------

          🧵 Thread 2 Stack

          Controller()

          Service()

--------------------------------------------------------

                ☕ Shared JVM Heap

Student

StudentResponse

SubjectResponse

ArrayList

Strings

Hibernate Objects

Connection Pool

--------------------------------------------------------

           Code • Metaspace • Native Memory

+------------------------------------------------------+
```

---

# 💡 Key Takeaways

✅ Every Java thread has its own private stack.

✅ The heap is shared by all threads within the JVM.

✅ Local variables and method calls live on the stack.

✅ Java objects are allocated on the heap.

✅ Stack memory is automatically released when methods return.

✅ Heap memory is reclaimed by the Garbage Collector when objects become unreachable.

✅ Stack overflows and heap out-of-memory errors are different problems with different causes.

✅ Docker and Kubernetes limit the JVM's total memory, which includes heap, stacks, and native memory—not just the Java heap.

---

# ➡️ Next Chapter

📘 **`03-Linux/06-Context-Switch.md`**

Next we'll answer another critical question:

> **What really happens when Linux pauses one Tomcat thread and runs another?**

We'll explore:

* 🔄 Context switches
* 🧠 CPU registers
* 📦 Process Control Blocks (`task_struct`)
* 🧵 Thread scheduling state
* ⚡ Cache effects
* 📊 Measuring context switches with `vmstat`, `pidstat`, `perf`, and `/proc`

By the end of the next chapter, you'll understand the hidden work the CPU and Linux kernel perform thousands of times per second while serving concurrent HTTP requests.
