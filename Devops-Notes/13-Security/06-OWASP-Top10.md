📘 Chapter 115 — OWASP Top 10

📂 File: student-results-api-notes/13-Security/06-OWASP-Top10.md

🌍 Introduction

In previous chapters we learned:

Authentication
Authorization
JWT
HTTPS

But another important question appears:

🤔 What are the most common ways web applications are compromised?

The answer is provided by:

🛡 OWASP Top 10

OWASP (Open Worldwide Application Security Project) publishes a regularly updated list of the most critical web application security risks.

Understanding these vulnerabilities helps developers build more secure applications.

🎯 Learning Objectives

After completing this chapter you will understand:

🛡 What OWASP is
🔓 Broken Access Control
🔐 Cryptographic Failures
💉 Injection
⚙️ Security Misconfiguration
📦 Vulnerable Components
🔍 Security Logging & Monitoring
🍃 Spring Boot Examples
☸️ Docker & Kubernetes Security Considerations
❓ What is OWASP?

OWASP is a nonprofit organization focused on improving software security.

One of its best-known resources is:

OWASP Top 10

It identifies the most significant categories of web application security risks based on industry data and expert analysis.

OWASP Top 10 (2021)
Risk	Description
A01	Broken Access Control
A02	Cryptographic Failures
A03	Injection
A04	Insecure Design
A05	Security Misconfiguration
A06	Vulnerable and Outdated Components
A07	Identification and Authentication Failures
A08	Software and Data Integrity Failures
A09	Security Logging and Monitoring Failures
A10	Server-Side Request Forgery (SSRF)
A01 — Broken Access Control

The most common and highest-ranked risk.

Example:

Student API:

PUT /students/1051110001

Any authenticated student can update marks.

Student

↓

Update Marks

↓

Allowed

This is incorrect.

Only teachers or administrators should be allowed.

Prevention
Enforce authorization on every protected endpoint.
Use role- or permission-based access control.
Never rely only on frontend restrictions.
A02 — Cryptographic Failures

Sensitive information is not adequately protected.

Bad:

HTTP

↓

Password

↓

Internet

Good:

HTTPS

↓

TLS Encryption

Other examples:

Weak password hashing
Storing secrets in plain text
Weak encryption algorithms
Prevention
Use HTTPS everywhere.
Hash passwords with BCrypt, Argon2, or scrypt.
Protect secrets appropriately.
A03 — Injection

One of the oldest web application attacks.

Bad example:

SELECT *
FROM users
WHERE username = '"
+ username + "'";

Attacker input:

' OR 1=1 --

Generated query:

SELECT *
FROM users
WHERE username = ''
OR 1=1;

Now every row may be returned.

Prevention
Prepared statements
Parameterized queries
ORM frameworks such as Hibernate (when used correctly)
Input validation
A04 — Insecure Design

The application architecture itself contains security weaknesses.

Example:

Password Reset

↓

Anyone Can Reset

↓

No Verification

Even perfectly written code cannot compensate for an insecure design.

Prevention
Perform threat modeling.
Apply secure design principles.
Review security during architecture discussions.
A05 — Security Misconfiguration

Examples:

Default passwords
Debug mode enabled in production
Open administrative endpoints
Unnecessary services exposed

Example:

Spring Boot

↓

/actuator

↓

Public Internet
Prevention
Disable unnecessary features.
Harden production configurations.
Regularly review exposed endpoints.
A06 — Vulnerable and Outdated Components

Applications often depend on third-party libraries.

Example:

Spring Boot

↓

Old Log4j Version

Known vulnerabilities may already exist.

Prevention
Update dependencies regularly.
Scan dependencies for known CVEs.
Remove unused libraries.
A07 — Identification and Authentication Failures

Examples:

Weak passwords
No account lockout
Predictable session identifiers
Poor password reset process
Prevention
Strong password hashing
Multi-factor authentication (MFA) where appropriate
Secure session/token management
Rate limiting for login attempts
A08 — Software and Data Integrity Failures

Examples:

Executing untrusted code
Installing packages from untrusted sources
Insecure CI/CD pipelines
Prevention
Verify software integrity.
Sign releases where appropriate.
Protect CI/CD pipelines.
Validate container images.
A09 — Security Logging and Monitoring Failures

Suppose someone attempts:

10,000 Failed Logins

No logs.

No alerts.

No monitoring.

The attack may go unnoticed.

Prevention
Log authentication events.
Monitor suspicious activity.
Configure alerting for critical security events.
A10 — Server-Side Request Forgery (SSRF)

Example:

Application accepts a URL from the user:

User URL

↓

Backend Fetches URL

An attacker provides:

http://169.254.169.254/

or an internal service URL.

The server may unintentionally access internal resources.

Prevention
Validate outbound destinations.
Use allow-lists where possible.
Restrict outbound network access.
Student Results API Examples
Vulnerability	Example
Broken Access Control	Student updates marks
Injection	SQL Injection in search endpoint
Authentication Failure	Weak passwords
Misconfiguration	Exposed Actuator endpoints
Vulnerable Components	Outdated Spring Boot dependencies
Security Layers
Browser
      │
HTTPS
      │
Spring Security
      │
Input Validation
      │
Hibernate
      │
PostgreSQL
      │
Docker
      │
Kubernetes

Security must exist at every layer.

Spring Boot Best Practices
Use Spring Security.
Use parameterized database queries.
Validate all input.
Keep dependencies updated.
Disable unnecessary endpoints.
Enable security logging.
Protect secrets using secure configuration.
Docker & Kubernetes Considerations

Docker:

Use minimal base images.
Run as a non-root user.
Scan images for vulnerabilities.

Kubernetes:

Use RBAC.
Store secrets securely.
Apply Network Policies.
Keep cluster components updated.
Hands-on Lab
Dependency Check

Review your project's dependencies:

mvn dependency:tree

Identify outdated libraries.

Test SQL Injection

Endpoint:

GET /students?name=test

Attempt malicious input in a safe development environment.

Verify that parameterized queries prevent SQL injection.

Verify HTTPS
curl -v https://localhost:8443

Confirm TLS is enabled.

Verify Authorization

Log in as a student.

Attempt:

PUT /students/1051110001

Expected:

403 Forbidden
Common Mistakes
❌ Relying Only on Authentication

Authentication without authorization still leaves applications vulnerable.

❌ Trusting User Input

Every request parameter, JSON body, HTTP header, and uploaded file should be treated as untrusted input.

❌ Ignoring Dependency Updates

A secure application today can become vulnerable tomorrow if dependencies are not maintained.

❌ Exposing Development Features

Do not expose:

Debug endpoints
Test APIs
Default credentials
Internal dashboards

in production.

Secure Development Checklist
✓ HTTPS Enabled

✓ Authentication

✓ Authorization

✓ Input Validation

✓ Parameterized Queries

✓ Updated Dependencies

✓ Secure Configuration

✓ Logging & Monitoring

✓ Least Privilege

✓ Secrets Protected
Security Review Workflow
Requirements
      │
      ▼
Secure Design
      │
      ▼
Implementation
      │
      ▼
Code Review
      │
      ▼
Dependency Scan
      │
      ▼
Security Testing
      │
      ▼
Deployment
      │
      ▼
Monitoring

Security is a continuous lifecycle, not a one-time activity.

OWASP Top 10 Summary
Risk	Primary Defense
Broken Access Control	Authorization
Cryptographic Failures	TLS and strong cryptography
Injection	Parameterized queries
Insecure Design	Secure architecture
Security Misconfiguration	Hardened configuration
Vulnerable Components	Dependency management
Authentication Failures	Strong authentication
Integrity Failures	Trusted software supply chain
Logging Failures	Monitoring and alerting
SSRF	Outbound request validation
💡 Key Takeaways

✅ The OWASP Top 10 identifies the most significant categories of web application security risks.

✅ Security must be addressed through architecture, implementation, configuration, deployment, and monitoring.

✅ Common defenses include strong authentication, proper authorization, input validation, parameterized queries, HTTPS, secure configuration, and dependency management.

✅ Security is most effective when applied throughout the software development lifecycle rather than added after development.

➡️ Next Chapter

📘 13-Security/07-SpringSecurity.md

In the next chapter, you'll learn how all these security concepts come together in a real Spring Boot application using Spring Security.

Topics include:

🔐 Spring Security architecture
🧩 Security filter chain
👤 Authentication flow
🔑 JWT authentication filter
🛡 Authorization rules
⚙️ Security configuration
☸️ Spring Security in Docker and Kubernetes

By the end of that chapter, you'll understand the complete request flow from an incoming HTTP request through the Spring Security filter chain to your controller.
