#!/bin/bash
# Validation script for Agent 03 - Context Mapping

set -e

echo "======================================"
echo "Validating Agent 03 - Context Mapping"
echo "======================================"

OUTPUT_FILE="03_context_map.md"

if [ ! -f "$OUTPUT_FILE" ]; then
    echo "ERROR: File $OUTPUT_FILE does not exist"
    exit 1
fi

echo "✓ File exists: $OUTPUT_FILE"

REQUIRED_SECTIONS=(
    "Bounded Contexts"
    "Context Relationships"
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

LINE_COUNT=$(wc -l < "$OUTPUT_FILE")
if [ "$LINE_COUNT" -lt 80 ]; then
    echo "ERROR: File seems too short ($LINE_COUNT lines). Expected at least 80 lines."
    exit 1
fi

echo "✓ File has sufficient content ($LINE_COUNT lines)"

echo "======================================"
echo "Agent 03 validation PASSED"
echo "======================================"

exit 0
