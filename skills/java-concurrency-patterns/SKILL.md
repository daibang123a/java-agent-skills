---
name: java-concurrency-patterns
description: >
  Java concurrency patterns using modern APIs — virtual threads (Java 21+),
  CompletableFuture, structured concurrency, and concurrent collections.
  Use when designing concurrent systems, using virtual threads, building
  async pipelines, or debugging thread safety issues. Triggers: "virtual threads",
  "CompletableFuture", "thread pool", "concurrent Java", "async", "parallel",
  "thread safety", "deadlock".
---

# Java Concurrency Patterns

Production-grade concurrency patterns for modern Java (17-21+). Each pattern includes when to use, implementation, and pitfalls.

## How It Works

1. Agent identifies the concurrency need from the task description
2. Agent selects the appropriate pattern(s) from this catalog
3. Agent implements with proper error handling and thread safety
4. Agent verifies correctness considerations (visibility, atomicity, ordering)

## Patterns

### 1. Virtual Threads — Java 21+ (Critical)

Lightweight threads managed by the JVM. Use for I/O-bound work. One virtual thread per task.

```java
// Simple virtual thread
Thread.ofVirtual().name("worker").start(() -> {
    var result = httpClient.send(request, BodyHandlers.ofString());
    process(result);
});

// Virtual thread executor — the default for I/O-bound services
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    List<Future<Response>> futures = requests.stream()
        .map(req -> executor.submit(() -> httpClient.send(req, BodyHandlers.ofString())))
        .toList();

    for (var future : futures) {
        process(future.get());
    }
}

// Spring Boot — enable globally
// application.yml: spring.threads.virtual.enabled: true
```

**Pitfalls:**
- Don't pool virtual threads — create new ones per task
- Avoid `synchronized` blocks with I/O inside — pins the carrier thread. Use `ReentrantLock` instead
- Virtual threads don't make CPU-bound work faster — use parallel streams for that

### 2. Structured Concurrency — Java 21+ Preview (Critical)

Treat concurrent tasks as a unit. If one fails, cancel siblings.

```java
// All-or-nothing: both must succeed
try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
    Subtask<User> userTask = scope.fork(() -> userService.findById(userId));
    Subtask<List<Order>> ordersTask = scope.fork(() -> orderService.findByUser(userId));

    scope.join().throwIfFailed();

    return new UserProfile(userTask.get(), ordersTask.get());
}

// First success wins (e.g., querying multiple replicas)
try (var scope = new StructuredTaskScope.ShutdownOnSuccess<String>()) {
    scope.fork(() -> queryReplica1(key));
    scope.fork(() -> queryReplica2(key));
    scope.fork(() -> queryReplica3(key));

    scope.join();
    return scope.result();
}
```

### 3. CompletableFuture Pipelines (High)

Composable async operations without blocking.

```java
public CompletableFuture<OrderResult> processOrder(OrderRequest request) {
    return CompletableFuture
        .supplyAsync(() -> validateOrder(request))
        .thenCompose(validated -> checkInventory(validated))
        .thenCombine(
            calculateShipping(request),
            (inventory, shipping) -> new OrderDetails(inventory, shipping)
        )
        .thenApplyAsync(details -> chargePayment(details))
        .thenApply(payment -> createOrder(request, payment))
        .exceptionally(ex -> {
            log.error("Order processing failed", ex);
            return OrderResult.failed(ex.getMessage());
        });
}

// Waiting for all futures
CompletableFuture<Void> allDone = CompletableFuture.allOf(
    future1, future2, future3
);

// Waiting for any future
CompletableFuture<Object> anyDone = CompletableFuture.anyOf(
    future1, future2, future3
);

// Timeout (Java 9+)
future.orTimeout(5, TimeUnit.SECONDS)
      .completeOnTimeout(defaultValue, 5, TimeUnit.SECONDS);
```

### 4. ExecutorService Patterns (High)

| Executor | Use Case | Thread Count |
|----------|----------|--------------|
| `newVirtualThreadPerTaskExecutor()` | I/O-bound (Java 21+) | Unlimited virtual |
| `newFixedThreadPool(N)` | CPU-bound work | N = CPU cores |
| `newCachedThreadPool()` | Short-lived bursts | Unbounded (careful!) |
| `newScheduledThreadPool(N)` | Periodic tasks | N based on task count |
| `newWorkStealingPool()` | Fork/join parallelism | CPU cores |

```java
// Proper shutdown pattern
ExecutorService executor = Executors.newFixedThreadPool(
    Runtime.getRuntime().availableProcessors()
);

Runtime.getRuntime().addShutdownHook(new Thread(() -> {
    executor.shutdown();
    try {
        if (!executor.awaitTermination(30, TimeUnit.SECONDS)) {
            executor.shutdownNow();
        }
    } catch (InterruptedException e) {
        executor.shutdownNow();
        Thread.currentThread().interrupt();
    }
}));
```

### 5. Concurrent Collections (Medium-High)

| Collection | Thread-Safe | Lock Type | Use When |
|-----------|-------------|-----------|----------|
| `ConcurrentHashMap` | Yes | Segment locks | Shared key-value cache |
| `CopyOnWriteArrayList` | Yes | Copy on write | Few writes, many reads |
| `BlockingQueue` | Yes | Locks | Producer-consumer |
| `ConcurrentLinkedQueue` | Yes | Lock-free | Non-blocking queue |
| `Collections.synchronizedMap` | Yes | Full lock | Avoid — prefer ConcurrentHashMap |

```java
// ConcurrentHashMap — compute patterns
ConcurrentHashMap<String, LongAdder> counters = new ConcurrentHashMap<>();
counters.computeIfAbsent("requests", k -> new LongAdder()).increment();

// BlockingQueue — producer-consumer
BlockingQueue<Task> queue = new LinkedBlockingQueue<>(1000);

// Producer
executor.submit(() -> {
    while (!Thread.currentThread().isInterrupted()) {
        Task task = generateTask();
        queue.put(task); // blocks if full
    }
});

// Consumer
executor.submit(() -> {
    while (!Thread.currentThread().isInterrupted()) {
        Task task = queue.take(); // blocks if empty
        process(task);
    }
});
```

### 6. Lock Patterns (Medium)

```java
// ReentrantLock — prefer over synchronized for virtual threads
private final ReentrantLock lock = new ReentrantLock();

public void safeUpdate() {
    lock.lock();
    try {
        // critical section
    } finally {
        lock.unlock();
    }
}

// ReadWriteLock — multiple concurrent readers, exclusive writers
private final ReadWriteLock rwLock = new ReentrantReadWriteLock();

public Data read() {
    rwLock.readLock().lock();
    try { return data; }
    finally { rwLock.readLock().unlock(); }
}

public void write(Data newData) {
    rwLock.writeLock().lock();
    try { this.data = newData; }
    finally { rwLock.writeLock().unlock(); }
}

// StampedLock — optimistic read (fastest for read-heavy)
private final StampedLock stampedLock = new StampedLock();

public Data optimisticRead() {
    long stamp = stampedLock.tryOptimisticRead();
    Data local = this.data;
    if (!stampedLock.validate(stamp)) {
        stamp = stampedLock.readLock();
        try { local = this.data; }
        finally { stampedLock.unlockRead(stamp); }
    }
    return local;
}
```

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| `synchronized` with I/O in virtual threads | Pins carrier thread | Use `ReentrantLock` |
| Shared mutable state without sync | Race conditions | Use atomic classes, locks, or immutability |
| Thread pool for I/O-bound work (Java 21+) | Wasted resources | Use virtual threads |
| `Thread.sleep()` for coordination | Fragile, slow | Use `CountDownLatch`, `CompletableFuture`, `Condition` |
| Double-checked locking (broken in Java) | Subtle bugs | Use `volatile` + DCL or lazy holder pattern |
| Calling `Future.get()` without timeout | Indefinite blocking | Always specify timeout |

For detailed channel patterns, see `references/virtual-threads-guide.md`.
