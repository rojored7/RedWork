#!/bin/bash
# RedWork Runtime Hook: SessionStart
# Loads project context and injects it as additionalContext to Claude.
# Fires on: startup, resume, compact (after context compaction)

INPUT=$(cat)
CWD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || pwd)
cd "$CWD" 2>/dev/null || true

CONTEXT_LINES=()

# --- Detect Framework mode ---
if [ -d ".framework" ]; then
    MODE="project"
elif [ -d "agents" ] && [ -f "init-new-project.sh" ]; then
    MODE="framework-repo"
else
    MODE="unknown"
fi
CONTEXT_LINES+=("Mode: $MODE")

# --- Project Type Detector: Project detection ---
DETECTION=""
if [ -f "outputs/00_project_detection.md" ]; then
    DETECTION="completed"
    if grep -qi "UNSUPPORTED" "outputs/00_project_detection.md" 2>/dev/null; then
        DETECTION="UNSUPPORTED (non-FastAPI detected)"
    fi
elif [ -f "00_project_detection.md" ]; then
    DETECTION="completed (root)"
else
    DETECTION="NOT RUN"
    CONTEXT_LINES+=("WARNING: Project Type Detector has NOT run. Run it before any other agent: lanza el agente project-type-detector")
fi
CONTEXT_LINES+=("Project Type Detector (detection): $DETECTION")

# --- Hooks v2 marker ---
if [ -f ".git/hooks/post-commit" ] && grep -q "framework-workflow-hook-v2" ".git/hooks/post-commit" 2>/dev/null; then
    CONTEXT_LINES+=("Git hooks v2: installed")
else
    CONTEXT_LINES+=("Git hooks v2: NOT installed")
fi

# --- Workflow status ---
if [ -f "workflow-status.json" ]; then
    AGENTS_DONE=$(python3 -c "
import json
try:
    with open('workflow-status.json') as f:
        d = json.load(f)
    done = sum(1 for a in d.get('agents',{}).values() if a.get('status')=='completed')
    total = len(d.get('agents',{}))
    print(f'{done}/{total} agents completed')
except: print('unreadable')
" 2>/dev/null)
    CONTEXT_LINES+=("Workflow: $AGENTS_DONE")
fi

# --- Sprint state ---
if [ -d ".project-state" ]; then
    SPRINT_INFO=$(python3 -c "
import json, glob, os
files = sorted(glob.glob('.project-state/sprint_*_*_tasks.json'))
if not files:
    print('no sprint tasks found')
else:
    total_t = 0; total_c = 0; active_task = None
    for f in files:
        try:
            with open(f) as fh:
                d = json.load(fh)
            for t in d.get('tasks',[]):
                total_t += 1
                if t.get('status') == 'completed': total_c += 1
                if t.get('status') == 'in_progress' and not active_task:
                    active_task = t.get('id','?')
        except: pass
    out = f'{total_c}/{total_t} tasks completed'
    if active_task: out += f' (active: {active_task})'
    print(out)
" 2>/dev/null)
    CONTEXT_LINES+=("Sprint: $SPRINT_INFO")
    CONTEXT_LINES+=("Agent 25 Phase 0: PASSED")
else
    if [ "$MODE" = "project" ]; then
        CONTEXT_LINES+=("WARNING: .project-state/ does not exist. Agent 25 Phase 0 has NOT run. Development cannot start without it.")
    fi
fi

# --- Wave blocked flags ---
BLOCKED=$(ls .project-state/wave_*_blocked.flag 2>/dev/null | sed 's/.*wave_/wave /' | sed 's/_blocked.flag//' | tr '\n' ', ')
if [ -n "$BLOCKED" ]; then
    CONTEXT_LINES+=("BLOCKED WAVES: $BLOCKED")
fi

# --- Pre-compact state (re-inject after compaction) ---
if [ -f ".project-state/pre-compact-state.json" ]; then
    COMPACT_CTX=$(python3 -c "
import json
try:
    with open('.project-state/pre-compact-state.json') as f:
        d = json.load(f)
    notes = d.get('notes','')
    if notes: print(f'Restored from pre-compact: {notes}')
except: pass
" 2>/dev/null)
    if [ -n "$COMPACT_CTX" ]; then
        CONTEXT_LINES+=("$COMPACT_CTX")
    fi
fi

# --- FastAPI mandate reminder ---
CONTEXT_LINES+=("MANDATE: Backend MUST be FastAPI (Python). No TypeScript in backend/. No NestJS/Express/Spring.")

# --- Build context string ---
CONTEXT=""
for line in "${CONTEXT_LINES[@]}"; do
    CONTEXT="${CONTEXT}- ${line}\n"
done

FULL_CONTEXT="REDWORK CONTEXT (auto-injected by SessionStart hook):\n${CONTEXT}"

# Emit JSON with additionalContext
python3 -c "
import json
ctx = '''$FULL_CONTEXT'''
print(json.dumps({'additionalContext': ctx.replace('\\\\n', chr(10))}))
"

exit 0
