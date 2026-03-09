---
name: microservices-patterns
description: >
  Microservices architecture patterns for Java/Spring Cloud. Covers service
  discovery, circuit breaking, API gateway, event-driven architecture, saga
  pattern, CQRS, and distributed tracing. Use when designing microservices,
  implementing resilience, or setting up inter-service communication.
  Triggers: "microservice", "circuit breaker", "Resilience4j", "Kafka",
  "service discovery", "API gateway", "saga pattern", "distributed tracing".
---

# Microservices Patterns for Java

Production-grade microservices patterns using Spring Cloud and related frameworks.

## Patterns

### 1. Circuit Breaker with Resilience4j (Critical)

Prevent cascading failures when a downstream service is unavailable.

```java
@Service
public class PaymentService {

    private final PaymentClient paymentClient;

    @CircuitBreaker(name = "payment", fallbackMethod = "paymentFallback")
    @Retry(name = "payment")
    @TimeLimiter(name = "payment")
    public CompletableFuture<PaymentResult> processPayment(PaymentRequest request) {
        return CompletableFuture.supplyAsync(() -> paymentClient.charge(request));
    }

    private CompletableFuture<PaymentResult> paymentFallback(PaymentRequest request, Throwable ex) {
        log.warn("Payment service unavailable, queuing for retry", ex);
        return CompletableFuture.completedFuture(PaymentResult.pending(request.orderId()));
    }
}
```

```yaml
# application.yml
resilience4j:
  circuitbreaker:
    instances:
      payment:
        sliding-window-size: 10
        failure-rate-threshold: 50
        wait-duration-in-open-state: 30s
        permitted-number-of-calls-in-half-open-state: 3
  retry:
    instances:
      payment:
        max-attempts: 3
        wait-duration: 500ms
        exponential-backoff-multiplier: 2
  timelimiter:
    instances:
      payment:
        timeout-duration: 5s
```

### 2. API Gateway (High)

```java
// Spring Cloud Gateway
@Configuration
public class GatewayConfig {

    @Bean
    public RouteLocator routes(RouteLocatorBuilder builder) {
        return builder.routes()
            .route("user-service", r -> r
                .path("/api/v1/users/**")
                .filters(f -> f
                    .circuitBreaker(cb -> cb
                        .setName("user-service")
                        .setFallbackUri("forward:/fallback"))
                    .retry(retry -> retry.setRetries(2))
                    .addRequestHeader("X-Gateway", "true"))
                .uri("lb://user-service"))
            .route("order-service", r -> r
                .path("/api/v1/orders/**")
                .uri("lb://order-service"))
            .build();
    }
}
```

### 3. Event-Driven Architecture with Kafka (High)

```java
// Producer
@Service
public class OrderEventPublisher {

    private final KafkaTemplate<String, OrderEvent> kafkaTemplate;

    public void publishOrderCreated(Order order) {
        var event = new OrderCreatedEvent(order.getId(), order.getUserId(), order.getTotal());
        kafkaTemplate.send("order-events", order.getId().toString(), event);
    }
}

// Consumer
@Component
public class OrderEventListener {

    @KafkaListener(topics = "order-events", groupId = "inventory-service")
    public void handleOrderEvent(OrderCreatedEvent event, Acknowledgment ack) {
        try {
            inventoryService.reserveItems(event.orderId(), event.items());
            ack.acknowledge();
        } catch (InsufficientStockException e) {
            // Publish compensation event
            compensationPublisher.publishReservationFailed(event.orderId());
            ack.acknowledge(); // Don't retry — handle via compensation
        }
    }
}
```

### 4. Saga Pattern (High)

Manage distributed transactions across services using choreography or orchestration.

```java
// Orchestration-based Saga
@Service
public class CreateOrderSaga {

    public Order execute(CreateOrderRequest request) {
        Order order = null;
        try {
            // Step 1: Create order
            order = orderService.createPending(request);

            // Step 2: Reserve inventory
            inventoryService.reserve(order.getId(), request.items());

            // Step 3: Process payment
            paymentService.charge(order.getId(), request.total());

            // Step 4: Confirm order
            orderService.confirm(order.getId());
            return order;

        } catch (PaymentException e) {
            // Compensate: release inventory
            if (order != null) {
                inventoryService.release(order.getId());
                orderService.cancel(order.getId(), "Payment failed");
            }
            throw new OrderCreationException("Payment failed", e);

        } catch (InventoryException e) {
            // Compensate: cancel order
            if (order != null) {
                orderService.cancel(order.getId(), "Insufficient inventory");
            }
            throw new OrderCreationException("Inventory unavailable", e);
        }
    }
}
```

### 5. Distributed Tracing with Micrometer (Medium-High)

```java
// Spring Boot 3+ with Micrometer Tracing
// Dependencies: micrometer-tracing-bridge-otel + opentelemetry-exporter-zipkin

// application.yml
management:
  tracing:
    sampling:
      probability: 1.0  # 100% in dev, lower in prod
  zipkin:
    tracing:
      endpoint: http://zipkin:9411/api/v2/spans

// Custom spans
@Service
public class PaymentService {

    private final ObservationRegistry registry;

    public PaymentResult processPayment(PaymentRequest request) {
        return Observation.createNotStarted("payment.process", registry)
            .lowCardinalityKeyValue("payment.method", request.method().name())
            .observe(() -> doProcessPayment(request));
    }
}
```

### 6. Inter-Service Communication Rules

| # | Rule | Description |
|---|------|-------------|
| IS1 | **Use OpenFeign for synchronous calls** | Declarative HTTP clients with built-in load balancing. |
| IS2 | **Use Kafka/RabbitMQ for async** | Event-driven for eventual consistency. |
| IS3 | **Always set timeouts** | Connection timeout + read timeout on all HTTP clients. |
| IS4 | **Implement idempotency** | Use idempotency keys for write operations to handle retries safely. |
| IS5 | **Use correlation IDs** | Pass trace ID through all service calls for end-to-end tracing. |
| IS6 | **Design for failure** | Every network call can fail. Handle gracefully with fallbacks. |

```java
// Feign client with Resilience4j
@FeignClient(name = "user-service", fallbackFactory = UserClientFallbackFactory.class)
public interface UserClient {

    @GetMapping("/api/v1/users/{id}")
    UserResponse getUser(@PathVariable UUID id);

    @GetMapping("/api/v1/users")
    Page<UserResponse> listUsers(@RequestParam int page, @RequestParam int size);
}
```

For saga implementation patterns, see `references/saga-patterns.md`.
For Kafka configuration guide, see `references/kafka-guide.md`.
