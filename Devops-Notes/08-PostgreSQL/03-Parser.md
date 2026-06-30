# 📘 Chapter 61 — PostgreSQL SQL Parser

> 📂 File: `student-results-api-notes/08-PostgreSQL/03-Parser.md`

This chapter begins the PostgreSQL query execution pipeline.

In the previous chapter, we established a connection to PostgreSQL.

Now the database receives this SQL:

SELECT *
FROM student
WHERE id = 1;

But PostgreSQL does not execute SQL immediately.

The very first component that receives the SQL is the Parser.

This chapter explains how PostgreSQL converts raw SQL text into an internal tree representation before planning or executing anything.

---

# 🌍 Introduction

In the previous chapter, we learned how Spring Boot establishes a connection with PostgreSQL.

The flow looked like this:

```text
Spring Boot
      │
      ▼
Hibernate
      │
      ▼
JDBC Driver
      │
      ▼
TCP Socket
      │
      ▼
PostgreSQL
```

Now suppose Hibernate sends:

```sql
SELECT *
FROM student
WHERE id = 1;
```

What happens first?

Does PostgreSQL immediately read the database?

❌ No.

The SQL first goes to the **Parser**.

The Parser verifies that the SQL is valid before any planning or execution begins.

---

# 🎯 Learning Objectives

After completing this chapter you will understand:

* 📝 What the SQL Parser is
* 🔍 Lexical Analysis
* 🌳 Parse Tree
* ✅ Syntax Validation
* 🏷️ Semantic Validation
* 🚫 SQL Errors
* 📈 Parser Architecture
* 🚀 Query Pipeline
* 🐳 Docker
* ☸️ Kubernetes

---

# ❓ Why Does PostgreSQL Need a Parser?

Applications send SQL as plain text.

Example:

```sql
SELECT *
FROM student
WHERE id = 1;
```

For PostgreSQL this is simply:

```text
Character Stream

↓

"S"

"E"

"L"

"E"

"C"

"T"
```

The database cannot execute characters.

It first converts the text into an internal representation.

---

# 🏗️ Query Execution Pipeline

Every SQL statement passes through several stages.

```text
SQL Text
     │
     ▼
Parser
     │
     ▼
Parse Tree
     │
     ▼
Analyzer
     │
     ▼
Planner
     │
     ▼
Optimizer
     │
     ▼
Executor
     │
     ▼
Database Pages
```

The Parser is always the first stage.

---

# 🔍 Step 1 — Lexical Analysis

The Parser first breaks SQL into **tokens**.

Example:

```sql
SELECT *
FROM student
WHERE id = 1;
```

Tokens:

```text
SELECT

*

FROM

student

WHERE

id

=

1
```

Each token has a meaning.

---

# 📝 Step 2 — Syntax Validation

Now PostgreSQL checks whether the SQL follows SQL grammar.

Valid:

```sql
SELECT *
FROM student;
```

Invalid:

```sql
SELECT FROM;
```

Result:

```text
ERROR:

syntax error
```

No planning occurs because the SQL itself is invalid.

---

# 🌳 Step 3 — Parse Tree

After successful parsing:

```sql
SELECT *
FROM student
WHERE id = 1;
```

becomes:

```text
SELECT
│
├── Target List
│     └── *
│
├── FROM
│     └── student
│
└── WHERE
      │
      ├── id
      ├── =
      └── 1
```

This is called the **Parse Tree**.

It represents the SQL structure in memory.

---

# 🏷️ Step 4 — Semantic Validation

The Analyzer now verifies database objects.

Example:

```sql
SELECT age
FROM student;
```

Suppose:

```text
student

↓

No "age" column
```

PostgreSQL returns:

```text
ERROR:

column "age" does not exist
```

Similarly:

```sql
SELECT *
FROM employees;
```

If the table doesn't exist:

```text
ERROR:

relation "employees" does not exist
```

---

# ⚙️ Internal Parser Architecture

```text
SQL Text
     │
     ▼
Lexer
     │
     ▼
Tokens
     │
     ▼
Parser
     │
     ▼
Parse Tree
     │
     ▼
Analyzer
```

The Lexer and Parser work together to understand the SQL statement.

---

# 🍃 Student Results API Example

Suppose the browser requests:

```http
GET /students/1
```

Hibernate generates:

```sql
SELECT *
FROM student
WHERE id = 1;
```

PostgreSQL performs:

```text
Receive SQL

↓

Lexer

↓

Parser

↓

Parse Tree

↓

Analyzer

↓

Planner
```

Only after successful parsing does PostgreSQL continue to query planning.

---

# 📊 Parser Example

Input:

```sql
SELECT name, marks
FROM student
WHERE marks > 80;
```

Internal representation:

```text
SELECT
│
├── Columns
│      ├── name
│      └── marks
│
├── Table
│      └── student
│
└── Condition
       ├── marks
       ├── >
       └── 80
```

The database now understands the logical structure of the query.

---

# 🚫 Common Parser Errors

## ❌ Missing Keyword

```sql
SELECT
student;
```

Produces:

```text
syntax error
```

---

## ❌ Misspelled SQL

```sql
SELEKT *
FROM student;
```

Produces:

```text
syntax error
```

---

## ❌ Unknown Table

```sql
SELECT *
FROM employee;
```

Produces:

```text
relation does not exist
```

---

## ❌ Unknown Column

```sql
SELECT salary
FROM student;
```

Produces:

```text
column does not exist
```

---

# 🧠 Parser vs Planner

Many beginners confuse these components.

| Parser 📝           | Planner 📈                 |
| ------------------- | -------------------------- |
| Checks SQL syntax   | Chooses execution strategy |
| Creates Parse Tree  | Creates Execution Plan     |
| Finds syntax errors | Optimizes query            |
| Runs first          | Runs after parsing         |

The Parser validates the query.

The Planner determines how to execute it efficiently.

---

# 🐳 Docker Perspective

```text
Spring Boot Container
        │
        ▼
TCP Port 5432
        │
        ▼
PostgreSQL Container
        │
        ▼
SQL Parser
```

The Parser runs inside the PostgreSQL process regardless of whether PostgreSQL is installed directly or runs inside a container.

---

# ☸️ Kubernetes Perspective

```text
Spring Boot Pod
       │
       ▼
Service
       │
       ▼
PostgreSQL Pod
       │
       ▼
Parser
```

Every SQL statement received by the PostgreSQL Pod passes through the Parser.

---

# 🧪 Hands-on Lab

## Execute a Valid Query

```sql
SELECT *
FROM student;
```

Verify that PostgreSQL accepts the query.

---

## Generate a Syntax Error

```sql
SELECT FROM student;
```

Observe the parser error message.

---

## Query a Missing Table

```sql
SELECT *
FROM employees;
```

Observe the semantic validation error.

---

## Query a Missing Column

```sql
SELECT salary
FROM student;
```

Observe PostgreSQL rejecting the query before execution.

---

## Enable Statement Logging

In `postgresql.conf`:

```properties
log_statement = 'all'
```

Restart PostgreSQL and observe every SQL statement entering the parsing pipeline.

---

# 📈 Complete Parser Flow

```text
Hibernate
      │
      ▼
JDBC Driver
      │
      ▼
TCP Socket
      │
      ▼
PostgreSQL
      │
      ▼
Lexer
      │
      ▼
Tokens
      │
      ▼
Parser
      │
      ▼
Parse Tree
      │
      ▼
Analyzer
      │
      ▼
Planner
```

This is the complete journey of a SQL statement before optimization begins.

---

# 📊 Parser Component Summary

| Component    | Responsibility                                   |
| ------------ | ------------------------------------------------ |
| 📝 Lexer     | Breaks SQL into tokens                           |
| 🌳 Parser    | Validates SQL grammar and builds the parse tree  |
| 🏷️ Analyzer | Resolves tables, columns, types, and permissions |
| 📈 Planner   | Builds an execution strategy                     |
| ⚡ Executor   | Executes the selected plan                       |

---

# 💡 Key Takeaways

✅ PostgreSQL receives SQL as plain text over a database connection.

✅ The Lexer converts SQL text into tokens such as keywords, identifiers, operators, and literals.

✅ The Parser validates SQL grammar and builds an internal parse tree.

✅ The Analyzer verifies that referenced tables, columns, data types, and permissions are valid.

✅ Invalid SQL is rejected before planning or execution begins.

✅ Every SQL statement must successfully pass through the Parser before PostgreSQL can optimize or execute it.

✅ Understanding the Parser is the first step toward understanding how PostgreSQL transforms SQL into efficient database operations.

---

# ➡️ Next Chapter

📘 **`08-PostgreSQL/04-Query-Planner.md`**

In the next chapter, we'll explore PostgreSQL's **Query Planner**, the component that decides **how** a SQL statement should be executed.

We'll cover:

* 📈 Cost-Based Optimization
* 📄 Execution Plans
* 🔍 Sequential Scan vs Index Scan
* 🧠 Statistics
* ⚖️ Cost Estimation
* 🚀 `EXPLAIN` and `EXPLAIN ANALYZE`

By the end of the next chapter, you'll understand why two SQL queries that look similar can have completely different performance characteristics based on the execution plan chosen by PostgreSQL.
