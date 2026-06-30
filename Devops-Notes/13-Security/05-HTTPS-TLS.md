📘 Chapter 114 — HTTPS & TLS

📂 File: student-results-api-notes/13-Security/05-HTTPS-TLS.md

This chapter is one of the most important chapters in networking and security because every modern web application uses HTTPS.

You've already learned:

Authentication
Authorization
JWT

Now another important question appears:

How does the JWT travel safely across the Internet?

Suppose a browser sends:

Authorization:
Bearer eyJhbGciOiJIUzI1Ni...

If this request uses plain HTTP:

Browser
      │
HTTP
      │
Internet
      │
Anyone Can Read It

An attacker on the network could potentially capture the JWT and impersonate the user.

HTTPS prevents this by encrypting the communication.


🌍 Introduction

In previous chapters we learned how users authenticate and how JWT secures user identity.

Another important question appears:

🤔 How do we securely send usernames, passwords, and JWTs across the Internet?

The answer is:

🔒 HTTPS

HTTPS protects communication between clients and servers using:

HTTP

+

TLS

Without HTTPS:

Passwords can be intercepted.
JWTs can be stolen.
Sensitive data can be modified.
🎯 Learning Objectives

After completing this chapter you will understand:

🌐 What HTTPS is
🔒 What TLS is
🤝 TLS Handshake
🔑 Symmetric vs Asymmetric Encryption
📜 Digital Certificates
🏛 Certificate Authorities (CA)
🍃 HTTPS in Spring Boot
🐳 Docker HTTPS
☸️ Kubernetes TLS
❓ What is HTTPS?

HTTPS stands for:

HyperText Transfer Protocol Secure

It is simply:

HTTP

+

TLS

HTTP defines how browsers and servers communicate.

TLS protects that communication.

Why HTTP Is Insecure

Suppose a login request is sent over HTTP:

POST /login

username=nishanth
password=secret123

Anyone able to observe the network traffic can read it.

Browser
      │
HTTP
      │
Internet
      │
Attacker
      │
Reads Password
HTTPS

With HTTPS:

Browser
      │
Encrypted TLS Tunnel
      │
Server

An attacker may capture packets, but cannot read the encrypted application data without the appropriate cryptographic keys.

What is TLS?

TLS stands for:

Transport Layer Security

TLS provides:

Confidentiality
Integrity
Server Authentication

TLS is the modern successor to SSL.

TLS Handshake

Before encrypted communication begins, the browser and server perform a handshake.

Browser
     │
ClientHello
     │
──────────────►
     │
     │
◄──────────────
ServerHello
Certificate
     │
Key Exchange
     │
Secure Session

Only after the handshake is complete do they exchange encrypted HTTP messages.

TLS Handshake Steps
Step 1 — ClientHello

Browser sends:

Supported TLS versions
Supported cipher suites
Random value
Browser

↓

ClientHello
Step 2 — ServerHello

Server responds with:

Selected TLS version
Selected cipher suite
Random value
Server

↓

ServerHello
Step 3 — Certificate

Server sends its certificate.

Example:

Certificate

↓

example.com

The certificate contains:

Domain name
Public key
Issuer
Validity period
Digital signature
Step 4 — Certificate Validation

The browser checks:

Is the certificate trusted?
Is it expired?
Does the hostname match?
Was it issued by a trusted Certificate Authority?

If validation fails:

Browser Warning

↓

Connection Not Secure
Step 5 — Session Key Establishment

The browser and server establish shared cryptographic secrets (using modern key exchange mechanisms such as ECDHE in current TLS versions).

These secrets are then used to derive symmetric encryption keys for the session.

Step 6 — Encrypted Communication

Now every HTTP request is encrypted.

Browser

↓

HTTPS

↓

Spring Boot
Symmetric vs Asymmetric Encryption
Symmetric Encryption

Same key:

Encrypt

↓

Secret Key

↓

Decrypt

Examples:

AES
ChaCha20

Advantages:

Very fast
Used for bulk data transfer
Asymmetric Encryption

Two keys:

Public Key

↓

Encrypt / Verify

Private Key

↓

Decrypt / Sign

Examples:

RSA
Elliptic Curve Cryptography (ECC)

Advantages:

Secure key exchange
Digital signatures

Slower than symmetric encryption, so it's mainly used during the handshake and for authentication.

Why TLS Uses Both

TLS combines both approaches.

Handshake

↓

Asymmetric Cryptography

↓

Shared Session Keys

↓

Symmetric Encryption

↓

HTTP Data

This provides both security and high performance.

Digital Certificates

A certificate proves:

This Server

↓

Owns

↓

example.com

It includes:

Public key
Domain name
Expiration date
Issuer
Digital signature
Certificate Authority (CA)

Browsers trust well-known Certificate Authorities.

Examples include:

DigiCert
GlobalSign
Let's Encrypt

A CA verifies ownership of a domain before issuing a certificate.

Student Results API Example

Browser:

GET /students/1051110001

Flow:

Browser
      │
HTTPS
      │
Spring Boot
      │
JWT
      │
Controller
      │
Database

The JWT travels inside the encrypted TLS session.

HTTPS in Spring Boot

Spring Boot can terminate TLS directly.

Example configuration:

server.port=8443
server.ssl.enabled=true
server.ssl.key-store=classpath:keystore.p12
server.ssl.key-store-password=changeit

In production, TLS is often terminated before the application by a reverse proxy or load balancer.

HTTPS with Docker

Docker itself does not provide HTTPS.

Typical deployment:

Browser
      │
HTTPS
      │
Nginx
      │
HTTP
      │
Spring Boot Container

Or HTTPS can terminate inside the application container.

HTTPS in Kubernetes

Typical architecture:

Browser
      │
HTTPS
      │
Ingress Controller
      │
HTTP
      │
Service
      │
Pod

The Ingress Controller often manages TLS certificates and decrypts incoming HTTPS traffic before forwarding requests internally.

Some environments also use TLS passthrough or mTLS between services.

End-to-End Flow
Browser
      │
TLS Handshake
      │
HTTPS
      │
Ingress
      │
Service
      │
Spring Boot
      │
JWT Validation
      │
Controller
      │
PostgreSQL
Hands-on Lab
Verify HTTPS
curl -v https://localhost:8443

Observe:

TLS version
Certificate
Cipher suite
Inspect Certificate
openssl s_client -connect localhost:8443

Observe:

Certificate chain
Issuer
Validity period
Public key information
Verify Headers
curl -I https://localhost:8443

Look for security headers such as:

Strict-Transport-Security
X-Content-Type-Options
X-Frame-Options
Capture Traffic
sudo tcpdump port 443

Open the capture in Wireshark.

Notice that you can identify the TLS handshake but not the encrypted HTTP payload.

Common Mistakes
❌ Using HTTP in Production

Always use HTTPS for production applications.

Never transmit:

Passwords
JWTs
Session cookies
Personal information

over plain HTTP.

❌ Ignoring Certificate Expiration

Expired certificates cause browsers and clients to reject secure connections.

Monitor certificate expiration and renew certificates before they expire.

❌ Believing HTTPS Encrypts Stored Data

HTTPS protects data in transit.

It does not automatically encrypt:

Database contents
Log files
Disk storage

Those require separate protections.

❌ Disabling Certificate Validation

Never disable certificate validation in production.

Doing so removes protection against man-in-the-middle attacks.

HTTPS Workflow
Browser
    │
    ▼
TLS Handshake
    │
    ▼
Certificate Validation
    │
    ▼
Shared Session Keys
    │
    ▼
Encrypted HTTPS
    │
    ▼
Spring Boot
    │
    ▼
JWT Authentication
    │
    ▼
Authorization
    │
    ▼
Controller
HTTP vs HTTPS
HTTP	HTTPS
Plain text	Encrypted
No identity verification	Server identity verified by certificate
Vulnerable to interception	Protected by TLS
Port 80	Port 443
Not suitable for sensitive data	Suitable for production traffic
💡 Key Takeaways

✅ HTTPS is HTTP running over TLS.

✅ TLS provides confidentiality, integrity, and server authentication.

✅ A TLS handshake establishes a secure session before application data is exchanged.

✅ TLS uses asymmetric cryptography for authentication and key exchange, then symmetric encryption for efficient data transfer.

✅ Modern Spring Boot applications commonly use HTTPS through an Ingress Controller, reverse proxy, load balancer, or directly within the application.

➡️ Next Chapter

📘 13-Security/06-OWASP-Top10.md

In the next chapter, you'll learn about the OWASP Top 10, the industry's most widely recognized list of common web application security risks.

Topics include:

🛡 Broken Access Control
🔐 Cryptographic Failures
💉 Injection attacks
🎭 Cross-Site Scripting (XSS)
⚙️ Security Misconfiguration
📦 Vulnerable dependencies
🚀 Secure coding practices in Spring Boot

By the end of that chapter, you'll understand the most common security vulnerabilities affecting modern web applications and how to prevent them.
