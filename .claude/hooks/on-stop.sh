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

# Update last_activity timestamp
python3 -c "
import json, os
from datetime import datetime, timezone

ctx_file = '.project-state/current_context.json'
if os.path.exists(ctx_file):
    try:
        with open(ctx_file, 'r') as f:
            ctx = json.load(f)
        ctx['last_activity'] = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
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
