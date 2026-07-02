#!/bin/bash
# Validation script for Agent 07bis - Hidden Complexity Analyzer

set -e

echo "======================================"
echo "Validating Agent 07bis - Hidden Complexity Analyzer"
echo "======================================"

OUTPUT_FILE="outputs/07bis_hidden_complexity.md"
[ -f "$OUTPUT_FILE" ] || OUTPUT_FILE="07bis_hidden_complexity.md"

# Check if file exists
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "ERROR: File $OUTPUT_FILE does not exist"
    exit 1
fi

echo "✓ File exists: $OUTPUT_FILE"

# Check required sections
REQUIRED_SECTIONS=(
    "Middleware Analysis"
    "Interceptor Discovery"
    "AOP Aspects"
    "Event System"
)

MISSING_SECTIONS=()

for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -q "$section" "$OUTPUT_FILE"; then
        MISSING_SECTIONS+=("$section")
    fi
done

if [ ${#MISSING_SECTIONS[@]} -gt 0 ]; then
    echo "ERROR: Missing required sections:"
    for section in "${MISSING_SECTIONS[@]}"; do
        echo "  - $section"
    done
    exit 1
fi

echo "✓ All required sections present"

# Check file has sufficient content (at least 120 lines for complexity analysis)
LINE_COUNT=$(wc -l < "$OUTPUT_FILE")
if [ "$LINE_COUNT" -lt 120 ]; then
    echo "ERROR: File seems too short ($LINE_COUNT lines). Expected at least 120 lines."
    exit 1
fi

echo "✓ File has sufficient content ($LINE_COUNT lines)"

echo "======================================"
echo "Agent 07bis validation PASSED"
echo "======================================"

exit 0
