📘 Chapter 113 — JSON Web Token (JWT)

📂 File: student-results-api-notes/13-Security/04-JWT.md

🌍 Introduction

In the previous chapter we learned about Authentication and Authorization.

Now another important question appears:

🤔 Once a user logs in successfully, how does the server recognize future requests?

Example:

Login

↓

Authenticated

A second request arrives:

GET /students/1051110001

How does the server know who sent it?

One popular solution is:

🎟 JSON Web Token (JWT)
🎯 Learning Objectives

After completing this chapter you will understand:

🎟 What JWT is
📦 JWT Structure
✍️ Token Signing
✅ Token Verification
⏰ Token Expiration
🔄 Refresh Tokens
🍃 Spring Security JWT Flow
☸️ JWT in Microservices
❓ What is JWT?

JWT stands for:

JSON Web Token

A JWT is a compact, signed token that contains information (called claims) about an authenticated user.

Unlike session-based authentication, the server typically does not store per-user session state.

JWT Authentication Flow
Browser
      │
      ▼
POST /login
      │
      ▼
Spring Security
      │
      ▼
Verify Username & Password
      │
      ▼
Generate JWT
      │
      ▼
Return Token
      │
      ▼
Browser Stores Token

Subsequent requests include the token.

Request Flow
Browser
      │
Authorization:
Bearer <JWT>
      │
      ▼
Spring Security
      │
      ▼
Verify Token
      │
      ▼
SecurityContext
      │
      ▼
Controller
JWT Structure

A JWT has three parts:

Header

.

Payload

.

Signature

Example:

xxxxx.yyyyy.zzzzz

Each part is Base64URL-encoded.

Header

Example:

{
  "alg":"HS256",
  "typ":"JWT"
}

Fields:

Field	Meaning
alg	Signing algorithm
typ	Token type

The header tells the receiver how the token was signed.

Payload

The payload contains claims.

Example:

{
  "sub":"nishanth",
  "roles":[
      "ROLE_STUDENT"
  ],
  "exp":1750000000
}

Common claims:

Claim	Meaning
sub	Subject (user identifier)
exp	Expiration time
iat	Issued-at time
iss	Issuer
aud	Audience
roles	User roles (custom claim in many applications)

Important: The payload is encoded, not encrypted. Anyone possessing the token can decode and read its contents. Do not store passwords or other sensitive secrets in a JWT payload.

Signature

The signature protects the token from tampering.

Conceptually:

Header

+

Payload

+

Secret Key

↓

Signature

If someone modifies the payload:

Role

↓

ROLE_ADMIN

the signature verification fails.

Login Example

Browser:

POST /login

Body:

{
    "username":"nishanth",
    "password":"secret"
}

Server:

Verify Password

↓

Generate JWT

↓

Return Token
API Request

Browser:

GET /students/1051110001

Authorization:
Bearer eyJhb...

Spring Security:

Read Token

↓

Verify Signature

↓

Verify Expiration

↓

Authenticate User

If valid, the request continues.

Spring Security JWT Flow
HTTP Request
      │
      ▼
JWT Authentication Filter
      │
      ▼
Extract Bearer Token
      │
      ▼
Validate JWT
      │
      ▼
Load User (optional, depending on implementation)
      │
      ▼
SecurityContext
      │
      ▼
Controller
Token Expiration

JWTs should have a limited lifetime.

Example:

Issued

10:00

Expires

10:30

After expiration:

401 Unauthorized

The client must obtain a new token.

Refresh Token

A common approach:

Access Token

15 Minutes
Refresh Token

7 Days

Workflow:

Login

↓

Access Token

↓

Expires

↓

Refresh Token

↓

New Access Token

This reduces the need for users to log in repeatedly while keeping access tokens short-lived.

Student Results API Example

User:

Student

Logs in:

JWT

↓

ROLE_STUDENT

Request:

GET /students/1051110001

Spring Security verifies:

Signature
Expiration
Roles

Then authorizes access.

JWT in Microservices

Architecture:

Browser
      │
      ▼
API Gateway
      │
      ▼
Student Service
      │
      ▼
Marks Service

The browser sends the JWT with each request.

Each service (or the API gateway, depending on the architecture) validates the token before processing requests.

Kubernetes

JWT authentication works the same whether the application runs:

On a VM
In Docker
In Kubernetes

The application validates the token regardless of where it is deployed.

JWT Advantages
Stateless authentication
No server-side session storage
Well suited for REST APIs
Works well with microservices
Easy to propagate between services
JWT Disadvantages
Difficult to revoke immediately once issued
Larger than a simple session identifier
Payload is readable (not encrypted)
Requires careful key management
Expiration strategy must be designed carefully
Hands-on Lab
Login
POST /login

Receive:

JWT
Decode Token

Paste the token into a JWT decoder (for learning purposes).

Observe:

Header
Payload
Claims

Notice that the payload is readable.

API Request
Authorization:
Bearer <token>

Call:

GET /students/1051110001

Observe successful authentication.

Expired Token

Wait until expiration.

Retry the request.

Expected:

401 Unauthorized
Common Mistakes
❌ Treating JWT as Encrypted

JWT payloads are Base64URL-encoded, not encrypted.

Never store:

Passwords
Credit card numbers
Secrets
Private keys

inside the payload.

❌ Long-Lived Access Tokens

Access tokens should have reasonable expiration times.

Short-lived access tokens reduce risk if a token is stolen.

❌ Forgetting Signature Validation

Never trust the payload without verifying the signature.

The signature confirms the token was issued by a trusted authority and has not been modified.

❌ Storing Tokens Insecurely

Protect tokens from theft.

For browser applications, choose storage and cookie strategies carefully based on your security requirements (for example, HttpOnly cookies are commonly used to reduce JavaScript access to tokens).

JWT Workflow
User
    │
    ▼
Login
    │
    ▼
Username & Password
    │
    ▼
Spring Security
    │
    ▼
Generate JWT
    │
    ▼
Browser Stores Token
    │
    ▼
Authorization: Bearer <JWT>
    │
    ▼
JWT Filter
    │
    ▼
Validate Token
    │
    ▼
SecurityContext
    │
    ▼
Controller
Session vs JWT
Session	JWT
Server stores session state	Server validates a signed token
Browser sends session cookie	Client sends Authorization: Bearer token
Common in traditional web apps	Common in REST APIs and microservices
Requires session storage	Typically stateless
💡 Key Takeaways

✅ JWT (JSON Web Token) is a signed token used for stateless authentication.

✅ A JWT consists of three parts: Header, Payload, and Signature.

✅ The payload is readable but protected from tampering by the signature.

✅ Every request carries the token, and Spring Security validates it before authorizing access.

✅ Short-lived access tokens combined with refresh tokens provide a balance between security and usability.

➡️ Next Chapter

📘 13-Security/05-HTTPS-TLS.md

In the next chapter, you'll learn how JWTs and all other application data are protected while traveling across the network.

Topics include:

🔒 Why HTTP is insecure
🌐 HTTPS and TLS
🤝 TLS handshake
🔑 Certificates and Certificate Authorities (CAs)
🔐 Symmetric and asymmetric encryption
☸️ TLS termination with Spring Boot, Docker, Kubernetes, and Ingress

By the end of that chapter, you'll understand exactly how a browser securely establishes an encrypted connection before sending a JWT or any other sensitive data.
