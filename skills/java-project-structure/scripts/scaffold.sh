#!/bin/bash
set -e

# Java Project Scaffolding Script
# Generates a new Spring Boot project with recommended structure
# Usage: bash scaffold.sh <project-name> --type=<api|hexagonal|cli> --build=<maven|gradle>

PROJECT_NAME="${1:?Usage: scaffold.sh <project-name> --type=<api|hexagonal|cli> --build=<maven|gradle>}"
PROJECT_TYPE="api"
BUILD_TOOL="maven"
GROUP_ID="com.example"
JAVA_VERSION="21"

for arg in "$@"; do
    case $arg in
        --type=*) PROJECT_TYPE="${arg#*=}" ;;
        --build=*) BUILD_TOOL="${arg#*=}" ;;
        --group=*) GROUP_ID="${arg#*=}" ;;
        --java=*) JAVA_VERSION="${arg#*=}" ;;
    esac
done

PACKAGE_PATH=$(echo "$GROUP_ID.$PROJECT_NAME" | tr '.' '/' | tr '-' '_')
PACKAGE_NAME=$(echo "$GROUP_ID.$PROJECT_NAME" | tr '-' '_')

echo "Scaffolding Java project: $PROJECT_NAME" >&2
echo "Type: $PROJECT_TYPE, Build: $BUILD_TOOL, Java: $JAVA_VERSION" >&2

if [ -d "$PROJECT_NAME" ]; then
    echo "ERROR: Directory $PROJECT_NAME already exists" >&2
    exit 1
fi

mkdir -p "$PROJECT_NAME"

scaffold_maven_pom() {
    cat > "$PROJECT_NAME/pom.xml" << POMEOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.0</version>
    </parent>

    <groupId>$GROUP_ID</groupId>
    <artifactId>$PROJECT_NAME</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>$PROJECT_NAME</name>

    <properties>
        <java.version>$JAVA_VERSION</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.testcontainers</groupId>
            <artifactId>postgresql</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
POMEOF
}

scaffold_api() {
    local SRC="$PROJECT_NAME/src/main/java/$PACKAGE_PATH"
    local RES="$PROJECT_NAME/src/main/resources"
    local TEST="$PROJECT_NAME/src/test/java/$PACKAGE_PATH"

    mkdir -p "$SRC"/{shared/{config,exception},user}
    mkdir -p "$RES/db/migration"
    mkdir -p "$TEST/user"

    # Application class
    cat > "$SRC/Application.java" << JEOF
package $PACKAGE_NAME;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
JEOF

    # application.yml
    cat > "$RES/application.yml" << YEOF
spring:
  application:
    name: $PROJECT_NAME
  datasource:
    url: \${DATABASE_URL:jdbc:postgresql://localhost:5432/${PROJECT_NAME}}
    username: \${DATABASE_USERNAME:postgres}
    password: \${DATABASE_PASSWORD:postgres}
  jpa:
    hibernate:
      ddl-auto: validate
    open-in-view: false
  flyway:
    enabled: true
  threads:
    virtual:
      enabled: true

server:
  port: \${PORT:8080}

management:
  endpoints:
    web:
      exposure:
        include: health, metrics, info
  endpoint:
    health:
      probes:
        enabled: true

logging:
  level:
    root: INFO
    $PACKAGE_NAME: DEBUG
YEOF

    # Dockerfile
    cat > "$PROJECT_NAME/Dockerfile" << DEOF
FROM eclipse-temurin:${JAVA_VERSION}-jdk-alpine AS builder
WORKDIR /app
COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN ./mvnw dependency:go-offline -B
COPY src src
RUN ./mvnw package -DskipTests -B

FROM eclipse-temurin:${JAVA_VERSION}-jre-alpine
RUN addgroup -g 1001 app && adduser -u 1001 -G app -D app
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
USER app
EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
DEOF

    scaffold_maven_pom

    # .gitignore
    cat > "$PROJECT_NAME/.gitignore" << GEOF
target/
build/
*.class
*.jar
.idea/
*.iml
.vscode/
.env
GEOF

    # README
    cat > "$PROJECT_NAME/README.md" << REOF
# $PROJECT_NAME

## Development

\`\`\`bash
./mvnw spring-boot:run
./mvnw test
./mvnw package
\`\`\`
REOF
}

case "$PROJECT_TYPE" in
    api) scaffold_api ;;
    *) echo "Type $PROJECT_TYPE not yet supported (use: api)" >&2; exit 1 ;;
esac

echo "Project scaffolded: $PROJECT_NAME" >&2

cat << EOF
{
  "project": "$PROJECT_NAME",
  "type": "$PROJECT_TYPE",
  "build": "$BUILD_TOOL",
  "java": "$JAVA_VERSION",
  "package": "$PACKAGE_NAME"
}
EOF
