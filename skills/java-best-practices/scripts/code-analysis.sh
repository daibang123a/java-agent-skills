#!/bin/bash
set -e

# Java Best Practices Code Analysis
# Runs static analysis tools and checks against best practice rules
# Usage: bash code-analysis.sh /path/to/project

PROJECT_DIR="${1:-.}"

echo "=== Java Best Practices Analysis ===" >&2
echo "Project: $PROJECT_DIR" >&2

cleanup() {
    rm -f /tmp/java-analysis-$$.json
}
trap cleanup EXIT

cd "$PROJECT_DIR"

RESULTS=()
PASS=0
FAIL=0
WARN=0

check() {
    local name="$1"
    local status="$2"
    local severity="$3"
    local message="$4"
    RESULTS+=("{\"check\":\"$name\",\"status\":\"$status\",\"severity\":\"$severity\",\"message\":\"$message\"}")
    if [ "$status" = "pass" ]; then PASS=$((PASS + 1));
    elif [ "$severity" = "error" ]; then FAIL=$((FAIL + 1));
    else WARN=$((WARN + 1)); fi
}

# Detect build tool
BUILD_TOOL="unknown"
if [ -f "pom.xml" ]; then BUILD_TOOL="maven";
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then BUILD_TOOL="gradle";
fi
echo "Build tool: $BUILD_TOOL" >&2

# Check Java version
JAVA_VERSION="unknown"
if [ -f "pom.xml" ]; then
    JAVA_VERSION=$(grep -oP '<java.version>\K[^<]+' pom.xml 2>/dev/null || \
                   grep -oP '<maven.compiler.source>\K[^<]+' pom.xml 2>/dev/null || echo "unknown")
elif [ -f "build.gradle.kts" ]; then
    JAVA_VERSION=$(grep -oP 'jvmTarget\s*=\s*"\K[^"]+' build.gradle.kts 2>/dev/null || echo "unknown")
fi
echo "Java version: $JAVA_VERSION" >&2

# Check for raw types
echo "Checking for raw types..." >&2
RAW_TYPES=$(grep -rn "new ArrayList()\|new HashMap()\|new HashSet()\|List list\b\|Map map\b" \
    --include="*.java" . 2>/dev/null | grep -v "test" | head -10 || true)
if [ -z "$RAW_TYPES" ]; then
    check "no-raw-types" "pass" "error" "No raw types found"
else
    check "no-raw-types" "fail" "error" "Raw types detected"
fi

# Check for empty catch blocks
echo "Checking for empty catch blocks..." >&2
EMPTY_CATCH=$(grep -rn -A1 "catch\s*(" --include="*.java" . 2>/dev/null | \
    grep -B1 "^\s*}" | grep "catch" | head -10 || true)
if [ -z "$EMPTY_CATCH" ]; then
    check "no-empty-catch" "pass" "error" "No empty catch blocks"
else
    check "no-empty-catch" "fail" "error" "Empty catch blocks found"
fi

# Check for System.out/err usage (should use logger)
echo "Checking for System.out usage..." >&2
SYSOUT=$(grep -rn "System\.out\.\|System\.err\." --include="*.java" . 2>/dev/null | \
    grep -v "test\|Test" | head -10 || true)
if [ -z "$SYSOUT" ]; then
    check "no-sysout" "pass" "warning" "No System.out/err usage"
else
    COUNT=$(echo "$SYSOUT" | wc -l | tr -d ' ')
    check "no-sysout" "fail" "warning" "$COUNT occurrences of System.out/err"
fi

# Check for Optional misuse (as field/parameter)
echo "Checking for Optional misuse..." >&2
OPT_FIELD=$(grep -rn "private.*Optional<\|protected.*Optional<\|Optional<.*param" \
    --include="*.java" . 2>/dev/null | grep -v "test" | head -10 || true)
if [ -z "$OPT_FIELD" ]; then
    check "optional-usage" "pass" "warning" "No Optional misuse as fields/parameters"
else
    check "optional-usage" "fail" "warning" "Optional used as field or parameter"
fi

# Check for String concatenation in loops
echo "Checking for String concatenation in loops..." >&2
STR_CONCAT=$(grep -rn -A5 "for\s*(\|while\s*(" --include="*.java" . 2>/dev/null | \
    grep '+=.*"' | head -10 || true)
if [ -z "$STR_CONCAT" ]; then
    check "no-string-concat-loop" "pass" "error" "No string concatenation in loops"
else
    check "no-string-concat-loop" "fail" "error" "String concatenation in loops detected"
fi

# Check for try-with-resources usage
echo "Checking resource management..." >&2
MANUAL_CLOSE=$(grep -rn "\.close()" --include="*.java" . 2>/dev/null | \
    grep -v "try\|test\|Test" | head -10 || true)
if [ -z "$MANUAL_CLOSE" ]; then
    check "try-with-resources" "pass" "warning" "Proper resource management"
else
    check "try-with-resources" "fail" "warning" "Manual close() calls found — use try-with-resources"
fi

# Check for null returns where Optional/empty collection is better
echo "Checking for null returns..." >&2
NULL_RETURN=$(grep -rn "return null;" --include="*.java" . 2>/dev/null | \
    grep -v "test\|Test" | head -10 || true)
if [ -z "$NULL_RETURN" ]; then
    check "no-null-return" "pass" "warning" "No null returns found"
else
    COUNT=$(echo "$NULL_RETURN" | wc -l | tr -d ' ')
    check "no-null-return" "fail" "warning" "$COUNT null return statements — consider Optional or empty collections"
fi

# Build check
echo "Checking if project compiles..." >&2
if [ "$BUILD_TOOL" = "maven" ]; then
    if mvn compile -q -DskipTests 2>/dev/null; then
        check "compilation" "pass" "error" "Project compiles successfully"
    else
        check "compilation" "fail" "error" "Compilation failed"
    fi
elif [ "$BUILD_TOOL" = "gradle" ]; then
    if ./gradlew compileJava -q 2>/dev/null; then
        check "compilation" "pass" "error" "Project compiles successfully"
    else
        check "compilation" "fail" "error" "Compilation failed"
    fi
else
    check "compilation" "skip" "info" "No build tool detected"
fi

# Output JSON results
RESULTS_JSON=$(printf '%s,' "${RESULTS[@]}")
RESULTS_JSON="[${RESULTS_JSON%,}]"

cat <<EOF
{
  "project": "$PROJECT_DIR",
  "build_tool": "$BUILD_TOOL",
  "java_version": "$JAVA_VERSION",
  "summary": {
    "pass": $PASS,
    "fail": $FAIL,
    "warn": $WARN,
    "total": $((PASS + FAIL + WARN))
  },
  "checks": $RESULTS_JSON
}
EOF

echo "" >&2
echo "Results: $PASS passed, $FAIL failed, $WARN warnings" >&2
