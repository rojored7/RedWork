#!/bin/bash
# Validation script for Agent 23 - Quick Reference Generator

set -e

echo "======================================"
echo "Validating Agent 23 - Quick Reference Generator"
echo "======================================"

OUTPUT_FILE="CLAUDE.md"

# Check if file exists
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "ERROR: File $OUTPUT_FILE does not exist"
    exit 1
fi

echo "✓ File exists: $OUTPUT_FILE"

# Check required sections (from promptInitProyecto.txt format)
REQUIRED_SECTIONS=(
    "PROJECT IDENTITY"
    "ARCHITECTURE PATTERNS"
    "DETECTED CONVENTIONS"
    "HIDDEN COMPLEXITY"
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

# Check file is concise (between 200 and 300 lines for 1000-1500 words)
LINE_COUNT=$(wc -l < "$OUTPUT_FILE")
if [ "$LINE_COUNT" -lt 50 ]; then
    echo "ERROR: File seems too short ($LINE_COUNT lines). Expected at least 50 lines."
    exit 1
fi

if [ "$LINE_COUNT" -gt 500 ]; then
    echo "WARNING: File seems too long ($LINE_COUNT lines). Should be concise (1000-1500 words)."
fi

echo "✓ File has appropriate length ($LINE_COUNT lines)"

echo "======================================"
echo "Agent 23 validation PASSED"
echo "======================================"

exit 0
