# Create project root
mkdir -p student-results-api-notes
cd student-results-api-notes

# Root README
touch README.md

# ==========================
# 01 - Architecture
# ==========================
mkdir -p 01-Architecture/images
touch 01-Architecture/{01-System-Overview.md,02-Complete-Request-Journey.md,03-Response-Journey.md,04-Layered-Architecture.md,05-Sequence-Diagram.md}

# ==========================
# 02 - Network
# ==========================
mkdir -p 02-Network/images
touch 02-Network/{01-OSI-Model.md,02-TCP-IP.md,03-TCP-Handshake.md,04-HTTP-Request.md,05-DNS.md,06-IP-Routing.md,07-Socket.md,08-Port.md,09-Linux-Network-Stack.md,10-Network-Namespaces.md}

# ==========================
# 03 - Linux
# ==========================
mkdir -p 03-Linux/images
touch 03-Linux/{01-Linux-Process.md,02-Linux-Thread.md,03-Scheduler.md,04-Virtual-Memory.md,05-Heap-vs-Stack.md,06-File-Descriptors.md,07-Sockets.md,08-Epoll.md,09-Context-Switch.md,10-proc-filesystem.md}

# ==========================
# 04 - JVM
# ==========================
mkdir -p 04-JVM/images
touch 04-JVM/{01-JVM-Architecture.md,02-ClassLoader.md,03-Heap.md,04-Stack.md,05-Metaspace.md,06-Garbage-Collection.md,07-JIT-Compiler.md,08-JVM-Threads.md,09-JVM-Memory.md}

# ==========================
# 05 - Tomcat
# ==========================
mkdir -p 05-Tomcat/images
touch 05-Tomcat/{01-Tomcat-Architecture.md,02-NIO-Connector.md,03-Acceptor-Thread.md,04-Poller-Thread.md,05-Worker-Thread.md,06-ThreadPool.md,07-DispatcherServlet.md}

# ==========================
# 06 - Spring Boot
# ==========================
mkdir -p 06-SpringBoot/images
touch 06-SpringBoot/{01-SpringBoot-Architecture.md,02-MVC.md,03-DispatcherServlet.md,04-Controller.md,05-Service.md,06-Repository.md,07-DTO.md,08-Bean-Lifecycle.md,09-Dependency-Injection.md,10-Exception-Handling.md}

# ==========================
# 07 - Hibernate
# ==========================
mkdir -p 07-Hibernate/images
touch 07-Hibernate/{01-Entity.md,02-Persistence-Context.md,03-Entity-Lifecycle.md,04-Dirty-Checking.md,05-SQL-Generation.md,06-Lazy-vs-Eager.md,07-Transactions.md}

# ==========================
# 08 - PostgreSQL
# ==========================
mkdir -p 08-PostgreSQL/images
touch 08-PostgreSQL/{01-Architecture.md,02-Connection.md,03-Parser.md,04-Planner.md,05-Executor.md,06-Indexes.md,07-Shared-Buffers.md,08-WAL.md,09-VACUUM.md,10-EXPLAIN.md}

# ==========================
# 09 - Docker
# ==========================
mkdir -p 09-Docker/images
touch 09-Docker/{01-Docker-Architecture.md,02-Image.md,03-Container.md,04-Namespaces.md,05-cgroups.md,06-OverlayFS.md,07-Bridge-Network.md,08-veth.md,09-Port-Mapping.md}

# ==========================
# 10 - Kubernetes
# ==========================
mkdir -p 10-Kubernetes/images
touch 10-Kubernetes/{01-Kubernetes-Architecture.md,02-API-Server.md,03-etcd.md,04-Scheduler.md,05-ControllerManager.md,06-Kubelet.md,07-ContainerRuntime.md,08-Pod.md,09-ReplicaSet.md,10-Deployment.md,11-Service.md,12-Ingress.md,13-kube-proxy.md,14-CNI.md,15-HPA.md}

# ==========================
# 11 - Observability
# ==========================
mkdir -p 11-Observability/images
touch 11-Observability/{01-ps.md,02-top.md,03-jstack.md,04-jcmd.md,05-jmap.md,06-ss.md,07-lsof.md,08-pg_stat_activity.md}

# ==========================
# 12 - Performance
# ==========================
mkdir -p 12-Performance/images
touch 12-Performance/{01-ApacheBench.md,02-LoadTesting.md,03-JVM-Tuning.md,04-ThreadPool.md,05-ConnectionPool.md,06-DatabasePerformance.md,07-Observations.md}

# ==========================
# 13 - Interview
# ==========================
mkdir -p 13-Interview
touch 13-Interview/{SpringBoot.md,Linux.md,Docker.md,Kubernetes.md,PostgreSQL.md,JVM.md,Performance.md}

# ==========================
# Assets
# ==========================
mkdir -p assets

echo "Folder structure created successfully!"
