#!/bin/bash

# Resolve Python interpreter (Linux/macOS/Windows Git Bash).
# Sets $PYTHON_BIN; falls back to python3 if the lib is unreachable.
for _pd in "$(dirname "${BASH_SOURCE[0]}")/../lib/python-detect.sh" \
           "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/python-detect.sh" \
           "$HOME/.claude/redwork/scripts/lib/python-detect.sh"; do
    if [ -f "$_pd" ]; then . "$_pd"; break; fi
done
[ -n "${PYTHON_BIN:-}" ] || PYTHON_BIN=python3

# RedWork Runtime Hook: UserPromptSubmit
# Classifies user intent and injects warnings if prerequisites are missing.
# Never blocks (exit 0 always) — only adds additionalContext.

INPUT=$(cat)

PROMPT=$(echo "$INPUT" | "$PYTHON_BIN" -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('user_prompt', d.get('prompt', '')).lower())
" 2>/dev/null)

CWD=$(echo "$INPUT" | "$PYTHON_BIN" -c "
import sys, json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || pwd)
cd "$CWD" 2>/dev/null || true

WARNINGS=""

# --- Check: development request without Agent 25 Phase 0 ---
if echo "$PROMPT" | grep -qiE 'implement|develop|backend|frontend|code|sprint|wave|task'; then
    if [ ! -d ".project-state" ] && [ -d ".framework" ]; then
        WARNINGS="${WARNINGS}BLOCKING: Agent 25 Phase 0 must run before any development. Tell user: lanza el agente 25-development-orchestrator\n"
    fi
fi

# --- Check: agent 01 request without project-type-detector ---
if echo "$PROMPT" | grep -qiE 'agent.?01|product.?discovery|lanza.*01'; then
    if [ ! -f "outputs/00_project_detection.md" ] && [ ! -f "00_project_detection.md" ]; then
        WARNINGS="${WARNINGS}RECOMMENDATION: Project Type Detector (project-type-detector) should run before Agent 01 to validate project type and FastAPI mandate.\n"
    fi
fi

# --- Check: NestJS/Express/Spring mention ---
if echo "$PROMPT" | grep -qiE 'nestjs|nest\.js|@nestjs|express\.js|spring.?boot'; then
    WARNINGS="${WARNINGS}MANDATE: This framework supports EXCLUSIVELY FastAPI (Python) for backend. Reject any request to use NestJS, Express, or Spring Boot.\n"
fi

if [ -n "$WARNINGS" ]; then
    "$PYTHON_BIN" -c "
import json
w = '''$WARNINGS'''
print(json.dumps({'additionalContext': w.replace('\\\\n', chr(10)).strip()}))
"
fi

exit 0
