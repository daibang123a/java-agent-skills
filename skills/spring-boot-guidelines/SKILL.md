---
name: spring-boot-guidelines
description: >
  Spring Boot application design, configuration, and performance best practices.
  70+ rules covering DI, REST APIs, security, validation, error handling, and
  production readiness. Use when building or reviewing Spring Boot applications,
  configuring Spring Security, or optimizing startup. Triggers: "Review my
  Spring Boot app", "Create REST API", "Spring Security", "Spring configuration",
  "Spring Boot best practices".
---

# Spring Boot Guidelines

Production-grade Spring Boot patterns. 70+ rules across 9 categories for Spring Boot 3.2+ and Spring Framework 6.1+.

## How It Works

1. Agent examines Spring Boot code — controllers, services, configuration, security
2. Agent applies rules by category in priority order
3. Agent suggests idiomatic Spring patterns with code examples
4. Agent references supporting docs for advanced topics

## Rules

### 1. Dependency Injection & Component Design (Critical)

| # | Rule | Description |
|---|------|-------------|
| DI1 | **Use constructor injection** | Always. Never `@Autowired` on fields. Mark constructors `final` on dependencies. |
| DI2 | **Single constructor = no @Autowired needed** | Spring auto-detects the single constructor. Don't add `@Autowired`. |
| DI3 | **Program to interfaces** | Inject `UserService` interface, not `UserServiceImpl`. |
| DI4 | **Use @RequiredArgsConstructor (Lombok)** | Or write explicit constructor. Both are fine; be consistent. |
| DI5 | **Avoid circular dependencies** | Redesign if two beans depend on each other. Never use `@Lazy` as a band-aid. |
| DI6 | **Use @Configuration for complex wiring** | `@Bean` methods for third-party classes or complex setup. |
| DI7 | **Prefer @Service, @Repository, @Controller** | Stereotype annotations clarify component roles. Use `@Component` only for generic beans. |

```java
// GOOD: Constructor injection, final fields
@Service
public class OrderService {

    private final OrderRepository orderRepository;
    private final PaymentClient paymentClient;
    private final EventPublisher eventPublisher;

    public OrderService(OrderRepository orderRepository,
                        PaymentClient paymentClient,
                        EventPublisher eventPublisher) {
        this.orderRepository = orderRepository;
        this.paymentClient = paymentClient;
        this.eventPublisher = eventPublisher;
    }
}
```

### 2. REST Controller Patterns (Critical)

| # | Rule | Description |
|---|------|-------------|
| RC1 | **Use @RestController** | Combines `@Controller` + `@ResponseBody`. |
| RC2 | **Keep controllers thin** | Controllers validate input and delegate to services. No business logic. |
| RC3 | **Use proper HTTP methods** | GET=read, POST=create, PUT=full update, PATCH=partial update, DELETE=remove. |
| RC4 | **Return proper status codes** | 201 Created, 204 No Content, 400 Bad Request, 404 Not Found, 409 Conflict. |
| RC5 | **Use ResponseEntity for control** | `ResponseEntity.created(uri).body(dto)` for headers and status codes. |
| RC6 | **Map DTOs, not entities** | Never expose JPA entities in REST responses. Use records as DTOs. |
| RC7 | **Version your API** | `/api/v1/users`. Use `@RequestMapping("/api/v1")` on the controller class. |
| RC8 | **Use @PathVariable and @RequestParam properly** | Path for resource identity, query params for filtering/pagination. |

```java
@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    public Page<UserResponse> list(Pageable pageable) {
        return userService.findAll(pageable)
            .map(UserResponse::from);
    }

    @GetMapping("/{id}")
    public UserResponse get(@PathVariable UUID id) {
        return UserResponse.from(userService.findById(id));
    }

    @PostMapping
    public ResponseEntity<UserResponse> create(@Valid @RequestBody CreateUserRequest request) {
        User user = userService.create(request);
        URI location = URI.create("/api/v1/users/" + user.getId());
        return ResponseEntity.created(location)
            .body(UserResponse.from(user));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        userService.delete(id);
    }
}

// DTO as record
public record UserResponse(UUID id, String name, String email, Instant createdAt) {
    public static UserResponse from(User user) {
        return new UserResponse(user.getId(), user.getName(),
            user.getEmail(), user.getCreatedAt());
    }
}
```

### 3. Configuration & Profiles (High)

| # | Rule | Description |
|---|------|-------------|
| CF1 | **Use @ConfigurationProperties** | Type-safe configuration binding over `@Value`. |
| CF2 | **Validate configuration** | Add `@Validated` and Bean Validation annotations on config classes. |
| CF3 | **Use profiles for environments** | `application-dev.yml`, `application-prod.yml`. Activate with `spring.profiles.active`. |
| CF4 | **Never hardcode secrets** | Use environment variables, Vault, or Spring Cloud Config. |
| CF5 | **Use yaml over properties** | YAML supports hierarchical config. Use `application.yml` as the default. |
| CF6 | **Externalize all configuration** | Database URLs, API keys, feature flags — all external. |

```java
@Configuration
@ConfigurationProperties(prefix = "app.payment")
@Validated
public class PaymentConfig {
    @NotBlank private String apiKey;
    @NotNull private URI baseUrl;
    @Min(1) @Max(30) private int timeoutSeconds = 10;
    @Min(1) @Max(5) private int maxRetries = 3;

    // getters and setters
}
```

### 4. Spring Security (High)

| # | Rule | Description |
|---|------|-------------|
| SC1 | **Use SecurityFilterChain bean** | Not the deprecated `WebSecurityConfigurerAdapter`. |
| SC2 | **Stateless for APIs** | `sessionManagement.sessionCreationPolicy(STATELESS)` for JWT/token-based auth. |
| SC3 | **Use method-level security** | `@PreAuthorize("hasRole('ADMIN')")` on service methods. Enable with `@EnableMethodSecurity`. |
| SC4 | **Hash passwords with BCrypt** | `new BCryptPasswordEncoder(12)`. Never store plaintext. |
| SC5 | **Configure CORS properly** | Whitelist origins. Never `allowedOrigins("*")` in production. |
| SC6 | **Disable CSRF for stateless APIs** | `.csrf(csrf -> csrf.disable())` when using JWT/tokens. |

```java
@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(sm -> sm.sessionCreationPolicy(STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers("/actuator/health").permitAll()
                .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
            .build();
    }
}
```

### 5. Data Validation (High)

| # | Rule | Description |
|---|------|-------------|
| VL1 | **Use Bean Validation on DTOs** | `@NotBlank`, `@Email`, `@Size`, `@Pattern` on request records/classes. |
| VL2 | **Use @Valid on controller params** | `@Valid @RequestBody CreateUserRequest request`. Triggers validation. |
| VL3 | **Create custom validators** | `@Constraint` annotation + `ConstraintValidator` for complex rules. |
| VL4 | **Validate at the boundary** | Validate in controllers/incoming messages. Services trust validated input. |
| VL5 | **Use validation groups** | `@Validated(OnCreate.class)` for different validation per operation. |

### 6. Exception Handling & Error Responses (Medium-High)

| # | Rule | Description |
|---|------|-------------|
| EH1 | **Use @ControllerAdvice** | Centralized exception handling. One per application. |
| EH2 | **Use ProblemDetail (RFC 9457)** | Spring 6+ native support: `ProblemDetail.forStatusAndDetail()`. |
| EH3 | **Map domain exceptions to HTTP status** | `NotFoundException → 404`, `ConflictException → 409`, `ValidationException → 422`. |
| EH4 | **Never expose stack traces** | Log the full trace, return only the message to clients. |
| EH5 | **Include correlation ID** | Request ID in error response for debugging. |

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(NotFoundException.class)
    public ProblemDetail handleNotFound(NotFoundException ex) {
        ProblemDetail pd = ProblemDetail.forStatusAndDetail(
            HttpStatus.NOT_FOUND, ex.getMessage());
        pd.setTitle("Resource Not Found");
        pd.setProperty("timestamp", Instant.now());
        return pd;
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail handleValidation(MethodArgumentNotValidException ex) {
        ProblemDetail pd = ProblemDetail.forStatus(HttpStatus.BAD_REQUEST);
        pd.setTitle("Validation Failed");

        Map<String, String> errors = ex.getBindingResult().getFieldErrors().stream()
            .collect(Collectors.toMap(
                FieldError::getField,
                fe -> fe.getDefaultMessage() != null ? fe.getDefaultMessage() : "invalid",
                (a, b) -> a
            ));
        pd.setProperty("errors", errors);
        return pd;
    }
}
```

### 7. Actuator & Production Readiness (Medium)

| # | Rule | Description |
|---|------|-------------|
| AC1 | **Enable health and metrics endpoints** | `/actuator/health`, `/actuator/metrics`, `/actuator/info`. |
| AC2 | **Custom health indicators** | Check critical dependencies: database, cache, external APIs. |
| AC3 | **Separate liveness and readiness** | `/actuator/health/liveness` vs `/actuator/health/readiness` for Kubernetes. |
| AC4 | **Secure actuator endpoints** | Only expose health publicly. Require auth for everything else. |
| AC5 | **Use Micrometer for metrics** | `@Timed`, custom counters, timers for business metrics. |

### 8. Testing Spring Applications (Medium)

| # | Rule | Description |
|---|------|-------------|
| TS1 | **Use sliced test annotations** | `@WebMvcTest` for controllers, `@DataJpaTest` for repositories. Faster than `@SpringBootTest`. |
| TS2 | **Use @MockBean sparingly** | Only mock what's needed. Prefer constructor injection in tests. |
| TS3 | **Test happy path + error paths** | Every endpoint needs success, validation error, and not-found tests. |
| TS4 | **Use Testcontainers for integration** | Real databases, not H2 in tests. |
| TS5 | **Use @DirtiesContext carefully** | Restarting context is slow. Design tests to not need it. |

### 9. Performance & Startup Optimization (Medium)

| # | Rule | Description |
|---|------|-------------|
| PF1 | **Use GraalVM native for fast startup** | `spring-boot-starter-parent` + `native-maven-plugin`. Reduces startup from seconds to milliseconds. |
| PF2 | **Use virtual threads (Java 21+)** | `spring.threads.virtual.enabled=true` for massive I/O concurrency. |
| PF3 | **Lazy initialization** | `spring.main.lazy-initialization=true` for development (not production). |
| PF4 | **Exclude unnecessary auto-configurations** | `@SpringBootApplication(exclude = {DataSourceAutoConfiguration.class})`. |
| PF5 | **Use Spring AOT** | Ahead-of-Time compilation for faster startup without going full native. |

## Quick Reference

```bash
bash skills/spring-boot-guidelines/scripts/spring-audit.sh /path/to/project
```

For Spring Security patterns, see `references/security-patterns.md`.
For configuration examples, see `references/config-examples.md`.
