#!/bin/bash

# Validation script for Agent 22: Design Compliance Validator
# Validates that outputs/compliance/sprint_NN_design_compliance.json exists
# and reports an accepted verdict.
#
# Usage: bash validate-agent-22.sh [<sprint-number>]
# Default sprint: latest found

set -e

SPRINT_ARG="${1:-}"

if [ -n "$SPRINT_ARG" ]; then
    SPRINT_NUM=$(printf "%02d" "$SPRINT_ARG" 2>/dev/null || echo "$SPRINT_ARG")
    REPORT_FILE="outputs/compliance/sprint_${SPRINT_NUM}_design_compliance.json"
else
    REPORT_FILE=$(ls -1 outputs/compliance/sprint_*_design_compliance.json 2>/dev/null | sort | tail -n 1)
fi

echo "Validating Agent 22 output: Design Compliance Report..."

# Check if file exists
if [ -z "$REPORT_FILE" ] || [ ! -f "$REPORT_FILE" ]; then
    echo "ERROR: Design Compliance Report not found"
    echo "Expected: outputs/compliance/sprint_NN_design_compliance.json"
    exit 1
fi

echo "File found: $REPORT_FILE"

# For JSON reports, required sections are required keys
REQUIRED_KEYS=(
    "executive_summary"
    "compliance_score"
    "exit_state"
    "layer_structure"
    "domain_layer"
    "application_layer"
    "dependency_rule"
    "final_verdict"
)

if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 required to parse JSON report"
    exit 1
fi

python3 - "$REPORT_FILE" "${REQUIRED_KEYS[@]}" <<'PYEOF'
import sys, json

report_file = sys.argv[1]
required    = sys.argv[2:]

try:
    with open(report_file, 'r', encoding='utf-8') as f:
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

print("All required keys found.")

score = data.get('compliance_score')
if score is not None:
    print(f"Compliance Score: {score}%")
    if float(score) < 99.0:
        print(f"WARNING: Compliance below threshold (<99%)")

exit_state = str(data.get('exit_state', '')).upper()
print(f"Exit State: {exit_state}")

if exit_state == 'APPROVED':
    print("Validation PASSED: Design compliance APPROVED")
    sys.exit(0)
elif exit_state == 'CONDITIONAL':
    print("Validation PASSED with CONDITIONS: Remediation required")
    sys.exit(0)
elif exit_state in ('REJECTED', 'BLOCKED'):
    print("Validation FAILED: Design compliance REJECTED - workflow BLOCKED")
    sys.exit(1)
else:
    print(f"WARNING: Unknown exit state: {exit_state}")
    sys.exit(1)
PYEOF
