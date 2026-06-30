📘 Chapter 112 — Authorization

📂 File: student-results-api-notes/13-Security/03-Authorization.md

🌍 Introduction

In the previous chapter we learned Authentication.

Authentication answers:

Who are you?

Now we learn:

🔑 Authorization

Authorization answers:

What are you allowed to do?

Every secure application must verify permissions before allowing access to protected resources.

🎯 Learning Objectives

After completing this chapter you will understand:

🔑 What Authorization is
👥 Roles
🛡 Permissions
🎯 Role-Based Access Control (RBAC)
🍃 Spring Security Authorization
🏷 Authorities
🔒 Method Security
🌐 URL Security
☸️ Kubernetes RBAC
Authentication vs Authorization

Authentication:

Who are you?

Authorization:

What can you do?

Workflow:

User

↓

Authentication

↓

Authorization

↓

Controller

Authorization never happens before authentication.

Student Results API Example

Suppose your application has three users.

Student

Teacher

Administrator

Permissions:

Student

↓

View Own Marks
Teacher

↓

Update Marks
Administrator

↓

Manage Users

Every user logs in successfully.

Only their permissions differ.

What is Authorization?

Authorization determines whether an authenticated user may perform an action.

Example:

Authenticated User

↓

Permission Check

↓

Allowed?

If allowed:

Controller

Otherwise:

403 Forbidden
Roles

A role groups related permissions.

Example:

ROLE_STUDENT

ROLE_TEACHER

ROLE_ADMIN

Instead of assigning dozens of permissions directly to every user, users receive one or more roles.

Permissions

Permissions represent specific actions.

Example:

READ_MARKS

UPDATE_MARKS

DELETE_MARKS

CREATE_USER

A role is simply a collection of permissions.

Example:

ROLE_TEACHER

↓

READ_MARKS

UPDATE_MARKS
Role-Based Access Control (RBAC)

RBAC is the most common authorization model.

User

↓

Role

↓

Permissions

↓

Resource

Example:

Nishanth

↓

ROLE_TEACHER

↓

UPDATE_MARKS

↓

Allowed
Authorization Flow
Browser
      │
      ▼
Authentication
      │
      ▼
SecurityContext
      │
      ▼
Authorization Check
      │
      ▼
Controller

If authorization fails, the controller is never executed.

Spring Security Roles

Example:

ROLE_STUDENT

ROLE_TEACHER

ROLE_ADMIN

Spring Security conventionally prefixes roles with:

ROLE_
URL-Based Authorization

Protect endpoints.

Example:

/students/**

↓

Authenticated Users
/admin/**

↓

ROLE_ADMIN

Example configuration:

http.authorizeHttpRequests(auth -> auth
    .requestMatchers("/students/**").authenticated()
    .requestMatchers("/admin/**").hasRole("ADMIN")
    .anyRequest().denyAll()
);
Method-Level Authorization

Sometimes URL rules aren't enough.

Spring Security provides annotations.

Example:

@PreAuthorize("hasRole('TEACHER')")
public void updateMarks(...)

Only teachers may invoke this method.

Checking Multiple Roles

Example:

@PreAuthorize(
    "hasAnyRole('ADMIN','TEACHER')"
)

Either role is accepted.

Permissions Instead of Roles

Larger applications often authorize by permission.

Example:

@PreAuthorize(
    "hasAuthority('UPDATE_MARKS')"
)

This provides more granular control than roles alone.

Student Results API Example

Endpoint:

PUT /students/1051110001

Flow:

Teacher

↓

Authenticated

↓

ROLE_TEACHER

↓

UPDATE_MARKS

↓

Controller

↓

Database

Student:

ROLE_STUDENT

↓

UPDATE_MARKS?

↓

No

↓

403 Forbidden
HTTP Status Codes

Authentication failure:

401 Unauthorized

Meaning:

The client has not successfully authenticated.

Authorization failure:

403 Forbidden

Meaning:

The user is authenticated but lacks permission.

SecurityContext

After authentication:

SecurityContext

↓

Current User

↓

Roles

↓

Authorities

Authorization decisions use the information stored in the SecurityContext.

JWT and Authorization

JWT may contain claims such as:

{
  "sub":"nishanth",
  "roles":[
      "ROLE_TEACHER"
  ]
}

Spring Security validates the token and uses these claims during authorization.

Microservices Authorization

Architecture:

API Gateway
      │
      ▼
Student Service
      │
      ▼
Marks Service

Each service should verify that the authenticated caller has permission to perform the requested action, even when requests originate from another trusted service.

Kubernetes RBAC

Kubernetes also uses RBAC.

Example:

Developer

↓

Read Pods

Administrator:

Administrator

↓

Delete Pods

The concept is similar to Spring Security RBAC, but it applies to Kubernetes resources.

Authorization Matrix
Role	View Marks	Update Marks	Delete Marks	Manage Users
Student	✅ Own records	❌	❌	❌
Teacher	✅	✅	❌	❌
Admin	✅	✅	✅	✅
Hands-on Lab
Configure Roles

Create users with:

ROLE_STUDENT

ROLE_TEACHER

ROLE_ADMIN
Secure Endpoint

Example:

@PreAuthorize("hasRole('ADMIN')")

Only administrators can access the method.

Test Access

Login as:

Student

Try:

PUT /students/1051110001

Expected:

403 Forbidden

Login as:

Teacher

Expected:

200 OK
JWT

Decode a JWT.

Verify:

roles

or

authorities

claims are present and match expected permissions.

Common Mistakes
❌ Confusing Authentication with Authorization

Authentication identifies the user.

Authorization determines what that user may do.

❌ Giving Every User Admin Access

Always follow the Principle of Least Privilege.

Grant only the permissions required.

❌ Protecting Only the UI

Never rely on frontend restrictions.

Authorization must always be enforced on the server.

❌ Returning the Wrong Status Code

Use:

401 Unauthorized → Authentication required or failed.
403 Forbidden → Authentication succeeded, but permission is denied.
Authorization Workflow
User
    │
    ▼
Login
    │
    ▼
Authentication
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
Security Best Practices
Authenticate every protected request.
Authorize every sensitive operation.
Apply the Principle of Least Privilege.
Prefer role and permission checks on the server.
Audit authorization failures.
Keep authorization rules centralized and consistent.
Authentication vs Authorization Summary
Authentication	Authorization
Verifies identity	Verifies permissions
"Who are you?"	"What are you allowed to do?"
Produces an authenticated user	Decides whether access is granted
Failure → 401	Failure → 403
💡 Key Takeaways

✅ Authentication verifies identity, while authorization verifies permissions.

✅ Authorization always occurs after successful authentication.

✅ RBAC (Role-Based Access Control) is the most common authorization model.

✅ Spring Security supports both URL-level and method-level authorization using roles and authorities.

✅ A secure application must enforce authorization on the server for every protected resource.

➡️ Next Chapter

📘 13-Security/04-JWT.md

In the next chapter, you'll learn JSON Web Tokens (JWT) in depth.

Topics include:

🎟 What a JWT is
🧩 JWT structure (Header, Payload, Signature)
✍️ Token signing and verification
⏰ Expiration and refresh tokens
🔐 JWT authentication flow in Spring Boot
☸️ JWT in Docker, Kubernetes, and microservice architectures

By the end of that chapter, you'll understand exactly how a JWT is created, transmitted, validated, and used to secure stateless REST APIs.
