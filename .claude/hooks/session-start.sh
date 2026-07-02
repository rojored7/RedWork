#!/bin/bash

# Resolve Python interpreter (Linux/macOS/Windows Git Bash).
# Sets $PYTHON_BIN; falls back to python3 if the lib is unreachable.
for _pd in "$(dirname "${BASH_SOURCE[0]}")/../lib/python-detect.sh" \
           "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/python-detect.sh" \
           "$HOME/.claude/redwork/scripts/lib/python-detect.sh"; do
    if [ -f "$_pd" ]; then . "$_pd"; break; fi
done
[ -n "${PYTHON_BIN:-}" ] || PYTHON_BIN=python3

# RedWork Runtime Hook: SessionStart
# Loads project context and injects it as additionalContext to Claude.
# Fires on: startup, resume, compact (after context compaction)

INPUT=$(cat)
CWD=$(echo "$INPUT" | "$PYTHON_BIN" -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || pwd)
cd "$CWD" 2>/dev/null || true

CONTEXT_LINES=()

# --- Detect Framework mode ---
if [ -d ".framework" ]; then
    MODE="project"
elif [ -d "agents" ] && [ -f "install.py" ]; then
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

# --- State.json (v2.0 unified state) ---
if [ -f ".project-state/state.json" ]; then
    STATE_INFO=$("$PYTHON_BIN" -c "
import json
try:
    with open('.project-state/state.json') as f:
        s = json.load(f)
    phase = s.get('current_phase', '?')
    stack_b = s.get('stack', {}).get('backend', '?')
    stack_f = s.get('stack', {}).get('frontend', '?')
    agents_done = sum(1 for a in s.get('agents', {}).values() if a.get('status') == 'completed')
    agents_total = len(s.get('agents', {}))
    sprints = s.get('sprints', {})
    active_sprint = None
    for sn, sv in sorted(sprints.items()):
        if sv.get('status') != 'completed':
            active_sprint = sn
            break
    parts = []
    parts.append(f'Phase: {phase}')
    parts.append(f'Stack: {stack_b}/{stack_f}')
    parts.append(f'Agents: {agents_done}/{agents_total} completed')
    if active_sprint:
        waves = sprints[active_sprint].get('waves', {})
        wave_info = ', '.join(f'{k}={v.get(\"status\",\"?\")}' for k,v in waves.items())
        parts.append(f'Sprint {active_sprint}: {wave_info or \"starting\"}')
    print(' | '.join(parts))
except Exception as e:
    print(f'state error: {e}')
" 2>/dev/null)
    CONTEXT_LINES+=("State: $STATE_INFO")
elif [ -f "workflow-status.json" ]; then
    AGENTS_DONE=$("$PYTHON_BIN" -c "
import json
try:
    with open('workflow-status.json') as f:
        d = json.load(f)
    done = sum(1 for a in d.get('agents',{}).values() if a.get('status')=='completed')
    total = len(d.get('agents',{}))
    print(f'{done}/{total} agents completed')
except: print('unreadable')
" 2>/dev/null)
    CONTEXT_LINES+=("Workflow (legacy): $AGENTS_DONE")
fi

# --- Sprint state (from state.json or legacy task files) ---
if [ -d ".project-state" ]; then
    SPRINT_INFO=$("$PYTHON_BIN" -c "
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
    CONTEXT_LINES+=("BLOCKED WAVES: $BLOCKED(fix within plan scope, then re-run: bash scripts/workflow/run-gates.sh <wave>)")
fi

# --- Factory loop: escalation flag and retry state ---
if [ -f ".project-state/needs_human.flag" ]; then
    CONTEXT_LINES+=("NEEDS HUMAN: a gate exhausted its retries. Present a consolidated report (attempts, evidence, options). Clear .project-state/needs_human.flag only after the human decides.")
fi
if [ -f ".project-state/retry_state.json" ]; then
    RETRY_INFO=$("$PYTHON_BIN" -c "
import json
try:
    with open('.project-state/retry_state.json') as f:
        d = json.load(f)
    active = {g: i.get('attempts', 0) for g, i in d.get('gates', {}).items() if i.get('attempts', 0) > 0}
    if active:
        print('RETRY STATE: ' + ', '.join(f'{g}={a} attempts' for g, a in active.items()))
except Exception:
    pass
" 2>/dev/null)
    if [ -n "$RETRY_INFO" ]; then
        CONTEXT_LINES+=("$RETRY_INFO")
    fi
fi

# --- Pre-compact state (re-inject after compaction) ---
if [ -f ".project-state/pre-compact-state.json" ]; then
    COMPACT_CTX=$("$PYTHON_BIN" -c "
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

# --- Learning system status ---
if [ -d ".learning" ]; then
    LEARNING_INFO=$("$PYTHON_BIN" -c "
import sys, os
sys.path.insert(0, os.environ.get('REDWORK_ROOT', os.path.expanduser('~/.claude/redwork')))
try:
    from scripts.lib.learning_manager import LearningManager
    lm = LearningManager('.')
    obs = lm.observation_count()
    proj = len(lm.list_instincts(scope='project'))
    glob = len(lm.list_instincts(scope='global'))
    active = len(lm.list_instincts(scope='project', min_confidence=0.5))
    print(f'observations={obs}, project_instincts={proj}, global_instincts={glob}, active={active}')
except Exception:
    print('unavailable')
" 2>/dev/null)
    if [ -n "$LEARNING_INFO" ] && [ "$LEARNING_INFO" != "unavailable" ]; then
        CONTEXT_LINES+=("LEARNING: $LEARNING_INFO")
    fi
fi

# --- Build context string ---
CONTEXT=""
for line in "${CONTEXT_LINES[@]}"; do
    CONTEXT="${CONTEXT}- ${line}\n"
done

FULL_CONTEXT="REDWORK CONTEXT (auto-injected by SessionStart hook):\n${CONTEXT}"

# Emit JSON with additionalContext
"$PYTHON_BIN" -c "
import json
ctx = '''$FULL_CONTEXT'''
print(json.dumps({'additionalContext': ctx.replace('\\\\n', chr(10))}))
"

exit 0
