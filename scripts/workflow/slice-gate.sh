#!/bin/bash
# slice-gate.sh - The per-slice quality gate of the factory flows.
#
# The flows (/flow-update, /flow-bugfix, /flow-new-project) call this
# DIRECTLY after implementing each TDD slice. It does not depend on git,
# commits, or hooks: it is a synchronous command the flow runs.
#
# Green slice = permission to checkpoint (checkpoint-commit.sh verifies the
# marker this script writes on success: .project-state/last_slice_gate.json).
#
# Usage: slice-gate.sh [backend|frontend|auto] [test-path]
#   backend : ruff + mypy + pytest --cov=app --cov-fail-under=100
#   frontend: eslint + tsc --noEmit + vitest run --coverage (thresholds 100
#             live in vitest.config.* — the project template sets them)
#   auto    : detect from changed files (git status) or run both if unclear
#   test-path (optional): restrict pytest/vitest to a module's tests
#
# Exit codes:
#   0 = slice green (marker written; checkpoint authorized)
#   1 = gate failed (fix within plan scope and re-run; counted via
#       retry_controller under gate id "slice")
#   3 = broken infrastructure (missing tools/dirs)

set +e

# Resolve Python interpreter (Linux/macOS/Windows Git Bash).
for _pd in "$(dirname "${BASH_SOURCE[0]}")/../lib/python-detect.sh" \
           "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/python-detect.sh" \
           "$HOME/.claude/redwork/scripts/lib/python-detect.sh"; do
    if [ -f "$_pd" ]; then . "$_pd"; break; fi
done
[ -n "${PYTHON_BIN:-}" ] || PYTHON_BIN=python3

# Locate retry controller (shared counter with wave gates)
RETRY_CTL=""
for _rc in "$(dirname "${BASH_SOURCE[0]}")/../lib/retry_controller.py" \
           "./scripts/lib/retry_controller.py" \
           "$HOME/.claude/redwork/scripts/lib/retry_controller.py"; do
    [ -f "$_rc" ] && RETRY_CTL="$_rc" && break
done

SIDE="${1:-auto}"
TEST_PATH="${2:-}"

if [ "$SIDE" = "auto" ]; then
    CHANGED=$(git status --porcelain 2>/dev/null | awk '{print $2}')
    HAS_BE=0; HAS_FE=0
    echo "$CHANGED" | grep -q "^backend/" && HAS_BE=1
    echo "$CHANGED" | grep -q "^frontend/" && HAS_FE=1
    if [ $HAS_BE -eq 1 ] && [ $HAS_FE -eq 0 ]; then SIDE="backend"
    elif [ $HAS_FE -eq 1 ] && [ $HAS_BE -eq 0 ]; then SIDE="frontend"
    else SIDE="both"
    fi
fi

echo "======================================"
echo "SLICE GATE: $SIDE${TEST_PATH:+ ($TEST_PATH)}"
echo "======================================"

ERRORS=0

run_backend_gate() {
    if [ ! -d "backend" ]; then
        echo "[slice-gate] ERROR: backend/ not found"
        return 3
    fi
    cd backend || return 3

    echo "[slice-gate] ruff check..."
    if ! "$PYTHON_BIN" -m ruff check . 2>/dev/null && ! ruff check . 2>/dev/null; then
        echo "[slice-gate] FAIL: ruff (or ruff not installed)"
        ERRORS=$((ERRORS + 1))
    fi

    echo "[slice-gate] mypy..."
    if ! "$PYTHON_BIN" -m mypy app/ 2>/dev/null && ! mypy app/ 2>/dev/null; then
        echo "[slice-gate] FAIL: mypy (or mypy not installed)"
        ERRORS=$((ERRORS + 1))
    fi

    echo "[slice-gate] pytest with 100% coverage gate..."
    if ! "$PYTHON_BIN" -c "import pytest_cov" 2>/dev/null; then
        echo "[slice-gate] FAIL: pytest-cov not installed (pip install pytest-cov)."
        echo "              Coverage is a HARD gate — absence is failure, not skip."
        ERRORS=$((ERRORS + 1))
    else
        if ! "$PYTHON_BIN" -m pytest ${TEST_PATH:-tests/} -q --tb=short \
             --cov=app --cov-report=term-missing --cov-fail-under=100; then
            echo "[slice-gate] FAIL: pytest/coverage below 100%"
            ERRORS=$((ERRORS + 1))
        fi
    fi
    cd ..
    return 0
}

run_frontend_gate() {
    if [ ! -d "frontend" ]; then
        echo "[slice-gate] ERROR: frontend/ not found"
        return 3
    fi
    cd frontend || return 3

    echo "[slice-gate] eslint..."
    if ! npx eslint src/ 2>/dev/null; then
        echo "[slice-gate] FAIL: eslint (or not installed)"
        ERRORS=$((ERRORS + 1))
    fi

    echo "[slice-gate] tsc --noEmit..."
    if ! npx tsc --noEmit 2>/dev/null; then
        echo "[slice-gate] FAIL: tsc (or not installed)"
        ERRORS=$((ERRORS + 1))
    fi

    echo "[slice-gate] vitest with coverage (thresholds 100 from vitest.config)..."
    if ! npx vitest run --coverage ${TEST_PATH:+--dir "$TEST_PATH"} 2>/dev/null; then
        echo "[slice-gate] FAIL: vitest/coverage thresholds (or coverage provider missing)."
        echo "              Coverage is a HARD gate — absence is failure, not skip."
        ERRORS=$((ERRORS + 1))
    fi
    cd ..
    return 0
}

case "$SIDE" in
    backend)  run_backend_gate;  RC=$? ;;
    frontend) run_frontend_gate; RC=$? ;;
    both)
        run_backend_gate;  RC=$?
        [ $RC -eq 0 ] && { run_frontend_gate; RC=$?; }
        ;;
    *)
        echo "ERROR: Unknown side '$SIDE' (backend|frontend|auto)"
        exit 3
        ;;
esac
[ "$RC" = "3" ] && exit 3

record_attempt() {
    local result="$1"
    if [ -n "$RETRY_CTL" ]; then
        "$PYTHON_BIN" "$RETRY_CTL" record "slice" "$result" >/dev/null 2>&1
    fi
}

if [ $ERRORS -eq 0 ]; then
    mkdir -p .project-state
    "$PYTHON_BIN" - "$SIDE" <<'PYEOF'
import json, subprocess, sys, time
sha = ""
try:
    sha = subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True,
                         text=True, timeout=5).stdout.strip()
except Exception:
    pass
marker = {"side": sys.argv[1], "passed_at_epoch": int(time.time()),
          "head_at_pass": sha}
with open(".project-state/last_slice_gate.json", "w", encoding="utf-8") as f:
    json.dump(marker, f, indent=2)
PYEOF
    record_attempt pass
    echo "RESULT: SLICE GREEN — checkpoint authorized (checkpoint-commit.sh)"
    exit 0
fi

record_attempt fail
echo "RESULT: SLICE FAILED ($ERRORS check(s)) — fix within plan scope and re-run"
exit 1
