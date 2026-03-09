# Logback Configuration Examples

## Production (JSON Structured Logging)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <springProfile name="prod,staging">
        <appender name="JSON" class="ch.qos.logback.core.ConsoleAppender">
            <encoder class="net.logstash.logback.encoder.LogstashEncoder">
                <includeMdcKeyName>requestId</includeMdcKeyName>
                <includeMdcKeyName>userId</includeMdcKeyName>
                <includeMdcKeyName>traceId</includeMdcKeyName>
                <includeMdcKeyName>spanId</includeMdcKeyName>
                <timeZone>UTC</timeZone>
                <fieldNames>
                    <timestamp>@timestamp</timestamp>
                    <version>[ignore]</version>
                </fieldNames>
            </encoder>
        </appender>

        <root level="INFO">
            <appender-ref ref="JSON" />
        </root>
    </springProfile>

    <springProfile name="dev,local">
        <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
            <encoder>
                <pattern>
                    %d{HH:mm:ss.SSS} %highlight(%-5level) %cyan(%logger{36}) [%mdc{requestId:-}] - %msg%n
                </pattern>
            </encoder>
        </appender>

        <logger name="org.hibernate.SQL" level="DEBUG" />
        <logger name="org.hibernate.orm.jdbc.bind" level="TRACE" />

        <root level="INFO">
            <appender-ref ref="CONSOLE" />
        </root>
    </springProfile>
</configuration>
```

## Maven Dependency

```xml
<dependency>
    <groupId>net.logstash.logback</groupId>
    <artifactId>logstash-logback-encoder</artifactId>
    <version>7.4</version>
</dependency>
```

## Log Output Examples

### Development (human-readable)
```
14:32:01.123 INFO  c.e.m.u.UserService [req-abc123] - User created: alice@example.com
14:32:01.456 DEBUG c.e.m.u.UserRepository [req-abc123] - SELECT * FROM users WHERE email = ?
```

### Production (JSON for log aggregation)
```json
{
  "@timestamp": "2024-01-15T14:32:01.123Z",
  "level": "INFO",
  "logger_name": "com.example.myservice.user.UserService",
  "message": "User created: alice@example.com",
  "requestId": "req-abc123",
  "traceId": "64a3b2c1d4e5f6a7",
  "thread_name": "virtual-thread-42"
}
```
