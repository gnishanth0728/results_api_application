📘 Chapter 121 — Message Queue

📂 File: student-results-api-notes/14-SystemDesign/05-MessageQueue.md

This chapter is one of the biggest mindset shifts in System Design because it introduces asynchronous processing.

Until now, every request followed this pattern:

Browser

↓

Spring Boot

↓

Database

↓

Response

The user waits until everything finishes.

Now suppose your Student Results API has a new feature:

Email the student after marks are updated.

Teacher updates marks:

Update Marks

↓

Send Email

↓

Generate PDF

↓

Send SMS

↓

Update Analytics

↓

Response

The user now waits:

8 Seconds

Even though updating the database only took:

100 ms

Another important question appears:

Why should the user wait for background work?

Instead:

Update Marks

↓

Database

↓

Message Queue

↓

Return Response

↓

Background Processing

This is the idea behind Message Queues.

Large companies such as Amazon, Netflix, Uber, LinkedIn, and many others use message queues extensively to build scalable, resilient systems.

🌍 Introduction

In the previous chapter we learned how caching reduces database load.

Another important question appears:

🤔 How do we perform slow background work without making users wait?

The answer is:

📨 Message Queue

A Message Queue allows applications to send work to be processed asynchronously.

🎯 Learning Objectives

After completing this chapter you will understand:

📨 What a Message Queue is
⚡ Synchronous vs Asynchronous Processing
📤 Producer
📥 Consumer
📬 Queue
🔄 Event-Driven Architecture
☕ Kafka vs RabbitMQ
☸️ Message Queues in Kubernetes
🍃 Student Results API Example
❓ What is a Message Queue?

A Message Queue is an intermediary that stores messages until another component processes them.

Instead of:

Application

↓

Application

we have:

Application

↓

Queue

↓

Application

The sender and receiver no longer need to run at the same speed.

Synchronous Processing

Current API:

Browser
      │
      ▼
Spring Boot
      │
      ▼
Database
      │
      ▼
Email
      │
      ▼
PDF
      │
      ▼
Response

The browser waits for every step to complete.

Asynchronous Processing

Instead:

Browser
      │
      ▼
Spring Boot
      │
      ▼
Database
      │
      ▼
Queue
      │
      ▼
Response

Later:

Queue

↓

Email Service

↓

PDF Service

↓

Analytics

The user receives a fast response while background work continues independently.

Student Results API Example

Teacher updates marks.

Without queue:

Update Marks

↓

Database

↓

Email

↓

SMS

↓

Analytics

↓

Response

Response time:

6 Seconds

With queue:

Update Marks

↓

Database

↓

Queue

↓

Response

Response time:

120 ms

Background workers process:

Email
SMS
Analytics
Producer

The component that sends a message.

Spring Boot

↓

Producer

↓

Queue

Example message:

{
  "event":"MARKS_UPDATED",
  "rollNumber":"1051110001"
}
Queue

The queue temporarily stores messages.

Producer

↓

Queue

↓

Consumer

If consumers are busy, messages wait safely in the queue.

Consumer

The component that processes messages.

Queue

↓

Consumer

↓

Send Email

Multiple consumers can process messages concurrently.

Message Flow
Teacher
      │
      ▼
Spring Boot
      │
      ▼
Queue
      │
 ┌────┼────┐
 ▼    ▼    ▼
Email PDF Analytics

Each service performs one responsibility.

Why Use Message Queues?

Advantages:

Faster user response
Loose coupling
Independent scaling
Better resilience
Retry support
Event-driven architecture
Event-Driven Architecture

Instead of directly calling another service:

Student Service

↓

Email Service

Publish an event:

Student Service

↓

MARKS_UPDATED

↓

Queue

↓

Email Service

Any interested service can subscribe.

Kafka

Apache Kafka is a distributed event streaming platform.

Common use cases:

Event streaming
Log aggregation
Analytics pipelines
High-throughput messaging

Characteristics:

Very high throughput
Persistent event log
Consumer groups
Replay capability
RabbitMQ

RabbitMQ is a traditional message broker.

Common use cases:

Background jobs
Task queues
Request distribution
Reliable message delivery

Characteristics:

Rich routing options
Simple work queues
Mature AMQP implementation
Kafka vs RabbitMQ
Kafka	RabbitMQ
Distributed event streaming	Message broker
Very high throughput	Excellent for task queues
Messages retained for a configurable period	Messages typically removed after acknowledgment
Supports replay	Focused on delivery and acknowledgment
Often used for event-driven systems	Often used for background jobs

Both are widely used; the right choice depends on your requirements.

Multiple Consumers

Suppose:

100,000 Messages

One consumer:

Slow

Add more consumers:

Queue
      │
 ┌────┼────┐
 ▼    ▼    ▼
C1   C2   C3

The workload is shared.

Retry

Sometimes processing fails.

Queue

↓

Consumer

↓

Failure

Instead of losing the message:

Retry

Many messaging systems support configurable retry strategies.

Dead Letter Queue (DLQ)

If a message keeps failing:

Retry

↓

Retry

↓

Retry

↓

Dead Letter Queue

The failed message is isolated for investigation instead of blocking normal processing.

Kubernetes

Typical deployment:

Browser
      │
      ▼
Ingress
      │
      ▼
Student Service
      │
      ▼
Kafka
      │
 ┌────┼────┐
 ▼    ▼    ▼
Email Analytics PDF

Each consumer can scale independently using Deployments.

Spring Boot Example

Publish:

kafkaTemplate.send(
    "marks-updated",
    event
);

Consume:

@KafkaListener(topics = "marks-updated")
public void process(Event event) {
    ...
}

RabbitMQ has similar concepts using exchanges, queues, and listeners.

Complete Request Flow
Teacher
      │
      ▼
HTTP Request
      │
      ▼
Spring Boot
      │
      ▼
PostgreSQL
      │
      ▼
Message Queue
      │
      ▼
200 OK
      │
      ▼
Background Consumers
      │
 ┌────┼────┐
 ▼    ▼    ▼
Email PDF Analytics

The user receives the response before background processing completes.

Hands-on Lab
Run Kafka (Docker Compose)

Start Kafka and its required services (such as a KRaft-based broker or ZooKeeper-based setup, depending on the version you choose).

Publish Message
kafkaTemplate.send(
    "student-events",
    event
);
Consume Message
@KafkaListener(
    topics="student-events"
)

Verify that the consumer receives the event.

Simulate Failure

Throw an exception in the consumer.

Observe:

Retry behavior
Dead-letter handling (if configured)
Common Mistakes
❌ Using a Queue for Everything

Not every operation should be asynchronous.

If the client needs an immediate result (for example, login or payment authorization), synchronous processing is usually more appropriate.

❌ Assuming Messages Are Always Processed Exactly Once

Many messaging systems provide at-least-once delivery by default.

Consumers should be idempotent, meaning they can safely process the same message more than once without producing incorrect results.

❌ Ignoring Failed Messages

Always define a strategy for:

Retries
Dead Letter Queues
Monitoring
Alerting
❌ Sending Large Payloads

Instead of sending an entire document or image, send a lightweight reference (such as an ID or URL) when appropriate.

This reduces network overhead and improves throughput.

Message Queue Workflow
Producer
    │
    ▼
Queue
    │
    ▼
Consumer
    │
 ┌──┼──┐
 ▼  ▼  ▼
Email PDF Analytics
Synchronous vs Asynchronous
Synchronous	Asynchronous
Caller waits for completion	Caller continues immediately
Simple request-response	Background processing
Higher user latency	Faster user response
Tight coupling	Loose coupling
Good for immediate results	Good for long-running work
💡 Key Takeaways

✅ A Message Queue enables asynchronous communication between services.

✅ Producers publish messages, queues store them, and consumers process them independently.

✅ Asynchronous processing reduces user-facing latency and improves scalability.

✅ Kafka is commonly used for high-throughput event streaming, while RabbitMQ is commonly used for reliable task distribution and messaging.

✅ Retries, dead-letter queues, monitoring, and idempotent consumers are essential for building reliable message-driven systems.

➡️ Next Chapter

📘 14-SystemDesign/06-Microservices.md

In the next chapter, you'll learn how large applications are divided into independently deployable services.

Topics include:

🧩 Monolith vs Microservices
📦 Service decomposition
🌐 Inter-service communication
📡 API Gateway
🔄 Service discovery
☸️ Running microservices on Kubernetes

By the end of that chapter, you'll understand how a single Spring Boot application evolves into a distributed microservice architecture.
