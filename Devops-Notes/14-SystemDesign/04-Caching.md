📘 Chapter 120 — Caching

📂 File: student-results-api-notes/14-SystemDesign/04-Caching.md

This chapter is one of the most important chapters in System Design because it explains why large systems can serve millions of requests without querying the database every time.

Suppose your Student Results API receives:

100,000 Requests/sec

Every request executes:

SELECT *
FROM students
WHERE roll_number = ?;

Even with indexes, eventually PostgreSQL becomes the bottleneck.

CPU:

95%

Connections:

500 Active

Latency:

2 Seconds

Now another important question appears:

Why query the database repeatedly if the same data is requested thousands of times?

Instead, store frequently accessed data in memory.

Browser
      │
      ▼
Spring Boot
      │
      ▼
Redis Cache
      │
      ▼
PostgreSQL

If the data already exists in Redis:

Database

↓

NOT CALLED

This is called Caching.

🌍 Introduction

In previous chapters we learned:

Scalability
Load Balancing

Now another important question appears:

🤔 How can we reduce database load and improve response time?

The answer is:

⚡ Caching

A cache stores frequently accessed data in fast memory so it can be reused instead of repeatedly fetching it from a slower data source.

🎯 Learning Objectives

After completing this chapter you will understand:

⚡ What Caching is
🧠 Cache Hit vs Cache Miss
🔴 Redis Architecture
⏱ TTL (Time-To-Live)
🔄 Cache Invalidation
📦 Cache-Aside Pattern
☸️ Redis in Kubernetes
🍃 Student Results API Example
❓ What is a Cache?

A cache is a temporary storage layer that keeps frequently used data close to the application.

Without cache:

Browser
      │
      ▼
Spring Boot
      │
      ▼
PostgreSQL

Every request reaches the database.

With Cache
Browser
      │
      ▼
Spring Boot
      │
      ▼
Redis
      │
      ▼
PostgreSQL

The application checks Redis first.

If the data is available:

Redis

↓

Response

The database is not queried.

Why Use a Cache?

Suppose:

Student Result

↓

Requested

10,000 Times

The student record changes only occasionally.

Reading it from the database every time wastes resources.

A cache avoids repeated database queries for frequently accessed data.

Cache Hit

Data already exists in Redis.

Request

↓

Redis

↓

Found

↓

Response

Database:

Not Used

Response time may be a few milliseconds.

Cache Miss

Data is not present in Redis.

Request

↓

Redis

↓

Not Found

↓

PostgreSQL

↓

Store In Redis

↓

Response

Future requests become cache hits.

Student Results API Example

Endpoint:

GET /students/1051110001

Flow:

Browser
      │
      ▼
Spring Boot
      │
      ▼
Redis
      │
Hit?

If yes:

Redis

↓

Response

Otherwise:

PostgreSQL

↓

Redis

↓

Response
Cache-Aside Pattern

This is the most common caching strategy.

Application
      │
      ▼
Check Cache
      │
 ┌────┴─────┐
 │          │
Hit       Miss
 │          │
 ▼          ▼
Return    Database
              │
              ▼
        Update Cache
              │
              ▼
           Return

The application manages the cache.

Redis

Redis is an in-memory data store commonly used for:

Caching
Session storage
Rate limiting
Queues
Counters

Because it stores data primarily in memory, it is much faster than disk-based databases for read-heavy workloads.

Performance Comparison

Approximate access times:

Storage	Typical Latency
CPU Cache	Nanoseconds
RAM (Redis)	Microseconds to low milliseconds
SSD Database	Milliseconds
Remote Database Query	Often several milliseconds or more

The exact numbers depend on hardware, workload, and network conditions.

Time-To-Live (TTL)

Cached data should not live forever.

Example:

Student Result

↓

TTL

10 Minutes

After expiration:

Removed

↓

Next Request

↓

Database

TTL helps ensure stale data is eventually refreshed.

Cache Invalidation

Suppose a teacher updates marks.

Database:

95

↓

98

Redis still contains:

95

The cache is now stale.

Possible solutions:

Remove the cache entry
Update the cache entry
Allow TTL to expire

Cache invalidation is one of the hardest parts of designing caching systems.

Read Flow
Request
     │
     ▼
Redis
     │
 ┌───┴────┐
 │        │
Hit      Miss
 │        │
 ▼        ▼
Return  PostgreSQL
            │
            ▼
      Update Cache
            │
            ▼
         Return
Write Flow

Student marks updated:

Teacher

↓

Spring Boot

↓

PostgreSQL

After a successful update:

Invalidate Cache

or

Update Cache

This prevents stale reads.

Redis in Kubernetes

Architecture:

Browser
      │
      ▼
Ingress
      │
      ▼
Spring Boot Pods
      │
      ▼
Redis
      │
      ▼
PostgreSQL

All application Pods share the same Redis instance or Redis cluster.

Cache Keys

Good cache keys are predictable and unique.

Example:

student:1051110001

or

student:1051110002

Consistent naming simplifies debugging and cache management.

What Should Be Cached?

Good candidates:

Frequently read data
Rarely changing data
Expensive database queries
Configuration values
Reference data

Avoid caching highly volatile data unless you have a clear invalidation strategy.

What Should Not Be Cached?

Examples:

Highly sensitive information without proper protection
Continuously changing values
One-time tokens
Very large objects with low reuse

Choose cached data based on access patterns and consistency requirements.

Cache Consistency

There is always a trade-off between:

Performance
Freshness
Complexity

Questions to ask:

Is slightly stale data acceptable?
How quickly must updates become visible?
Can the application tolerate eventual consistency?
Student Results API Evolution
Version 1
Browser

↓

Spring Boot

↓

PostgreSQL
Version 2
Browser

↓

Spring Boot

↓

Redis

↓

PostgreSQL
Version 3
Browser

↓

Load Balancer

↓

Spring Boot Pods

↓

Redis

↓

PostgreSQL

The database receives fewer read requests.

Spring Boot Cache Example

Enable caching:

@EnableCaching

Cache a method:

@Cacheable("students")
public Student getStudent(String rollNumber) {
    ...
}

Update the cache after a write:

@CachePut("students")

Or remove stale entries:

@CacheEvict("students")
Hands-on Lab
Start Redis
docker run -d \
--name redis \
-p 6379:6379 \
redis
Cache Student

Use:

@Cacheable("students")

Call:

GET /students/1051110001

First request:

Database

Second request:

Redis

Observe the response time difference.

View Keys
redis-cli

KEYS *

Expected:

student:1051110001
Set TTL
TTL student:1051110001

Observe the remaining lifetime of the cached key.

Common Mistakes
❌ Caching Everything

Caching unnecessary data wastes memory and increases invalidation complexity.

Cache only data with measurable performance benefits.

❌ Forgetting Cache Invalidation

Updating the database without updating or removing the cache can result in stale responses.

❌ Using Very Long TTLs

Excessively long expiration times increase the chance of serving outdated data.

Choose TTL values based on business requirements.

❌ Assuming Cache Is Always Faster

A cache adds network and serialization overhead.

For very small datasets or rarely accessed data, caching may provide little benefit.

Measure before and after introducing a cache.

Caching Workflow
Client
    │
    ▼
Spring Boot
    │
    ▼
Redis
    │
 ┌──┴──┐
 │     │
Hit   Miss
 │     │
 ▼     ▼
Return PostgreSQL
          │
          ▼
    Store in Redis
          │
          ▼
       Return
Common Cache Patterns
Pattern	Description	Common Use
Cache-Aside	Application loads and stores cache	Most Spring Boot applications
Read-Through	Cache fetches data automatically	Managed cache solutions
Write-Through	Every write updates cache and database	Strong consistency requirements
Write-Behind	Cache updates database asynchronously	High write throughput
💡 Key Takeaways

✅ A cache stores frequently accessed data in fast memory to reduce database load and improve response times.

✅ A cache hit serves data directly from the cache, while a cache miss retrieves data from the database and populates the cache.

✅ Redis is one of the most widely used in-memory caching systems for modern applications.

✅ TTL and cache invalidation strategies are essential for balancing performance with data freshness.

✅ The Cache-Aside pattern is the most common caching approach in Spring Boot applications using Redis.

➡️ Next Chapter

📘 14-SystemDesign/05-MessageQueue.md

In the next chapter, you'll learn how large systems process work asynchronously instead of making users wait.

Topics include:

📬 What a Message Queue is
⚡ Synchronous vs asynchronous communication
📨 Producers and consumers
🔄 Kafka and RabbitMQ fundamentals
☸️ Message queues in Spring Boot and Kubernetes
🌍 Event-driven architecture

By the end of that chapter, you'll understand how systems like Amazon, Uber, and Netflix decouple services and handle millions of background tasks reliably.
