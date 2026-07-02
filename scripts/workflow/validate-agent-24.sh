#!/bin/bash

# Resolve Python interpreter (Linux/macOS/Windows Git Bash).
# Sets $PYTHON_BIN; falls back to python3 if the lib is unreachable.
for _pd in "$(dirname "${BASH_SOURCE[0]}")/../lib/python-detect.sh" \
           "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/python-detect.sh" \
           "$HOME/.claude/redwork/scripts/lib/python-detect.sh"; do
    if [ -f "$_pd" ]; then . "$_pd"; break; fi
done
[ -n "${PYTHON_BIN:-}" ] || PYTHON_BIN=python3

# Validation script for Agent 24 - Build & Deploy Analyzer
# Validates that outputs/compliance/sprint_NN_build_deploy_analysis.json exists
# and contains required keys.
#
# Usage: bash validate-agent-24.sh [<sprint-number>]

set -e

echo "======================================"
echo "Validating Agent 24 - Build & Deploy Analyzer"
echo "======================================"

SPRINT_ARG="${1:-}"

if [ -n "$SPRINT_ARG" ]; then
    SPRINT_NUM=$(printf "%02d" "$SPRINT_ARG" 2>/dev/null || echo "$SPRINT_ARG")
    OUTPUT_FILE="outputs/compliance/sprint_${SPRINT_NUM}_build_deploy_analysis.json"
else
    OUTPUT_FILE=$(ls -1 outputs/compliance/sprint_*_build_deploy_analysis.json 2>/dev/null | sort | tail -n 1)
fi

# Check if file exists
if [ -z "$OUTPUT_FILE" ] || [ ! -f "$OUTPUT_FILE" ]; then
    echo "ERROR: File does not exist"
    echo "Expected: outputs/compliance/sprint_NN_build_deploy_analysis.json"
    exit 1
fi

echo "File exists: $OUTPUT_FILE"

REQUIRED_KEYS=(
    "build_system_configuration"
    "cicd_pipeline_analysis"
    "containerization"
    "deployment_strategy"
)

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    echo "ERROR: "$PYTHON_BIN" required to parse JSON report"
    exit 1
fi

"$PYTHON_BIN" - "$OUTPUT_FILE" "${REQUIRED_KEYS[@]}" <<'PYEOF'
import sys, json

output_file = sys.argv[1]
required    = sys.argv[2:]

try:
    with open(output_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
except Exception as e:
    print(f"ERROR: could not parse JSON: {e}")
    sys.exit(1)

missing = [k for k in required if k not in data]
if missing:
    print("ERROR: Missing required keys:")
    for k in missing:
        print(f"  - {k}")
    sys.exit(1)

print("All required keys present")
PYEOF

PY_EXIT=$?

if [ $PY_EXIT -ne 0 ]; then
    exit 1
fi

echo "======================================"
echo "Agent 24 validation PASSED"
echo "======================================"

exit 0
