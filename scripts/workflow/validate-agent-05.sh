#!/bin/bash
# Validation script for Agent 05 - Service Design

set -e

echo "======================================"
echo "Validating Agent 05 - Service Design"
echo "======================================"

OUTPUT_FILE="05_service_design.md"

if [ ! -f "$OUTPUT_FILE" ]; then
    echo "ERROR: File $OUTPUT_FILE does not exist"
    exit 1
fi

echo "✓ File exists: $OUTPUT_FILE"

REQUIRED_SECTIONS=(
    "Service Design"
    "Clean Architecture"
    "Domain Layer"
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
if [ "$LINE_COUNT" -lt 100 ]; then
    echo "ERROR: File seems too short ($LINE_COUNT lines). Expected at least 100 lines."
    exit 1
fi

echo "✓ File has sufficient content ($LINE_COUNT lines)"

echo "======================================"
echo "Agent 05 validation PASSED"
echo "======================================"

exit 0
