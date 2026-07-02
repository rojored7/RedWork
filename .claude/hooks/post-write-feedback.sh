#!/bin/bash

# Resolve Python interpreter (Linux/macOS/Windows Git Bash).
# Sets $PYTHON_BIN; falls back to python3 if the lib is unreachable.
for _pd in "$(dirname "${BASH_SOURCE[0]}")/../lib/python-detect.sh" \
           "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/python-detect.sh" \
           "$HOME/.claude/redwork/scripts/lib/python-detect.sh"; do
    if [ -f "$_pd" ]; then . "$_pd"; break; fi
done
[ -n "${PYTHON_BIN:-}" ] || PYTHON_BIN=python3

# RedWork Runtime Hook: PostToolUse (Write|Edit)
# Provides feedback after file writes. Never blocks.

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | "$PYTHON_BIN" -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('file_path', ti.get('filePath', '')))
" 2>/dev/null)

CWD=$(echo "$INPUT" | "$PYTHON_BIN" -c "
import sys, json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || pwd)
cd "$CWD" 2>/dev/null || true

FILE_PATH=$(echo "$FILE_PATH" | sed 's|^\./||' | sed "s|^$(pwd)/||")

FEEDBACK=""

# --- Backend file touched: remind about linting ---
if echo "$FILE_PATH" | grep -qE '^backend/.*\.py$'; then
    if [ -f "backend/pyproject.toml" ] || [ -f "backend/setup.cfg" ]; then
        FEEDBACK="REMINDER: Backend file modified. Run ruff check / ruff format on modified files before committing."
    fi
fi

# --- Frontend src touched without design system ---
if echo "$FILE_PATH" | grep -qE '^frontend/src/'; then
    if [ ! -d "frontend/src/design-system" ] && [ ! -f "frontend/tailwind.config.ts" ] && [ ! -f "frontend/tailwind.config.js" ]; then
        FEEDBACK="WARNING: Frontend code written but design system not configured. Agent 11 Phase 0 requires design tokens (tailwind.config.ts or design-system/tokens/) before writing screens."
    fi
fi

# --- Agent output artifact written ---
if echo "$FILE_PATH" | grep -qE '^outputs/[0-9]+'; then
    ARTIFACT=$(basename "$FILE_PATH")
    FEEDBACK="Agent artifact written: $ARTIFACT. Auto-commit with: bash scripts/workflow/auto-commit-agent-output.sh $FILE_PATH"
fi

if [ -n "$FEEDBACK" ]; then
    "$PYTHON_BIN" -c "
import json
print(json.dumps({'additionalContext': '''$FEEDBACK'''}))
"
fi

exit 0
