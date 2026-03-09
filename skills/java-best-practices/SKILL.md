---
name: java-best-practices
description: >
  Core Java performance optimization and idiomatic coding guidelines with 60+
  rules across 10 categories. Covers memory, collections, streams, records,
  sealed classes, and modern Java 17-21+ features. Use when writing new Java
  code, reviewing for performance issues, or modernizing legacy code.
  Triggers: "Review my Java code", "Optimize Java performance", "Modern Java",
  "Java best practices", "Migrate to Java 17/21".
---

# Java Best Practices

Performance optimization and idiomatic Java coding guidelines. 60+ rules across 10 categories, targeting Java 17+ with Java 21+ enhancements clearly marked.

## How It Works

1. Agent receives Java code to write or review
2. Agent loads this skill and applies relevant rules by category
3. Rules are applied in priority order: Critical → High → Medium → Low
4. Agent provides specific, actionable feedback with code examples

## Rules

### 1. Memory & GC Optimization (Critical)

| # | Rule | Description |
|---|------|-------------|
| M1 | **Avoid unnecessary object creation** | Reuse immutable objects. Use `Integer.valueOf()` (cached -128 to 127), `Boolean.TRUE/FALSE`, `String` interning for constants. |
| M2 | **Pre-size collections** | `new ArrayList<>(expectedSize)`, `new HashMap<>(capacity, 0.75f)`. Avoids repeated resizing and rehashing. |
| M3 | **Use primitive specializations** | Prefer `int[]` over `List<Integer>`. Use `IntStream`, `LongStream`, `DoubleStream` to avoid boxing. |
| M4 | **Close resources with try-with-resources** | All `AutoCloseable` resources must be in try-with-resources blocks. Never rely on `finalize()`. |
| M5 | **Avoid memory leaks in collections** | Remove unused entries from static collections. Use `WeakHashMap` for caches. Clear event listeners on dispose. |
| M6 | **Use StringBuilder for loops** | Never concatenate strings with `+` in loops. Use `StringBuilder` or `StringJoiner`. |
| M7 | **Prefer stack allocation** | Small short-lived objects may benefit from escape analysis. Avoid unnecessary `new` in hot paths. |
| M8 | **Be careful with large byte arrays** | Arrays >50% of a G1 region become humongous objects with special GC treatment. Split if possible. |

### 2. Collections & Data Structures (Critical)

| # | Rule | Description |
|---|------|-------------|
| C1 | **Choose the right collection** | `ArrayList` for random access, `LinkedList` almost never, `ArrayDeque` for stacks/queues, `EnumSet`/`EnumMap` for enum keys. |
| C2 | **Use unmodifiable collections** | `List.of()`, `Map.of()`, `Set.of()`, `Collections.unmodifiableList()`. Prevent accidental mutation. |
| C3 | **Use Map.computeIfAbsent** | Replace check-then-put patterns: `map.computeIfAbsent(key, k -> new ArrayList<>()).add(value)`. |
| C4 | **Iterate efficiently** | Use enhanced for-loop or `forEach`. Avoid `get(i)` on `LinkedList`. Use `Iterator` for concurrent removal. |
| C5 | **Use specialized collections** | `BitSet` for boolean flags, `EnumSet` for enum combinations, `ConcurrentHashMap` for concurrent access. |
| C6 | **Implement equals/hashCode correctly** | Use `Objects.equals()`, `Objects.hash()`. Override both or neither. Records generate them automatically. |
| C7 | **Return empty collections, not null** | `Collections.emptyList()`, `List.of()`. Never return `null` from a method returning a collection. |

### 3. Exception Handling (Critical)

| # | Rule | Description |
|---|------|-------------|
| E1 | **Catch specific exceptions** | Never `catch (Exception e)` unless rethrowing. Catch the narrowest exception type. |
| E2 | **Don't swallow exceptions** | Never empty catch blocks. Log or rethrow with context. |
| E3 | **Use unchecked exceptions for programming errors** | `IllegalArgumentException`, `IllegalStateException`, `NullPointerException`. Don't create checked exceptions for bugs. |
| E4 | **Wrap exceptions with context** | `throw new ServiceException("Failed to process order " + orderId, cause)`. Preserve the cause chain. |
| E5 | **Use Optional instead of null** | Return `Optional<T>` for values that may be absent. Never use Optional as a field or parameter. |
| E6 | **Don't use exceptions for control flow** | Exceptions are expensive. Use conditional checks for expected cases. |
| E7 | **Define domain exception hierarchy** | Base `DomainException`, then `NotFoundException`, `ConflictException`, `ValidationException`. |

### 4. Stream API & Functional Patterns (High)

| # | Rule | Description |
|---|------|-------------|
| S1 | **Prefer streams for transformations** | `map`, `filter`, `collect` for data pipelines. Don't force streams where a for-loop is clearer. |
| S2 | **Use method references** | `list.stream().map(String::toUpperCase)` over `s -> s.toUpperCase()`. |
| S3 | **Avoid side effects in streams** | Don't modify external state in `map` or `filter`. Use `forEach` only for terminal side effects. |
| S4 | **Use Collectors wisely** | `toList()` (Java 16+), `toMap()`, `groupingBy()`, `partitioningBy()`. Know when to use `toUnmodifiableList()`. |
| S5 | **Parallel streams are rarely needed** | Only for CPU-bound work on large datasets. Never for I/O. Measure before parallelizing. |
| S6 | **Use flatMap for nested structures** | `orders.stream().flatMap(o -> o.getItems().stream())`. |
| S7 | **Short-circuit when possible** | `findFirst()`, `findAny()`, `anyMatch()`, `limit()` stop processing early. |

### 5. Modern Java Features (High)

| # | Rule | Description |
|---|------|-------------|
| J1 | **Use Records for data carriers** | `record Point(int x, int y) {}`. Immutable, auto-generated equals/hashCode/toString. |
| J2 | **Use Sealed classes for type hierarchies** | `sealed interface Shape permits Circle, Rectangle`. Exhaustive pattern matching. |
| J3 | **Use Pattern Matching** | `if (obj instanceof String s)` (Java 16+). Switch pattern matching (Java 21+). |
| J4 | **Use Text Blocks for multi-line strings** | Triple-quote `"""` for JSON, SQL, HTML templates. |
| J5 | **Use var for local variables** | `var list = new ArrayList<String>()`. Only when the type is obvious from context. |
| J6 | **Use switch expressions** | `var result = switch(day) { case MON -> "Monday"; ... };` with arrow syntax. |
| J7 | **Use Virtual Threads (Java 21+)** | `Thread.ofVirtual().start(task)` or `Executors.newVirtualThreadPerTaskExecutor()` for I/O-bound work. |

```java
// Records (Java 16+)
public record CreateUserRequest(
    @NotBlank String name,
    @Email String email,
    @NotNull Role role
) {}

// Sealed classes (Java 17+)
public sealed interface PaymentResult
    permits PaymentSuccess, PaymentFailure, PaymentPending {
}
public record PaymentSuccess(String transactionId, BigDecimal amount) implements PaymentResult {}
public record PaymentFailure(String errorCode, String message) implements PaymentResult {}
public record PaymentPending(String pendingId) implements PaymentResult {}

// Pattern matching switch (Java 21+)
String describe(PaymentResult result) {
    return switch (result) {
        case PaymentSuccess s -> "Paid " + s.amount();
        case PaymentFailure f -> "Failed: " + f.message();
        case PaymentPending p -> "Pending: " + p.pendingId();
    };
}
```

### 6. String & Text Processing (Medium-High)

| # | Rule | Description |
|---|------|-------------|
| T1 | **Use String.formatted() or format()** | `"Hello %s, age %d".formatted(name, age)` over concatenation for complex strings. |
| T2 | **Use StringJoiner for delimited output** | `new StringJoiner(", ", "[", "]")` or `String.join(", ", list)`. |
| T3 | **Prefer equals() with constant first** | `"admin".equals(role)` avoids NullPointerException. Or use `Objects.equals()`. |
| T4 | **Use strip() not trim()** | `strip()` handles Unicode whitespace. `stripLeading()`, `stripTrailing()` for partial. |
| T5 | **Use isBlank() not isEmpty()** | `isBlank()` checks for whitespace-only strings too. |

### 7. Generics & Type Safety (Medium)

| # | Rule | Description |
|---|------|-------------|
| G1 | **Prefer generic methods** | `<T> List<T> filter(List<T> items, Predicate<T> p)` over raw types. |
| G2 | **Use bounded wildcards** | `List<? extends Number>` for producers, `List<? super Integer>` for consumers (PECS). |
| G3 | **Avoid raw types** | Never `List list = new ArrayList()`. Always parameterize: `List<String>`. |
| G4 | **Use @SafeVarargs on safe varargs methods** | Suppress the unchecked warning when you know it's safe. |

### 8. Immutability & Thread Safety (Medium)

| # | Rule | Description |
|---|------|-------------|
| I1 | **Prefer immutable objects** | Final fields, no setters, defensive copies. Records are immutable by default. |
| I2 | **Make fields final by default** | `private final` for all fields. Only relax when mutation is necessary. |
| I3 | **Return defensive copies** | `return List.copyOf(items)` not `return items` for mutable collections in getters. |
| I4 | **Use @Immutable or document thread safety** | Annotate thread-safe classes. Document if a class is NOT thread-safe. |

### 9. Annotations & Reflection (Low-Medium)

| # | Rule | Description |
|---|------|-------------|
| A1 | **Don't overuse custom annotations** | Only create annotations when they drive code generation or framework behavior. |
| A2 | **Avoid reflection in hot paths** | Reflection is slow. Cache `Method`/`Field` handles. Consider `MethodHandle` for performance. |
| A3 | **Use @Override always** | Compiler catches typos in method signatures. |
| A4 | **Use @SuppressWarnings narrowly** | Apply to the smallest scope, always with a comment explaining why. |

### 10. Code Style & Naming (Low)

| # | Rule | Description |
|---|------|-------------|
| Y1 | **Follow standard naming** | `camelCase` methods/variables, `PascalCase` classes, `UPPER_SNAKE` constants. |
| Y2 | **Keep methods short** | Methods over 30 lines are usually doing too much. Extract helper methods. |
| Y3 | **Use early returns** | Reduce nesting by handling error cases first. |
| Y4 | **One class per file** | Exception: small private helper classes or records. |
| Y5 | **Javadoc on public API** | All public classes and methods must have Javadoc. |
| Y6 | **Use meaningful names** | `userService` not `us`. `calculateTotal` not `calc`. |

## Quick Reference

Run the analysis script:

```bash
bash skills/java-best-practices/scripts/code-analysis.sh /path/to/project
```

For collection performance characteristics, see `references/collections-guide.md`.
For GC tuning guide, see `references/gc-tuning.md`.
