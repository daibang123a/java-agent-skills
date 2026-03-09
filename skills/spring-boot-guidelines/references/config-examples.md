# Spring Boot Configuration Examples

## Production application-prod.yml

```yaml
spring:
  datasource:
    url: ${DATABASE_URL}
    username: ${DATABASE_USERNAME}
    password: ${DATABASE_PASSWORD}
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      idle-timeout: 300000
      connection-timeout: 20000
      max-lifetime: 1200000
  jpa:
    hibernate:
      ddl-auto: validate
    open-in-view: false
    properties:
      hibernate:
        jdbc.batch_size: 25
        order_inserts: true
        order_updates: true
        default_batch_fetch_size: 25
  flyway:
    enabled: true
  threads:
    virtual:
      enabled: true

server:
  port: ${PORT:8080}
  shutdown: graceful
  tomcat:
    max-threads: 200
    accept-count: 100
    connection-timeout: 5s

management:
  endpoints:
    web:
      exposure:
        include: health, metrics, prometheus
  endpoint:
    health:
      show-details: when-authorized
      probes:
        enabled: true
  metrics:
    export:
      prometheus:
        enabled: true
    tags:
      application: ${spring.application.name}

spring.lifecycle.timeout-per-shutdown-phase: 30s

logging:
  level:
    root: WARN
    com.example: INFO
    org.springframework.security: WARN
```

## Development application-dev.yml

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/mydb
    username: postgres
    password: postgres
  jpa:
    show-sql: false
    properties:
      hibernate:
        generate_statistics: true
        format_sql: true
  devtools:
    restart:
      enabled: true

logging:
  level:
    root: INFO
    com.example: DEBUG
    org.hibernate.SQL: DEBUG
    org.hibernate.orm.jdbc.bind: TRACE
```
