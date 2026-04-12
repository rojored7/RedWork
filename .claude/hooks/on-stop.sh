#!/bin/bash
# RedWork Runtime Hook: Stop
# Persists session state when Claude finishes a response.
# Lightweight — must complete quickly.

INPUT=$(cat)

CWD=$(echo "$INPUT" | python3 -c "
import sys, json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || pwd)
cd "$CWD" 2>/dev/null || true

# Only act if .project-state exists (Agent 25 has run)
if [ ! -d ".project-state" ]; then
    exit 0
fi

# Update last_activity in state.json and current_context.json
python3 -c "
import json, os
from datetime import datetime, timezone

now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

# Update state.json
state_file = '.project-state/state.json'
if os.path.exists(state_file):
    try:
        with open(state_file, 'r') as f:
            state = json.load(f)
        state['last_activity'] = now
        tmp = state_file + '.tmp'
        with open(tmp, 'w') as f:
            json.dump(state, f, indent=2)
        os.replace(tmp, state_file)
    except: pass

# Update current_context.json (legacy compat)
ctx_file = '.project-state/current_context.json'
if os.path.exists(ctx_file):
    try:
        with open(ctx_file, 'r') as f:
            ctx = json.load(f)
        ctx['last_activity'] = now
        tmp = ctx_file + '.tmp'
        with open(tmp, 'w') as f:
            json.dump(ctx, f, indent=2)
        os.replace(tmp, ctx_file)
    except: pass
" 2>/dev/null

# Refresh workflow-status.json if outputs/ or .project-state/ changed recently
SCRIPTS_PATH=""
if [ -d ".framework/scripts" ]; then
    SCRIPTS_PATH=".framework/scripts"
elif [ -d "scripts" ]; then
    SCRIPTS_PATH="scripts"
fi

if [ -n "$SCRIPTS_PATH" ] && [ -x "$SCRIPTS_PATH/workflow/update-workflow-status.sh" ]; then
    # Only run if workflow-status.json is older than 60 seconds
    if [ -f "workflow-status.json" ]; then
        AGE=$(( $(date +%s) - $(stat -c %Y "workflow-status.json" 2>/dev/null || echo 0) ))
        if [ "$AGE" -gt 60 ]; then
            bash "$SCRIPTS_PATH/workflow/update-workflow-status.sh" "stop-hook" >/dev/null 2>&1 || true
        fi
    fi
fi

exit 0
