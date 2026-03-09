# JPA Entity Mapping Patterns

## Inheritance Strategies

| Strategy | Table Layout | Polymorphic Queries | Performance | Use When |
|----------|-------------|---------------------|-------------|----------|
| `SINGLE_TABLE` | One table, discriminator column | Fast (single table) | Best | Default choice, few columns differ |
| `JOINED` | Table per class, JOINs | Slower (joins) | Medium | Normalized schema, many subtype columns |
| `TABLE_PER_CLASS` | Separate tables, no joins | Slow (UNION) | Worst | Rarely — avoid if possible |

```java
// SINGLE_TABLE (recommended)
@Entity
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "payment_type")
public abstract class Payment {
    @Id @GeneratedValue private Long id;
    private BigDecimal amount;
}

@Entity
@DiscriminatorValue("CREDIT_CARD")
public class CreditCardPayment extends Payment {
    private String cardNumber;
    private String expiryDate;
}

@Entity
@DiscriminatorValue("BANK_TRANSFER")
public class BankTransferPayment extends Payment {
    private String bankAccount;
    private String routingNumber;
}
```

## Composite Keys

```java
// Using @EmbeddedId
@Embeddable
public record OrderItemId(Long orderId, Long productId) implements Serializable {}

@Entity
public class OrderItem {
    @EmbeddedId
    private OrderItemId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("orderId")
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("productId")
    private Product product;

    private int quantity;
}
```

## Auditing with Spring Data

```java
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class AuditableEntity {

    @CreatedDate
    @Column(updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;

    @CreatedBy
    @Column(updatable = false)
    private String createdBy;

    @LastModifiedBy
    private String updatedBy;

    @Version
    private Long version;
}

// Enable with @EnableJpaAuditing
@Configuration
@EnableJpaAuditing(auditorAwareRef = "auditorProvider")
public class JpaConfig {
    @Bean
    public AuditorAware<String> auditorProvider() {
        return () -> Optional.ofNullable(SecurityContextHolder.getContext())
            .map(SecurityContext::getAuthentication)
            .filter(Authentication::isAuthenticated)
            .map(Authentication::getName);
    }
}
```

## Value Objects as @Embeddable

```java
@Embeddable
public record Money(
    @Column(name = "amount", precision = 19, scale = 4) BigDecimal amount,
    @Column(name = "currency", length = 3) String currency
) {
    public Money {
        Objects.requireNonNull(amount);
        Objects.requireNonNull(currency);
        if (amount.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Amount cannot be negative");
        }
    }
}

@Entity
public class Product {
    @Id @GeneratedValue private Long id;
    private String name;

    @Embedded
    @AttributeOverrides({
        @AttributeOverride(name = "amount", column = @Column(name = "price_amount")),
        @AttributeOverride(name = "currency", column = @Column(name = "price_currency"))
    })
    private Money price;
}
```

## Soft Delete Pattern

```java
@Entity
@SQLRestriction("deleted = false")  // Hibernate 6.4+
public class User {
    @Id @GeneratedValue private Long id;
    private String name;
    private boolean deleted = false;
    private Instant deletedAt;

    public void softDelete() {
        this.deleted = true;
        this.deletedAt = Instant.now();
    }
}
```
