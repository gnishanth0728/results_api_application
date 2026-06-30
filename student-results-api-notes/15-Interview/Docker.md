📘 Chapter 127 — Docker Interview Questions

📂 File: student-results-api-notes/15-Interview/Docker.md

🌍 Introduction

Docker is one of the most commonly asked interview topics for Backend, DevOps, and Platform Engineering roles.

Interviewers usually don't ask:

"What is Docker?"

Instead, they ask:

What happens internally when you run docker run?
How is a container different from a virtual machine?
What are namespaces?
What are cgroups?
What is OverlayFS?
How does Docker networking work?
Where is writable data stored?
How does Docker communicate with the Linux kernel?

This chapter summarizes the most common interview questions.

🎯 Learning Objectives

After completing this chapter you should be able to answer:

Docker Architecture
Docker Images
Containers
Namespaces
cgroups
OverlayFS
Networking
Volumes
Container Lifecycle
Debugging
Production Best Practices
1. What is Docker?
Answer

Docker is a containerization platform that packages an application together with its runtime, libraries, and dependencies into a portable container.

Containers share the host operating system kernel while remaining isolated using Linux kernel features.

2. Difference Between VM and Docker
Virtual Machine	Docker
Virtualizes hardware	Virtualizes the operating system
Includes guest OS	Shares host kernel
Higher memory usage	Lightweight
Slower startup	Starts in seconds or less
Stronger isolation	Process-level isolation
3. Docker Architecture

Explain:

Docker CLI
      │
REST API
      │
dockerd
      │
containerd
      │
runc
      │
Linux Kernel

Mention:

CLI sends REST requests
dockerd manages Docker
containerd manages container lifecycle
runc creates Linux processes
Linux kernel provides namespaces and cgroups
4. What Happens During docker run?

Expected flow:

docker run nginx
      │
Docker CLI
      │
Docker Daemon
      │
Image Check
      │
Image Pull (if needed)
      │
Create Writable Layer
      │
Namespaces
      │
cgroups
      │
Container Process

The interviewer is often looking for this lifecycle rather than the command syntax.

5. What is a Docker Image?

Answer:

A Docker image is an immutable template consisting of read-only layers.

It contains:

Application
Runtime
Libraries
Dependencies
Metadata

Containers are created from images.

6. Image vs Container
Image	Container
Blueprint	Running instance
Read-only	Read-write layer added
Static	Running process
Multiple containers can use one image	Each container has its own writable layer
7. What is OverlayFS?

Explain:

Image Layer 1

↓

Image Layer 2

↓

Image Layer 3

↓

Writable Layer

Reads come from the combined filesystem view.

Writes go only to the writable layer.

8. What are Linux Namespaces?

Namespaces provide isolation.

Common namespaces:

PID
Network
Mount
IPC
UTS
User

Example:

PID namespace:

Host

PID 100

↓

Container

PID 1

The container has its own process view.

9. What are cgroups?

cgroups control resource usage.

Examples:

CPU
Memory
I/O
PIDs

Example:

Container

↓

CPU 2 cores

Memory 1 GB

Without cgroups, one container could consume all host resources.

10. How Does Docker Networking Work?

Default bridge network:

Container A
      │
     veth
      │
Docker Bridge
      │
     veth
      │
Container B

The bridge acts as a virtual switch.

11. What is a veth Pair?

A virtual Ethernet cable.

Container

↓

veth

↓

Bridge

↓

Host

One end is inside the container.

The other end connects to the bridge.

12. Port Mapping

Command:

docker run -p 8080:80 nginx

Flow:

Browser

↓

Host:8080

↓

Docker NAT

↓

Container:80

Docker configures networking so traffic reaches the container port.

13. Volumes vs Bind Mounts
Volume	Bind Mount
Managed by Docker	Uses host directory
Portable	Depends on host path
Preferred for persistent container data	Useful during development
14. Container Lifecycle
docker run
      │
Created
      │
Running
      │
Stopped
      │
Restarted
      │
Removed

Know the lifecycle states and related commands.

15. What Happens if PID 1 Exits?

Container stops.

Reason:

The container exists to run its main process.

If the main process exits, Docker considers the container finished.

16. Why Containers Start Fast?

Because Docker:

Doesn't boot a guest OS
Doesn't start a kernel
Simply creates isolated Linux processes
17. Where Are Container Writes Stored?

All changes are stored in:

Writable Layer

Unless data is written to a mounted volume or bind mount.

18. Docker Logs

Useful commands:

docker logs container
docker logs -f container
19. Common Debugging Commands
docker ps
docker inspect container
docker exec -it container bash
docker logs container
docker stats
docker network ls
docker volume ls

Interviewers often ask which commands you would use to troubleshoot a container.

20. Production Best Practices
Use small base images.
Pin image versions.
Run as a non-root user.
Minimize image layers.
Use multi-stage builds.
Store secrets outside the image.
Add health checks.
Keep images updated.
Frequently Asked Interview Questions
Easy
What is Docker?
Image vs Container?
Why Docker over Virtual Machines?
What is Docker Hub?
Medium
Explain Docker architecture.
What happens during docker run?
What is OverlayFS?
Explain namespaces.
Explain cgroups.
Bridge networking vs host networking.
Volumes vs bind mounts.
Advanced
How does Docker communicate with the Linux kernel?
Why does a container stop when PID 1 exits?
How does Docker isolate processes?
What happens if a container exceeds its memory limit?
How does Docker networking work internally?
How does Kubernetes use Docker concepts?
Explain OverlayFS internals.
How would you debug a crashing container?
Complete Docker Flow
docker run
      │
Docker CLI
      │
dockerd
      │
containerd
      │
runc
      │
Namespaces
      │
cgroups
      │
OverlayFS
      │
veth Pair
      │
Bridge Network
      │
Linux Process
Interview Tips
When asked:

Explain Docker architecture.

Draw:

CLI
 │
 ▼
dockerd
 │
 ▼
containerd
 │
 ▼
runc
 │
 ▼
Linux Kernel
When asked:

Explain docker run.

Walk through the lifecycle:

Image
↓

Pull

↓

Create

↓

Namespaces

↓

cgroups

↓

Network

↓

Filesystem

↓

PID 1 Starts

↓

Container Running
When asked:

How would you debug a container?

A good structured answer is:

Check whether the container is running (docker ps -a).
Inspect logs (docker logs).
Inspect configuration (docker inspect).
Enter the container (docker exec), if it's still running.
Check networking, mounts, resource limits, and the application's main process.
💡 Key Takeaways

✅ Docker containers are isolated Linux processes, not virtual machines.

✅ The docker run command ultimately creates a Linux process using containerd, runc, namespaces, cgroups, networking, and OverlayFS.

✅ Images are immutable; each container gets its own writable layer.

✅ Understanding what happens internally is more valuable in interviews than memorizing commands.

✅ For senior-level interviews, explain concepts using diagrams and end-to-end execution flow rather than one-line definitions.
