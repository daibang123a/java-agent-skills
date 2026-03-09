---
name: java-project-structure
description: >
  Java project layout and architecture patterns for Maven/Gradle projects.
  Covers hexagonal architecture, DDD, modular monolith, multi-module builds,
  and package strategies. Use when starting a new project, refactoring packages,
  or designing architecture. Triggers: "Project structure", "New Spring Boot project",
  "Hexagonal architecture", "Clean architecture Java", "Multi-module Maven",
  "Package by feature", "DDD Java".
---

# Java Project Structure

Project layout and architecture patterns for Java/Spring Boot applications.

## How It Works

1. Agent identifies the project type (API, CLI, library, microservice, monolith)
2. Agent applies the appropriate layout template
3. Agent generates directory structure with standard files
4. Agent organizes existing code into the recommended structure

## Layouts

### 1. Spring Boot API (Package-by-Feature)

```
myservice/
├── src/main/java/com/example/myservice/
│   ├── MyServiceApplication.java
│   ├── user/                          # Feature package
│   │   ├── User.java                  # Entity
│   │   ├── UserRepository.java        # Repository
│   │   ├── UserService.java           # Business logic
│   │   ├── UserController.java        # REST controller
│   │   ├── CreateUserRequest.java     # DTO (record)
│   │   ├── UserResponse.java          # DTO (record)
│   │   └── UserNotFoundException.java # Domain exception
│   ├── order/                         # Another feature
│   │   ├── Order.java
│   │   ├── OrderRepository.java
│   │   ├── OrderService.java
│   │   ├── OrderController.java
│   │   └── dto/
│   │       ├── CreateOrderRequest.java
│   │       └── OrderResponse.java
│   ├── shared/                        # Cross-cutting concerns
│   │   ├── config/
│   │   │   ├── SecurityConfig.java
│   │   │   ├── JpaConfig.java
│   │   │   └── WebConfig.java
│   │   ├── exception/
│   │   │   ├── GlobalExceptionHandler.java
│   │   │   ├── NotFoundException.java
│   │   │   └── ConflictException.java
│   │   └── audit/
│   │       └── AuditableEntity.java
│   └── infra/                         # Infrastructure
│       ├── client/
│       │   └── PaymentClient.java
│       └── messaging/
│           └── EventPublisher.java
├── src/main/resources/
│   ├── application.yml
│   ├── application-dev.yml
│   ├── application-prod.yml
│   └── db/migration/
│       ├── V1__create_users.sql
│       └── V2__create_orders.sql
├── src/test/java/com/example/myservice/
│   ├── user/
│   │   ├── UserControllerTest.java
│   │   ├── UserServiceTest.java
│   │   └── UserRepositoryTest.java
│   └── TestcontainersConfiguration.java
├── pom.xml (or build.gradle.kts)
├── Dockerfile
├── docker-compose.yml
└── README.md
```

### 2. Hexagonal Architecture (Ports & Adapters)

```
myservice/
├── src/main/java/com/example/myservice/
│   ├── domain/                        # Core business logic (no framework deps)
│   │   ├── model/
│   │   │   ├── User.java
│   │   │   ├── UserId.java           # Value object
│   │   │   └── Email.java            # Value object
│   │   ├── port/
│   │   │   ├── in/                    # Driving ports (use cases)
│   │   │   │   ├── CreateUserUseCase.java
│   │   │   │   └── FindUserUseCase.java
│   │   │   └── out/                   # Driven ports (SPI)
│   │   │       ├── UserPersistencePort.java
│   │   │       ├── UserEventPort.java
│   │   │       └── PaymentPort.java
│   │   ├── service/                   # Use case implementations
│   │   │   └── UserDomainService.java
│   │   └── exception/
│   │       └── UserNotFoundException.java
│   ├── adapter/                       # Framework-specific implementations
│   │   ├── in/                        # Driving adapters
│   │   │   ├── web/
│   │   │   │   ├── UserController.java
│   │   │   │   └── dto/
│   │   │   └── messaging/
│   │   │       └── UserEventListener.java
│   │   └── out/                       # Driven adapters
│   │       ├── persistence/
│   │       │   ├── UserJpaRepository.java
│   │       │   ├── UserJpaEntity.java
│   │       │   └── UserPersistenceAdapter.java
│   │       ├── payment/
│   │       │   └── StripePaymentAdapter.java
│   │       └── event/
│   │           └── KafkaUserEventAdapter.java
│   └── config/
│       ├── BeanConfiguration.java     # Wire ports to adapters
│       └── SecurityConfig.java
```

### 3. Multi-Module Maven

```
platform/
├── pom.xml                            # Parent POM (dependencyManagement)
├── common/
│   ├── pom.xml
│   └── src/main/java/                 # Shared DTOs, utils
├── user-service/
│   ├── pom.xml
│   └── src/
├── order-service/
│   ├── pom.xml
│   └── src/
├── gateway/
│   ├── pom.xml
│   └── src/
└── infrastructure/
    ├── docker-compose.yml
    └── k8s/
```

## Architecture Rules

| # | Rule | Description |
|---|------|-------------|
| A1 | **Package by feature, not by layer** | `user/`, `order/` — not `controller/`, `service/`, `repository/`. |
| A2 | **Domain has zero framework dependencies** | Domain model must not import Spring, JPA, or any framework. |
| A3 | **Dependencies flow inward** | Adapters → Domain. Domain never depends on adapters. |
| A4 | **DTOs at the boundary** | Never expose domain entities to REST or messaging. Map at adapter layer. |
| A5 | **One Application class at root** | `@SpringBootApplication` scans from root package. |
| A6 | **Configuration in dedicated package** | `config/` or `shared/config/` for all `@Configuration` classes. |
| A7 | **Tests mirror source structure** | Same package structure under `src/test/java`. |

## Scaffold Script

```bash
bash skills/java-project-structure/scripts/scaffold.sh myservice --type=api --build=maven
```

For hexagonal architecture guide, see `references/hexagonal-guide.md`.
