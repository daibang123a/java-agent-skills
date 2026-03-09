#!/bin/bash
set -e

# Java Logging & Observability Audit
# Checks logging configuration and practices
# Usage: bash logging-audit.sh /path/to/project

PROJECT_DIR="${1:-.}"
echo "=== Java Logging Audit ===" >&2
cd "$PROJECT_DIR"

ISSUES=()
ERRORS=0
WARNINGS=0

add_issue() {
    local sev="$1" rule="$2" msg="$3"
    ISSUES+=("{\"severity\":\"$sev\",\"rule\":\"$rule\",\"message\":\"$msg\"}")
    [ "$sev" = "error" ] && ERRORS=$((ERRORS + 1)) || WARNINGS=$((WARNINGS + 1))
}

# Check for System.out/err
SYSOUT=$(grep -rn "System\.out\.\|System\.err\.\|\.printStackTrace()" --include="*.java" . 2>/dev/null | \
    grep -v "test\|Test" | wc -l | tr -d ' ')
[ "$SYSOUT" -gt 0 ] && add_issue "error" "L1" "$SYSOUT uses of System.out/err/printStackTrace — use SLF4J"

# Check for string concatenation in logging
CONCAT_LOG=$(grep -rn 'log\.\(info\|debug\|warn\|error\)(".*" +' --include="*.java" . 2>/dev/null | \
    grep -v "test" | wc -l | tr -d ' ')
[ "$CONCAT_LOG" -gt 0 ] && add_issue "warning" "L2" "$CONCAT_LOG log calls with string concatenation — use parameterized logging"

# Check for logback config
LOGBACK=$(find . -name "logback*.xml" -o -name "logback*.groovy" | wc -l | tr -d ' ')
[ "$LOGBACK" -eq 0 ] && add_issue "warning" "CFG" "No logback configuration file found"

# Check for actuator
ACTUATOR=$(grep -rn "spring-boot-starter-actuator" --include="pom.xml" --include="*.gradle*" . 2>/dev/null | wc -l | tr -d ' ')
[ "$ACTUATOR" -eq 0 ] && add_issue "warning" "AC" "Spring Boot Actuator not found — add for production monitoring"

# Check for Micrometer
MICROMETER=$(grep -rn "micrometer" --include="pom.xml" --include="*.gradle*" . 2>/dev/null | wc -l | tr -d ' ')
[ "$MICROMETER" -eq 0 ] && add_issue "warning" "METRICS" "Micrometer not found — add for metrics collection"

# Check for MDC usage
MDC=$(grep -rn "MDC\." --include="*.java" . 2>/dev/null | wc -l | tr -d ' ')

# Check for health endpoints
HEALTH=$(grep -rn "HealthIndicator\|HealthContributor\|/health" --include="*.java" --include="*.yml" . 2>/dev/null | wc -l | tr -d ' ')

ISSUES_JSON=$(printf '%s,' "${ISSUES[@]}")
cat <<EOF
{
  "project": "$PROJECT_DIR",
  "statistics": {
    "logback_configs": $LOGBACK,
    "mdc_usage": $MDC,
    "health_indicators": $HEALTH,
    "actuator_present": $([ "$ACTUATOR" -gt 0 ] && echo true || echo false),
    "micrometer_present": $([ "$MICROMETER" -gt 0 ] && echo true || echo false)
  },
  "summary": { "errors": $ERRORS, "warnings": $WARNINGS },
  "issues": [${ISSUES_JSON%,}]
}
EOF
echo "Results: $ERRORS errors, $WARNINGS warnings" >&2
