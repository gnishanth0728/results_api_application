📘 Chapter 116 — Spring Security Architecture

📂 File: student-results-api-notes/13-Security/07-SpringSecurity.md

This chapter is one of the most important chapters in the entire roadmap because it combines everything you've learned so far:

HTTP
Tomcat
Spring Boot
Filters
Authentication
Authorization
JWT
HTTPS

Up to now you've learned each concept separately.

Now another important question appears:

What actually happens inside Spring Boot when a request reaches a secured endpoint?

Suppose a browser sends:

GET /students/1051110001

Authorization:
Bearer eyJhbGciOiJIUzI1Ni...

Does the request go directly to the controller?

Browser

↓

Controller

No.

It first travels through Spring Security's Filter Chain, where every security check occurs.

This chapter explains the complete internal execution flow.


📘 Chapter 116 — Spring Security Architecture

📂 File: student-results-api-notes/13-Security/07-SpringSecurity.md

🌍 Introduction

In previous chapters we learned:

Authentication
Authorization
JWT
HTTPS

Now another important question appears:

🤔 Where does Spring Security fit into the request flow?

Consider this request:

GET /students/1051110001

The request does not go directly to:

Controller

Instead it passes through multiple security filters before your application code executes.

🎯 Learning Objectives

After completing this chapter you will understand:

🛡 What Spring Security is
🔗 Security Filter Chain
🎟 JWT Authentication Filter
👤 Authentication Process
🔑 Authorization Process
🧵 SecurityContext
🍃 Spring Boot Integration
☸️ Spring Security in Kubernetes
❓ What is Spring Security?

Spring Security is the security framework for the Spring ecosystem.

It provides:

Authentication
Authorization
Password hashing
JWT support
Session management
CSRF protection
Security headers
OAuth2/OpenID

❓ What is Spring Security?

Spring Security is a framework that secures Spring applications.

Instead of writing security code yourself, Spring Security provides reusable components.

It protects:

REST APIs
Web applications
Microservices
Request Flow Without Security
Browser
      │
HTTP Request
      │
Controller
      │
Service
      │
Repository
      │
Database

Every request reaches the controller.

Request Flow With Spring Security
Browser
      │
HTTP Request
      │
Spring Security
      │
Controller
      │
Service
      │
Repository

Every request passes through Spring Security first.

High-Level Architecture
HTTP Request
      │
      ▼
Security Filter Chain
      │
      ▼
Authentication Filter
      │
      ▼
AuthenticationManager
      │
      ▼
UserDetailsService
      │
      ▼
PasswordEncoder
      │
      ▼
SecurityContext
      │
      ▼
Authorization
      │
      ▼
Controller
Security Filter Chain

The Security Filter Chain is the heart of Spring Security.

Every incoming request passes through a series of filters.

Example:

HTTP Request

↓

Filter 1

↓

Filter 2

↓

Filter 3

↓

Controller

Each filter performs one responsibility.

Typical Filters

Examples include:

SecurityContext Filter

↓

JWT Authentication Filter

↓

Authorization Filter

↓

Exception Translation Filter

The exact filters depend on your Spring Security configuration.

JWT Authentication Filter

Suppose the request contains:

Authorization:

Bearer eyJhb...

JWT filter:

Extract Token

↓

Validate Signature

↓

Validate Expiration

↓

Authenticate User

If validation succeeds, the authenticated user is stored in the SecurityContext.

AuthenticationManager

The AuthenticationManager coordinates authentication.

Username

↓

Password

↓

AuthenticationManager

It delegates authentication to one or more configured authentication providers.

UserDetailsService

Spring Security loads users through:

UserDetailsService

Flow:

Username

↓

Database

↓

UserDetails

It returns:

Username
Password hash
Roles
Authorities
Account status
PasswordEncoder

Spring Security compares passwords using:

PasswordEncoder

Common implementation:

BCryptPasswordEncoder

Verification:

Password

↓

Hash

↓

Match?

Passwords are never compared in plain text.

SecurityContext

After successful authentication:

SecurityContext

↓

Authenticated User

↓

Roles

↓

Authorities

Controllers and services can access the current user through the SecurityContext.

Authorization

After authentication:

User

↓

Role Check

↓

Permission Check

↓

Controller

Failure:

403 Forbidden
Complete Request Flow
Browser
      │
      ▼
HTTPS
      │
      ▼
Security Filter Chain
      │
      ▼
JWT Filter
      │
      ▼
AuthenticationManager
      │
      ▼
UserDetailsService
      │
      ▼
SecurityContext
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
Spring Boot Configuration

Typical configuration:

@Bean
SecurityFilterChain securityFilterChain(HttpSecurity http)
        throws Exception {

    http
        .csrf(csrf -> csrf.disable())
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/login").permitAll()
            .requestMatchers("/admin/**").hasRole("ADMIN")
            .anyRequest().authenticated()
        );

    return http.build();
}

This example:

Allows anyone to access /login
Restricts /admin/** to administrators
Requires authentication for all other requests
Method Security

Example:

@PreAuthorize("hasRole('ADMIN')")
public void deleteStudent(...)

Spring Security checks authorization before the method executes.

Student Results API Example

Request:

GET /students/1051110001

Authorization:
Bearer eyJhb...

Execution:

JWT Filter

↓

SecurityContext

↓

ROLE_STUDENT

↓

Authorization

↓

Controller

↓

Database
Exception Handling

Authentication failure:

401 Unauthorized

Authorization failure:

403 Forbidden

Spring Security provides handlers to return appropriate HTTP responses.

Spring Security Components
Component	Responsibility
Security Filter Chain	Intercepts every request
AuthenticationManager	Coordinates authentication
AuthenticationProvider	Verifies credentials
UserDetailsService	Loads user information
PasswordEncoder	Verifies password hashes
SecurityContext	Stores authenticated user
Authorization Manager / Rules	Evaluates access permissions
Docker

Spring Security works exactly the same inside Docker.

Browser

↓

Container

↓

Spring Security

Containerization does not change the authentication or authorization process.

Kubernetes

Typical production deployment:

Browser
      │
HTTPS
      │
Ingress
      │
Service
      │
Pod
      │
Spring Security

The Ingress routes traffic.

Spring Security authenticates and authorizes the request inside the application.

Hands-on Lab
Configure Security

Create:

SecurityFilterChain
Create User

Implement:

UserDetailsService

Load users from your database.

Password Hash

Generate a BCrypt hash:

passwordEncoder.encode("password123");
Secure Endpoint
@PreAuthorize("hasRole('ADMIN')")

Verify:

Admin → Success
Student → 403 Forbidden
JWT Request
Authorization:
Bearer <token>

Verify that the JWT filter authenticates the request before the controller executes.

Common Mistakes
❌ Thinking the Controller Performs Authentication

Authentication occurs in the Security Filter Chain, before the controller is called.

❌ Storing Plain Passwords

Always use a secure password hashing algorithm such as BCrypt, Argon2, or scrypt.

❌ Disabling CSRF Without Understanding It

For stateless REST APIs that use JWTs instead of browser sessions, disabling CSRF protection is common.

For browser applications that use cookies and sessions, CSRF protection should generally remain enabled unless you have a well-understood alternative.

❌ Putting Business Authorization Logic Only in Controllers

Protect sensitive operations using centralized security configuration and/or method security annotations such as @PreAuthorize.

Security Request Lifecycle
Browser
    │
    ▼
HTTPS
    │
    ▼
Security Filter Chain
    │
    ▼
JWT Authentication
    │
    ▼
AuthenticationManager
    │
    ▼
SecurityContext
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
Database
Spring Security Best Practices
Use HTTPS for all authenticated traffic.
Hash passwords using BCrypt, Argon2, or scrypt.
Prefer JWT for stateless REST APIs.
Apply least-privilege authorization.
Keep Spring Security dependencies up to date.
Return 401 for authentication failures and 403 for authorization failures.
Log security-relevant events without logging sensitive secrets or passwords.
💡 Key Takeaways

✅ Spring Security is the standard framework for securing Spring Boot applications.

✅ Every request passes through the Security Filter Chain before reaching the controller.

✅ Authentication loads the user into the SecurityContext; authorization then determines whether access is allowed.

✅ Components such as SecurityFilterChain, AuthenticationManager, UserDetailsService, and PasswordEncoder work together to implement authentication.

✅ Spring Security integrates naturally with JWT, HTTPS, Docker, Kubernetes, and modern microservice architectures.

➡️ Next Chapter

📘 14-SystemDesign/01-System-Design-Fundamentals.md

The next section moves beyond securing a single application and focuses on designing systems that scale.

Topics include:

🏗 Functional vs non-functional requirements
📈 Scalability
⚖️ Availability
🔄 Reliability
🌍 Horizontal vs vertical scaling
🚀 Designing distributed systems

By the end of that section, you'll understand how to architect production-ready systems capable of serving millions of users while remaining secure, scalable, and highly available.
