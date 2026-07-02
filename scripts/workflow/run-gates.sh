#!/bin/bash
# run-gates.sh - Re-runnable quality gate for one wave (the factory gate).
#
# Single source of truth for wave validation: the post-commit hook and any
# manual/agent retry call THIS script, so pass/fail and the retry counter
# stay consistent. It is the ONLY piece that clears wave_N_blocked.flag.
#
# Usage: run-gates.sh <wave_num> [sprint_num]
#   wave_num:   0 (infra) | 3 (backend) | 4 (api) | 5 (frontend) | 6 (test)
#   sprint_num: 2-digit sprint (default: newest sprint_*_tasks.json found)
#
# Exit codes:
#   0 = gate PASS  -> clears .project-state/wave_<N>_blocked.flag, resets retries
#   1 = gate FAIL, retries still available (retry counter incremented)
#   2 = gate FAIL, retries exhausted -> wave_<N>_blocked.flag + needs_human.flag
#   3 = unknown wave / broken infrastructure

set +e

# Resolve Python interpreter (Linux/macOS/Windows Git Bash).
for _pd in "$(dirname "${BASH_SOURCE[0]}")/../lib/python-detect.sh" \
           "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/python-detect.sh" \
           "$HOME/.claude/redwork/scripts/lib/python-detect.sh"; do
    if [ -f "$_pd" ]; then . "$_pd"; break; fi
done
[ -n "${PYTHON_BIN:-}" ] || PYTHON_BIN=python3

# Detect framework scripts path (project vs framework repo mode).
# REDWORK_SCRIPTS overrides detection (tests / non-standard layouts).
if [ -n "${REDWORK_SCRIPTS:-}" ]; then
    SCRIPTS="$REDWORK_SCRIPTS"
elif [ -f "./scripts/lib/retry_controller.py" ]; then
    SCRIPTS="./scripts"   # framework repo itself
elif [ -d ".framework/scripts" ]; then
    SCRIPTS="./.framework/scripts"
elif [ -d "$HOME/.claude/redwork/scripts" ]; then
    SCRIPTS="$HOME/.claude/redwork/scripts"
else
    SCRIPTS="./scripts"
fi

WAVE_NUM="${1:-}"
SPRINT_NUM="${2:-}"

case "$WAVE_NUM" in
    0) WAVE_NAME="infra";    POST_WAVE_SCRIPT="" ;;
    3) WAVE_NAME="backend";  POST_WAVE_SCRIPT="post-wave-3-backend.sh" ;;
    4) WAVE_NAME="api";      POST_WAVE_SCRIPT="post-wave-4-api.sh" ;;
    5) WAVE_NAME="frontend"; POST_WAVE_SCRIPT="post-wave-5-frontend.sh" ;;
    6) WAVE_NAME="test";     POST_WAVE_SCRIPT="" ;;
    *)
        echo "ERROR: Unknown wave: '$WAVE_NUM' (valid: 0, 3, 4, 5, 6)"
        echo "Usage: run-gates.sh <wave_num> [sprint_num]"
        exit 3
        ;;
esac

RETRY_CTL="$SCRIPTS/lib/retry_controller.py"
if [ ! -f "$RETRY_CTL" ]; then
    echo "ERROR: retry_controller.py not found at $RETRY_CTL"
    exit 3
fi
if ! command -v "$PYTHON_BIN" >/dev/null 2>&1 && [ ! -x "$PYTHON_BIN" ]; then
    echo "ERROR: No Python interpreter available for the retry controller"
    exit 3
fi

# Default sprint: newest sprint_*_tasks.json in .project-state
if [ -z "$SPRINT_NUM" ]; then
    NEWEST=$(ls -1 .project-state/sprint_*_tasks.json 2>/dev/null | sort | tail -n 1)
    if [ -n "$NEWEST" ]; then
        SPRINT_NUM=$(basename "$NEWEST" | sed -E 's/^sprint_([0-9]+)_.*/\1/')
    fi
fi

GATE_ID="wave_${WAVE_NUM}"
FLAG=".project-state/wave_${WAVE_NUM}_blocked.flag"

echo "======================================"
echo "RUN-GATES: wave ${WAVE_NUM} (${WAVE_NAME})${SPRINT_NUM:+, sprint $SPRINT_NUM}"
echo "======================================"

GATE_PASSED=1

# --- Gate part 1: post-wave hook (lint, tests, security) -------------------
if [ -n "$POST_WAVE_SCRIPT" ]; then
    WAVE_HOOK="$SCRIPTS/hooks/$POST_WAVE_SCRIPT"
    if [ -x "$WAVE_HOOK" ] || [ -f "$WAVE_HOOK" ]; then
        if bash "$WAVE_HOOK"; then
            echo "[gate] $POST_WAVE_SCRIPT PASSED"
        else
            echo "[gate] $POST_WAVE_SCRIPT FAILED"
            GATE_PASSED=0
        fi
    else
        echo "[gate] WARNING: $WAVE_HOOK not found — treating as failure"
        GATE_PASSED=0
    fi
fi

# --- Gate part 2: sprint completeness (tasks vs repo) -----------------------
if [ "$GATE_PASSED" -eq 1 ] && [ -n "$SPRINT_NUM" ]; then
    COMPLETENESS="$SCRIPTS/workflow/validate-sprint-completeness.sh"
    if [ -f "$COMPLETENESS" ]; then
        if bash "$COMPLETENESS" "$SPRINT_NUM" --wave "$WAVE_NAME"; then
            echo "[gate] completeness gate CLEARED"
        else
            echo "[gate] completeness gate FAILED"
            GATE_PASSED=0
        fi
    fi
fi

# --- Record the attempt and act on the result --------------------------------
if [ "$GATE_PASSED" -eq 1 ]; then
    "$PYTHON_BIN" "$RETRY_CTL" record "$GATE_ID" pass >/dev/null 2>&1
    if [ -f "$FLAG" ]; then
        rm -f "$FLAG"
        echo "[gate] cleared $FLAG (wave unblocked automatically)"
    fi
    echo "RESULT: wave ${WAVE_NUM} gate PASS"
    exit 0
fi

RECORD=$("$PYTHON_BIN" "$RETRY_CTL" record "$GATE_ID" fail 2>/dev/null)
EXHAUSTED=$(echo "$RECORD" | "$PYTHON_BIN" -c "import json,sys; print('yes' if json.load(sys.stdin).get('exhausted') else 'no')" 2>/dev/null)
ATTEMPT=$(echo "$RECORD" | "$PYTHON_BIN" -c "import json,sys; d=json.load(sys.stdin); print(d.get('attempt','?'), d.get('max','?'))" 2>/dev/null)

mkdir -p .project-state
touch "$FLAG"

if [ "$EXHAUSTED" = "yes" ]; then
    touch ".project-state/needs_human.flag"
    echo "RESULT: wave ${WAVE_NUM} gate FAIL — retries EXHAUSTED (${ATTEMPT})"
    echo "needs_human.flag created. Escalate with a consolidated report:"
    echo "  what was attempted, evidence per attempt, concrete options."
    exit 2
fi

echo "RESULT: wave ${WAVE_NUM} gate FAIL — attempt ${ATTEMPT}, retry available"
echo "Fix within plan scope (build-error-resolver / re-run wave agent),"
echo "then re-run: bash $SCRIPTS/workflow/run-gates.sh $WAVE_NUM${SPRINT_NUM:+ $SPRINT_NUM}"
exit 1
