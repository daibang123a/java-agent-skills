---
name: jpa-hibernate-patterns
description: >
  JPA/Hibernate data access patterns and performance optimization. 50+ rules
  covering entity design, N+1 queries, fetching strategies, caching,
  transactions, and Spring Data JPA. Use when designing JPA entities,
  optimizing Hibernate, debugging N+1 problems, or implementing repositories.
  Triggers: "N+1 query", "JPA entity", "Hibernate performance", "Spring Data JPA",
  "lazy loading", "entity mapping", "database query optimization".
---

# JPA & Hibernate Patterns

Production-grade JPA/Hibernate patterns. 50+ rules covering entity design, query optimization, caching, and Spring Data JPA for Hibernate 6.4+.

## How It Works

1. Agent examines JPA entities, repositories, and query code
2. Agent applies rules by category to identify performance issues
3. Agent suggests optimized patterns with concrete code examples
4. Agent checks for common Hibernate pitfalls (N+1, lazy init, etc.)

## Rules

### 1. Entity Design (Critical)

| # | Rule | Description |
|---|------|-------------|
| ED1 | **Use @Id with proper generation** | `@GeneratedValue(strategy = IDENTITY)` for auto-increment, `SEQUENCE` for batch inserts. |
| ED2 | **Use natural IDs when appropriate** | `@NaturalId` for business keys (email, ISBN). Speeds up lookup without surrogate key. |
| ED3 | **Implement equals/hashCode on business key** | Never on `@Id` for new entities. Use business key or UUID. |
| ED4 | **Prefer UUID over Long for distributed** | `UUID.randomUUID()` assigned in constructor for portability across systems. |
| ED5 | **Map relationships bidirectionally only when needed** | Bidirectional adds complexity. Use unidirectional `@ManyToOne` by default. |
| ED6 | **Use @ManyToOne, avoid @OneToMany where possible** | `@ManyToOne` is the owning side. `@OneToMany` causes extra queries if not careful. |
| ED7 | **Never use CascadeType.ALL blindly** | Only cascade what makes domain sense. `PERSIST` and `MERGE` are usually sufficient. |
| ED8 | **Use @Enumerated(EnumType.STRING)** | Never `ORDINAL` — adding/reordering enum values breaks data. |

```java
@Entity
@Table(name = "orders")
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, updatable = false)
    private UUID orderNumber;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @OneToMany(mappedBy = "order", cascade = {CascadeType.PERSIST, CascadeType.MERGE},
               orphanRemoval = true)
    private List<OrderItem> items = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OrderStatus status;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    protected Order() {} // JPA requires no-arg constructor

    public Order(User user) {
        this.orderNumber = UUID.randomUUID();
        this.user = user;
        this.status = OrderStatus.PENDING;
        this.createdAt = Instant.now();
    }

    public void addItem(Product product, int quantity) {
        items.add(new OrderItem(this, product, quantity));
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Order other)) return false;
        return orderNumber != null && orderNumber.equals(other.orderNumber);
    }

    @Override
    public int hashCode() {
        return Objects.hash(orderNumber);
    }
}
```

### 2. N+1 Problem & Fetching (Critical)

| # | Rule | Description |
|---|------|-------------|
| N1 | **Default to FetchType.LAZY** | All relationships should be LAZY. Eager fetching causes unnecessary queries. |
| N2 | **Use JOIN FETCH for known needs** | `SELECT o FROM Order o JOIN FETCH o.items WHERE o.id = :id`. |
| N3 | **Use @EntityGraph for dynamic fetching** | Named or ad-hoc graphs: `@EntityGraph(attributePaths = {"items", "user"})`. |
| N4 | **Use @BatchSize for collections** | `@BatchSize(size = 25)` fetches 25 collections in one query instead of N. |
| N5 | **Use projections for read-only** | DTO projections avoid loading full entities: `SELECT new UserSummary(u.id, u.name) FROM User u`. |
| N6 | **Enable SQL logging in dev** | `spring.jpa.show-sql=false`, use `logging.level.org.hibernate.SQL=DEBUG` + `org.hibernate.orm.jdbc.bind=TRACE`. |
| N7 | **Use Hibernate statistics** | `spring.jpa.properties.hibernate.generate_statistics=true` in dev to count queries. |

```java
// BAD: N+1 — loads each user's orders in separate queries
List<User> users = userRepository.findAll();
users.forEach(u -> u.getOrders().size()); // N+1!

// GOOD: JOIN FETCH
@Query("SELECT u FROM User u LEFT JOIN FETCH u.orders WHERE u.status = :status")
List<User> findByStatusWithOrders(@Param("status") UserStatus status);

// GOOD: EntityGraph
@EntityGraph(attributePaths = {"orders", "orders.items"})
List<User> findByStatus(UserStatus status);

// GOOD: DTO Projection (best for read-only)
public interface UserSummary {
    UUID getId();
    String getName();
    String getEmail();
    long getOrderCount(); // from @Formula or native query
}

@Query("SELECT u.id as id, u.name as name, u.email as email, COUNT(o) as orderCount " +
       "FROM User u LEFT JOIN u.orders o GROUP BY u.id, u.name, u.email")
List<UserSummary> findUserSummaries();
```

### 3. Transaction Management (High)

| # | Rule | Description |
|---|------|-------------|
| TX1 | **Use @Transactional on service layer** | Not on repositories (Spring Data adds them) or controllers. |
| TX2 | **Use readOnly=true for reads** | `@Transactional(readOnly = true)` enables flush-mode MANUAL, skip dirty checking. |
| TX3 | **Keep transactions short** | No HTTP calls inside transactions. Don't hold locks longer than necessary. |
| TX4 | **Use REQUIRES_NEW carefully** | Creates a new transaction. Use for audit logs or independent operations. |
| TX5 | **Handle optimistic locking** | `@Version` field + catch `OptimisticLockException` and retry. |
| TX6 | **Use @Transactional on class for default** | Override on methods that need different behavior. |

```java
@Service
@Transactional(readOnly = true) // default for all methods
public class OrderService {

    @Transactional // overrides readOnly for write operations
    public Order createOrder(CreateOrderRequest request) {
        // ...
    }

    public Page<OrderResponse> findAll(Pageable pageable) {
        // readOnly = true from class-level annotation
    }
}
```

### 4. Spring Data JPA (Medium-High)

| # | Rule | Description |
|---|------|-------------|
| SD1 | **Use derived query methods for simple queries** | `findByEmailAndStatus(String email, Status status)`. |
| SD2 | **Use @Query for complex queries** | JPQL or native SQL when derived methods become unreadable. |
| SD3 | **Use Pageable and Page** | `Page<User> findByStatus(Status status, Pageable pageable)`. |
| SD4 | **Use Specification for dynamic queries** | `JpaSpecificationExecutor<T>` for filter-based search. |
| SD5 | **Custom repository for complex logic** | `UserRepositoryCustom` interface + `UserRepositoryImpl`. |
| SD6 | **Use @Modifying for UPDATE/DELETE** | `@Modifying @Query("UPDATE User u SET u.status = :status WHERE u.id = :id")`. |
| SD7 | **Flush after @Modifying** | `@Modifying(clearAutomatically = true)` to refresh persistence context. |

### 5. Caching (High)

| # | Rule | Description |
|---|------|-------------|
| CA1 | **Don't disable first-level cache** | It's per-session and prevents duplicate fetches within a transaction. |
| CA2 | **Use second-level cache selectively** | Only for frequently read, rarely written entities. Enable with `@Cacheable`. |
| CA3 | **Use query cache with caution** | Invalidated on any table change. Useful only for truly static data. |
| CA4 | **Use Spring Cache (@Cacheable) for service layer** | Cache at the service level, not JPA level, for more control. |

### 6. Schema Migration (Medium)

| # | Rule | Description |
|---|------|-------------|
| MG1 | **Never use hibernate.ddl-auto in production** | Always `none` or `validate`. Use Flyway or Liquibase. |
| MG2 | **Use Flyway for versioned migrations** | `V1__Create_users.sql`, `V2__Add_orders.sql`. Sequential and repeatable. |
| MG3 | **Test migrations** | Run up and down in CI with real database containers. |

```yaml
# application.yml
spring:
  jpa:
    hibernate:
      ddl-auto: validate  # NEVER 'update' or 'create' in production
  flyway:
    enabled: true
    locations: classpath:db/migration
```

## Quick Reference

Run the JPA audit script:

```bash
bash skills/jpa-hibernate-patterns/scripts/jpa-audit.sh /path/to/project
```

For entity mapping patterns, see `references/entity-mapping.md`.
For query optimization guide, see `references/query-optimization.md`.
