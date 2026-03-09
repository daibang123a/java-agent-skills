#!/bin/bash
set -e

# Generate Dockerfile for Java Project
# Detects build tool, framework, and Java version
# Usage: bash generate-dockerfile.sh /path/to/project

PROJECT_DIR="${1:-.}"
OUTPUT="${2:-$PROJECT_DIR/Dockerfile}"

echo "=== Java Dockerfile Generator ===" >&2
cd "$PROJECT_DIR"

# Detect build tool
BUILD_TOOL="unknown"
[ -f "pom.xml" ] && BUILD_TOOL="maven"
[ -f "build.gradle" ] || [ -f "build.gradle.kts" ] && BUILD_TOOL="gradle"

# Detect Java version
JAVA_VERSION="21"
if [ -f "pom.xml" ]; then
    JV=$(grep -oP '<java.version>\K[^<]+' pom.xml 2>/dev/null || echo "")
    [ -n "$JV" ] && JAVA_VERSION="$JV"
fi

# Detect Spring Boot
IS_SPRING="false"
grep -q "spring-boot" pom.xml 2>/dev/null && IS_SPRING="true"
grep -q "spring-boot" build.gradle* 2>/dev/null && IS_SPRING="true"

echo "Build: $BUILD_TOOL, Java: $JAVA_VERSION, Spring: $IS_SPRING" >&2

if [ "$BUILD_TOOL" = "maven" ]; then
    cat > "$OUTPUT" << DOCKERFILE
FROM eclipse-temurin:${JAVA_VERSION}-jdk-alpine AS builder
WORKDIR /app
COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B
COPY src src
RUN ./mvnw package -DskipTests -B

FROM eclipse-temurin:${JAVA_VERSION}-jre-alpine
RUN addgroup -g 1001 app && adduser -u 1001 -G app -D app
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
USER app:app
EXPOSE 8080
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+UseG1GC -XX:+UseStringDeduplication"
ENTRYPOINT ["sh", "-c", "java \$JAVA_OPTS -jar app.jar"]
DOCKERFILE
elif [ "$BUILD_TOOL" = "gradle" ]; then
    cat > "$OUTPUT" << DOCKERFILE
FROM eclipse-temurin:${JAVA_VERSION}-jdk-alpine AS builder
WORKDIR /app
COPY build.gradle* settings.gradle* gradle.properties gradlew ./
COPY gradle gradle
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon
COPY src src
RUN ./gradlew bootJar -x test --no-daemon

FROM eclipse-temurin:${JAVA_VERSION}-jre-alpine
RUN addgroup -g 1001 app && adduser -u 1001 -G app -D app
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar
USER app:app
EXPOSE 8080
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+UseG1GC"
ENTRYPOINT ["sh", "-c", "java \$JAVA_OPTS -jar app.jar"]
DOCKERFILE
else
    echo "ERROR: No pom.xml or build.gradle found" >&2
    exit 1
fi

# Create .dockerignore
if [ ! -f ".dockerignore" ]; then
    cat > ".dockerignore" << 'DIGNORE'
.git
.github
.idea
*.iml
.vscode
target
build
.gradle
*.md
!README.md
.env
docker-compose*.yml
DIGNORE
    echo "Created .dockerignore" >&2
fi

echo "Dockerfile written to: $OUTPUT" >&2

cat << EOF
{"project":"$PROJECT_DIR","build":"$BUILD_TOOL","java":"$JAVA_VERSION","spring":$IS_SPRING,"dockerfile":"$OUTPUT"}
EOF
