# 📘 Chapter 21 — Linux File Descriptors

This is another fundamental Linux chapter. By the end of it, readers should understand one of Unix's most elegant ideas:

In Linux, almost everything is represented as a file.

That includes:

📄 Regular files
📁 Directories
🔌 Network sockets
🖥️ Terminal devices
📡 Pipes
📂 /proc entries

This chapter will connect Linux file descriptors, Java, Tomcat, HTTP sockets, Docker, and Kubernetes into one coherent model.

> 📂 File: `student-results-api-notes/03-Linux/06-File-Descriptors.md`

---

# 🌍 Introduction

During your Student Results API experiments, you inspected the Java process:

```bash id="n8x7qa"
ps -ef | grep java
```

Suppose the Java process has:

```text id="a1r4ud"
PID = 7065
```

Now inspect its open file descriptors:

```bash id="r2v8zt"
ls -l /proc/7065/fd
```

Example output:

```text id="b7w5nm"
0 -> /dev/pts/0
1 -> /dev/pts/0
2 -> /dev/pts/0
3 -> socket:[38492]
4 -> socket:[38495]
5 -> /home/ubuntu/logs/app.log
6 -> student-results-api.jar
```

This raises an interesting question:

> 🤔 Why is a network socket listed like a file?

The answer is one of the core design principles of Unix:

> **Everything is a file.**

Linux represents open resources using **File Descriptors (FDs)**.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📄 What a file descriptor is
* 🔢 File descriptor numbers
* 📂 File descriptor tables
* 🔗 Kernel file objects
* 📁 Open files
* 🔌 Network sockets
* 🧵 Pipes
* 📡 Devices
* 🍃 Tomcat sockets
* ☕ JVM file descriptors
* 🐳 Docker
* ☸️ Kubernetes
* 🧪 Debugging file descriptors

---

# ❓ What Is a File Descriptor?

A **File Descriptor (FD)** is a small integer that identifies an open resource within a process.

Resources include:

* 📄 Files
* 📁 Directories
* 🔌 TCP sockets
* 📡 UDP sockets
* 🧵 Pipes
* 🖥️ Terminals
* 📀 Devices

The application never manipulates the kernel object directly—it uses the file descriptor as a handle.

---

# 🏗️ High-Level Architecture

```text id="k9d1mz"
                Java Process

+--------------------------------------+

FD Table

0

1

2

3

4

5

+--------------------------------------+

          │

          ▼

Linux Kernel

          │

          ▼

Open File Objects

          │

          ▼

Disk

Sockets

Terminal

Pipe
```

---

# 🔢 Standard File Descriptors

Every Linux process starts with three predefined file descriptors.

| FD | Name   | Purpose         |
| -: | ------ | --------------- |
|  0 | stdin  | Standard Input  |
|  1 | stdout | Standard Output |
|  2 | stderr | Standard Error  |

Example:

```text id="o2d0qu"
FD 0

↓

Keyboard

FD 1

↓

Terminal Output

FD 2

↓

Error Output
```

---

# 📂 File Descriptor Table

Every process owns its own FD table.

Conceptually:

```text id="j6n8vl"
Java Process

+-----------------------------+

FD 0 → stdin

FD 1 → stdout

FD 2 → stderr

FD 3 → Socket

FD 4 → Socket

FD 5 → Log File

FD 6 → JAR File

+-----------------------------+
```

The numbers are indexes into the process's descriptor table.

---

# 🔗 Kernel File Objects

An FD is **not** the file itself.

Instead:

```text id="s1b2af"
FD 5

↓

Kernel File Object

↓

inode

↓

Disk
```

The kernel stores metadata such as:

* Current file offset
* Access mode
* Status flags
* Reference count

Multiple FDs can reference the same kernel file object.

---

# 📄 Opening a File

Conceptually:

```c id="f8p0aw"
open("students.txt")
```

Linux performs:

```text id="u7n1vd"
File

↓

Kernel File Object

↓

Assign FD

↓

Return Integer
```

Example:

```text id="m0h4jk"
FD = 7
```

The application uses `7` for subsequent reads and writes.

---

# 📖 Reading a File

Conceptually:

```c id="u9s5kc"
read(fd, buffer, size)
```

Flow:

```text id="t7y8op"
Application

↓

FD

↓

Kernel

↓

Disk

↓

Buffer

↓

Application
```

The application never accesses the disk directly.

---

# ✍️ Writing a File

Conceptually:

```c id="q4d7nh"
write(fd, buffer, size)
```

Flow:

```text id="g5c8re"
Application

↓

Kernel Buffer

↓

Filesystem

↓

Disk
```

---

# 🔌 Sockets Are File Descriptors

This is one of the most important ideas in Linux.

When Tomcat accepts a new connection:

```text id="r1k2vn"
accept()

↓

Socket Created

↓

FD Returned
```

Example:

```text id="x3l7bs"
FD 8

↓

TCP Socket

↓

Client Connection
```

Tomcat reads and writes HTTP data using this FD.

---

# 🍃 Student Results API Example

Suppose a browser connects:

```text id="d5p1mc"
Browser

↓

TCP Connection

↓

Tomcat

↓

FD 8
```

Tomcat performs operations equivalent to:

```text id="f9t6yz"
read(8)

↓

HTTP Request

↓

Spring Boot

↓

write(8)

↓

HTTP Response
```

The same interface (`read()`/`write()`) works for both files and sockets.

---

# 📦 JAR File

When the JVM starts:

```bash id="c4y0nk"
java -jar student-results-api.jar
```

The JAR itself is opened by the JVM.

```text id="e7z9pb"
FD

↓

student-results-api.jar
```

The JVM reads:

* Class files
* Resources
* Configuration

using ordinary file descriptors.

---

# 📝 Log Files

Suppose your application writes logs:

```text id="u1a8fw"
logs/app.log
```

The logger opens the file once.

```text id="v6j2lm"
FD 5

↓

app.log
```

Each log entry becomes a `write()` operation on that file descriptor.

---

# 🧵 Pipes

Pipes also use file descriptors.

Example:

```bash id="b3m7qt"
cat file.txt | grep Student
```

Linux creates a pipe:

```text id="h4n9rs"
cat

↓

Pipe

↓

grep
```

The pipe has two file descriptors:

* Read end
* Write end

---

# 🖥️ Devices

Even hardware devices are exposed as files.

Examples:

```text id="k7u5xd"
/dev/null

/dev/random

/dev/tty

/dev/sda
```

Applications interact with them using the same `open()`, `read()`, and `write()` system calls.

---

# 🧠 File Descriptor Lifecycle

```text id="y0l4pv"
open()

↓

FD Allocated

↓

read()

↓

write()

↓

close()

↓

FD Released
```

After `close()`, the FD number may be reused for another resource.

---

# 📊 Complete Flow

```text id="n2w8be"
Browser

↓

TCP Socket

↓

FD 8

↓

Tomcat

↓

DispatcherServlet

↓

StudentController

↓

StudentService

↓

Repository

↓

PostgreSQL

↓

FD 12

↓

Database Socket
```

Your application may simultaneously hold:

* Socket FDs
* Log file FDs
* JAR file FDs
* Database connection FDs

---

# 🚨 File Descriptor Leaks

Suppose code repeatedly opens files but never closes them.

```java id="q8k1tv"
new FileInputStream(file);
```

without:

```java id="m5d7af"
close();
```

Eventually:

```text id="g9u6lw"
Too many open files
```

The process reaches its FD limit and cannot open additional files or sockets.

Always use:

```java id="p7s2ke"
try (InputStream in = ...) {
    ...
}
```

to ensure resources are closed.

---

# 🐳 Docker Perspective

A container is just a Linux process.

It has its own file descriptor table.

```text id="w8h3oj"
Container

↓

Java Process

↓

FD Table

↓

Sockets

↓

Logs

↓

JAR
```

The kernel still manages all descriptors.

---

# ☸️ Kubernetes Perspective

Inside a Pod:

```text id="r3y6nm"
Pod

↓

Container

↓

Java Process

↓

FD Table

↓

Socket

↓

ConfigMap File

↓

Volume File
```

Volumes, ConfigMaps, Secrets, and sockets all appear as ordinary files or file descriptors to the application.

---

# 🧪 Hands-on Lab

## Find the Java PID

```bash id="a6v8ps"
ps -ef | grep java
```

---

## List File Descriptors

```bash id="j9r2mk"
ls -l /proc/<PID>/fd
```

Observe entries such as:

```text id="n4x1zd"
socket:[38492]

socket:[38501]

student-results-api.jar

app.log
```

---

## Count Open File Descriptors

```bash id="h8m5kc"
ls /proc/<PID>/fd | wc -l
```

---

## Display Open Files

```bash id="t1q4sw"
lsof -p <PID>
```

This shows every file, socket, pipe, and device opened by the process.

---

## Monitor Socket File Descriptors

Generate load:

```bash id="y7n3rl"
ab -n 10000 -c 100 \
http://localhost:8080/students/1051110244
```

In another terminal:

```bash id="p5d9gf"
lsof -p <PID> | grep TCP
```

Observe new socket descriptors appearing as clients connect.

---

## View Descriptor Limits

```bash id="s2c8nv"
ulimit -n
```

This displays the maximum number of open file descriptors allowed for the current shell.

---

# 💡 Key Takeaways

✅ A file descriptor is an integer that represents an open resource.

✅ Every process owns its own file descriptor table.

✅ Standard descriptors are 0 (stdin), 1 (stdout), and 2 (stderr).

✅ Files, sockets, pipes, terminals, and devices all use the same file descriptor abstraction.

✅ Tomcat communicates with clients through socket file descriptors.

✅ The JVM uses file descriptors for JAR files, log files, database sockets, and network connections.

✅ Docker containers and Kubernetes Pods rely on the same Linux file descriptor mechanism because they ultimately run ordinary Linux processes.

---

# ➡️ Next Chapter

📘 **`03-Linux/07-System-Calls.md`**

Next we'll explore the boundary between **user space** and **kernel space**.

We'll answer:

> **How does Java ask Linux to open a file, allocate memory, create a socket, or send an HTTP response?**

We'll cover:

* 📞 What a system call is
* 🔄 User mode vs kernel mode
* ⚙️ `open()`, `read()`, `write()`, `socket()`, `accept()`, `fork()`, `execve()`
* 🧠 CPU privilege levels
* 🍃 Spring Boot system calls
* 🧪 Using `strace` to observe real system calls

By the end of the next chapter, you'll see exactly how every action performed by your Student Results API eventually becomes a Linux system call.
