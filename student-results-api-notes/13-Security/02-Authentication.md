📘 Chapter 111 — Authentication

📂 File: student-results-api-notes/13-Security/02-Authentication.md

🌍 Introduction

In the previous chapter we learned the basics of security.

Now we focus on the first security mechanism:

👤 Authentication

Authentication answers one question:

Who are you?

Every secure application must verify the identity of its users before allowing access to protected resources.

🎯 Learning Objectives

After completing this chapter you will understand:

👤 What Authentication is
🔑 Username & Password Authentication
🔒 Password Hashing
🍪 Session Authentication
🎟 JWT Authentication
🔄 Authentication Flow
🍃 Spring Security Authentication
☸️ Authentication in Microservices
❓ What is Authentication?

Authentication is the process of verifying a user's identity.

Example:

User

↓

Username

↓

Password

↓

Identity Verified

If verification succeeds:

Authenticated

Otherwise:

Access Denied
Authentication vs Authorization

Authentication:

Who are you?

Authorization:

What are you allowed to do?

Example:

Login

↓

Authentication

↓

Authorization

↓

Access Resource

Authentication always happens first.

Real-World Example

Suppose:

Bank

↓

ATM Card

↓

PIN

The ATM first verifies:

Card
PIN

Only then does it allow:

Withdraw money
Check balance
Transfer funds

The same principle applies to web applications.

Student Results API Example

Suppose the API exposes:

GET /students/1051110001

Without authentication:

Anyone

↓

Student Marks

With authentication:

Login

↓

Verify Identity

↓

Access Granted
Username and Password Authentication

The most common authentication method.

User enters:

Username

Password

Browser sends:

POST /login

{
    "username":"nishanth",
    "password":"secret"
}

Server verifies the credentials.

Why Passwords Are Never Stored Directly

Bad practice:

Database

↓

secret123

If the database is compromised, every password is exposed.

Instead:

secret123

↓

Hash Function

↓

$2a$10$...

Only the hash is stored.

Password Hashing

Spring Security commonly uses:

BCrypt

Example:

BCryptPasswordEncoder

Verification:

Password

↓

Hash

↓

Compare

↓

Match?

The original password cannot be recovered from the stored hash.

Authentication Flow
Browser
      │
      ▼
POST /login
      │
      ▼
Spring Security
      │
      ▼
Load User
      │
      ▼
Verify Password
      │
      ▼
Authenticated
Session-Based Authentication

Traditional web applications often use sessions.

Flow:

Browser

↓

Login

↓

Session Created

↓

Session ID

↓

Cookie

↓

Next Request

The browser automatically sends the session cookie with future requests.

JWT Authentication

Modern REST APIs often use:

JWT

(JSON Web Token)

Flow:

Login

↓

JWT Created

↓

Browser Stores Token

↓

Authorization Header

↓

Server Validates Token

Unlike session authentication, the server typically does not keep per-user session state.

HTTP Authentication Example

Login:

POST /login

Response:

200 OK

JWT

Next request:

GET /students/1051110001

Authorization:
Bearer eyJhb...

Spring Security verifies the token before invoking the controller.

Spring Security Flow
Browser
      │
      ▼
Authentication Filter
      │
      ▼
Authentication Manager
      │
      ▼
UserDetailsService
      │
      ▼
Database
      │
      ▼
Password Verification
      │
      ▼
Authenticated User
Authentication Components
Component	Responsibility
Authentication Filter	Extract credentials or token
AuthenticationManager	Coordinate authentication
UserDetailsService	Load user information
PasswordEncoder	Verify password hash
SecurityContext	Store the authenticated user for the current request
UserDetailsService

Spring Security loads users through:

UserDetailsService

Example:

Username

↓

Database

↓

User Object

The service retrieves:

Username
Password hash
Roles
Account status
SecurityContext

Once authenticated:

SecurityContext

↓

Current User

Controllers can obtain information about the authenticated user from the security context.

Authentication Failure

Wrong password:

Password

↓

Hash Comparison

↓

No Match

↓

401 Unauthorized

The request is rejected.

Microservices Authentication

Suppose:

API Gateway

↓

Student Service

↓

Marks Service

Common flow:

User Login

↓

JWT

↓

Gateway

↓

Microservices

Each service validates the token or relies on a trusted gateway depending on the architecture.

Kubernetes

Authentication is independent of Kubernetes.

Pods simply run the application.

Authentication is typically implemented by:

Spring Security
API Gateway
Identity Provider

Kubernetes itself has a separate authentication system for cluster users and components.

Hands-on Lab
Password Hash

Generate a BCrypt hash:

new BCryptPasswordEncoder().encode("password123");

Observe that hashing the same password multiple times produces different hashes because BCrypt uses a random salt.

Verify Password
passwordEncoder.matches(
    "password123",
    storedHash
);
Test Login
POST /login

Verify:

Correct password → Success
Wrong password → 401 Unauthorized
JWT Request
Authorization:

Bearer <token>

Observe Spring Security accepting or rejecting the request based on token validity.

Common Mistakes
❌ Storing Plain Text Passwords

Never store:

password123

Always store a password hash.

❌ Creating Your Own Hash Algorithm

Use well-tested password hashing algorithms such as:

BCrypt
Argon2
scrypt

Avoid fast general-purpose hashes like SHA-256 for password storage.

❌ Confusing Login with Authentication

Authentication verifies identity.

Logging in is simply one way to initiate authentication.

❌ Sending Credentials Over HTTP

Always use:

HTTPS

Credentials should never be transmitted over unencrypted HTTP.

Authentication Checklist
✓ HTTPS Enabled

✓ Password Hashing

✓ Authentication Filter

✓ UserDetailsService

✓ Password Verification

✓ SecurityContext

✓ Authentication Success

✓ Authentication Failure Handling
Authentication Workflow
User
    │
    ▼
Login Page
    │
    ▼
Username & Password
    │
    ▼
Spring Security
    │
    ▼
UserDetailsService
    │
    ▼
Database
    │
    ▼
PasswordEncoder
    │
    ▼
Authenticated User
    │
    ▼
SecurityContext
    │
    ▼
Controller
Session vs JWT
Session Authentication	JWT Authentication
Server stores session state	Token contains user claims
Browser sends session cookie	Client sends Bearer token
Common for traditional web apps	Common for REST APIs and microservices
Requires server-side session storage	Typically stateless on the server
💡 Key Takeaways

✅ Authentication verifies who the user is.

✅ Authentication always occurs before authorization.

✅ Passwords must be stored as secure password hashes using algorithms such as BCrypt, Argon2, or scrypt.

✅ Spring Security uses components such as AuthenticationManager, UserDetailsService, PasswordEncoder, and SecurityContext to authenticate users.

✅ Modern REST APIs commonly use JWT-based authentication, while many traditional web applications use session-based authentication.

➡️ Next Chapter

📘 13-Security/03-Authorization.md

In the next chapter, you'll learn Authorization.

Topics include:

🔑 Roles and permissions
👤 RBAC (Role-Based Access Control)
🏷️ Spring Security authorities
🛡️ @PreAuthorize and method security
📂 URL-based authorization
☸️ Authorization in microservices and Kubernetes

By the end of that chapter, you'll understand how an authenticated user is granted—or denied—access to specific resources.
