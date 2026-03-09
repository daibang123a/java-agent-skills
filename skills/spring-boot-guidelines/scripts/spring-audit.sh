#!/bin/bash
set -e

# Spring Boot Application Audit
# Scans a Spring Boot project for common issues and anti-patterns
# Usage: bash spring-audit.sh /path/to/project

PROJECT_DIR="${1:-.}"

echo "=== Spring Boot Audit ===" >&2
echo "Project: $PROJECT_DIR" >&2

cleanup() { rm -f /tmp/spring-audit-$$.tmp; }
trap cleanup EXIT

cd "$PROJECT_DIR"

ISSUES=()
ERRORS=0
WARNINGS=0

add_issue() {
    local sev="$1" rule="$2" msg="$3" file="$4"
    ISSUES+=("{\"severity\":\"$sev\",\"rule\":\"$rule\",\"message\":\"$msg\",\"file\":\"$file\"}")
    [ "$sev" = "error" ] && ERRORS=$((ERRORS + 1)) || WARNINGS=$((WARNINGS + 1))
}

# Check for field injection
echo "Checking for field injection..." >&2
FIELD_INJ=$(grep -rn "@Autowired" --include="*.java" . 2>/dev/null | \
    grep -v "constructor\|test\|Test\|Config" | head -10 || true)
if [ -n "$FIELD_INJ" ]; then
    while IFS= read -r line; do
        FILE=$(echo "$line" | cut -d: -f1)
        add_issue "error" "DI1" "@Autowired field injection — use constructor injection" "$FILE"
    done <<< "$FIELD_INJ"
fi

# Check for entities exposed in controllers
echo "Checking for entity exposure in controllers..." >&2
ENTITY_EXPOSE=$(grep -rn "@Entity" --include="*.java" . 2>/dev/null | cut -d: -f1 | \
    xargs -I{} basename {} .java | while read entity; do
        grep -rn "ResponseEntity<$entity\|List<$entity\|Page<$entity" --include="*.java" . 2>/dev/null | \
        grep -i "controller" || true
    done | head -5)
if [ -n "$ENTITY_EXPOSE" ]; then
    add_issue "error" "RC6" "JPA entities exposed directly in REST responses — use DTOs" ""
fi

# Check for WebSecurityConfigurerAdapter (deprecated)
echo "Checking for deprecated security config..." >&2
DEPRECATED_SEC=$(grep -rn "WebSecurityConfigurerAdapter" --include="*.java" . 2>/dev/null || true)
if [ -n "$DEPRECATED_SEC" ]; then
    FILE=$(echo "$DEPRECATED_SEC" | head -1 | cut -d: -f1)
    add_issue "error" "SC1" "Deprecated WebSecurityConfigurerAdapter — use SecurityFilterChain bean" "$FILE"
fi

# Check for hardcoded secrets in config
echo "Checking for hardcoded secrets..." >&2
SECRETS=$(grep -rn "password\s*[:=]\s*['\"].\+\|secret\s*[:=]\s*['\"].\+" \
    --include="*.yml" --include="*.yaml" --include="*.properties" . 2>/dev/null | \
    grep -v "\\${\|\\$(" | grep -v "test\|example\|changeme" | head -5 || true)
if [ -n "$SECRETS" ]; then
    add_issue "error" "CF4" "Possible hardcoded secrets in configuration" ""
fi

# Check for missing health endpoint config
echo "Checking actuator configuration..." >&2
ACTUATOR=$(find . -name "pom.xml" -exec grep -l "spring-boot-starter-actuator" {} \; 2>/dev/null || true)
if [ -z "$ACTUATOR" ]; then
    ACTUATOR=$(find . -name "build.gradle*" -exec grep -l "spring-boot-starter-actuator" {} \; 2>/dev/null || true)
fi
if [ -z "$ACTUATOR" ]; then
    add_issue "warning" "AC1" "spring-boot-starter-actuator not found — add for production readiness" ""
fi

# Check for proper exception handling
echo "Checking exception handling..." >&2
CTRL_ADVICE=$(grep -rn "@ControllerAdvice\|@RestControllerAdvice" --include="*.java" . 2>/dev/null || true)
if [ -z "$CTRL_ADVICE" ]; then
    add_issue "warning" "EH1" "No @ControllerAdvice found — add centralized exception handling" ""
fi

# Check for @Transactional on read operations
echo "Checking transaction annotations..." >&2
TRANSACTIONAL_READ=$(grep -rn -B2 "@Transactional" --include="*.java" . 2>/dev/null | \
    grep -A2 "find\|get\|list\|search\|count" | grep "@Transactional" | \
    grep -v "readOnly" | head -5 || true)
if [ -n "$TRANSACTIONAL_READ" ]; then
    add_issue "warning" "TX" "Read methods with @Transactional missing readOnly=true" ""
fi

# Output JSON
ISSUES_JSON=$(printf '%s,' "${ISSUES[@]}")
ISSUES_JSON="[${ISSUES_JSON%,}]"

cat <<EOF
{
  "project": "$PROJECT_DIR",
  "summary": { "errors": $ERRORS, "warnings": $WARNINGS, "total": $((ERRORS + WARNINGS)) },
  "issues": ${ISSUES_JSON:-[]}
}
EOF

echo "" >&2
echo "Results: $ERRORS errors, $WARNINGS warnings" >&2
