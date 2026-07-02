#!/bin/bash

# Resolve Python interpreter (Linux/macOS/Windows Git Bash).
# Sets $PYTHON_BIN; falls back to python3 if the lib is unreachable.
for _pd in "$(dirname "${BASH_SOURCE[0]}")/../lib/python-detect.sh" \
           "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/python-detect.sh" \
           "$HOME/.claude/redwork/scripts/lib/python-detect.sh"; do
    if [ -f "$_pd" ]; then . "$_pd"; break; fi
done
[ -n "${PYTHON_BIN:-}" ] || PYTHON_BIN=python3

# RedWork Runtime Hook: PreCompact
# Saves critical context before Claude compacts its conversation.
# SessionStart (matcher: compact) re-injects this after compaction.

INPUT=$(cat)

CWD=$(echo "$INPUT" | "$PYTHON_BIN" -c "
import sys, json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || pwd)
cd "$CWD" 2>/dev/null || true

if [ ! -d ".project-state" ]; then
    exit 0
fi

"$PYTHON_BIN" -c "
import json, glob, os
from datetime import datetime, timezone

state = {
    'saved_at': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'notes': '',
}

# Active sprint and wave
ctx_file = '.project-state/current_context.json'
if os.path.exists(ctx_file):
    try:
        with open(ctx_file) as f:
            ctx = json.load(f)
        state['active_sprint'] = ctx.get('active_sprint')
        state['active_agent'] = ctx.get('active_agent')
        state['last_task'] = ctx.get('last_task')
    except: pass

# Task progress
total_t = 0; total_c = 0; active = None
for f in sorted(glob.glob('.project-state/sprint_*_*_tasks.json')):
    try:
        with open(f) as fh:
            d = json.load(fh)
        for t in d.get('tasks', []):
            total_t += 1
            if t.get('status') == 'completed': total_c += 1
            if t.get('status') == 'in_progress' and not active:
                active = t.get('id')
    except: pass

state['tasks_completed'] = total_c
state['tasks_total'] = total_t
state['active_task'] = active

# Wave blocked flags
blocked = []
for flag in glob.glob('.project-state/wave_*_blocked.flag'):
    wave = os.path.basename(flag).replace('wave_','').replace('_blocked.flag','')
    blocked.append(wave)
state['blocked_waves'] = blocked

# Build notes string for re-injection
parts = []
parts.append(f'Sprint {state.get(\"active_sprint\",\"?\")}')
parts.append(f'Tasks: {total_c}/{total_t}')
if active: parts.append(f'Active task: {active}')
if blocked: parts.append(f'Blocked waves: {\" \".join(blocked)}')
state['notes'] = ' | '.join(parts)

# Write atomically
tmp = '.project-state/pre-compact-state.json.tmp'
target = '.project-state/pre-compact-state.json'
with open(tmp, 'w') as f:
    json.dump(state, f, indent=2)
os.replace(tmp, target)
" 2>/dev/null

exit 0
