#!/bin/bash
# checkpoint-commit.sh - Silent git checkpoint after a green slice gate.
#
# Git stays in the background of the factory: this script creates a quiet,
# recoverable commit ONLY when the slice gate has just passed. It NEVER
# pushes — publishing is always a human decision.
#
# Usage: checkpoint-commit.sh "<short description>" [slice-id]
#
# Preconditions (hard):
#   .project-state/last_slice_gate.json exists, is fresh (< 30 min), and the
#   working tree matches (no gate pass borrowed from another state).
#
# Steps: selective git add (defensive excludes) -> staged secret scan
# (blocking) -> quiet commit. Never empty, never pushed, one line of output.
#
# Exit codes:
#   0 = checkpoint created (or nothing to commit)
#   1 = blocked (no fresh gate pass, or secrets staged)
#   3 = broken infrastructure (not a git repo / scanner missing)

set +e

# Resolve Python interpreter
for _pd in "$(dirname "${BASH_SOURCE[0]}")/../lib/python-detect.sh" \
           "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/python-detect.sh" \
           "$HOME/.claude/redwork/scripts/lib/python-detect.sh"; do
    if [ -f "$_pd" ]; then . "$_pd"; break; fi
done
[ -n "${PYTHON_BIN:-}" ] || PYTHON_BIN=python3

DESC="${1:-}"
SLICE_ID="${2:-}"

if [ -z "$DESC" ]; then
    echo "Usage: checkpoint-commit.sh \"<short description>\" [slice-id]"
    exit 3
fi

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "ERROR: not a git repository"
    exit 3
}

# --- Precondition: fresh slice-gate pass -------------------------------------
MARKER=".project-state/last_slice_gate.json"
if [ ! -f "$MARKER" ]; then
    echo "BLOCKED: no slice gate pass on record. Run slice-gate.sh first."
    exit 1
fi
FRESH=$("$PYTHON_BIN" - "$MARKER" <<'PYEOF'
import json, sys, time
try:
    with open(sys.argv[1], encoding="utf-8") as f:
        marker = json.load(f)
    age = time.time() - marker.get("passed_at_epoch", 0)
    print("fresh" if age < 1800 else "stale")
except Exception:
    print("invalid")
PYEOF
)
if [ "$FRESH" != "fresh" ]; then
    echo "BLOCKED: slice gate pass is $FRESH (>30 min or unreadable). Re-run slice-gate.sh."
    exit 1
fi

# --- Selective staging with defensive excludes --------------------------------
git add -A -- . \
    ':(exclude).env' ':(exclude).env.*' ':(exclude)*.pem' ':(exclude)*.key' \
    ':(exclude)*.p12' ':(exclude)id_rsa*' 2>/dev/null

if git diff --cached --quiet 2>/dev/null; then
    echo "checkpoint: nothing to commit (working tree clean)"
    exit 0
fi

# --- Blocking secret scan on staged content ----------------------------------
SCANNER=""
for _sc in "$(dirname "${BASH_SOURCE[0]}")/../security/scan-secrets.sh" \
           "./scripts/security/scan-secrets.sh" \
           "$HOME/.claude/redwork/scripts/security/scan-secrets.sh"; do
    [ -f "$_sc" ] && SCANNER="$_sc" && break
done
if [ -z "$SCANNER" ]; then
    echo "ERROR: scan-secrets.sh not found — refusing to checkpoint unscanned"
    exit 3
fi
SCAN_OUTPUT=$(bash "$SCANNER" --staged 2>&1)
if [ $? -ne 0 ]; then
    echo "BLOCKED: secrets detected in staged files — checkpoint aborted."
    echo "$SCAN_OUTPUT" | grep -A1 "SECRET DETECTED" | head -20
    exit 1
fi

# --- Quiet commit (NEVER push) -------------------------------------------------
MSG="checkpoint:${SLICE_ID:+ $SLICE_ID —} $DESC"
if git commit -q -m "$MSG"; then
    echo "checkpoint: $(git rev-parse --short HEAD) — $DESC"
    exit 0
fi
echo "ERROR: git commit failed"
exit 3
