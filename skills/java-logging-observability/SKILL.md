---
name: java-logging-observability
description: >
  Java logging, metrics, and observability best practices. Covers SLF4J/Logback,
  structured logging with MDC, Micrometer metrics, OpenTelemetry, Spring Boot
  Actuator, and health checks. Use when setting up logging, adding metrics,
  integrating tracing, or configuring monitoring. Triggers: "logging", "SLF4J",
  "Logback", "structured logging", "MDC", "metrics", "Micrometer",
  "OpenTelemetry", "health check", "Actuator", "monitoring".
---

# Java Logging & Observability

Production-grade logging, metrics, and tracing for Java applications.

## Rules

### 1. SLF4J & Logback (Critical)

| # | Rule | Description |
|---|------|-------------|
| L1 | **Use SLF4J as the logging facade** | `private static final Logger log = LoggerFactory.getLogger(MyClass.class)`. |
| L2 | **Use parameterized logging** | `log.info("User {} created", userId)` — not string concatenation. |
| L3 | **Log at correct levels** | ERROR: failures needing attention. WARN: degraded. INFO: lifecycle. DEBUG: diagnostic. TRACE: verbose. |
| L4 | **Never log sensitive data** | Mask passwords, tokens, PII. |
| L5 | **Include context in log messages** | `log.info("Order {} processed for user {}", orderId, userId)`. |
| L6 | **Use Lombok @Slf4j** | Or define the logger field manually. Be consistent across the project. |
| L7 | **Check level before expensive ops** | `if (log.isDebugEnabled()) log.debug("Details: {}", expensiveToString())`. |

### 2. Structured Logging & MDC (High)

```java
// MDC (Mapped Diagnostic Context) — per-request context
@Component
public class RequestIdFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request,
            HttpServletResponse response, FilterChain chain) throws Exception {
        String requestId = Optional.ofNullable(request.getHeader("X-Request-Id"))
            .orElse(UUID.randomUUID().toString());

        MDC.put("requestId", requestId);
        MDC.put("userId", extractUserId(request));
        response.setHeader("X-Request-Id", requestId);

        try {
            chain.doFilter(request, response);
        } finally {
            MDC.clear();
        }
    }
}
```

```xml
<!-- logback-spring.xml — JSON structured logging for production -->
<configuration>
    <springProfile name="prod">
        <appender name="JSON" class="ch.qos.logback.core.ConsoleAppender">
            <encoder class="net.logstash.logback.encoder.LogstashEncoder">
                <includeMdcKeyName>requestId</includeMdcKeyName>
                <includeMdcKeyName>userId</includeMdcKeyName>
                <includeMdcKeyName>traceId</includeMdcKeyName>
            </encoder>
        </appender>
        <root level="INFO">
            <appender-ref ref="JSON" />
        </root>
    </springProfile>

    <springProfile name="dev">
        <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
            <encoder>
                <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} [%mdc] - %msg%n</pattern>
            </encoder>
        </appender>
        <root level="DEBUG">
            <appender-ref ref="CONSOLE" />
        </root>
    </springProfile>
</configuration>
```

### 3. Micrometer Metrics (High)

```java
// Custom metrics
@Service
public class OrderService {

    private final Counter orderCounter;
    private final Timer orderProcessingTimer;
    private final DistributionSummary orderAmountSummary;

    public OrderService(MeterRegistry registry) {
        this.orderCounter = Counter.builder("orders.created")
            .description("Number of orders created")
            .tag("service", "order-service")
            .register(registry);

        this.orderProcessingTimer = Timer.builder("orders.processing.time")
            .description("Time to process an order")
            .publishPercentiles(0.5, 0.95, 0.99)
            .register(registry);

        this.orderAmountSummary = DistributionSummary.builder("orders.amount")
            .description("Order amounts")
            .baseUnit("usd")
            .register(registry);
    }

    public Order createOrder(CreateOrderRequest request) {
        return orderProcessingTimer.record(() -> {
            Order order = processOrder(request);
            orderCounter.increment();
            orderAmountSummary.record(order.getTotal().doubleValue());
            return order;
        });
    }
}

// @Timed annotation (simpler)
@Timed(value = "users.find", description = "Time to find user by ID")
public User findById(UUID id) {
    return userRepository.findById(id)
        .orElseThrow(() -> new NotFoundException("User not found"));
}
```

### 4. Spring Boot Actuator (Medium)

```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: health, metrics, info, prometheus
  endpoint:
    health:
      show-details: when-authorized
      probes:
        enabled: true  # Kubernetes liveness/readiness
  health:
    diskspace:
      enabled: true
    db:
      enabled: true
  metrics:
    export:
      prometheus:
        enabled: true
    tags:
      application: ${spring.application.name}
```

```java
// Custom health indicator
@Component
public class PaymentServiceHealthIndicator implements HealthIndicator {

    private final PaymentClient paymentClient;

    @Override
    public Health health() {
        try {
            paymentClient.healthCheck();
            return Health.up()
                .withDetail("service", "payment")
                .withDetail("status", "reachable")
                .build();
        } catch (Exception e) {
            return Health.down()
                .withDetail("service", "payment")
                .withDetail("error", e.getMessage())
                .build();
        }
    }
}
```

### 5. OpenTelemetry Integration (Medium-High)

```xml
<!-- pom.xml dependencies -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-tracing-bridge-otel</artifactId>
</dependency>
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-otlp</artifactId>
</dependency>
```

```yaml
management:
  tracing:
    sampling:
      probability: 0.1  # 10% sampling in production
  otlp:
    tracing:
      endpoint: http://otel-collector:4318/v1/traces
```

## Key Metrics to Expose

| Metric | Type | Description |
|--------|------|-------------|
| `http.server.requests` | Timer | Request latency by URI, method, status |
| `jvm.memory.used` | Gauge | Heap and non-heap memory |
| `jvm.gc.pause` | Timer | GC pause durations |
| `db.pool.active` | Gauge | Active database connections |
| `orders.created` | Counter | Business metric: orders created |
| `orders.processing.time` | Timer | Business metric: order processing time |

For Logback configuration examples, see `references/logback-configs.md`.
