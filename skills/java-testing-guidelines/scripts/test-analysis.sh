#!/bin/bash
set -e

# Java Test Analysis Script
# Analyzes test code quality and coverage patterns
# Usage: bash test-analysis.sh /path/to/project

PROJECT_DIR="${1:-.}"
echo "=== Java Test Analysis ===" >&2
cd "$PROJECT_DIR"

ISSUES=()
ERRORS=0
WARNINGS=0
STATS=()

add_issue() {
    local sev="$1" rule="$2" msg="$3"
    ISSUES+=("{\"severity\":\"$sev\",\"rule\":\"$rule\",\"message\":\"$msg\"}")
    [ "$sev" = "error" ] && ERRORS=$((ERRORS + 1)) || WARNINGS=$((WARNINGS + 1))
}

# Count test files
TEST_FILES=$(find . -name "*Test.java" -o -name "*Tests.java" -o -name "*IT.java" | wc -l | tr -d ' ')
SRC_FILES=$(find . -path "*/src/main/java/*.java" | wc -l | tr -d ' ')
echo "Source files: $SRC_FILES, Test files: $TEST_FILES" >&2

# Check test ratio
if [ "$SRC_FILES" -gt 0 ]; then
    RATIO=$(echo "scale=2; $TEST_FILES / $SRC_FILES * 100" | bc 2>/dev/null || echo "0")
    STATS+=("\"test_ratio\": $RATIO")
fi

# Check for JUnit 4 usage (should be JUnit 5)
JUNIT4=$(grep -rn "import org.junit.Test\b\|import org.junit.Before\b\|import org.junit.After\b" \
    --include="*.java" . 2>/dev/null | wc -l | tr -d ' ')
[ "$JUNIT4" -gt 0 ] && add_issue "warning" "J-MIGRATE" "$JUNIT4 files still using JUnit 4 — migrate to JUnit 5"

# Check for @Autowired in tests (prefer constructor or @MockBean)
AUTOWIRED_TEST=$(grep -rn "@Autowired" --include="*Test*.java" . 2>/dev/null | \
    grep -v "MockMvc\|TestRestTemplate\|WebTestClient" | wc -l | tr -d ' ')
[ "$AUTOWIRED_TEST" -gt 3 ] && add_issue "warning" "SB" "Excessive @Autowired in tests — prefer @MockBean or constructor injection"

# Check for Thread.sleep in tests
SLEEP=$(grep -rn "Thread.sleep" --include="*Test*.java" --include="*IT.java" . 2>/dev/null | wc -l | tr -d ' ')
[ "$SLEEP" -gt 0 ] && add_issue "error" "ASYNC" "$SLEEP uses of Thread.sleep in tests — use Awaitility instead"

# Check for @SpringBootTest overuse
FULL_CONTEXT=$(grep -rn "@SpringBootTest" --include="*.java" . 2>/dev/null | wc -l | tr -d ' ')
SLICED=$(grep -rn "@WebMvcTest\|@DataJpaTest\|@WebFluxTest\|@JsonTest" --include="*.java" . 2>/dev/null | wc -l | tr -d ' ')
if [ "$FULL_CONTEXT" -gt "$SLICED" ] && [ "$FULL_CONTEXT" -gt 3 ]; then
    add_issue "warning" "SB1" "More @SpringBootTest ($FULL_CONTEXT) than sliced tests ($SLICED) — prefer @WebMvcTest, @DataJpaTest"
fi

# Check for Testcontainers usage
TC=$(grep -rn "@Testcontainers\|@Container" --include="*.java" . 2>/dev/null | wc -l | tr -d ' ')

# Check for assertions (tests without assertions are useless)
NO_ASSERT=$(find . -name "*Test.java" -exec grep -L "assert\|verify\|expect\|should" {} \; 2>/dev/null | wc -l | tr -d ' ')
[ "$NO_ASSERT" -gt 0 ] && add_issue "error" "ASSERT" "$NO_ASSERT test files with no assertions found"

# Check for @DisplayName usage
DISPLAY_NAME=$(grep -rn "@DisplayName" --include="*Test*.java" . 2>/dev/null | wc -l | tr -d ' ')

# Check for ArchUnit tests
ARCHUNIT=$(grep -rn "@ArchTest\|ArchRule" --include="*.java" . 2>/dev/null | wc -l | tr -d ' ')

ISSUES_JSON=$(printf '%s,' "${ISSUES[@]}")

cat <<EOF
{
  "project": "$PROJECT_DIR",
  "statistics": {
    "source_files": $SRC_FILES,
    "test_files": $TEST_FILES,
    "junit5_sliced_tests": $SLICED,
    "spring_boot_tests": $FULL_CONTEXT,
    "testcontainers": $TC,
    "display_names": $DISPLAY_NAME,
    "archunit_rules": $ARCHUNIT
  },
  "summary": { "errors": $ERRORS, "warnings": $WARNINGS },
  "issues": [${ISSUES_JSON%,}]
}
EOF
echo "Results: $ERRORS errors, $WARNINGS warnings" >&2
