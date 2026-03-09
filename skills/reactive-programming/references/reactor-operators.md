# Project Reactor Operators Cheat Sheet

## Creating Publishers

| Operator | Description | Example |
|----------|-------------|---------|
| `Mono.just(value)` | Emit single value | `Mono.just("hello")` |
| `Mono.empty()` | Complete without value | `Mono.empty()` |
| `Mono.error(ex)` | Emit error | `Mono.error(new RuntimeException())` |
| `Mono.defer(supplier)` | Lazy creation | `Mono.defer(() -> Mono.just(compute()))` |
| `Mono.fromCallable(fn)` | From blocking call | `Mono.fromCallable(() -> blockingOp())` |
| `Flux.just(a, b, c)` | From values | `Flux.just(1, 2, 3)` |
| `Flux.fromIterable(list)` | From collection | `Flux.fromIterable(users)` |
| `Flux.range(start, count)` | Generate range | `Flux.range(1, 10)` |
| `Flux.interval(duration)` | Periodic ticks | `Flux.interval(Duration.ofSeconds(1))` |

## Transforming

| Operator | Description |
|----------|-------------|
| `map(fn)` | Synchronous 1:1 transform |
| `flatMap(fn)` | Async 1:N transform (interleaved) |
| `concatMap(fn)` | Async 1:N transform (ordered) |
| `flatMapSequential(fn)` | Async 1:N (ordered, parallel exec) |
| `switchMap(fn)` | Cancel previous, subscribe to new |
| `cast(Class)` | Cast elements |
| `index()` | Add index to each element |

## Filtering

| Operator | Description |
|----------|-------------|
| `filter(predicate)` | Keep matching elements |
| `distinct()` | Remove duplicates |
| `take(n)` | First N elements |
| `takeLast(n)` | Last N elements |
| `skip(n)` | Skip first N |
| `elementAt(index)` | Single element at index |
| `first()` / `last()` | First/last element |

## Combining

| Operator | Description |
|----------|-------------|
| `zip(mono1, mono2, combiner)` | Combine when both complete |
| `merge(flux1, flux2)` | Interleave elements |
| `concat(flux1, flux2)` | Sequential combination |
| `combineLatest(flux1, flux2, fn)` | Latest from each |
| `switchIfEmpty(alternative)` | Fallback if empty |
| `defaultIfEmpty(value)` | Default value if empty |

## Error Handling

| Operator | Description |
|----------|-------------|
| `onErrorResume(fn)` | Fallback publisher |
| `onErrorReturn(value)` | Fallback value |
| `onErrorMap(fn)` | Transform error |
| `retry(n)` | Retry N times |
| `retryWhen(spec)` | Custom retry logic |
| `timeout(duration)` | Timeout with error |
| `onErrorComplete()` | Swallow error, complete |

## Side Effects (do* operators)

| Operator | Description |
|----------|-------------|
| `doOnNext(consumer)` | On each element |
| `doOnError(consumer)` | On error |
| `doOnComplete(runnable)` | On completion |
| `doOnSubscribe(consumer)` | On subscription |
| `doFinally(signalType)` | On any terminal signal |
| `log()` | Log all signals |

## Scheduling

```java
// subscribeOn: affects the ENTIRE chain upstream
mono.subscribeOn(Schedulers.boundedElastic())  // blocking I/O
    .map(data -> transform(data));              // runs on boundedElastic

// publishOn: affects operators DOWNSTREAM
flux.publishOn(Schedulers.parallel())           // CPU work
    .map(data -> heavyComputation(data))
    .publishOn(Schedulers.boundedElastic())     // switch to I/O
    .flatMap(result -> saveToDb(result));
```

| Scheduler | Use For |
|-----------|---------|
| `Schedulers.parallel()` | CPU-bound work |
| `Schedulers.boundedElastic()` | Blocking I/O |
| `Schedulers.immediate()` | Current thread |
| `Schedulers.single()` | Sequential work |
