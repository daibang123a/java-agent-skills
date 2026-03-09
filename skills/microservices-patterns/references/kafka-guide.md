# Kafka Configuration Guide for Spring Boot

## Producer Configuration

```yaml
spring:
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
      acks: all                    # Wait for all replicas
      retries: 3
      properties:
        enable.idempotence: true   # Exactly-once semantics
        max.in.flight.requests.per.connection: 5
```

## Consumer Configuration

```yaml
spring:
  kafka:
    consumer:
      group-id: ${spring.application.name}
      auto-offset-reset: earliest
      enable-auto-commit: false    # Manual ack for reliability
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
      properties:
        spring.json.trusted.packages: "com.example.*"
    listener:
      ack-mode: manual             # Manual acknowledgment
      concurrency: 3               # Number of consumer threads
```

## Error Handling

```java
@Configuration
public class KafkaConfig {

    @Bean
    public DefaultErrorHandler errorHandler(KafkaTemplate<String, Object> template) {
        // Dead letter topic for failed messages
        DeadLetterPublishingRecoverer recoverer =
            new DeadLetterPublishingRecoverer(template);

        // Retry 3 times with backoff, then send to DLT
        return new DefaultErrorHandler(recoverer,
            new FixedBackOff(1000L, 3));
    }
}
```

## Idempotent Consumer Pattern

```java
@Component
public class OrderEventListener {

    private final ProcessedEventRepository processedEvents;

    @KafkaListener(topics = "order-events")
    public void handle(OrderCreatedEvent event, Acknowledgment ack) {
        String eventId = event.eventId();

        // Idempotency check
        if (processedEvents.existsById(eventId)) {
            ack.acknowledge();
            return;
        }

        try {
            processOrder(event);
            processedEvents.save(new ProcessedEvent(eventId, Instant.now()));
            ack.acknowledge();
        } catch (Exception e) {
            // Don't ack — will be retried
            throw e;
        }
    }
}
```
