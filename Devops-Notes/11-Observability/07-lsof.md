🌍 Introduction

In the previous chapter we learned about ss, which displays network sockets.

But another important question appears:

🤔 How can we see every file, socket, pipe, and device that a process has opened?

Consider a running Spring Boot application:

Spring Boot
      │
      ├── application.properties
      ├── student-results-api.jar
      ├── log file
      ├── TCP socket :8080
      ├── PostgreSQL socket
      └── SSL certificate

Linux treats all of these as files.

The tool that displays them is:

📂 lsof
🎯 Learning Objectives

After completing this chapter you will understand:

📂 What lsof is
📄 Open Files
🔢 File Descriptors
🌐 Network Sockets
🔒 File Locks
🧵 Pipes
🐳 Docker Troubleshooting
☸️ Kubernetes Troubleshooting
💽 Deleted Files
🚀 Production Debugging
❓ What is lsof?

lsof stands for:

List Open Files

It displays every file currently opened by a process.

Unlike:

ps

which answers:

Which processes are running?

lsof answers:

Which files are those processes using?

🏗 Linux Philosophy

One of Linux's most famous ideas is:

Everything is a file.

Examples:

Regular File

↓

application.properties

--------------------

Directory

↓

/var/log

--------------------

TCP Socket

↓

8080

--------------------

Pipe

↓

stdin/stdout

--------------------

Device

↓

/dev/sda

lsof can display all of them.

📂 Viewing All Open Files
lsof

Example:

COMMAND   PID USER FD TYPE NAME
java     5123 root txt student-results-api.jar

This lists every open file on the system.

🔢 File Descriptors

Every process has file descriptors.

Typical descriptors:

FD	Meaning
0	Standard Input (stdin)
1	Standard Output (stdout)
2	Standard Error (stderr)
3+	Files, sockets, pipes, devices, etc.

Example:

Java

↓

FD 3

↓

application.properties
📄 View Files Opened by One Process

Suppose Java PID:

5123

Run:

lsof -p 5123

Output:

student-results-api.jar

application.properties

server.log

TCP *:8080

Now you know every resource the JVM is using.

🌐 View Network Connections

One of the most useful commands:

lsof -i

Output:

java

TCP

*:8080

Equivalent to inspecting sockets with ss, but grouped by process.

Find Process Using Port

Suppose:

8080 already in use

Run:

sudo lsof -i :8080

Output:

java

PID 5123

Now you know exactly which process owns the port.

🍃 Student Results API Example

Run:

java -jar student-results-api.jar

Inspect:

lsof -p <PID>

Observe:

student-results-api.jar

application.properties

server.log

TCP:8080

PostgreSQL Connection
PostgreSQL Example
sudo lsof -i :5432

Output:

postgres

Verify the database server is listening.

Deleted Files

One of the most valuable production features.

Suppose:

server.log

↓

Deleted

The Java process still has the file open.

Disk space is not released.

Check:

lsof | grep deleted

Example:

java

server.log (deleted)

The process must close the file (or exit) before the space is reclaimed.

Docker Example

Container:

docker exec container lsof

Observe:

Log files
JAR
TCP sockets
Configuration files

On the host:

sudo lsof -i

Observe Docker-related processes and sockets.

Kubernetes Example
kubectl exec -it student-api-pod -- lsof

Observe:

Java JAR
ConfigMap-mounted files
Secret-mounted certificates
Log files
TCP sockets
Pipes

Processes communicate using pipes.

Example:

bash

↓

pipe

↓

grep

↓

less

lsof displays these pipe file descriptors.

File Locks

Some applications lock files.

Example:

Database

↓

Lock File

lsof helps identify which process currently has the file open, which is often the first step when investigating lock-related issues.

Complete Application Resources
Spring Boot
      │
      ├── student-results-api.jar
      ├── application.properties
      ├── server.log
      ├── TCP :8080
      ├── PostgreSQL Socket
      ├── SSL Certificates
      └── Temporary Files

lsof can reveal all of these resources.

Hands-on Lab
View All Open Files
lsof
View Java Files
ps -ef | grep java

Then:

lsof -p <PID>
View Listening Port
sudo lsof -i :8080
View Network Files
lsof -i
View Deleted Files
lsof | grep deleted
Kubernetes
kubectl exec -it student-api-pod -- lsof

Observe:

Open files
Sockets
Configuration files
Common Mistakes
❌ Thinking lsof Shows Only Regular Files

It also shows:

TCP sockets
UDP sockets
UNIX sockets
Pipes
Devices
Directories
❌ Confusing File Descriptors with Files

A file descriptor is simply an integer used by a process to reference an open file or socket.

Multiple descriptors may refer to different resources.

❌ Forgetting Deleted Files Consume Space

Deleting a file does not immediately free disk space if a running process still has it open.

lsof | grep deleted is a classic command for diagnosing mysteriously full disks.

Useful Commands
Command	Purpose
lsof	Show all open files
lsof -p <PID>	Files opened by a process
lsof -i	Show network sockets
sudo lsof -i :8080	Find process using port 8080
`lsof	grep deleted`
lsof +D /path	Show open files under a directory
lsof vs ss
lsof	ss
Shows files and sockets	Shows socket information only
Can identify open files, logs, pipes, devices	Focuses on network connections
Shows file descriptors	Shows TCP/UDP states and statistics
Excellent for file-related debugging	Excellent for networking debugging
Complete Linux Debugging Flow
Application Problem
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
High CPU / Memory?
        │
        ▼
jcmd
        │
        ▼
Need Memory Analysis?
        │
        ▼
jmap
        │
        ▼
Need Network Debugging?
        │
        ▼
ss
        │
        ▼
Need File / Socket Ownership?
        │
        ▼
lsof
💡 Key Takeaways

✅ lsof lists every file currently opened by a process.

✅ In Linux, regular files, sockets, pipes, devices, and directories are all represented as files.

✅ lsof -p <PID> reveals everything a process is using, including configuration files, log files, and network sockets.

✅ sudo lsof -i :<port> is one of the fastest ways to identify which process owns a TCP or UDP port.

✅ lsof | grep deleted is invaluable for diagnosing disk space issues caused by deleted-but-still-open files.

✅ lsof complements ps, top, ss, and JVM tools to provide a complete picture of application resource usage.

➡️ Next Chapter

📘 11-Observability/08-strace.md

In the next chapter, we'll explore strace, one of the most powerful Linux debugging tools.

You'll learn:

🔍 What system calls are
🐧 How user-space programs communicate with the Linux kernel
📂 How to trace file operations (open, read, write)
🌐 How to trace network system calls (connect, accept, send, recv)
🚀 How to diagnose hung applications, permission errors, and failed system calls in Docker and Kubernetes

By the end of that chapter, you'll understand how to watch a running application interact with the Linux kernel in real time.
