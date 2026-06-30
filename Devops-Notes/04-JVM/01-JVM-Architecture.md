# 📘 Chapter 26 — JVM Architecture

> 📂 File: `student-results-api-notes/04-JVM/01-JVM-Architecture.md`

# 📘 Chapter 26 — JVM Architecture

> 📂 File: `student-results-api-notes/04-JVM/01-JVM-Architecture.md`

---

# 🌍 Introduction

In the previous module, we explored the Linux operating system in depth.

We learned how Linux creates and manages your Spring Boot application:

```text
Power On
    │
    ▼
Linux Kernel
    │
    ▼
Java Process (PID 7065)
    │
    ▼
Threads
    │
    ▼
Virtual Memory
    │
    ▼
Sockets
    │
    ▼
Tomcat
```

But one important question still remains:

> 🤔 **What happens inside the Java process?**

When you execute:

```bash
java -jar student-results-api.jar
```

Linux only starts the **Java Virtual Machine (JVM)**.

From that point onward, the JVM becomes responsible for:

* 📦 Loading Java classes
* 🧠 Managing memory
* 🧵 Creating Java threads
* ⚡ Executing bytecode
* 🚀 Compiling hot code into native machine code
* 🗑️ Running the Garbage Collector
* 🍃 Starting Spring Boot
* 🌐 Starting Tomcat

This entire module is about understanding **everything that happens inside the JVM**.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* ☕ What the JVM is
* 🧩 Why Java needs a JVM
* 📦 JVM architecture
* 📥 Class Loader Subsystem
* 🧠 Runtime Data Areas
* ⚙️ Execution Engine
* 🗑️ Garbage Collector
* 🚀 JIT Compiler
* 🧵 JVM Threads
* 📚 Native Interface (JNI)
* 🐳 JVM inside Docker
* ☸️ JVM inside Kubernetes
* 🧪 JVM monitoring tools

---

# ❓ Why Does Java Need a JVM?

Suppose you write:

```java
System.out.println("Hello World");
```

Your CPU **cannot** execute Java source code.

Instead:

```text
Java Source (.java)

↓

Java Compiler (javac)

↓

Bytecode (.class)

↓

JVM

↓

Machine Code

↓

CPU
```

The JVM provides a layer of abstraction between Java programs and the underlying operating system.

---

# 🌍 "Write Once, Run Anywhere"

Without the JVM:

```text
Windows

↓

Windows Binary

Linux

↓

Linux Binary

macOS

↓

macOS Binary
```

You would need separate binaries for each operating system.

With Java:

```text
Java Source

↓

Bytecode

↓

JVM (Windows)

↓

Runs

-----------------------

Bytecode

↓

JVM (Linux)

↓

Runs

-----------------------

Bytecode

↓

JVM (macOS)

↓

Runs
```

The same `.class` files execute on any platform with a compatible JVM.

---

# 🏗️ High-Level JVM Architecture

```text
                  Java Source (.java)
                           │
                           ▼
                     javac Compiler
                           │
                           ▼
                    Bytecode (.class)
                           │
                           ▼
+------------------------------------------------------+
|                 ☕ Java Virtual Machine              |
|------------------------------------------------------|
| 📥 Class Loader Subsystem                            |
|------------------------------------------------------|
| 🧠 Runtime Data Areas                                |
|   • Heap                                             |
|   • Java Stacks                                      |
|   • PC Registers                                     |
|   • Native Method Stack                              |
|   • Metaspace                                        |
|------------------------------------------------------|
| ⚙️ Execution Engine                                  |
|   • Interpreter                                      |
|   • JIT Compiler                                     |
|   • Garbage Collector                                |
|------------------------------------------------------|
| 🔗 Java Native Interface (JNI)                       |
|------------------------------------------------------|
| 📚 Native Libraries                                  |
+------------------------------------------------------+
                           │
                           ▼
                    Linux System Calls
                           │
                           ▼
                      Linux Kernel
                           │
                           ▼
                           CPU
```

This is the complete execution environment for every Java application.

---

# 📦 Class Loader Subsystem

The first responsibility of the JVM is loading classes.

When your application starts:

```bash
java -jar student-results-api.jar
```

The JVM loads:

```text
StudentResultsApiApplication

↓

StudentController

↓

StudentService

↓

StudentRepository

↓

Student

↓

DispatcherServlet

↓

Tomcat Classes
```

Classes are loaded **only when needed**, not all at once.

---

# 🧠 Runtime Data Areas

The JVM divides memory into several logical areas.

```text
+--------------------------------------+
| 🧵 Java Thread Stack (per thread)    |
+--------------------------------------+
| ☕ Heap (shared)                      |
+--------------------------------------+
| 📚 Metaspace                         |
+--------------------------------------+
| 🖥️ PC Registers                      |
+--------------------------------------+
| 🧩 Native Method Stack               |
+--------------------------------------+
```

We'll study each of these in dedicated chapters.

---

# 🧵 Java Thread Stack

Each Java thread has its own stack.

Example:

```text
Tomcat Thread

↓

Controller()

↓

Service()

↓

Repository()
```

Each method call creates a new stack frame.

Stacks are **private** to each thread.

---

# ☕ Heap

All Java objects are stored on the Heap.

Examples:

```java
Student

StudentResponse

ArrayList

HashMap

String
```

All Tomcat worker threads share the same heap.

This is why synchronization becomes important for shared mutable objects.

---

# 📚 Metaspace

The JVM stores class metadata in **Metaspace**.

Examples:

* Class definitions
* Method metadata
* Constant pool information
* Field information

Metaspace replaced the older **Permanent Generation (PermGen)** in Java 8.

---

# ⚙️ Execution Engine

The Execution Engine is responsible for running bytecode.

It contains three major components:

### 1️⃣ Interpreter

Executes bytecode instruction by instruction.

Good for startup, but relatively slow.

---

### 2️⃣ JIT Compiler

Detects frequently executed ("hot") methods and compiles them into native machine code.

```text
Bytecode

↓

Hot Method

↓

JIT Compiler

↓

Native Machine Code

↓

CPU
```

This dramatically improves performance.

---

### 3️⃣ Garbage Collector

Automatically reclaims heap memory occupied by unreachable objects.

Example:

```java
Student student = new Student();
student = null;
```

Eventually:

```text
Garbage Collector

↓

Reclaim Heap Memory
```

No manual memory management is required.

---

# 🔗 Java Native Interface (JNI)

Sometimes Java must call native operating system code.

Examples:

* File operations
* Socket operations
* Compression libraries
* Graphics
* Cryptography

Flow:

```text
Java Code

↓

JNI

↓

Native C/C++

↓

Linux System Calls
```

JNI provides this bridge.

---

# 📚 Native Libraries

Examples include:

```text
libjvm.so

libjava.so

libnet.so

libzip.so
```

These libraries interact directly with the operating system.

---

# 🍃 Student Results API Startup

When you ran:

```bash
java -jar student-results-api.jar
```

The JVM performed approximately this sequence:

```text
Linux Starts Java Process
        │
        ▼
JVM Starts
        │
        ▼
Initialize Runtime
        │
        ▼
Load StudentResultsApiApplication
        │
        ▼
Load Spring Boot Classes
        │
        ▼
Initialize Spring Context
        │
        ▼
Start Embedded Tomcat
        │
        ▼
Bind Port 8080
        │
        ▼
Application Ready
```

This entire process happens before the first HTTP request arrives.

---

# 🌐 Handling an HTTP Request

Once the application is running:

```text
Browser
      │
      ▼
Tomcat Thread
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
Student Object
      │
      ▼
JSON Response
```

Throughout this flow:

* Classes are already loaded.
* Objects are allocated on the heap.
* Method calls use thread stacks.
* The Execution Engine runs the bytecode.
* The Garbage Collector cleans up temporary objects.

---

# 🐳 JVM Inside Docker

When running in Docker:

```text
Docker Container
        │
        ▼
Java Process
        │
        ▼
JVM
        │
        ▼
Spring Boot
```

The JVM behaves exactly the same.

Docker provides:

* Process isolation
* Filesystem isolation
* Network namespace
* cgroup resource limits

The JVM is unaware that it is running inside a container unless it queries container-aware metrics.

---

# ☸️ JVM Inside Kubernetes

Inside Kubernetes:

```text
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
Spring Boot
```

The JVM still performs:

* Class loading
* Memory management
* JIT compilation
* Garbage collection

The kubelet and Linux kernel manage CPU and memory limits externally.

---

# 🧪 Hands-on Lab

## Verify the JVM Version

```bash
java -version
```

---

## Display JVM Settings

```bash
java -XshowSettings:vm -version
```

Observe:

* Heap sizes
* Garbage collector
* VM mode

---

## Display JVM Flags

```bash
java -XX:+PrintFlagsFinal -version
```

Useful for understanding default JVM configuration.

---

## View Running Java Processes

```bash
jps -l
```

Example:

```text
7065 student-results-api.jar
```

---

## Inspect JVM System Properties

```bash
jcmd <PID> VM.system_properties
```

Observe properties such as:

* `java.home`
* `java.version`
* `user.dir`
* `file.encoding`

---

## Inspect JVM Command Line

```bash
jcmd <PID> VM.command_line
```

Shows the JVM arguments used to start your application.

---

## Display JVM Native Memory Summary

```bash
jcmd <PID> VM.native_memory summary
```

If Native Memory Tracking is enabled, this provides insight into heap, metaspace, thread stacks, and native allocations.

---

# 📈 Complete Architecture

```text
Browser
    │
    ▼
HTTP Request
    │
    ▼
Linux Socket
    │
    ▼
Tomcat
    │
    ▼
Java Thread
    │
    ▼
Execution Engine
    │
    ▼
Bytecode
    │
    ▼
Heap Objects
    │
    ▼
Garbage Collector
    │
    ▼
JSON Response
```

This illustrates how Linux and the JVM work together to execute your Spring Boot application.

---

# 💡 Key Takeaways

✅ The JVM is the runtime environment that executes Java bytecode.

✅ Java source code is compiled into platform-independent bytecode, which the JVM interprets and optimizes.

✅ The JVM consists of the Class Loader Subsystem, Runtime Data Areas, Execution Engine, JNI, and Native Libraries.

✅ The Execution Engine combines interpretation, Just-In-Time (JIT) compilation, and Garbage Collection to balance startup speed and runtime performance.

✅ Docker and Kubernetes do not replace the JVM—they provide isolation and resource management around the Java process.

✅ Understanding JVM architecture is essential before exploring class loading, bytecode execution, memory management, and Spring Boot internals.

---

# ➡️ Next Chapter

📘 **`04-JVM/02-Class-Loading.md`**

In the next chapter, we'll answer one of the most fundamental JVM questions:

> **How does the JVM find and load `StudentController.class` after you run `java -jar student-results-api.jar`?**

We'll explore:

* 📦 Bootstrap, Platform, and Application Class Loaders
* 📄 JAR file structure
* 🔄 Parent Delegation Model
* 📚 Class Loading vs Linking vs Initialization
* 🧪 Inspecting loaded classes with `jcmd` and JVM logging

By the end of the next chapter, you'll understand exactly how your Spring Boot application and all of its dependencies are discovered and loaded into the JVM before the first line of your application code executes.

---

# 🌍 Introduction

In the previous module, we explored the Linux operating system in depth.

We learned how Linux creates and manages your Spring Boot application:

```text
Power On
    │
    ▼
Linux Kernel
    │
    ▼
Java Process (PID 7065)
    │
    ▼
Threads
    │
    ▼
Virtual Memory
    │
    ▼
Sockets
    │
    ▼
Tomcat
```

But one important question still remains:

> 🤔 **What happens inside the Java process?**

When you execute:

```bash
java -jar student-results-api.jar
```

Linux only starts the **Java Virtual Machine (JVM)**.

From that point onward, the JVM becomes responsible for:

* 📦 Loading Java classes
* 🧠 Managing memory
* 🧵 Creating Java threads
* ⚡ Executing bytecode
* 🚀 Compiling hot code into native machine code
* 🗑️ Running the Garbage Collector
* 🍃 Starting Spring Boot
* 🌐 Starting Tomcat

This entire module is about understanding **everything that happens inside the JVM**.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* ☕ What the JVM is
* 🧩 Why Java needs a JVM
* 📦 JVM architecture
* 📥 Class Loader Subsystem
* 🧠 Runtime Data Areas
* ⚙️ Execution Engine
* 🗑️ Garbage Collector
* 🚀 JIT Compiler
* 🧵 JVM Threads
* 📚 Native Interface (JNI)
* 🐳 JVM inside Docker
* ☸️ JVM inside Kubernetes
* 🧪 JVM monitoring tools

---

# ❓ Why Does Java Need a JVM?

Suppose you write:

```java
System.out.println("Hello World");
```

Your CPU **cannot** execute Java source code.

Instead:

```text
Java Source (.java)

↓

Java Compiler (javac)

↓

Bytecode (.class)

↓

JVM

↓

Machine Code

↓

CPU
```

The JVM provides a layer of abstraction between Java programs and the underlying operating system.

---

# 🌍 "Write Once, Run Anywhere"

Without the JVM:

```text
Windows

↓

Windows Binary

Linux

↓

Linux Binary

macOS

↓

macOS Binary
```

You would need separate binaries for each operating system.

With Java:

```text
Java Source

↓

Bytecode

↓

JVM (Windows)

↓

Runs

-----------------------

Bytecode

↓

JVM (Linux)

↓

Runs

-----------------------

Bytecode

↓

JVM (macOS)

↓

Runs
```

The same `.class` files execute on any platform with a compatible JVM.

---

# 🏗️ High-Level JVM Architecture

```text
                  Java Source (.java)
                           │
                           ▼
                     javac Compiler
                           │
                           ▼
                    Bytecode (.class)
                           │
                           ▼
+------------------------------------------------------+
|                 ☕ Java Virtual Machine              |
|------------------------------------------------------|
| 📥 Class Loader Subsystem                            |
|------------------------------------------------------|
| 🧠 Runtime Data Areas                                |
|   • Heap                                             |
|   • Java Stacks                                      |
|   • PC Registers                                     |
|   • Native Method Stack                              |
|   • Metaspace                                        |
|------------------------------------------------------|
| ⚙️ Execution Engine                                  |
|   • Interpreter                                      |
|   • JIT Compiler                                     |
|   • Garbage Collector                                |
|------------------------------------------------------|
| 🔗 Java Native Interface (JNI)                       |
|------------------------------------------------------|
| 📚 Native Libraries                                  |
+------------------------------------------------------+
                           │
                           ▼
                    Linux System Calls
                           │
                           ▼
                      Linux Kernel
                           │
                           ▼
                           CPU
```

This is the complete execution environment for every Java application.

---

# 📦 Class Loader Subsystem

The first responsibility of the JVM is loading classes.

When your application starts:

```bash
java -jar student-results-api.jar
```

The JVM loads:

```text
StudentResultsApiApplication

↓

StudentController

↓

StudentService

↓

StudentRepository

↓

Student

↓

DispatcherServlet

↓

Tomcat Classes
```

Classes are loaded **only when needed**, not all at once.

---

# 🧠 Runtime Data Areas

The JVM divides memory into several logical areas.

```text
+--------------------------------------+
| 🧵 Java Thread Stack (per thread)    |
+--------------------------------------+
| ☕ Heap (shared)                      |
+--------------------------------------+
| 📚 Metaspace                         |
+--------------------------------------+
| 🖥️ PC Registers                      |
+--------------------------------------+
| 🧩 Native Method Stack               |
+--------------------------------------+
```

We'll study each of these in dedicated chapters.

---

# 🧵 Java Thread Stack

Each Java thread has its own stack.

Example:

```text
Tomcat Thread

↓

Controller()

↓

Service()

↓

Repository()
```

Each method call creates a new stack frame.

Stacks are **private** to each thread.

---

# ☕ Heap

All Java objects are stored on the Heap.

Examples:

```java
Student

StudentResponse

ArrayList

HashMap

String
```

All Tomcat worker threads share the same heap.

This is why synchronization becomes important for shared mutable objects.

---

# 📚 Metaspace

The JVM stores class metadata in **Metaspace**.

Examples:

* Class definitions
* Method metadata
* Constant pool information
* Field information

Metaspace replaced the older **Permanent Generation (PermGen)** in Java 8.

---

# ⚙️ Execution Engine

The Execution Engine is responsible for running bytecode.

It contains three major components:

### 1️⃣ Interpreter

Executes bytecode instruction by instruction.

Good for startup, but relatively slow.

---

### 2️⃣ JIT Compiler

Detects frequently executed ("hot") methods and compiles them into native machine code.

```text
Bytecode

↓

Hot Method

↓

JIT Compiler

↓

Native Machine Code

↓

CPU
```

This dramatically improves performance.

---

### 3️⃣ Garbage Collector

Automatically reclaims heap memory occupied by unreachable objects.

Example:

```java
Student student = new Student();
student = null;
```

Eventually:

```text
Garbage Collector

↓

Reclaim Heap Memory
```

No manual memory management is required.

---

# 🔗 Java Native Interface (JNI)

Sometimes Java must call native operating system code.

Examples:

* File operations
* Socket operations
* Compression libraries
* Graphics
* Cryptography

Flow:

```text
Java Code

↓

JNI

↓

Native C/C++

↓

Linux System Calls
```

JNI provides this bridge.

---

# 📚 Native Libraries

Examples include:

```text
libjvm.so

libjava.so

libnet.so

libzip.so
```

These libraries interact directly with the operating system.

---

# 🍃 Student Results API Startup

When you ran:

```bash
java -jar student-results-api.jar
```

The JVM performed approximately this sequence:

```text
Linux Starts Java Process
        │
        ▼
JVM Starts
        │
        ▼
Initialize Runtime
        │
        ▼
Load StudentResultsApiApplication
        │
        ▼
Load Spring Boot Classes
        │
        ▼
Initialize Spring Context
        │
        ▼
Start Embedded Tomcat
        │
        ▼
Bind Port 8080
        │
        ▼
Application Ready
```

This entire process happens before the first HTTP request arrives.

---

# 🌐 Handling an HTTP Request

Once the application is running:

```text
Browser
      │
      ▼
Tomcat Thread
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
Student Object
      │
      ▼
JSON Response
```

Throughout this flow:

* Classes are already loaded.
* Objects are allocated on the heap.
* Method calls use thread stacks.
* The Execution Engine runs the bytecode.
* The Garbage Collector cleans up temporary objects.

---

# 🐳 JVM Inside Docker

When running in Docker:

```text
Docker Container
        │
        ▼
Java Process
        │
        ▼
JVM
        │
        ▼
Spring Boot
```

The JVM behaves exactly the same.

Docker provides:

* Process isolation
* Filesystem isolation
* Network namespace
* cgroup resource limits

The JVM is unaware that it is running inside a container unless it queries container-aware metrics.

---

# ☸️ JVM Inside Kubernetes

Inside Kubernetes:

```text
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
Spring Boot
```

The JVM still performs:

* Class loading
* Memory management
* JIT compilation
* Garbage collection

The kubelet and Linux kernel manage CPU and memory limits externally.

---

# 🧪 Hands-on Lab

## Verify the JVM Version

```bash
java -version
```

---

## Display JVM Settings

```bash
java -XshowSettings:vm -version
```

Observe:

* Heap sizes
* Garbage collector
* VM mode

---

## Display JVM Flags

```bash
java -XX:+PrintFlagsFinal -version
```

Useful for understanding default JVM configuration.

---

## View Running Java Processes

```bash
jps -l
```

Example:

```text
7065 student-results-api.jar
```

---

## Inspect JVM System Properties

```bash
jcmd <PID> VM.system_properties
```

Observe properties such as:

* `java.home`
* `java.version`
* `user.dir`
* `file.encoding`

---

## Inspect JVM Command Line

```bash
jcmd <PID> VM.command_line
```

Shows the JVM arguments used to start your application.

---

## Display JVM Native Memory Summary

```bash
jcmd <PID> VM.native_memory summary
```

If Native Memory Tracking is enabled, this provides insight into heap, metaspace, thread stacks, and native allocations.

---

# 📈 Complete Architecture

```text
Browser
    │
    ▼
HTTP Request
    │
    ▼
Linux Socket
    │
    ▼
Tomcat
    │
    ▼
Java Thread
    │
    ▼
Execution Engine
    │
    ▼
Bytecode
    │
    ▼
Heap Objects
    │
    ▼
Garbage Collector
    │
    ▼
JSON Response
```

This illustrates how Linux and the JVM work together to execute your Spring Boot application.

---

# 💡 Key Takeaways

✅ The JVM is the runtime environment that executes Java bytecode.

✅ Java source code is compiled into platform-independent bytecode, which the JVM interprets and optimizes.

✅ The JVM consists of the Class Loader Subsystem, Runtime Data Areas, Execution Engine, JNI, and Native Libraries.

✅ The Execution Engine combines interpretation, Just-In-Time (JIT) compilation, and Garbage Collection to balance startup speed and runtime performance.

✅ Docker and Kubernetes do not replace the JVM—they provide isolation and resource management around the Java process.

✅ Understanding JVM architecture is essential before exploring class loading, bytecode execution, memory management, and Spring Boot internals.

---

# ➡️ Next Chapter

📘 **`04-JVM/02-Class-Loading.md`**

In the next chapter, we'll answer one of the most fundamental JVM questions:

> **How does the JVM find and load `StudentController.class` after you run `java -jar student-results-api.jar`?**

We'll explore:

* 📦 Bootstrap, Platform, and Application Class Loaders
* 📄 JAR file structure
* 🔄 Parent Delegation Model
* 📚 Class Loading vs Linking vs Initialization
* 🧪 Inspecting loaded classes with `jcmd` and JVM logging

By the end of the next chapter, you'll understand exactly how your Spring Boot application and all of its dependencies are discovered and loaded into the JVM before the first line of your application code executes.
