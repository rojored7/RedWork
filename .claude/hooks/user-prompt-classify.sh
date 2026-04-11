#!/bin/bash
# RedWork Runtime Hook: UserPromptSubmit
# Classifies user intent and injects warnings if prerequisites are missing.
# Never blocks (exit 0 always) — only adds additionalContext.

INPUT=$(cat)

PROMPT=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('user_prompt', d.get('prompt', '')).lower())
" 2>/dev/null)

CWD=$(echo "$INPUT" | python3 -c "
import sys, json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || pwd)
cd "$CWD" 2>/dev/null || true

WARNINGS=""

# --- Check: development request without Agent 25 Phase 0 ---
if echo "$PROMPT" | grep -qiE 'implement|develop|backend|frontend|code|sprint|wave|task'; then
    if [ ! -d ".project-state" ] && [ -d ".framework" ]; then
        WARNINGS="${WARNINGS}BLOCKING: Agent 25 Phase 0 must run before any development. Tell user: lanza el agente 25-development-orchestrator\n"
    fi
fi

# --- Check: agent 01 request without agent 00 ---
if echo "$PROMPT" | grep -qiE 'agent.?01|product.?discovery|lanza.*01'; then
    if [ ! -f "outputs/00_project_detection.md" ] && [ ! -f "00_project_detection.md" ]; then
        WARNINGS="${WARNINGS}RECOMMENDATION: Agent 00 (project-type-detector) should run before Agent 01 to validate project type and FastAPI mandate.\n"
    fi
fi

# --- Check: NestJS/Express/Spring mention ---
if echo "$PROMPT" | grep -qiE 'nestjs|nest\.js|@nestjs|express\.js|spring.?boot'; then
    WARNINGS="${WARNINGS}MANDATE: This framework supports EXCLUSIVELY FastAPI (Python) for backend. Reject any request to use NestJS, Express, or Spring Boot.\n"
fi

if [ -n "$WARNINGS" ]; then
    python3 -c "
import json
w = '''$WARNINGS'''
print(json.dumps({'additionalContext': w.replace('\\\\n', chr(10)).strip()}))
"
fi

exit 0
