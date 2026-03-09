# Virtual Threads Guide (Java 21+)

## When to Use Virtual Threads vs Platform Threads

| Workload | Virtual Threads | Platform Threads |
|----------|----------------|------------------|
| HTTP API serving (I/O-bound) | ✅ Ideal | Wasted resources |
| Database queries | ✅ Ideal | Acceptable |
| File I/O | ✅ Ideal | Acceptable |
| CPU-heavy computation | ❌ No benefit | ✅ Use fixed pool |
| Long-running background tasks | ⚠️ Test carefully | ✅ Dedicated threads |

## Spring Boot Integration

```yaml
# application.yml — enables virtual threads for request handling
spring:
  threads:
    virtual:
      enabled: true
```

This makes Tomcat use virtual threads for every request. No thread pool tuning needed.

## Pinning Prevention

Virtual threads "pin" to carrier threads inside `synchronized` blocks. This limits concurrency.

```java
// BAD: pins carrier thread during I/O
synchronized (lock) {
    database.query(sql);  // I/O inside synchronized — pinned!
}

// GOOD: use ReentrantLock instead
private final ReentrantLock lock = new ReentrantLock();

lock.lock();
try {
    database.query(sql);  // I/O with ReentrantLock — not pinned
} finally {
    lock.unlock();
}
```

Detect pinning with: `-Djdk.tracePinnedThreads=short`

## ThreadLocal Considerations

Virtual threads can use ThreadLocal, but because millions can exist, be careful with memory:

```java
// BAD: heavy ThreadLocal with millions of virtual threads
private static final ThreadLocal<byte[]> BUFFER =
    ThreadLocal.withInitial(() -> new byte[1024 * 1024]); // 1MB per thread!

// GOOD: use ScopedValue (Java 21 Preview) for request-scoped data
private static final ScopedValue<RequestContext> CONTEXT = ScopedValue.newInstance();

ScopedValue.where(CONTEXT, new RequestContext(requestId))
    .run(() -> handleRequest());
```

## Migration Checklist

1. ✅ Replace `Executors.newFixedThreadPool(N)` with `newVirtualThreadPerTaskExecutor()` for I/O work
2. ✅ Replace `synchronized` with `ReentrantLock` where I/O happens inside
3. ✅ Remove thread pool sizing configs (virtual threads don't need pooling)
4. ✅ Set `spring.threads.virtual.enabled=true` for Spring Boot
5. ⚠️ Test with `-Djdk.tracePinnedThreads=short` to find pinning
6. ⚠️ Review ThreadLocal usage for memory impact
7. ❌ Don't pool virtual threads — create new ones per task
