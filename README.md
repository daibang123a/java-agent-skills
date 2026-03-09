# Java Agent Skills

A comprehensive collection of skills for AI coding agents working with **Java** and its ecosystem — Spring Boot, Jakarta EE, Hibernate, Reactive, Microservices, and more. Skills are packaged instructions and scripts that extend agent capabilities for Java development.

Skills follow the [Agent Skills](https://agentskills.io/) format.

## Available Skills

### java-best-practices

Core Java performance optimization and idiomatic coding guidelines. Contains **60+ rules** across 10 categories, prioritized by impact. Covers memory management, collections, streams, records, sealed classes, and modern Java 17–21+ features.

**Use when:**

- Writing new Java classes, services, or utilities
- Reviewing code for performance and idiomatic issues
- Migrating legacy Java code to modern idioms (Java 17+)
- Optimizing memory, GC pressure, or throughput

**Categories covered:**

- Memory & GC Optimization (Critical)
- Collections & Data Structures (Critical)
- Exception Handling (Critical)
- Stream API & Functional Patterns (High)
- Modern Java Features — Records, Sealed Classes, Pattern Matching (High)
- String & Text Processing (Medium-High)
- Generics & Type Safety (Medium)
- Immutability & Thread Safety (Medium)
- Annotations & Reflection (Low-Medium)
- Code Style & Naming Conventions (Low)

---

### spring-boot-guidelines

Spring Boot application design, configuration, and performance best practices. Contains **70+ rules** across 9 categories covering auto-configuration, dependency injection, REST APIs, security, and production readiness.

**Use when:**

- "Review my Spring Boot app"
- "Create a REST API with Spring"
- "Configure Spring Security"
- "Optimize Spring Boot startup"
- Building or reviewing any Spring Boot application

**Categories covered:**

- Dependency Injection & Component Design (Critical)
- REST Controller Patterns (Critical)
- Configuration & Profiles (High)
- Spring Security (High)
- Data Validation (High)
- Exception Handling & Error Responses (Medium-High)
- Actuator & Production Readiness (Medium)
- Testing Spring Applications (Medium)
- Performance & Startup Optimization (Medium)

---

### jpa-hibernate-patterns

JPA/Hibernate data access patterns and performance optimization. Contains **50+ rules** covering entity design, query optimization, caching, transactions, and the N+1 problem.

**Use when:**

- Designing JPA entities and relationships
- Optimizing Hibernate query performance
- Debugging N+1 query problems or lazy loading issues
- Implementing repository patterns with Spring Data JPA
- Managing transactions and isolation levels

**Categories covered:**

- Entity Design (Critical) — mapping, relationships, inheritance strategies
- Query Optimization (Critical) — JPQL, Criteria API, native queries, projections
- N+1 Problem & Fetching (Critical) — JOIN FETCH, EntityGraph, batch fetching
- Transaction Management (High) — propagation, isolation, read-only optimization
- Caching (High) — first-level, second-level, query cache
- Spring Data JPA (Medium-High) — custom repositories, specifications, pagination
- Schema Migration (Medium) — Flyway, Liquibase strategies
- Testing (Medium) — embedded databases, @DataJpaTest, Testcontainers

---

### java-testing-guidelines

Java testing best practices optimized for AI agents. Contains **40+ rules** across 7 sections covering JUnit 5, Mockito, integration testing, contract testing, and mutation testing.

**Use when:**

- Writing unit tests or parameterized tests
- Setting up integration tests with Spring Boot
- Mocking dependencies with Mockito
- Writing contract tests with Pact or Spring Cloud Contract
- Reviewing test code for coverage and correctness

**Categories covered:**

- JUnit 5 Patterns (Critical) — parameterized tests, nested tests, lifecycle
- Mockito & Test Doubles (High) — mocks, spies, argument captors
- Spring Boot Testing (High) — @WebMvcTest, @DataJpaTest, TestRestTemplate
- Integration Testing (High) — Testcontainers, WireMock, embedded services
- Architecture Testing (Medium) — ArchUnit rules, dependency checks
- Performance Testing (Medium) — JMH benchmarks, load testing
- Mutation Testing (Medium) — PIT mutation testing, test quality metrics

---

### java-concurrency-patterns

Java concurrency patterns using modern APIs — virtual threads (Project Loom), CompletableFuture, structured concurrency, and reactive streams.

**Use when:**

- Designing concurrent or parallel systems
- Using virtual threads (Java 21+)
- Building async pipelines with CompletableFuture
- Implementing producer-consumer or fork-join patterns
- Debugging thread safety issues or deadlocks

**Patterns covered:**

- Virtual Threads (Java 21+)
- Structured Concurrency (Preview)
- CompletableFuture pipelines
- ExecutorService patterns & thread pool sizing
- Fork/Join framework
- Producer-Consumer with BlockingQueue
- ReadWriteLock & StampedLock
- Concurrent collections
- Atomic variables & VarHandle

---

### java-project-structure

Java project layout and architecture patterns for Maven/Gradle projects. Covers hexagonal architecture, DDD, modular monoliths, and multi-module builds.

**Use when:**

- Starting a new Java/Spring Boot project
- Refactoring a monolithic codebase
- Designing hexagonal (ports & adapters) architecture
- Setting up a multi-module Maven/Gradle project
- Reviewing project layout for maintainability

**Patterns covered:**

- Standard Maven/Gradle project layout
- Hexagonal Architecture (Ports & Adapters)
- Domain-Driven Design in Java
- Multi-module project structure
- Modular Monolith
- Package-by-feature vs Package-by-layer
- Configuration management (application.yml, profiles)

---

### docker-deploy-java

Build and deploy Java applications with Docker. Optimized multi-stage builds, JVM tuning, GraalVM native images, and CI/CD pipelines.

**Use when:**

- "Dockerize my Java app"
- "Create a production Dockerfile"
- "Optimize my Java Docker image"
- "Set up GraalVM native image build"
- "CI/CD pipeline for Spring Boot"

**Features:**

- Auto-detects build tool (Maven/Gradle) and framework
- Generates optimized multi-stage Dockerfiles with JVM tuning
- Supports GraalVM native image builds
- Includes JLink custom runtime images
- Docker Compose for local development with databases
- GitHub Actions / GitLab CI pipeline templates

---

### java-security-guidelines

Java application security best practices covering OWASP Top 10, Spring Security, input validation, cryptography, and secure coding patterns.

**Use when:**

- "Review my security"
- "Check for vulnerabilities"
- "Implement authentication"
- "Secure my API"
- Auditing Java code for OWASP compliance

**Categories covered:**

- Input Validation & Sanitization (Critical)
- Authentication & Authorization (Critical)
- SQL Injection Prevention (Critical)
- Cryptography & Secrets Management (High)
- CSRF, XSS, CORS Protection (High)
- Dependency Vulnerability Scanning (High)
- Session Management (Medium)
- Logging Security Events (Medium)
- HTTP Security Headers (Medium)

---

### reactive-programming

Reactive programming patterns with Project Reactor and Spring WebFlux. Covers Mono/Flux operators, backpressure, error handling, and testing reactive streams.

**Use when:**

- Building reactive APIs with Spring WebFlux
- Working with Project Reactor (Mono, Flux)
- Implementing non-blocking I/O patterns
- Handling backpressure in streaming scenarios
- Testing reactive code with StepVerifier

**Categories covered:**

- Reactor Core (Critical) — Mono, Flux, operators, composition
- Spring WebFlux (High) — functional endpoints, annotated controllers
- Error Handling (High) — onErrorResume, retry, fallback
- Backpressure (Medium-High) — buffer, drop, latest strategies
- Schedulers & Threading (Medium) — publishOn, subscribeOn, elastic
- R2DBC (Medium) — reactive database access
- Testing (Medium) — StepVerifier, WebTestClient

---

### microservices-patterns

Microservices architecture patterns for Java/Spring Cloud. Covers service discovery, circuit breaking, API gateway, event-driven architecture, and distributed transactions.

**Use when:**

- Designing microservices architecture
- Implementing service-to-service communication
- Adding resilience patterns (circuit breaker, retry, bulkhead)
- Setting up event-driven messaging with Kafka/RabbitMQ
- Implementing distributed tracing

**Patterns covered:**

- Service Discovery (Eureka, Consul)
- API Gateway (Spring Cloud Gateway)
- Circuit Breaker (Resilience4j)
- Event-Driven Architecture (Kafka, RabbitMQ)
- Saga Pattern for distributed transactions
- CQRS & Event Sourcing
- Distributed Tracing (Micrometer + Zipkin/Jaeger)
- Configuration Management (Spring Cloud Config)

---

### java-logging-observability

Java logging, metrics, and observability best practices. Covers SLF4J/Logback, Micrometer, OpenTelemetry, structured logging, and production monitoring.

**Use when:**

- Setting up logging in a Java application
- Implementing structured logging with MDC
- Adding metrics with Micrometer
- Integrating OpenTelemetry for distributed tracing
- Configuring log aggregation (ELK, Loki)

**Categories covered:**

- SLF4J & Logback Configuration (Critical)
- Structured Logging & MDC (High)
- Micrometer Metrics (High)
- OpenTelemetry Integration (Medium-High)
- Spring Boot Actuator (Medium)
- Health Checks & Readiness Probes (Medium)
- Log Aggregation Patterns (Medium)

---

## Installation

```bash
# Install using the skills CLI
npx skills add java-agent-skills/java-agent-skills

# Or install specific skills
npx skills add java-agent-skills/java-agent-skills --skill spring-boot-guidelines
npx skills add java-agent-skills/java-agent-skills --skill java-best-practices

# Install to specific agents
npx skills add java-agent-skills/java-agent-skills -a claude-code -a cursor

# Install all skills to all agents
npx skills add java-agent-skills/java-agent-skills --all
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/java-agent-skills/java-agent-skills.git

# Copy skills to your project
cp -r java-agent-skills/skills/spring-boot-guidelines .skills/

# Or symlink for automatic updates
ln -s $(pwd)/java-agent-skills/skills/spring-boot-guidelines .skills/spring-boot-guidelines
```

## Usage

Skills are automatically available once installed. The agent will use them when relevant tasks are detected.

**Examples:**

```
Review this Spring Boot controller for best practices
```

```
Help me fix the N+1 query problem in my JPA repository
```

```
Write parameterized tests for my UserService
```

```
Design a microservices architecture for an e-commerce platform
```

```
Dockerize my Spring Boot app with GraalVM native image
```

```
Add circuit breaker pattern to my service calls
```

## Skill Structure

Each skill contains:

- `SKILL.md` — Instructions for the agent (required)
- `scripts/` — Helper scripts for automation (optional)
- `references/` — Supporting documentation (optional)
- `assets/` — Templates and example files (optional)

### SKILL.md Format

```yaml
---
name: skill-name
description: >
  One sentence describing when to use this skill.
  Include trigger phrases.
---

# Skill Title

Brief description of what the skill does.

## How It Works
...

## Rules
...
```

## Java Version Support

| Feature | Minimum Java Version |
|---------|---------------------|
| Core patterns | Java 17 (LTS) |
| Records, sealed classes, pattern matching | Java 17+ |
| Virtual threads | Java 21 (LTS) |
| Structured concurrency | Java 21+ (Preview) |
| String templates | Java 21+ (Preview) |

All skills target **Java 17+** as the baseline, with Java 21+ features clearly marked.

## Framework Versions

| Framework | Version |
|-----------|---------|
| Spring Boot | 3.2+ |
| Spring Framework | 6.1+ |
| Hibernate | 6.4+ |
| JUnit | 5.10+ |
| Mockito | 5.x |
| Resilience4j | 2.x |
| Project Reactor | 3.6+ |

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Compatibility

| Agent | Status |
|-------|--------|
| Claude Code | ✅ Fully supported |
| Cursor | ✅ Fully supported |
| GitHub Copilot | ✅ Fully supported |
| OpenCode | ✅ Fully supported |
| Codex | ✅ Fully supported |
| Windsurf | ✅ Fully supported |
| Goose | ✅ Fully supported |

## ☕ Support this project

If you like this project, you can buy me a coffee.

<a href="https://buymeacoffee.com/dobadat111c" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" height="50">
</a>
