#!/bin/bash
set -e

# Java Security Audit Script
# Scans for common security vulnerabilities
# Usage: bash security-audit.sh /path/to/project

PROJECT_DIR="${1:-.}"
echo "=== Java Security Audit ===" >&2
cd "$PROJECT_DIR"

ISSUES=()
ERRORS=0
WARNINGS=0

add_issue() {
    local sev="$1" rule="$2" msg="$3"
    ISSUES+=("{\"severity\":\"$sev\",\"rule\":\"$rule\",\"message\":\"$msg\"}")
    [ "$sev" = "error" ] && ERRORS=$((ERRORS + 1)) || WARNINGS=$((WARNINGS + 1))
}

# SQL injection: string concatenation in queries
SQL_CONCAT=$(grep -rn '"SELECT\|"INSERT\|"UPDATE\|"DELETE' --include="*.java" . 2>/dev/null | \
    grep -v "test\|Test" | grep "+\s*\|String.format" | head -10 || true)
[ -n "$SQL_CONCAT" ] && add_issue "error" "SQ1" "Possible SQL injection: string concatenation in SQL queries"

# Hardcoded passwords
HARDCODED=$(grep -rn 'password\s*=\s*"[^"]\+"\|secret\s*=\s*"[^"]\+"\|apiKey\s*=\s*"[^"]\+"' \
    --include="*.java" . 2>/dev/null | grep -v "test\|Test\|example\|TODO" | head -5 || true)
[ -n "$HARDCODED" ] && add_issue "error" "CR3" "Hardcoded secrets found in source code"

# java.util.Random for security
WEAK_RANDOM=$(grep -rn "new Random()\|java\.util\.Random" --include="*.java" . 2>/dev/null | \
    grep -v "test\|Test" | head -5 || true)
[ -n "$WEAK_RANDOM" ] && add_issue "warning" "CR2" "java.util.Random used — use SecureRandom for security-sensitive ops"

# CORS wildcard
CORS_STAR=$(grep -rn 'allowedOrigins\("\\*"\)\|addAllowedOrigin\("\\*"\)' --include="*.java" . 2>/dev/null || true)
[ -n "$CORS_STAR" ] && add_issue "error" "HD" "CORS allows all origins (*) — whitelist specific domains"

# Missing @Valid
MISSING_VALID=$(grep -rn "@RequestBody" --include="*.java" . 2>/dev/null | grep -v "@Valid" | head -5 || true)
[ -n "$MISSING_VALID" ] && add_issue "warning" "IV2" "@RequestBody without @Valid — input may not be validated"

# System.out for logging
SYSOUT=$(grep -rn "System\.out\.\|System\.err\.\|printStackTrace" --include="*.java" . 2>/dev/null | \
    grep -v "test\|Test" | head -5 || true)
[ -n "$SYSOUT" ] && add_issue "warning" "L1" "System.out/err or printStackTrace found — use SLF4J logger"

# Sensitive data in logs
LOG_SENSITIVE=$(grep -rn 'log\.\(info\|debug\|warn\|error\).*password\|log\.\(info\|debug\|warn\|error\).*token\|log\.\(info\|debug\|warn\|error\).*secret' \
    --include="*.java" . 2>/dev/null | grep -v "test" | head -5 || true)
[ -n "$LOG_SENSITIVE" ] && add_issue "error" "L4" "Possible sensitive data logged (password/token/secret)"

# Dependency-check
if [ -f "pom.xml" ] && command -v mvn &>/dev/null; then
    echo "Checking for OWASP dependency-check plugin..." >&2
    OWASP=$(grep -c "dependency-check-maven" pom.xml 2>/dev/null || echo "0")
    [ "$OWASP" -eq 0 ] && add_issue "warning" "DV1" "OWASP dependency-check plugin not configured"
fi

ISSUES_JSON=$(printf '%s,' "${ISSUES[@]}")
cat <<EOF
{
  "project": "$PROJECT_DIR",
  "summary": { "errors": $ERRORS, "warnings": $WARNINGS },
  "issues": [${ISSUES_JSON%,}]
}
EOF
echo "Results: $ERRORS errors, $WARNINGS warnings" >&2
