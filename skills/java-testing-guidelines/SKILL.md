---
name: java-testing-guidelines
description: >
  Java testing best practices with 40+ rules across 7 categories. Covers JUnit 5,
  Mockito, Spring Boot testing, integration testing, ArchUnit, JMH benchmarks,
  and mutation testing. Use when writing tests, reviewing test code, or setting
  up CI testing pipelines. Triggers: "Write tests", "JUnit test", "Mockito mock",
  "Integration test", "Spring Boot test", "Benchmark", "Test coverage".
---

# Java Testing Guidelines

Comprehensive testing best practices for Java. 40+ rules covering unit, integration, architecture, and performance testing.

## How It Works

1. Agent identifies the testing need (unit, integration, benchmark, architecture)
2. Agent applies the appropriate patterns from this skill
3. Agent generates test code following JUnit 5 conventions
4. Agent ensures proper assertions, naming, and test isolation

## Rules

### 1. JUnit 5 Patterns (Critical)

| # | Rule | Description |
|---|------|-------------|
| J1 | **Use @ParameterizedTest for multiple inputs** | `@CsvSource`, `@MethodSource`, `@EnumSource` for data-driven tests. |
| J2 | **Name tests descriptively** | `@DisplayName("should return 404 when user not found")` or method names: `shouldReturn404WhenUserNotFound`. |
| J3 | **Use @Nested for grouping** | Group related test cases by scenario or method under test. |
| J4 | **One assertion concept per test** | Test one behavior. Multiple assertions are OK if they verify the same concept. |
| J5 | **Use assertAll for multi-property checks** | `assertAll(() -> assertEquals(...), () -> assertEquals(...))` — reports all failures. |
| J6 | **Use assertThrows for exception tests** | `assertThrows(NotFoundException.class, () -> service.findById(unknownId))`. |
| J7 | **Test edge cases** | null, empty, boundary values, overflow, special characters. |

```java
@Nested
@DisplayName("UserService.createUser")
class CreateUserTests {

    @Test
    @DisplayName("should create user with valid input")
    void shouldCreateUserWithValidInput() {
        var request = new CreateUserRequest("Alice", "alice@example.com");
        var result = userService.create(request);

        assertAll(
            () -> assertNotNull(result.getId()),
            () -> assertEquals("Alice", result.getName()),
            () -> assertEquals("alice@example.com", result.getEmail()),
            () -> assertNotNull(result.getCreatedAt())
        );
    }

    @ParameterizedTest(name = "should reject invalid email: {0}")
    @ValueSource(strings = {"", "  ", "not-an-email", "@missing", "missing@"})
    void shouldRejectInvalidEmail(String email) {
        var request = new CreateUserRequest("Alice", email);
        assertThrows(ValidationException.class, () -> userService.create(request));
    }

    @Test
    @DisplayName("should throw ConflictException when email already exists")
    void shouldThrowConflictWhenEmailExists() {
        when(userRepository.existsByEmail("alice@example.com")).thenReturn(true);

        var request = new CreateUserRequest("Alice", "alice@example.com");
        assertThrows(ConflictException.class, () -> userService.create(request));
    }
}
```

### 2. Mockito & Test Doubles (High)

| # | Rule | Description |
|---|------|-------------|
| MK1 | **Use @ExtendWith(MockitoExtension.class)** | JUnit 5 integration. Avoid `MockitoAnnotations.openMocks()`. |
| MK2 | **Use @Mock for dependencies** | Only mock what's necessary. Don't mock value objects or data classes. |
| MK3 | **Use @InjectMocks for the SUT** | Auto-injects mocks into the system under test via constructor. |
| MK4 | **Verify interactions sparingly** | `verify()` tests implementation, not behavior. Prefer asserting results. |
| MK5 | **Use ArgumentCaptor for complex args** | `ArgumentCaptor<Event> captor` when you need to inspect passed arguments. |
| MK6 | **Use BDDMockito for readability** | `given(...).willReturn(...)` and `then(...).should()`. |

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock OrderRepository orderRepository;
    @Mock PaymentClient paymentClient;
    @Mock EventPublisher eventPublisher;
    @InjectMocks OrderService orderService;

    @Test
    void shouldPublishEventAfterOrderCreation() {
        // given
        given(paymentClient.charge(any())).willReturn(new PaymentResult("tx-123", SUCCESS));
        given(orderRepository.save(any())).willAnswer(inv -> inv.getArgument(0));

        // when
        var order = orderService.placeOrder(new PlaceOrderRequest(/*...*/));

        // then
        var captor = ArgumentCaptor.forClass(OrderCreatedEvent.class);
        then(eventPublisher).should().publish(captor.capture());
        assertEquals(order.getId(), captor.getValue().orderId());
    }
}
```

### 3. Spring Boot Testing (High)

| # | Rule | Description |
|---|------|-------------|
| SB1 | **Use @WebMvcTest for controllers** | Loads only web layer. Mock service beans with `@MockBean`. |
| SB2 | **Use @DataJpaTest for repositories** | Auto-configures embedded database, entity manager, and repositories. |
| SB3 | **Use @SpringBootTest sparingly** | Full context is slow. Use sliced tests first. |
| SB4 | **Use MockMvc for HTTP testing** | `mockMvc.perform(get("/api/users")).andExpect(status().isOk())`. |
| SB5 | **Use @Testcontainers for real databases** | Real PostgreSQL/MySQL in Docker for integration tests. |
| SB6 | **Use @Sql for test data** | `@Sql("/test-data/users.sql")` to load fixtures before tests. |

```java
@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired MockMvc mockMvc;
    @MockBean UserService userService;

    @Test
    void shouldReturnUserById() throws Exception {
        var user = new User(UUID.randomUUID(), "Alice", "alice@example.com");
        given(userService.findById(user.getId())).willReturn(user);

        mockMvc.perform(get("/api/v1/users/{id}", user.getId()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.name").value("Alice"))
            .andExpect(jsonPath("$.email").value("alice@example.com"));
    }

    @Test
    void shouldReturn404WhenUserNotFound() throws Exception {
        var id = UUID.randomUUID();
        given(userService.findById(id)).willThrow(new NotFoundException("User not found"));

        mockMvc.perform(get("/api/v1/users/{id}", id))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.title").value("Resource Not Found"));
    }

    @Test
    void shouldReturn400ForInvalidRequest() throws Exception {
        mockMvc.perform(post("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"name": "", "email": "not-an-email"}
                    """))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errors.name").exists())
            .andExpect(jsonPath("$.errors.email").exists());
    }
}
```

### 4. Integration Testing (High)

| # | Rule | Description |
|---|------|-------------|
| IT1 | **Use Testcontainers for databases** | Real PostgreSQL, not H2. H2 hides SQL compatibility issues. |
| IT2 | **Use WireMock for external APIs** | Mock HTTP dependencies at the network level. |
| IT3 | **Isolate test data** | Each test creates its own data. Use `@Transactional` rollback or truncate. |
| IT4 | **Use @DynamicPropertySource** | Inject Testcontainer URLs into Spring context. |

```java
@SpringBootTest(webEnvironment = RANDOM_PORT)
@Testcontainers
class UserIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired TestRestTemplate restTemplate;
    @Autowired UserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
    }

    @Test
    void shouldCreateAndRetrieveUser() {
        var request = new CreateUserRequest("Alice", "alice@test.com");
        var response = restTemplate.postForEntity("/api/v1/users", request, UserResponse.class);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertNotNull(response.getBody().id());

        var getResponse = restTemplate.getForEntity(
            "/api/v1/users/{id}", UserResponse.class, response.getBody().id());
        assertEquals("Alice", getResponse.getBody().name());
    }
}
```

### 5. Architecture Testing (Medium)

| # | Rule | Description |
|---|------|-------------|
| AR1 | **Use ArchUnit for dependency rules** | Enforce layer boundaries at compile time. |
| AR2 | **Test package dependencies** | Controllers → Services → Repositories. Never reverse. |
| AR3 | **Enforce naming conventions** | Services end with `Service`, repositories with `Repository`, etc. |

```java
@AnalyzeClasses(packages = "com.example.myapp")
class ArchitectureTest {

    @ArchTest
    static final ArchRule controllersShouldNotAccessRepositories =
        noClasses().that().resideInAPackage("..controller..")
            .should().accessClassesThat().resideInAPackage("..repository..");

    @ArchTest
    static final ArchRule servicesShouldNotDependOnControllers =
        noClasses().that().resideInAPackage("..service..")
            .should().dependOnClassesThat().resideInAPackage("..controller..");

    @ArchTest
    static final ArchRule entitiesShouldNotDependOnSpring =
        noClasses().that().areAnnotatedWith(Entity.class)
            .should().dependOnClassesThat()
            .resideInAPackage("org.springframework..");
}
```

### 6. Performance Testing (Medium)

| # | Rule | Description |
|---|------|-------------|
| PT1 | **Use JMH for micro-benchmarks** | `@Benchmark`, `@State`, `@Fork`. Don't use `System.nanoTime()` manually. |
| PT2 | **Warm up before measuring** | JMH handles this with `@Warmup` annotations. |
| PT3 | **Use @BenchmarkMode** | `Throughput`, `AverageTime`, `SampleTime` depending on what you measure. |

### 7. Mutation Testing (Medium)

| # | Rule | Description |
|---|------|-------------|
| MT1 | **Use PIT for mutation testing** | Verifies tests actually catch bugs, not just exercise code. |
| MT2 | **Aim for >80% mutation coverage** | Higher than line coverage — it measures test effectiveness. |

## Quick Reference

```bash
bash skills/java-testing-guidelines/scripts/test-analysis.sh /path/to/project
```
