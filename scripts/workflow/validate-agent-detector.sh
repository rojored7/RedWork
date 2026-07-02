#!/bin/bash
# Validation script for Project Type Detector - Project Type Detector

set -e

echo "======================================"
echo "Validating Project Type Detector - Project Type Detector"
echo "======================================"

OUTPUT_FILE="outputs/00_project_detection.md"
[ -f "$OUTPUT_FILE" ] || OUTPUT_FILE="00_project_detection.md"

# Check if file exists
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "ERROR: File $OUTPUT_FILE does not exist"
    exit 1
fi

echo "✓ File exists: $OUTPUT_FILE"

# Check required sections
REQUIRED_SECTIONS=(
    "Project Classification"
    "Technology Stack Detection"
    "Project Maturity Assessment"
    "Workflow Routing"
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

# Check project type is detected (Greenfield or Brownfield or Hybrid)
if ! grep -qE "(Greenfield|Brownfield|Hybrid)" "$OUTPUT_FILE"; then
    echo "ERROR: Project type not detected"
    exit 1
fi

echo "✓ Project type detected"

# Check file has sufficient content (at least 80 lines)
LINE_COUNT=$(wc -l < "$OUTPUT_FILE")
if [ "$LINE_COUNT" -lt 80 ]; then
    echo "ERROR: File seems too short ($LINE_COUNT lines). Expected at least 80 lines."
    exit 1
fi

echo "✓ File has sufficient content ($LINE_COUNT lines)"

echo "======================================"
echo "Project Type Detector validation PASSED"
echo "======================================"

exit 0
