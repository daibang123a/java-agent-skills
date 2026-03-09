# Hexagonal Architecture in Java

## Core Concept

```
                    ┌─────────────────────┐
   Driving          │                     │          Driven
   Adapters ──────▶ │      DOMAIN         │ ──────▶  Adapters
   (input)          │   (business logic)  │          (output)
                    │                     │
   • REST API       │  • Entities         │  • PostgreSQL
   • gRPC           │  • Value Objects    │  • Redis
   • CLI            │  • Use Cases        │  • Kafka
   • Kafka Listener │  • Ports (interfaces)│  • HTTP Client
   • Scheduler      │  • Domain Services  │  • SMTP
                    └─────────────────────┘
```

## Port Definition (Domain Layer)

```java
// Driving port (input) — defines what the domain offers
public interface CreateUserUseCase {
    User createUser(CreateUserCommand command);
}

public record CreateUserCommand(String name, String email) {}

// Driven port (output) — defines what the domain needs
public interface UserPersistencePort {
    User save(User user);
    Optional<User> findById(UserId id);
    Optional<User> findByEmail(Email email);
    boolean existsByEmail(Email email);
}

public interface UserEventPort {
    void publishUserCreated(User user);
}
```

## Domain Service (Implements Driving Port)

```java
// No Spring annotations — pure Java
public class UserDomainService implements CreateUserUseCase, FindUserUseCase {

    private final UserPersistencePort persistence;
    private final UserEventPort events;

    public UserDomainService(UserPersistencePort persistence, UserEventPort events) {
        this.persistence = persistence;
        this.events = events;
    }

    @Override
    public User createUser(CreateUserCommand command) {
        Email email = Email.of(command.email());
        if (persistence.existsByEmail(email)) {
            throw new UserAlreadyExistsException(email);
        }

        User user = User.create(command.name(), email);
        User saved = persistence.save(user);
        events.publishUserCreated(saved);
        return saved;
    }
}
```

## Adapter Implementations

```java
// Driving adapter (REST)
@RestController
@RequestMapping("/api/v1/users")
public class UserRestAdapter {

    private final CreateUserUseCase createUser;

    @PostMapping
    public ResponseEntity<UserResponse> create(@Valid @RequestBody CreateUserRequest req) {
        User user = createUser.createUser(new CreateUserCommand(req.name(), req.email()));
        return ResponseEntity.created(URI.create("/api/v1/users/" + user.getId()))
            .body(UserResponse.from(user));
    }
}

// Driven adapter (JPA)
@Repository
public class UserJpaPersistenceAdapter implements UserPersistencePort {

    private final UserJpaRepository jpaRepository;

    @Override
    public User save(User user) {
        UserJpaEntity entity = UserJpaEntity.fromDomain(user);
        UserJpaEntity saved = jpaRepository.save(entity);
        return saved.toDomain();
    }
}

// Driven adapter (Kafka)
@Component
public class KafkaUserEventAdapter implements UserEventPort {

    private final KafkaTemplate<String, Object> kafka;

    @Override
    public void publishUserCreated(User user) {
        kafka.send("user-events", user.getId().toString(),
            new UserCreatedEvent(user.getId(), user.getName()));
    }
}
```

## Wiring Configuration

```java
@Configuration
public class BeanConfiguration {

    @Bean
    public CreateUserUseCase createUserUseCase(
            UserPersistencePort persistence,
            UserEventPort events) {
        return new UserDomainService(persistence, events);
    }
}
```

## Key Rules

1. **Domain has ZERO framework imports** — no Spring, JPA, Kafka
2. **Ports are interfaces in the domain layer**
3. **Adapters implement ports and live outside domain**
4. **Dependencies always point inward** (adapters → domain)
5. **Map between domain and adapter models** at the adapter boundary
