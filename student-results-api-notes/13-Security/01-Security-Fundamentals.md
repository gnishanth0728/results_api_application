📘 Chapter 110 — Security Fundamentals

📂 File: student-results-api-notes/13-Security/01-Security-Fundamentals.md

🌍 Introduction

So far in this course we've focused on:

Application Development
Docker
Kubernetes
Linux
Observability
Performance

Now we begin:

🔐 Security

Every production application is exposed to security threats.

Security answers questions such as:

Who is allowed to access the application?
How do we verify identity?
How do we protect data?
How do we prevent attacks?
What happens if someone compromises a server?
🎯 Learning Objectives

After completing this chapter you will understand:

🔐 What Security Means
🛡 CIA Triad
👤 Authentication
🔑 Authorization
🔒 Encryption
🌐 HTTPS
🐳 Docker Security
☸️ Kubernetes Security
🍃 Spring Boot Security
🚀 Defense in Depth
❓ What is Security?

Application security is the practice of protecting systems, data, and users from unauthorized access, modification, disclosure, or disruption.

Security is not one feature.

It is a collection of protections working together.

Security Layers
User
      │
      ▼
Browser
      │
      ▼
HTTPS
      │
      ▼
Spring Boot
      │
      ▼
Tomcat
      │
      ▼
JVM
      │
      ▼
Linux
      │
      ▼
Docker
      │
      ▼
Kubernetes
      │
      ▼
PostgreSQL

Every layer must be secured.

The CIA Triad

The foundation of information security is the CIA Triad.

Security
     │
     ├── Confidentiality
     ├── Integrity
     └── Availability
Confidentiality

Goal:

Only authorized users can view data.

Example:

Student Marks

↓

Only Student

Only Teacher

Not Public

Techniques:

Authentication
Authorization
Encryption
Integrity

Goal:

Prevent unauthorized modification.

Example:

Student Marks

95

↓

Cannot Become

100

Without Authorization

Techniques:

Digital signatures
Hashing
Database constraints
Audit logging
Availability

Goal:

The application should remain accessible to legitimate users.

Example:

Student Results API

↓

Available

24×7

Threats:

Hardware failures
Denial-of-Service (DoS) attacks
Software crashes
Network outages

Protection:

Replication
Kubernetes self-healing
Load balancing
Monitoring
Authentication

Question:

Who are you?

Example:

Username

+

Password

or

JWT Token

or

OAuth Login

Authentication verifies identity.

Authorization

Question:

What are you allowed to do?

Example:

Student

↓

View Own Marks

Teacher:

Teacher

↓

Update Marks

Administrator:

Admin

↓

Manage Users

Authorization occurs after authentication.

Authentication vs Authorization
Authentication	Authorization
Verifies identity	Determines permissions
"Who are you?"	"What can you do?"
Login	Access control
Encryption

Sensitive data should not travel across the network as plain text.

Without encryption:

Browser

↓

Password

↓

Internet

Anyone who can intercept the traffic may be able to read it.

With encryption:

Browser

↓

TLS Encryption

↓

Server

The data remains confidential while in transit.

HTTPS

Instead of:

HTTP

Production systems use:

HTTPS

HTTPS combines:

HTTP

+

TLS

Benefits:

Confidentiality
Integrity
Server authentication
Common Threats

Examples include:

SQL Injection
Cross-Site Scripting (XSS)
Cross-Site Request Forgery (CSRF)
Brute-force attacks
Credential theft
Remote Code Execution (RCE)
Denial of Service (DoS)

Each requires different defensive techniques.

Student Results API Example

Suppose your API exposes:

GET /students/{rollNumber}

Without authentication:

Anyone

↓

Student Data

With authentication and authorization:

Authenticated User

↓

Permission Check

↓

Allowed Data
Docker Security

Containers provide process isolation but are not a security boundary by themselves.

Good practices include:

Run as a non-root user.
Use minimal base images.
Scan images for vulnerabilities.
Avoid embedding secrets in images.
Keep images updated.
Kubernetes Security

Important concepts:

RBAC
Network Policies
Secrets
Pod Security Standards
Admission Controllers
Service Accounts

Each limits what workloads and users can do inside the cluster.

Spring Boot Security

Typical protections include:

Spring Security
JWT Authentication
Role-Based Access Control (RBAC)
Password hashing
CSRF protection (for browser-based applications)
Secure HTTP headers
Defense in Depth

Never rely on a single protection.

Internet
      │
Firewall
      │
HTTPS
      │
Authentication
      │
Authorization
      │
Application Validation
      │
Database Permissions

If one layer fails, the others continue to provide protection.

Secure Request Flow
Browser
      │
      ▼
HTTPS
      │
      ▼
Spring Security
      │
      ▼
Authentication
      │
      ▼
Authorization
      │
      ▼
Controller
      │
      ▼
Service
      │
      ▼
Repository
      │
      ▼
PostgreSQL
Security Principles

Follow these core principles:

Least Privilege
Defense in Depth
Fail Securely
Secure by Default
Keep Software Updated
Validate All Inputs
Never Trust User Input
Hands-on Lab
Verify HTTPS
curl -v https://localhost:8443

Observe the TLS handshake.

Check Security Headers
curl -I https://localhost:8443

Look for headers such as:

Strict-Transport-Security
X-Content-Type-Options
X-Frame-Options
Inspect Docker Image User
docker inspect student-api

Verify that the container does not run as root unless absolutely necessary.

View Kubernetes RBAC
kubectl get roles

kubectl get rolebindings

Review how permissions are assigned.

Common Mistakes
❌ Thinking Authentication Is Enough

Logging users in is only the first step.

You must also verify what each authenticated user is allowed to access.

❌ Storing Passwords in Plain Text

Passwords should never be stored directly.

Instead, store a strong password hash using a modern password hashing algorithm such as bcrypt, scrypt, or Argon2.

❌ Trusting Client Input

Never assume:

Request parameters
JSON bodies
HTTP headers
Cookies

are trustworthy.

Always validate and authorize on the server.

❌ Assuming Internal Systems Are Safe

Internal networks can also be compromised.

Apply authentication, authorization, and encryption where appropriate, even for internal services.

Security Checklist
✓ HTTPS Enabled

✓ Authentication

✓ Authorization

✓ Password Hashing

✓ Input Validation

✓ Least Privilege

✓ Secure Secrets

✓ Updated Dependencies

✓ Logging & Monitoring

✓ Regular Security Reviews
Security Across the Stack
Layer	Security Focus
Browser	HTTPS, secure cookies, CSP
Spring Boot	Authentication, authorization, input validation
Tomcat	Secure connector configuration
JVM	Timely updates, secure runtime
Linux	File permissions, users, firewall
Docker	Non-root containers, minimal images
Kubernetes	RBAC, Network Policies, Secrets
PostgreSQL	Roles, permissions, TLS, auditing
💡 Key Takeaways

✅ Security is a continuous process rather than a single feature.

✅ The CIA Triad—Confidentiality, Integrity, and Availability—is the foundation of application security.

✅ Authentication verifies identity, while authorization determines permissions.

✅ HTTPS protects data in transit using TLS.

✅ Defense in depth means applying multiple independent security controls across every layer of the application stack.

➡️ Next Chapter

📘 13-Security/02-Authentication.md

In the next chapter, we'll explore Authentication in depth.

You'll learn:

👤 User identity verification
🔑 Username/password authentication
🔐 Password hashing with bcrypt
🪪 Session-based authentication
🎟️ Token-based authentication (JWT)
🔄 Authentication flow in Spring Boot
☸️ Authentication in microservices and Kubernetes

By the end of that chapter, you'll understand exactly how a user logs into a Spring Boot application and how the application securely verifies every request.
