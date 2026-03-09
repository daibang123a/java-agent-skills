# JPA Query Optimization Guide

## Detecting N+1 Queries

Enable Hibernate statistics in development:

```yaml
spring.jpa.properties.hibernate.generate_statistics: true
logging.level.org.hibernate.stat: DEBUG
```

Or use a test assertion:

```java
@Test
void shouldNotHaveNPlusOneQueries() {
    var stats = entityManager.unwrap(SessionImplementor.class)
        .getSessionFactory().getStatistics();
    stats.clear();

    List<Order> orders = orderRepository.findAllWithItems();

    // Assert query count
    assertThat(stats.getPrepareStatementCount()).isLessThanOrEqualTo(2);
}
```

## Fetching Strategies Comparison

| Strategy | Use When | Example |
|----------|----------|---------|
| `JOIN FETCH` | Always need relation, small result set | `SELECT o FROM Order o JOIN FETCH o.items` |
| `@EntityGraph` | Sometimes need relation, want flexibility | `@EntityGraph(attributePaths = "items")` |
| `@BatchSize(25)` | Loading many parents, each with collection | Annotation on collection field |
| `DTO Projection` | Read-only views, reporting | `SELECT new OrderSummary(o.id, o.total) FROM Order o` |
| `@Subselect` | Complex read-only views | Map to a database view |

## DTO Projection Patterns

```java
// Interface projection (simplest)
public interface UserSummary {
    String getName();
    String getEmail();
}
List<UserSummary> findByStatus(UserStatus status);

// Record projection (Java 16+)
public record OrderSummary(UUID id, BigDecimal total, String customerName) {}

@Query("""
    SELECT new com.example.OrderSummary(o.id, o.total, u.name)
    FROM Order o JOIN o.user u
    WHERE o.status = :status
    """)
List<OrderSummary> findSummariesByStatus(@Param("status") OrderStatus status);

// Tuple projection for dynamic queries
@Query("SELECT o.id as id, o.total as total FROM Order o")
List<Tuple> findOrderTuples();
```

## Batch Operations

```java
// Batch insert with JPA
@Transactional
public void batchInsert(List<User> users) {
    for (int i = 0; i < users.size(); i++) {
        entityManager.persist(users.get(i));
        if (i % 50 == 0) {
            entityManager.flush();
            entityManager.clear();
        }
    }
}

// Batch update with Spring Data
@Modifying
@Query("UPDATE User u SET u.status = :status WHERE u.lastLoginAt < :threshold")
int deactivateInactiveUsers(@Param("status") UserStatus status,
                             @Param("threshold") Instant threshold);
```
