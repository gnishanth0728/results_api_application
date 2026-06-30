# 📘 Chapter 5 — Sequence Diagram

> 📂 File: `student-results-api-notes/01-Architecture/05-Sequence-Diagram.md`

---

# 🚀 Introduction

A sequence diagram is one of the most effective ways to understand how a distributed application works.

Instead of reading hundreds of lines of source code, a sequence diagram shows:

* 👤 Who starts the request
* 📞 Who calls whom
* ⏳ When each component executes
* 🔄 How control flows through the system
* 📤 How the response returns

This chapter visualizes the complete execution of the **Student Results API**.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📊 UML Sequence Diagrams
* 🎯 Lifelines
* 📞 Method Calls
* 🔄 Synchronous Calls
* 📤 Return Messages
* ⏱️ Activation Bars
* 🧵 Thread Ownership
* 🐧 Process Ownership
* 🗄️ Database Interaction
* 🌐 Complete End-to-End Request Flow

---

# 📖 What is a Sequence Diagram?

A Sequence Diagram is a UML (Unified Modeling Language) diagram that shows:

* Which component starts first
* Which component calls another component
* The order of execution
* The lifetime of each object
* When control returns

Unlike an architecture diagram, a sequence diagram focuses on **time**.

---

# 🏗️ System Participants

Our Student Results API consists of the following participants.

```text
👤 User

🌐 Browser

⚛️ React

📡 Axios

🐧 Linux Kernel

☕ JVM

🍃 Tomcat

🎯 DispatcherServlet

🎯 StudentController

🧠 StudentService

🗄️ StudentRepository

⚙️ Hibernate

🔗 JDBC Driver

🐘 PostgreSQL
```

Every request flows through these participants.

---

# 📊 Complete Sequence Diagram

```text
┌──────────┐
│ 👤 User  │
└────┬─────┘
     │ Click "Get Result"
     ▼
┌──────────┐
│ ⚛️ React │
└────┬─────┘
     │ onClick()
     ▼
┌──────────┐
│ 📡 Axios │
└────┬─────┘
     │ HTTP GET /students/1051110244
     ▼
┌─────────────┐
│ 🌐 Browser  │
└────┬────────┘
     │ TCP Connection
     ▼
┌─────────────┐
│ 🐧 Linux    │
└────┬────────┘
     │ Port 8080
     ▼
┌─────────────┐
│ ☕ JVM       │
└────┬────────┘
     │
     ▼
┌─────────────┐
│ 🍃 Tomcat   │
└────┬────────┘
     │
     ▼
┌────────────────────┐
│ DispatcherServlet  │
└────┬───────────────┘
     │
     ▼
┌────────────────────┐
│ StudentController  │
└────┬───────────────┘
     │
     ▼
┌────────────────────┐
│ StudentService     │
└────┬───────────────┘
     │
     ▼
┌────────────────────┐
│ StudentRepository  │
└────┬───────────────┘
     │
     ▼
┌────────────────────┐
│ Hibernate          │
└────┬───────────────┘
     │
     ▼
┌────────────────────┐
│ JDBC Driver        │
└────┬───────────────┘
     │ SQL
     ▼
┌────────────────────┐
│ PostgreSQL         │
└────────────────────┘
```

The response travels back through the same components in reverse order.

---

# ⏱️ Timeline of Execution

```text
Time
│
├── 👤 User clicks button
│
├── ⚛️ React handles event
│
├── 📡 Axios creates request
│
├── 🌐 Browser sends packet
│
├── 🐧 Linux receives TCP packet
│
├── 🍃 Tomcat accepts connection
│
├── 🎯 Controller executes
│
├── 🧠 Service executes
│
├── 🗄️ Repository executes
│
├── 🐘 PostgreSQL executes SQL
│
├── 📄 JSON generated
│
├── 🌐 Response transmitted
│
├── ⚛️ React updates state
│
└── 🎨 Material UI renders result
```

Every step happens within a fraction of a second.

---

# 🧵 Thread Ownership

One of the most misunderstood concepts is thread ownership.

Only one Tomcat worker thread processes the request.

```text
                Java Process

                     │

         http-nio-8080-exec-4

                     │

                     ▼

           DispatcherServlet

                     ▼

              StudentController

                     ▼

               StudentService

                     ▼

            StudentRepository

                     ▼

                Hibernate

                     ▼

               PostgreSQL
```

Notice that the same thread executes every layer.

Spring Boot does **not** create a new thread for every method call.

---

# 🐧 Process Ownership

Linux sees only one Java process.

```text
Linux

↓

Java Process (PID 7065)

↓

226 Threads

↓

Tomcat Worker Thread

↓

Spring Boot
```

Linux has no knowledge of:

* Controller
* Service
* Repository
* Hibernate

Those are JVM concepts.

---

# 📞 Call Stack

During request processing, the call stack grows as each method invokes the next.

```text
main()

↓

Tomcat

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

JDBC

↓

PostgreSQL
```

As methods return, the stack unwinds in reverse order.

---

# 📦 Data Transformation

The data changes format several times during its journey.

```text
HTTP Request

↓

Java Object

↓

Entity

↓

SQL Query

↓

Database Rows

↓

Entity

↓

DTO

↓

JSON

↓

React State

↓

HTML
```

Understanding these transformations is essential for debugging and performance analysis.

---

# 🔄 Request vs Response

```text
REQUEST

User
 ↓
React
 ↓
Axios
 ↓
HTTP
 ↓
Tomcat
 ↓
Spring
 ↓
Repository
 ↓
Database

-------------------------

RESPONSE

Database
 ↑
Repository
 ↑
Spring
 ↑
Tomcat
 ↑
HTTP
 ↑
Axios
 ↑
React
 ↑
User
```

The request and response use the same path but in opposite directions.

---

# 🧪 Hands-on Lab

Run your application:

```bash
mvn spring-boot:run
```

Find the Java process:

```bash
ps -ef | grep java
```

Find Tomcat worker threads:

```bash
top -H -p <PID>
```

Observe listening sockets:

```bash
ss -ltnp
```

Generate traffic:

```bash
curl http://localhost:8080/students/1051110244
```

Watch the logs while following the sequence diagram.

---

# 📈 Why Sequence Diagrams Matter

Sequence diagrams help you:

✅ Understand execution order

✅ Debug complex applications

✅ Explain architecture to teammates

✅ Trace request latency

✅ Identify performance bottlenecks

✅ Learn Spring Boot internals

---

# 💡 Key Takeaways

✅ A request flows through many components, but in a predictable order.

✅ One Tomcat worker thread processes a synchronous request from start to finish.

✅ Linux manages the process and threads, while the JVM manages Java objects and method calls.

✅ Each layer has a single responsibility and collaborates with the next layer.

✅ Sequence diagrams provide a clear mental model before diving into networking, Linux, JVM, and Spring Boot internals.

---

# 🎉 Congratulations

You have completed **Part 1 – Architecture**.

You now understand:

* 🏗️ System architecture
* 🔄 Complete request journey
* 📤 Complete response journey
* 🧩 Layered architecture
* 📊 Sequence diagrams

These concepts form the foundation for the next section.

---

# ➡️ Next Part

📂 **02-Network**

The first chapter is:

**📘 01-OSI-Model.md**

We'll leave the application architecture and begin exploring **how data actually travels across the network**, starting with the OSI model and progressing through TCP/IP, sockets, ports, the Linux network stack, Docker networking, and Kubernetes networking.
