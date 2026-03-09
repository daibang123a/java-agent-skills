#!/bin/bash
set -e

# JPA/Hibernate Audit Script
# Scans for common JPA anti-patterns
# Usage: bash jpa-audit.sh /path/to/project

PROJECT_DIR="${1:-.}"
echo "=== JPA/Hibernate Audit ===" >&2
cd "$PROJECT_DIR"

ISSUES=()
ERRORS=0
WARNINGS=0

add_issue() {
    local sev="$1" rule="$2" msg="$3"
    ISSUES+=("{\"severity\":\"$sev\",\"rule\":\"$rule\",\"message\":\"$msg\"}")
    [ "$sev" = "error" ] && ERRORS=$((ERRORS + 1)) || WARNINGS=$((WARNINGS + 1))
}

# Check for EAGER fetching
EAGER=$(grep -rn "fetch\s*=\s*FetchType.EAGER\|fetch=EAGER" --include="*.java" . 2>/dev/null || true)
[ -n "$EAGER" ] && add_issue "error" "N1" "FetchType.EAGER found — default to LAZY"

# Check for CascadeType.ALL
CASCADE_ALL=$(grep -rn "CascadeType.ALL" --include="*.java" . 2>/dev/null || true)
[ -n "$CASCADE_ALL" ] && add_issue "warning" "ED7" "CascadeType.ALL found — use specific cascades"

# Check for EnumType.ORDINAL
ORDINAL=$(grep -rn "EnumType.ORDINAL" --include="*.java" . 2>/dev/null || true)
[ -n "$ORDINAL" ] && add_issue "error" "ED8" "EnumType.ORDINAL found — use STRING"

# Check for ddl-auto in production configs
DDL_AUTO=$(grep -rn "ddl-auto.*update\|ddl-auto.*create" --include="*.yml" --include="*.yaml" --include="*.properties" . 2>/dev/null | grep -v "test\|dev" || true)
[ -n "$DDL_AUTO" ] && add_issue "error" "MG1" "hibernate.ddl-auto is not 'validate' or 'none'"

# Check for missing @Version
ENTITIES=$(grep -rln "@Entity" --include="*.java" . 2>/dev/null || true)
if [ -n "$ENTITIES" ]; then
    VERSION_COUNT=$(grep -rn "@Version" --include="*.java" . 2>/dev/null | wc -l | tr -d ' ')
    ENTITY_COUNT=$(echo "$ENTITIES" | wc -l | tr -d ' ')
    [ "$VERSION_COUNT" -lt "$ENTITY_COUNT" ] && \
        add_issue "warning" "TX5" "Some entities missing @Version for optimistic locking"
fi

# Check for show-sql=true
SHOW_SQL=$(grep -rn "show-sql.*true\|show_sql.*true" --include="*.yml" --include="*.yaml" --include="*.properties" . 2>/dev/null | grep -v "test" || true)
[ -n "$SHOW_SQL" ] && add_issue "warning" "N6" "show-sql=true in non-test config — use logging.level instead"

ISSUES_JSON=$(printf '%s,' "${ISSUES[@]}")
cat <<EOF
{
  "project": "$PROJECT_DIR",
  "summary": { "errors": $ERRORS, "warnings": $WARNINGS },
  "issues": [${ISSUES_JSON%,}]
}
EOF
echo "Results: $ERRORS errors, $WARNINGS warnings" >&2
