#!/bin/bash
# Validation script for Agent 06bis - Configuration Analysis Agent

set -e

echo "======================================"
echo "Validating Agent 06bis - Configuration Analyzer"
echo "======================================"

OUTPUT_FILE="06bis_configuration_analysis.md"

# Check if file exists
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "ERROR: File $OUTPUT_FILE does not exist"
    exit 1
fi

echo "✓ File exists: $OUTPUT_FILE"

# Check required sections
REQUIRED_SECTIONS=(
    "Configuration Files Inventory"
    "Configuration Resolution Order"
    "Environment Configuration Matrix"
    "Security Analysis"
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

# Check file has sufficient content (at least 100 lines for brownfield analysis)
LINE_COUNT=$(wc -l < "$OUTPUT_FILE")
if [ "$LINE_COUNT" -lt 100 ]; then
    echo "ERROR: File seems too short ($LINE_COUNT lines). Expected at least 100 lines."
    exit 1
fi

echo "✓ File has sufficient content ($LINE_COUNT lines)"

echo "======================================"
echo "Agent 06bis validation PASSED"
echo "======================================"

exit 0
