---
name: reactive-programming
description: >
  Reactive programming patterns with Project Reactor and Spring WebFlux.
  Covers Mono/Flux operators, backpressure, error handling, R2DBC, and
  testing reactive streams. Use when building reactive APIs, working with
  Mono/Flux, implementing non-blocking I/O, or testing reactive code.
  Triggers: "WebFlux", "Reactor", "Mono", "Flux", "reactive", "non-blocking",
  "R2DBC", "backpressure", "StepVerifier".
---

# Reactive Programming with Project Reactor

Production-grade reactive patterns for Spring WebFlux and Project Reactor.

## Rules

### 1. Reactor Core (Critical)

| # | Rule | Description |
|---|------|-------------|
| RC1 | **Mono for 0..1, Flux for 0..N** | `Mono<User>` for single results, `Flux<User>` for collections. |
| RC2 | **Never block in reactive chains** | No `.block()`, `Thread.sleep()`, or synchronous I/O in reactive pipelines. |
| RC3 | **Subscribe is the trigger** | Nothing happens until someone subscribes. Spring WebFlux subscribes for you. |
| RC4 | **Use operators, not imperative code** | `map`, `flatMap`, `filter`, `zip`, `concat` — not manual loops. |
| RC5 | **flatMap for async operations** | `mono.flatMap(user -> fetchOrders(user.getId()))` — switches to new publisher. |
| RC6 | **Avoid nesting** | Chain operators instead of nesting `flatMap` inside `flatMap`. |

```java
// GOOD: Reactive controller
@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    private final UserService userService;

    @GetMapping("/{id}")
    public Mono<UserResponse> getUser(@PathVariable UUID id) {
        return userService.findById(id)
            .map(UserResponse::from);
    }

    @GetMapping
    public Flux<UserResponse> listUsers(@RequestParam(defaultValue = "0") int page) {
        return userService.findAll(page, 20)
            .map(UserResponse::from);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<UserResponse> createUser(@Valid @RequestBody Mono<CreateUserRequest> request) {
        return request
            .flatMap(userService::create)
            .map(UserResponse::from);
    }
}
```

### 2. Error Handling (High)

| # | Rule | Description |
|---|------|-------------|
| EH1 | **Use onErrorResume for fallback** | `mono.onErrorResume(ex -> Mono.just(defaultValue))`. |
| EH2 | **Use onErrorMap to transform** | `mono.onErrorMap(IOException.class, ex -> new ServiceException(ex))`. |
| EH3 | **Use retry for transient failures** | `mono.retryWhen(Retry.backoff(3, Duration.ofSeconds(1)))`. |
| EH4 | **Use doOnError for logging** | Side-effect only — doesn't change the error signal. |
| EH5 | **Use timeout for circuit breaking** | `mono.timeout(Duration.ofSeconds(5))` throws `TimeoutException`. |

```java
public Mono<PaymentResult> processPayment(PaymentRequest request) {
    return paymentClient.charge(request)
        .timeout(Duration.ofSeconds(5))
        .retryWhen(Retry.backoff(3, Duration.ofMillis(500))
            .filter(ex -> ex instanceof WebClientResponseException.ServiceUnavailable))
        .onErrorResume(TimeoutException.class,
            ex -> Mono.just(PaymentResult.timeout()))
        .onErrorMap(ex -> new PaymentException("Payment failed", ex));
}
```

### 3. WebFlux Patterns (High)

```java
// Functional endpoint style
@Configuration
public class RouterConfig {
    @Bean
    public RouterFunction<ServerResponse> routes(UserHandler handler) {
        return route()
            .GET("/api/v1/users/{id}", handler::getUser)
            .GET("/api/v1/users", handler::listUsers)
            .POST("/api/v1/users", handler::createUser)
            .build();
    }
}

@Component
public class UserHandler {
    private final UserService userService;

    public Mono<ServerResponse> getUser(ServerRequest request) {
        UUID id = UUID.fromString(request.pathVariable("id"));
        return userService.findById(id)
            .flatMap(user -> ServerResponse.ok().bodyValue(UserResponse.from(user)))
            .switchIfEmpty(ServerResponse.notFound().build());
    }
}
```

### 4. R2DBC (Medium)

```java
// Reactive repository
public interface UserRepository extends ReactiveCrudRepository<User, UUID> {
    Flux<User> findByStatus(UserStatus status);
    Mono<User> findByEmail(String email);

    @Query("SELECT * FROM users WHERE name ILIKE :query LIMIT :limit")
    Flux<User> search(@Param("query") String query, @Param("limit") int limit);
}

// Transactional reactive service
@Service
@Transactional
public class OrderService {
    public Mono<Order> createOrder(CreateOrderRequest request) {
        return userRepository.findById(request.userId())
            .switchIfEmpty(Mono.error(new NotFoundException("User not found")))
            .flatMap(user -> {
                Order order = new Order(user.getId(), request.items());
                return orderRepository.save(order);
            });
    }
}
```

### 5. Testing (Medium)

```java
@Test
void shouldReturnUserById() {
    User user = new User(UUID.randomUUID(), "Alice", "alice@test.com");
    when(userRepository.findById(user.getId())).thenReturn(Mono.just(user));

    StepVerifier.create(userService.findById(user.getId()))
        .assertNext(result -> {
            assertEquals("Alice", result.getName());
            assertEquals("alice@test.com", result.getEmail());
        })
        .verifyComplete();
}

@Test
void shouldRetryOnTransientError() {
    when(paymentClient.charge(any()))
        .thenReturn(Mono.error(new ServiceUnavailableException()))
        .thenReturn(Mono.error(new ServiceUnavailableException()))
        .thenReturn(Mono.just(new PaymentResult("tx-123", SUCCESS)));

    StepVerifier.create(paymentService.processPayment(request))
        .assertNext(result -> assertEquals(SUCCESS, result.status()))
        .verifyComplete();
}

// WebFlux test
@WebFluxTest(UserController.class)
class UserControllerTest {
    @Autowired WebTestClient webClient;
    @MockBean UserService userService;

    @Test
    void shouldGetUser() {
        when(userService.findById(any())).thenReturn(Mono.just(testUser));

        webClient.get().uri("/api/v1/users/{id}", testUser.getId())
            .exchange()
            .expectStatus().isOk()
            .expectBody(UserResponse.class)
            .value(response -> assertEquals("Alice", response.name()));
    }
}
```

For operator cheat sheet, see `references/reactor-operators.md`.
