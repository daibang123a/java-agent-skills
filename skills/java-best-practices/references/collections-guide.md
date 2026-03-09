# Java Collections Performance Guide

## Time Complexity Comparison

| Operation | ArrayList | LinkedList | ArrayDeque | HashSet | TreeSet | HashMap | TreeMap |
|-----------|-----------|------------|------------|---------|---------|---------|---------|
| add(E) | O(1)* | O(1) | O(1)* | O(1) | O(log n) | O(1) | O(log n) |
| add(i, E) | O(n) | O(n)** | N/A | N/A | N/A | N/A | N/A |
| get(i) | O(1) | O(n) | N/A | N/A | N/A | O(1) | O(log n) |
| remove(i) | O(n) | O(n)** | O(1)*** | O(1) | O(log n) | O(1) | O(log n) |
| contains | O(n) | O(n) | O(n) | O(1) | O(log n) | O(1) | O(log n) |

\* Amortized — occasional O(n) for resizing
\*\* O(1) if you have the iterator position
\*\*\* O(1) for first/last

## When to Use What

```java
// RANDOM ACCESS → ArrayList (99% of the time)
List<String> names = new ArrayList<>(100);

// STACK or QUEUE → ArrayDeque (never LinkedList)
Deque<Task> stack = new ArrayDeque<>();
Queue<Event> queue = new ArrayDeque<>();

// UNIQUE ELEMENTS → HashSet (or LinkedHashSet for insertion order)
Set<String> tags = new HashSet<>();
Set<String> orderedTags = new LinkedHashSet<>();

// SORTED ELEMENTS → TreeSet
NavigableSet<Integer> sorted = new TreeSet<>();

// KEY-VALUE → HashMap (or LinkedHashMap for insertion order)
Map<String, User> cache = new HashMap<>(256);

// ENUM KEYS → EnumSet / EnumMap (vastly more efficient)
Set<DayOfWeek> weekdays = EnumSet.of(MON, TUE, WED, THU, FRI);
Map<Status, List<Order>> byStatus = new EnumMap<>(Status.class);

// CONCURRENT ACCESS → ConcurrentHashMap
Map<String, Session> sessions = new ConcurrentHashMap<>();

// BIT FLAGS → BitSet
BitSet permissions = new BitSet(64);
```

## Immutable Collection Factories (Java 9+)

```java
// Unmodifiable, null-hostile, no duplicates for Set/Map keys
List<String> list = List.of("a", "b", "c");
Set<Integer> set = Set.of(1, 2, 3);
Map<String, Integer> map = Map.of("a", 1, "b", 2);

// For more than 10 entries
Map<String, Integer> bigMap = Map.ofEntries(
    Map.entry("key1", 1),
    Map.entry("key2", 2)
);

// Defensive copy (immutable)
List<String> safe = List.copyOf(mutableList);
```

## Collectors Cheat Sheet

```java
// Basic
list.stream().collect(Collectors.toList());           // mutable list
list.stream().toList();                                // unmodifiable (Java 16+)
list.stream().collect(Collectors.toSet());
list.stream().collect(Collectors.toUnmodifiableList());

// To Map
items.stream().collect(Collectors.toMap(
    Item::getId,                    // key mapper
    Item::getName,                  // value mapper
    (v1, v2) -> v1                  // merge function (handle duplicates!)
));

// Grouping
orders.stream().collect(Collectors.groupingBy(
    Order::getStatus,               // classifier
    Collectors.counting()           // downstream collector
));

// Partitioning (exactly two groups: true/false)
Map<Boolean, List<User>> partitioned = users.stream()
    .collect(Collectors.partitioningBy(User::isActive));

// Joining
String csv = names.stream().collect(Collectors.joining(", ", "[", "]"));

// Statistics
IntSummaryStatistics stats = orders.stream()
    .collect(Collectors.summarizingInt(Order::getQuantity));
```
