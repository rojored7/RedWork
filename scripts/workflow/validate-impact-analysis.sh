#!/bin/bash
# validate-impact-analysis.sh - Hard gate for the impact-prevalidator agent.
#
# Verifies that outputs/00b_impact_analysis.md exists, is fresh (anchored to
# the current HEAD, or recent by mtime when git is unavailable) and carries a
# passing verdict. Flows and Agent 25 Phase 0 (check 0.6) run this BEFORE
# planning or development: no fresh report, no pipeline.
#
# Usage: validate-impact-analysis.sh [--max-age-hours N] [--allow-amber]
#
# Exit codes:
#   0 = report exists, fresh, verdict VERDE (or AMARILLO with --allow-amber)
#   1 = verdict ROJO (or AMARILLO without --allow-amber)
#   2 = report does not exist
#   3 = report malformed (missing "## Veredicto:" or [ANALYZED-COMMIT:])
#   4 = report stale (ANALYZED-COMMIT != HEAD, or older than --max-age-hours)

set -u

# Resolve Python interpreter (Linux/macOS/Windows Git Bash).
for _pd in "$(dirname "${BASH_SOURCE[0]}")/../lib/python-detect.sh" \
           "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/python-detect.sh" \
           "$HOME/.claude/redwork/scripts/lib/python-detect.sh"; do
    if [ -f "$_pd" ]; then . "$_pd"; break; fi
done
[ -n "${PYTHON_BIN:-}" ] || PYTHON_BIN=python3

MAX_AGE_HOURS=24
ALLOW_AMBER=0

while [ $# -gt 0 ]; do
    case "$1" in
        --max-age-hours)
            MAX_AGE_HOURS="${2:-24}"
            shift 2
            ;;
        --allow-amber)
            ALLOW_AMBER=1
            shift
            ;;
        *)
            echo "ERROR: Unknown argument: $1"
            echo "Usage: validate-impact-analysis.sh [--max-age-hours N] [--allow-amber]"
            exit 3
            ;;
    esac
done

REPORT="outputs/00b_impact_analysis.md"

echo "======================================"
echo "Impact Analysis Gate"
echo "======================================"

if [ ! -f "$REPORT" ]; then
    echo "ERROR: $REPORT does not exist."
    echo "Run the impact-prevalidator agent first:"
    echo "  \"lanza el agente impact-prevalidator para <cambio>\""
    exit 2
fi

HEAD_SHA=$(git rev-parse HEAD 2>/dev/null || echo "")

RESULT=$("$PYTHON_BIN" - "$REPORT" "$HEAD_SHA" "$MAX_AGE_HOURS" <<'PYEOF'
import os
import re
import sys
import time

report_path, head_sha, max_age_hours = sys.argv[1], sys.argv[2], float(sys.argv[3])

with open(report_path, encoding="utf-8", errors="replace") as f:
    text = f.read()

verdict_match = re.search(r"^## Veredicto:\s*(VERDE|AMARILLO|ROJO)\b", text, re.MULTILINE)
commit_match = re.search(r"\[ANALYZED-COMMIT:\s*([0-9a-fA-F]{7,40})\s*\]", text)

if not verdict_match or not commit_match:
    missing = []
    if not verdict_match:
        missing.append("'## Veredicto: VERDE|AMARILLO|ROJO'")
    if not commit_match:
        missing.append("'[ANALYZED-COMMIT: <sha>]'")
    print("MALFORMED " + ",".join(missing))
    sys.exit(0)

verdict = verdict_match.group(1)
analyzed = commit_match.group(1).lower()

if head_sha:
    if not head_sha.lower().startswith(analyzed) and not analyzed.startswith(head_sha.lower()):
        print(f"STALE commit {analyzed[:12]} != HEAD {head_sha[:12]}")
        sys.exit(0)
else:
    age_hours = (time.time() - os.path.getmtime(report_path)) / 3600.0
    if age_hours > max_age_hours:
        print(f"STALE age {age_hours:.1f}h > {max_age_hours:g}h (no git anchor)")
        sys.exit(0)

print(f"OK {verdict}")
PYEOF
)

if [ -z "$RESULT" ]; then
    echo "ERROR: Could not parse $REPORT (Python interpreter failed)."
    exit 3
fi

case "$RESULT" in
    MALFORMED*)
        echo "ERROR: Report malformed. Missing: ${RESULT#MALFORMED }"
        echo "The impact-prevalidator must emit the exact output contract."
        exit 3
        ;;
    STALE*)
        echo "ERROR: Report stale (${RESULT#STALE })."
        echo "Re-run the impact-prevalidator agent against current HEAD."
        exit 4
        ;;
    "OK VERDE")
        echo "PASS: Impact analysis VERDE. Pipeline may proceed."
        exit 0
        ;;
    "OK AMARILLO")
        if [ "$ALLOW_AMBER" -eq 1 ]; then
            echo "PASS (with conditions): Impact analysis AMARILLO."
            echo "The plan MUST incorporate the report's 'Condiciones para VERDE'."
            exit 0
        fi
        echo "BLOCKED: Impact analysis AMARILLO and --allow-amber not given."
        echo "Either mitigate the conditions or re-run the gate with --allow-amber."
        exit 1
        ;;
    "OK ROJO")
        echo "BLOCKED: Impact analysis ROJO. Do NOT plan or implement."
        echo "Resolve the report's 'Condiciones para VERDE' first."
        exit 1
        ;;
    *)
        echo "ERROR: Unexpected gate result: $RESULT"
        exit 3
        ;;
esac
