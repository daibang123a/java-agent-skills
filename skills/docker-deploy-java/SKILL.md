---
name: docker-deploy-java
description: >
  Build and deploy Java applications with Docker. Optimized multi-stage builds,
  JVM tuning for containers, GraalVM native images, JLink custom runtimes,
  and CI/CD pipelines. Use when dockerizing Java/Spring Boot apps, optimizing
  image size, or setting up deployment. Triggers: "Dockerize Java", "Dockerfile
  for Spring Boot", "GraalVM native image", "Java Docker optimization",
  "CI/CD pipeline Java", "Container JVM tuning".
---

# Docker Deploy for Java

Production-optimized Docker images for Java applications.

## How It Works

1. Agent detects build tool (Maven/Gradle) and framework
2. Agent generates multi-stage Dockerfile with JVM tuning
3. Agent creates docker-compose and CI/CD configs
4. Agent applies container-aware JVM flags

## Dockerfile Templates

### Spring Boot with Eclipse Temurin (Default)

```dockerfile
# ---- Build Stage ----
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app

# Cache dependencies
COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN ./mvnw dependency:go-offline -B

# Build
COPY src src
RUN ./mvnw package -DskipTests -B && \
    java -Djarmode=tools -jar target/*.jar extract --layers --destination extracted

# ---- Runtime Stage ----
FROM eclipse-temurin:21-jre-alpine

RUN addgroup -g 1001 app && adduser -u 1001 -G app -D app

WORKDIR /app

# Layered JAR for better Docker caching
COPY --from=builder /app/extracted/dependencies/ ./
COPY --from=builder /app/extracted/spring-boot-loader/ ./
COPY --from=builder /app/extracted/snapshot-dependencies/ ./
COPY --from=builder /app/extracted/application/ ./

USER app:app
EXPOSE 8080

# Container-aware JVM flags
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 \
  -XX:+UseG1GC \
  -XX:+UseStringDeduplication \
  -XX:+HeapDumpOnOutOfMemoryError \
  -XX:HeapDumpPath=/tmp"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher"]
```

### GraalVM Native Image

```dockerfile
FROM ghcr.io/graalvm/native-image-community:21 AS builder
WORKDIR /app
COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN ./mvnw dependency:go-offline -B
COPY src src
RUN ./mvnw -Pnative native:compile -DskipTests -B

FROM gcr.io/distroless/base-debian12
COPY --from=builder /app/target/myservice /app/myservice
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/app/myservice"]
```

### JLink Custom Runtime (Minimal JRE)

```dockerfile
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app
COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN ./mvnw dependency:go-offline -B
COPY src src
RUN ./mvnw package -DskipTests -B

# Create custom JRE with only needed modules
RUN jdeps --ignore-missing-deps --multi-release 21 \
    --print-module-deps target/*.jar > modules.txt && \
    jlink --add-modules $(cat modules.txt) \
    --strip-debug --no-man-pages --no-header-files \
    --compress=zip-6 --output /custom-jre

FROM alpine:3.19
RUN addgroup -g 1001 app && adduser -u 1001 -G app -D app
COPY --from=builder /custom-jre /opt/java
COPY --from=builder /app/target/*.jar /app/app.jar
USER app
EXPOSE 8080
ENTRYPOINT ["/opt/java/bin/java", "-jar", "/app/app.jar"]
```

## Docker Compose (Development)

```yaml
services:
  app:
    build: .
    ports: ["8080:8080"]
    environment:
      SPRING_PROFILES_ACTIVE: dev
      SPRING_DATASOURCE_URL: jdbc:postgresql://db:5432/mydb
      SPRING_DATASOURCE_USERNAME: user
      SPRING_DATASOURCE_PASSWORD: pass
    depends_on:
      db: { condition: service_healthy }
      redis: { condition: service_started }

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    ports: ["5432:5432"]
    volumes: [pgdata:/var/lib/postgresql/data]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d mydb"]
      interval: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]

volumes:
  pgdata:
```

## JVM Container Tuning Rules

| # | Rule | Description |
|---|------|-------------|
| D1 | **Use MaxRAMPercentage** | `-XX:MaxRAMPercentage=75.0` — let JVM calculate heap from container limits. Never hardcode `-Xmx`. |
| D2 | **Use layered JARs** | Spring Boot layer extraction improves Docker cache efficiency. |
| D3 | **Run as non-root** | Create `app` user. Use `USER app` in Dockerfile. |
| D4 | **Use JRE, not JDK** | Runtime image doesn't need compiler. Use `eclipse-temurin:21-jre-alpine`. |
| D5 | **Use .dockerignore** | Exclude `.git`, `target/`, `build/`, `.idea/`, `.gradle/`. |
| D6 | **Enable CDS (Class Data Sharing)** | `-XX:SharedArchiveFile` for faster startup. Spring Boot auto-creates CDS. |
| D7 | **Set HEALTHCHECK** | `HEALTHCHECK CMD curl -f http://localhost:8080/actuator/health || exit 1`. |

## GitHub Actions CI

```yaml
name: Build & Deploy
on:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: 21, cache: maven }
      - run: ./mvnw verify -B
      - uses: docker/build-push-action@v5
        with:
          context: .
          push: ${{ startsWith(github.ref, 'refs/tags/') }}
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
```

## Image Size Comparison

| Approach | Base Image | Typical Size |
|----------|-----------|-------------|
| JDK + Fat JAR | `eclipse-temurin:21-jdk` | ~400-500MB |
| JRE + Layered JAR | `eclipse-temurin:21-jre-alpine` | ~180-250MB |
| JLink custom runtime | `alpine:3.19` | ~80-120MB |
| GraalVM native image | `distroless/base` | ~30-80MB |

```bash
bash skills/docker-deploy-java/scripts/generate-dockerfile.sh /path/to/project
```
