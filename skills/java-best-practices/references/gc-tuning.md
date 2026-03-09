# Java GC Tuning Guide

## GC Algorithm Selection

| GC | Best For | Flag | Java Default |
|----|----------|------|--------------|
| G1 | General purpose, balanced latency/throughput | `-XX:+UseG1GC` | Java 9+ default |
| ZGC | Ultra-low latency (<1ms pauses) | `-XX:+UseZGC` | Production-ready Java 15+ |
| Shenandoah | Low latency (RedHat) | `-XX:+UseShenandoahGC` | OpenJDK only |
| Parallel | Maximum throughput (batch jobs) | `-XX:+UseParallelGC` | Java 8 default |
| Serial | Single-core, small heaps | `-XX:+UseSerialGC` | Containers <2 CPUs |

## Container-Aware JVM Flags (Java 17+)

```bash
# Production JVM flags for containers
java \
  -XX:+UseG1GC \
  -XX:MaxRAMPercentage=75.0 \           # Use 75% of container memory
  -XX:InitialRAMPercentage=50.0 \       # Start at 50%
  -XX:+UseStringDeduplication \          # Deduplicate String values in G1
  -XX:+UseCompressedOops \              # Compress object pointers (default <32GB)
  -XX:+HeapDumpOnOutOfMemoryError \     # Dump heap on OOM
  -XX:HeapDumpPath=/tmp/heapdump.hprof \
  -Xlog:gc*:file=/var/log/gc.log:time,level,tags \  # GC logging
  -jar app.jar
```

## ZGC for Low Latency (Java 21+)

```bash
java \
  -XX:+UseZGC \
  -XX:+ZGenerational \                   # Generational ZGC (Java 21+)
  -XX:MaxRAMPercentage=75.0 \
  -XX:+HeapDumpOnOutOfMemoryError \
  -jar app.jar
```

## Key Metrics to Monitor

| Metric | Healthy Range | Tool |
|--------|--------------|------|
| GC pause time | <200ms (G1), <1ms (ZGC) | GC logs, JFR |
| GC frequency | <1/sec for minor, <1/min for major | GC logs |
| Heap usage after GC | <70% of max | JMX, Micrometer |
| Allocation rate | Depends on app | JFR |
| Promotion rate | Low relative to allocation | JFR |

## Profiling Tools

```bash
# Java Flight Recorder (production-safe)
java -XX:+FlightRecorder \
     -XX:StartFlightRecording=duration=60s,filename=recording.jfr \
     -jar app.jar

# Async-profiler (low overhead)
./asprof -d 30 -f profile.html <pid>

# jcmd for on-demand diagnostics
jcmd <pid> GC.heap_info
jcmd <pid> VM.native_memory summary
jcmd <pid> Thread.print
```

## Common Memory Issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| OOM: Heap space | Object accumulation / leak | Heap dump analysis with Eclipse MAT |
| OOM: Metaspace | Too many classes loaded | Set `-XX:MaxMetaspaceSize`, check classloader leaks |
| OOM: Direct buffer | NIO buffer leak | Track direct buffers, ensure release |
| High GC pauses | Large heap, humongous objects | Tune region size, reduce allocation rate |
| Frequent minor GC | High allocation rate | Pool objects, reduce temporaries |
