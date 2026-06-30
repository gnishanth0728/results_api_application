📘 Chapter 123 — Distributed Transactions

📂 File: student-results-api-notes/14-SystemDesign/07-DistributedTransactions.md

This chapter is one of the most advanced topics in System Design.

It explains one of the biggest differences between a single application and microservices.

In a monolith:

Update Student

↓

Update Marks

↓

Update Payment

↓

COMMIT

Everything happens inside one database transaction.

If something fails:

ROLLBACK

Easy.

But now consider a microservice architecture.

Student Service

↓

Result Service

↓

Notification Service

↓

Payment Service

Each service has:

Its own database
Its own transaction
Its own deployment

Now another important question appears:

What happens if one service succeeds but another fails?

Example:

Result Service

↓

Marks Updated

✅ Success

Then:

Notification Service

↓

Email Failed

❌ Failure

Should the marks be rolled back?

How?

There is no single transaction spanning multiple databases.

This problem is called a Distributed Transaction.

Large companies solve this using patterns such as the Saga Pattern.

🌍 Introduction

In the previous chapter we learned how applications are split into microservices.

Another important question appears:

🤔 How do multiple microservices complete one business operation while keeping data consistent?

In a monolith, one database transaction solves this problem.

In a distributed system, there is no shared database transaction.

Distributed transaction patterns coordinate multiple local transactions.

🎯 Learning Objectives

After completing this chapter you will understand:

🔄 What Distributed Transactions are
⚖️ Why ACID Transactions Don't Scale Across Services
🎭 Saga Pattern
↩️ Compensating Transactions
🎼 Orchestration vs Choreography
📨 Event-Driven Transactions
☸️ Kafka-Based Saga
🍃 Student Results API Example
Monolith Transaction

Everything uses one database.

Spring Boot
      │
      ▼
PostgreSQL
      │
      ▼
BEGIN
      │
Update Student
      │
Update Marks
      │
Update Report
      │
COMMIT

If anything fails:

ROLLBACK

Everything returns to the previous state.

Microservice Transaction

Now imagine:

Student Service

↓

Student DB
Result Service

↓

Result DB
Notification Service

↓

Notification DB

Each service owns its own database.

There is no single database transaction covering all three.

Student Results API Example

Teacher updates marks.

Business process:

Update Marks

↓

Generate Report

↓

Send Email

↓

Audit Log

Each step belongs to a different service.

The Problem

Suppose:

Result Service

↓

Update Database

↓

SUCCESS

Next:

Notification Service

↓

Send Email

↓

FAILED

Now the system is only partially complete.

Should marks remain updated?

Should the update be undone?

Why Not Use One Database Transaction?

Imagine:

Result DB

↓

Notification DB

↓

Analytics DB

Traditional ACID transactions across multiple independent databases introduce significant complexity and coordination overhead.

Modern microservice architectures typically avoid this approach.

Local Transactions

Each service performs its own transaction.

Example:

Result Service

↓

BEGIN

↓

UPDATE

↓

COMMIT

Next:

Notification Service

↓

BEGIN

↓

INSERT

↓

COMMIT

These transactions are independent.

Saga Pattern

The most common solution.

Instead of:

One Big Transaction

We use:

Many Local Transactions

Each service commits independently.

If something fails:

Compensating Transaction

undoes the business effect of earlier steps.

Saga Flow
Result Service
      │
      ▼
Update Marks
      │
      ▼
Publish Event
      │
      ▼
Notification Service
      │
      ▼
Send Email
      │
      ▼
Analytics Service

Each successful step triggers the next.

Compensating Transaction

Suppose:

Marks Updated

↓

SUCCESS

Later:

Certificate Generation

↓

FAILED

Compensating action:

Marks Update

↓

Reverse Update

The compensation is another business operation—not a database rollback.

Choreography

There is no central coordinator.

Services react to events.

Result Service

↓

MARKS_UPDATED

↓

Kafka

↓

Notification Service

↓

Analytics Service

Advantages:

Loosely coupled
Easy to add new consumers

Challenges:

Harder to visualize the complete workflow
Event chains can become complex
Orchestration

A central coordinator manages the workflow.

Saga Orchestrator
      │
 ┌────┼────┐
 ▼    ▼    ▼
Result Email Report

The orchestrator decides:

Next step
Retry
Compensation

Advantages:

Easier to understand end-to-end flow
Centralized control

Challenges:

Adds another service
Can become a bottleneck if poorly designed
Kafka-Based Saga
Teacher
      │
      ▼
Result Service
      │
      ▼
Kafka
      │
 ┌────┼──────────┐
 ▼    ▼          ▼
Email Audit Certificate

Each service consumes the event independently.

Compensation Example

Suppose:

Payment

↓

SUCCESS

Inventory:

FAILED

Compensation:

Refund Payment

The goal is to restore business consistency.

Event Sequence
MARKS_UPDATED

↓

EMAIL_SENT

↓

REPORT_GENERATED

↓

AUDIT_COMPLETED

Every event advances the business process.

Failure Handling

Possible strategies:

Retry transient failures
Dead Letter Queue (DLQ)
Manual intervention
Compensating transaction

The appropriate strategy depends on the business requirement.

Eventual Consistency

Unlike ACID transactions:

Immediate Consistency

Saga-based systems often provide:

Eventual Consistency

The system may be temporarily inconsistent while background processing completes, but it converges to a correct state.

Kubernetes

Typical deployment:

Ingress
     │
     ▼
API Gateway
     │
     ▼
Result Service
     │
     ▼
Kafka
     │
 ┌───┼──────────┐
 ▼   ▼          ▼
Email Report Audit

Each service runs independently and communicates through events.

Student Results API Evolution
Version 1
Spring Boot

↓

PostgreSQL
Version 2
Result Service

↓

Result DB
Version 3
Result Service

↓

Kafka

↓

Notification Service
Version 4
Result Service

↓

Saga

↓

Email

↓

Certificate

↓

Audit

The workflow becomes distributed but coordinated.

Hands-on Lab
Publish Event
kafkaTemplate.send(
    "marks-updated",
    event
);
Consume Event
@KafkaListener(
    topics = "marks-updated"
)

Update another service based on the event.

Simulate Failure

Throw an exception after updating one service.

Observe:

Retry behavior
Compensation (if implemented)
Dead-letter handling
Trace the Workflow

Log each event:

MARKS_UPDATED

↓

EMAIL_SENT

↓

AUDIT_COMPLETED

Observe the end-to-end business process.

Common Mistakes
❌ Trying to Use One Database Transaction Across All Services

Independent microservices should own independent databases.

Avoid tightly coupling services through shared transactions.

❌ Forgetting Compensation

If a later step fails, define how earlier business actions should be compensated.

❌ Assuming Events Are Processed Only Once

Message brokers commonly provide at-least-once delivery.

Consumers should be idempotent so duplicate events do not produce incorrect results.

❌ Ignoring Observability

Distributed workflows require:

Correlation IDs
Distributed tracing
Structured logging
Metrics

Otherwise, debugging failures becomes extremely difficult.

Distributed Transaction Workflow
Teacher
    │
    ▼
Result Service
    │
    ▼
Local Transaction
    │
    ▼
Publish Event
    │
    ▼
Kafka
    │
 ┌──┼──────────┐
 ▼  ▼          ▼
Email Report Audit
    │
    ▼
Compensate If Needed
ACID vs Saga
ACID Transaction	Saga Pattern
Single database transaction	Multiple local transactions
Immediate consistency	Eventual consistency
Database rollback	Business compensation
Simpler within one database	Suitable for distributed systems
Common in monoliths	Common in microservices
💡 Key Takeaways

✅ Distributed transactions coordinate business operations across multiple independent services.

✅ Traditional ACID transactions do not naturally extend across independently owned service databases.

✅ The Saga Pattern coordinates multiple local transactions and uses compensating actions instead of database rollbacks.

✅ Sagas can be implemented using choreography (events) or orchestration (a central coordinator).

✅ Reliable distributed systems require retries, idempotent consumers, dead-letter queues, observability, and eventual consistency.


