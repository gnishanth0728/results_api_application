# 📘 Chapter 29 — JVM Stack

> 📂 File: `student-results-api-notes/04-JVM/04-Stack.md`

This chapter is one of the most important JVM chapters because every Java method call executes on the Java Stack.

Together with the Heap chapter, it forms the foundation for understanding how Spring Boot handles HTTP requests, how Tomcat worker threads execute code, and why errors such as StackOverflowError occur.

By the end of this chapter, readers should understand:

Where local variables live
How method calls work
What a stack frame contains
Why each Tomcat thread has its own stack
How recursion causes stack overflow
The difference between the Java Stack and the Linux Stack

---

# 🌍 Introduction

In the previous chapter, we explored the **JVM Heap**, where Java objects are stored.

Now we'll study another critical JVM memory area:

# 🧵 Java Stack

Whenever your Student Results API receives an HTTP request, Tomcat assigns it to a worker thread.

That thread executes methods such as:

```text
StudentController

↓

StudentService

↓

StudentRepository

↓

Hibernate

↓

JDBC Driver
```

Every one of these method calls creates a **Stack Frame**.

Understanding the Java Stack explains:

* 📞 How method calls work
* 📍 Where local variables are stored
* 🔙 How methods return
* 🧵 Why each thread has its own execution context
* 💥 Why `StackOverflowError` occurs

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 🧵 What the Java Stack is
* 📦 Stack Frames
* 📞 Method Invocation
* 📍 Local Variables
* 🔙 Return Addresses
* 🧠 Operand Stack
* 🧮 Local Variable Table
* 🔄 Method Call Lifecycle
* 💥 StackOverflowError
* 🍃 Spring Boot request execution
* 🐳 Docker
* ☸️ Kubernetes
* 🧪 JVM debugging

---

# ❓ What Is the Java Stack?

The **Java Stack** is a **per-thread memory area** used to execute Java methods.

Unlike the Heap:

| Feature        | ☕ Heap            | 🧵 Java Stack              |
| -------------- | ----------------- | -------------------------- |
| Stores         | Objects           | Method execution           |
| Shared         | ✅ Yes             | ❌ No                       |
| One Per Thread | ❌                 | ✅                          |
| Cleanup        | Garbage Collector | Automatic on method return |

Every Java thread owns its own stack.

---

# 🏗️ JVM Memory Layout

```text
                    JVM

+------------------------------------------------+

          🧵 Thread Stack (Thread 1)

--------------------------------------------------

          🧵 Thread Stack (Thread 2)

--------------------------------------------------

          🧵 Thread Stack (Thread 3)

--------------------------------------------------

                 ☕ Heap

--------------------------------------------------

               📚 Metaspace

+------------------------------------------------+
```

Notice that:

* Each thread has its own stack.
* All threads share the heap.

---

# 🧵 One Stack per Thread

Suppose your API is serving three users simultaneously.

```text
Browser A

↓

http-nio-8080-exec-1

↓

Own Stack

---------------------------------

Browser B

↓

http-nio-8080-exec-2

↓

Own Stack

---------------------------------

Browser C

↓

http-nio-8080-exec-3

↓

Own Stack
```

This separation makes local variables naturally thread-safe.

---

# 📦 What Is a Stack Frame?

Every Java method call creates one **Stack Frame**.

Example:

```java
StudentResponse getStudent(Long id)
```

When invoked:

```text
Thread Stack

↓

Stack Frame

↓

Method Parameters

↓

Local Variables

↓

Operand Stack

↓

Return Address
```

A stack frame is the unit of execution inside the JVM.

---

# 🧱 Stack Frame Structure

A stack frame contains several components.

```text
+----------------------------------+

📍 Local Variable Table

-----------------------------------

🧠 Operand Stack

-----------------------------------

🔙 Return Address

-----------------------------------

📚 Constant Pool Reference

+----------------------------------+
```

Each serves a different purpose during method execution.

---

# 📍 Local Variable Table

The Local Variable Table stores:

* Method parameters
* Primitive variables
* Object references

Example:

```java
public StudentResponse getStudent(Long id)
```

Memory:

```text
Local Variable Table

Slot 0 → this

Slot 1 → id

Slot 2 → student

Slot 3 → response
```

Notice that only **references** to objects are stored here.

The actual objects remain on the Heap.

---

# 🧠 Operand Stack

The JVM is a **stack-based virtual machine**.

It performs calculations using the Operand Stack.

Example:

```java
int total = maths + science;
```

Bytecode conceptually performs:

```text
Push maths

↓

Push science

↓

Add

↓

Store result
```

The Operand Stack is used for intermediate calculations.

---

# 🔙 Return Address

Every method call remembers where execution should continue.

Example:

```java
controller()

↓

service()

↓

repository()
```

When `repository()` finishes:

```text
Return Address

↓

Resume service()
```

The JVM automatically restores execution to the caller.

---

# 🔄 Method Call Lifecycle

Every method follows this sequence:

```text
Method Call

↓

Create Stack Frame

↓

Execute Bytecode

↓

Return Value

↓

Remove Stack Frame
```

This happens millions of times per second in a busy application.

---

# 🍃 Student Results API Example

Suppose a browser requests:

```http
GET /students/1051110244
```

Execution flow:

```text
Tomcat Thread

↓

DispatcherServlet

↓

StudentController

↓

StudentService

↓

StudentRepository

↓

Hibernate

↓

JDBC Driver
```

The thread stack grows like this:

```text
Top of Stack

+----------------------------+

JDBC Driver

-----------------------------

Hibernate

-----------------------------

StudentRepository

-----------------------------

StudentService

-----------------------------

StudentController

-----------------------------

DispatcherServlet

+----------------------------+
```

As methods return, frames are removed in reverse order.

---

# 🔄 Stack Growth and Shrinkage

Method calls push frames.

Returns pop frames.

```text
main()

↓

Controller()

↓

Service()

↓

Repository()

↓

Return

↓

Repository Removed

↓

Return

↓

Service Removed

↓

Return

↓

Controller Removed
```

This is why the stack follows a **Last-In, First-Out (LIFO)** structure.

---

# ☕ Stack vs Heap

Suppose:

```java
Student student = new Student();
```

Memory layout:

```text
Thread Stack

student
   │
   ▼
0x100A

----------------------------

Heap

0x100A

Student Object
```

The stack stores only the reference.

The heap stores the actual object.

---

# 💥 StackOverflowError

Consider:

```java
void recurse() {
    recurse();
}
```

Execution:

```text
Frame 1

↓

Frame 2

↓

Frame 3

↓

Frame 4

↓

...

↓

No Space Left

↓

StackOverflowError
```

The JVM throws:

```text
java.lang.StackOverflowError
```

This happens because the thread stack has reached its size limit.

---

# 📏 Stack Size

Each thread has a maximum stack size.

Configure it using:

```bash
java -Xss1m \
-jar student-results-api.jar
```

Example:

* `-Xss256k`
* `-Xss512k`
* `-Xss1m`

A larger stack supports deeper recursion but increases memory usage per thread.

---

# 🧵 Stack During Load Testing

You ran:

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

Tomcat created many worker threads.

Each thread owned:

```text
Own Java Stack

↓

Controller()

↓

Service()

↓

Repository()
```

Meanwhile:

```text
All Threads

↓

Shared Heap
```

Even with 200 concurrent requests, local variables never interfere because each thread has a separate stack.

---

# 🐧 JVM Stack vs Linux Stack

Earlier, in the Linux module, we learned about process stacks.

How do they relate?

```text
Linux Process

↓

Native Thread

↓

Native Stack

↓

JVM

↓

Java Thread

↓

Java Stack Frames
```

The Java Stack is implemented on top of the operating system's native thread stack.

From the JVM's perspective, it manages Java stack frames.

From Linux's perspective, it's simply memory allocated for a native thread.

---

# 🐳 Docker Perspective

Suppose your container runs:

```bash
docker run \
--memory=1g \
student-api
```

Each Java thread consumes:

* Java stack memory
* Native thread structures

If you create thousands of threads:

```text
1000 Threads

↓

1000 Stacks

↓

Large Memory Usage
```

Thread stacks contribute to the container's total memory consumption.

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

Memory usage includes:

```text
Heap

+

Thread Stacks

+

Metaspace

+

Native Memory
```

Stack memory must be considered when sizing JVM containers.

---

# 🧪 Hands-on Lab

## Display All Java Threads

```bash
jstack <PID>
```

Observe hundreds of thread stack traces.

---

## Display Thread Dump

```bash
jcmd <PID> Thread.print
```

This prints:

* Thread names
* Stack frames
* Method calls
* Thread states

---

## Observe Thread Count

```bash
ps -Lf -p <PID>
```

Compare the number of native threads with the number of Java thread dumps.

---

## Configure Stack Size

```bash
java -Xss512k \
-jar student-results-api.jar
```

Experiment with different stack sizes and observe the effect on recursion depth.

---

## Generate Concurrent Requests

```bash
ab -n 50000 -c 200 \
http://localhost:8080/students/1051110244
```

While the test runs:

```bash
jcmd <PID> Thread.print
```

Observe multiple `http-nio-8080-exec-*` threads, each with its own independent stack trace.

---

# 📈 Complete Request Execution

```text
Browser

↓

Tomcat Worker Thread

↓

DispatcherServlet

↓

StudentController

↓

StudentService

↓

StudentRepository

↓

Hibernate

↓

JDBC Driver

↓

PostgreSQL

↓

Return

↓

JSON Response
```

Each arrow downward pushes a new stack frame.

Each return pops one frame until the thread becomes idle again.

---

# 💡 Key Takeaways

✅ Every Java thread owns its own private stack.

✅ Every method invocation creates a new stack frame.

✅ A stack frame contains the Local Variable Table, Operand Stack, Return Address, and metadata references.

✅ The Java Stack stores primitive values and object references, while the Heap stores the actual objects.

✅ The stack automatically grows and shrinks as methods are called and returned.

✅ Excessive recursion causes `StackOverflowError`.

✅ Thread stacks consume native memory and must be considered when sizing JVMs in Docker and Kubernetes.

---

# ➡️ Next Chapter

📘 **`04-JVM/05-Garbage-Collection.md`**

In the next chapter, we'll answer one of the most common JVM questions:

> **How does Java automatically free memory without `free()` or `delete()`?**

We'll explore:

* 🗑️ Garbage Collection fundamentals
* 🌱 Minor GC
* 👴 Major GC
* ♻️ Object reachability
* 🚮 GC algorithms (Mark-Sweep, Copying, G1 overview)
* 📊 GC logs
* 🧪 Tools such as `jstat`, `jcmd`, `jmap`, and VisualVM

By the end of the next chapter, you'll understand how the JVM keeps the heap healthy while your Spring Boot application serves thousands of requests.
