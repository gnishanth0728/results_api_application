📘 Chapter 100 — Linux strace

📂 File: student-results-api-notes/11-Observability/08-strace.md

🌍 Introduction

In previous chapters we observed:

ps
↓

Processes
top
↓

CPU & Memory
jstack
↓

Threads
jcmd
↓

JVM
ss
↓

Network
lsof
↓

Files

But another important question appears:

🤔 What is the process actually asking Linux to do?

Suppose:

Spring Boot

↓

Read File

↓

Connect PostgreSQL

↓

Write Logs

Every one of these operations eventually becomes a system call.

The tool that lets us observe those calls is:

🔍 strace
🎯 Learning Objectives

After completing this chapter you will understand:

What strace is
System Calls
User Space vs Kernel Space
File Operations
Network Operations
Process Creation
Memory Allocation
Signals
Docker Debugging
Kubernetes Debugging
❓ What is strace?

strace traces system calls made by a Linux process.

It can:

Start a new program under tracing
Attach to an existing process
Show every interaction with the Linux kernel

Example:

strace ls

Output:

openat(...)
read(...)
close(...)
write(...)
exit_group(...)
🏗 User Space vs Kernel Space

Applications cannot directly access hardware.

Instead:

Application

↓

System Call

↓

Linux Kernel

↓

Disk

Network

Memory

The kernel performs privileged operations on behalf of user-space programs.

What is a System Call?

A system call is a request from a user-space process to the kernel.

Examples:

System Call	Purpose
openat()	Open file
read()	Read file
write()	Write file
close()	Close file
socket()	Create socket
connect()	Connect TCP
accept()	Accept connection
sendto()	Send data
recvfrom()	Receive data
clone()	Create thread/process
execve()	Execute program
mmap()	Map memory
brk()	Expand heap
File Example

Java:

Files.readString(path);

Eventually becomes:

Java

↓

JVM

↓

openat()

↓

read()

↓

close()

strace shows each step.

Network Example

Spring Boot:

DriverManager.getConnection()

Eventually:

socket()

↓

connect()

↓

send()

↓

recv()

Output:

socket(AF_INET,...)

connect(...5432...)

sendto(...)

recvfrom(...)

You can literally watch PostgreSQL communication begin.

Memory Example

Java allocates memory.

Eventually:

mmap()

↓

brk()

These system calls request additional virtual memory from the kernel.

Process Creation

Suppose Java executes:

Runtime.getRuntime().exec(...)

System calls:

clone()

↓

execve()

The kernel creates the new process.

Running Under strace
strace java -jar student-results-api.jar

You'll see:

openat()

read()

socket()

connect()

epoll_wait()

write()

Every system call is printed in order.

Attach to Existing Process

Find PID:

ps -ef | grep java

Attach:

sudo strace -p <PID>

Now every new system call made by the process is displayed.

Press:

Ctrl+C

to stop tracing.

Follow Child Processes

Many applications create child processes or threads.

Trace them too:

strace -f java -jar app.jar

-f follows fork(), clone(), and related process creation calls.

Trace Only File Operations
strace -e trace=file java -jar app.jar

Shows:

openat()

stat()

access()

readlink()

Useful when debugging missing configuration files.

Trace Only Network Calls
strace -e trace=network java -jar app.jar

Shows:

socket()

connect()

accept()

sendto()

recvfrom()

Excellent for network debugging.

Student Results API Example

Spring Boot starts.

Student Results API

↓

application.properties

↓

PostgreSQL

↓

Port 8080

strace shows:

openat("application.properties")

↓

socket()

↓

connect(5432)

↓

listen(8080)

↓

accept()

You can observe the application's interaction with the operating system from startup onward.

Docker Example

Inside the container:

docker exec -it container sh

Find PID:

ps -ef

Trace:

strace -p <PID>

The container must include strace, and attaching may require additional capabilities such as SYS_PTRACE.

Kubernetes Example
kubectl exec -it student-api-pod -- sh

Find Java:

ps -ef

Attach:

strace -p <PID>

If strace is unavailable in the application image, you can often use an ephemeral debug container or another debugging approach.

Diagnosing Permission Errors

Suppose the application reports:

Permission denied

Trace:

strace -e trace=file java -jar app.jar

Output:

openat(...)

=

EACCES

Now you know exactly which file caused the failure.

Diagnosing Missing Files

Output:

openat("application.properties")

=

ENOENT

Meaning:

No such file or directory

This is one of the fastest ways to find configuration issues.

Hands-on Lab
Trace ls
strace ls

Observe:

openat()
getdents64()
write()
Trace Java Startup
strace java -jar student-results-api.jar
Attach to Running JVM
ps -ef | grep java

Then:

sudo strace -p <PID>
Trace Only Network
strace -e trace=network java -jar student-results-api.jar
Trace Only Files
strace -e trace=file java -jar student-results-api.jar
Save Output
strace -o trace.log java -jar student-results-api.jar

Review later:

less trace.log
Common Mistakes
❌ Thinking strace Shows Java Methods

strace shows system calls, not Java stack frames.

For Java methods use:

jstack
❌ Forgetting strace Slows Applications

Every system call is intercepted.

Tracing can noticeably slow the application, especially under heavy load.

Avoid long-running tracing sessions on busy production systems unless necessary.

❌ Assuming Every Java Method Makes a System Call

Most Java methods execute entirely in user space.

Only operations that require kernel services—such as file I/O, networking, memory management, process creation, or synchronization primitives—result in system calls.

Useful Commands
Command	Purpose
strace command	Trace a new program
strace -p <PID>	Attach to an existing process
strace -f command	Follow child processes and threads
strace -e trace=file command	Trace only file-related system calls
strace -e trace=network command	Trace only network system calls
strace -o trace.log command	Save output to a file
Complete Debugging Flow
Application Problem
        │
        ▼
ps
        │
        ▼
Find Process
        │
        ▼
top
        │
        ▼
CPU / Memory
        │
        ▼
jcmd
        │
        ▼
JVM Diagnostics
        │
        ▼
ss
        │
        ▼
Network
        │
        ▼
lsof
        │
        ▼
Open Files
        │
        ▼
strace
        │
        ▼
System Calls
        │
        ▼
Linux Kernel
💡 Key Takeaways

✅ strace traces the system calls a process makes to the Linux kernel.

✅ Every file operation, network connection, memory request, and process creation eventually becomes one or more system calls.

✅ strace is invaluable for diagnosing permission problems, missing files, networking issues, and unexpected kernel-level behavior.

✅ strace -e trace=file and strace -e trace=network let you focus on specific categories of system calls.

✅ strace complements tools like ps, top, jstack, jcmd, ss, and lsof by revealing exactly how an application interacts with the operating system.

➡️ Next Chapter

📘 11-Observability/09-tcpdump.md

In the next chapter, we'll move one level lower than system calls and observe the actual network packets traveling across the wire.

You'll learn:

🌐 What a packet really is
📦 Ethernet, IP, TCP, and HTTP packet structure
🔍 Capturing traffic with tcpdump
🐳 Capturing packets from Docker containers
☸️ Capturing Pod traffic in Kubernetes
🧠 Following a complete HTTP request from the network interface to your Spring Boot application

This chapter completes the journey from Java method → system call → Linux kernel → network packet.
