#!/bin/bash
# Validation script for Agent 01 - Product Discovery

set -e

echo "======================================"
echo "Validating Agent 01 - Product Discovery"
echo "======================================"

OUTPUT_FILE="outputs/01_product_discovery.md"
[ -f "$OUTPUT_FILE" ] || OUTPUT_FILE="01_product_discovery.md"

# Check if file exists
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "ERROR: File $OUTPUT_FILE does not exist"
    exit 1
fi

echo "✓ File exists: $OUTPUT_FILE"

# Check required sections
REQUIRED_SECTIONS=(
    "Product Vision"
    "Problem Statement"
    "System Objectives"
    "Primary Actors"
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

# Check file is not empty (at least 100 lines)
LINE_COUNT=$(wc -l < "$OUTPUT_FILE")
if [ "$LINE_COUNT" -lt 100 ]; then
    echo "ERROR: File seems too short ($LINE_COUNT lines). Expected at least 100 lines."
    exit 1
fi

echo "✓ File has sufficient content ($LINE_COUNT lines)"

echo "======================================"
echo "Agent 01 validation PASSED"
echo "======================================"

exit 0
