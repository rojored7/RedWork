#!/bin/bash

# Resolve Python interpreter (Linux/macOS/Windows Git Bash).
# Sets $PYTHON_BIN; falls back to python3 if the lib is unreachable.
for _pd in "$(dirname "${BASH_SOURCE[0]}")/../lib/python-detect.sh" \
           "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/python-detect.sh" \
           "$HOME/.claude/redwork/scripts/lib/python-detect.sh"; do
    if [ -f "$_pd" ]; then . "$_pd"; break; fi
done
[ -n "${PYTHON_BIN:-}" ] || PYTHON_BIN=python3

# ============================================================================
# update-workflow-status.sh
# ============================================================================
# Regenerates workflow-status.json dynamically from the real state of the
# repository: agent outputs in outputs/, task state in .project-state/,
# and completeness reports in outputs/compliance/.
#
# CRITICAL: This script does NOT commit or push. It only writes the JSON.
# Committing is the responsibility of whoever called it (post-commit hook,
# auto-commit-task.sh, etc.). This breaks the infinite loop:
#     update -> commit -> hook -> update -> commit -> ...
#
# Usage:
#   bash update-workflow-status.sh [<agent_or_task_id>]
#
# The argument is optional and informational — the JSON is always regenerated
# from scratch by scanning the filesystem.
#
# Exit codes:
#   0 = success
#   1 = python error or write failure
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

STATUS_FILE="workflow-status.json"
TRIGGER="${1:-<unspecified>}"

echo "Regenerating $STATUS_FILE (trigger: $TRIGGER)..."

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    echo "ERROR: "$PYTHON_BIN" is required but not installed"
    exit 1
fi

"$PYTHON_BIN" - "$STATUS_FILE" "$TRIGGER" <<'PYEOF'
import sys
import os
import re
import json
import glob
from datetime import datetime, timezone

status_file = sys.argv[1]
trigger     = sys.argv[2]

now_iso = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

state = {
    'workflow_version': '2.0.0',
    'last_updated':     now_iso,
    'last_trigger':     trigger,
    'agents':           {},
    'sprints':          {},
}

# ----------------------------------------------------------------------------
# Scan outputs/ for agent artifacts
# ----------------------------------------------------------------------------
AGENT_FILES = {
    'project_type_detector':         'outputs/00_project_detection.md',
    'agent_01_product_discovery':    'outputs/01_product_discovery.md',
    'agent_02_domain_modeling':      'outputs/02_domain_model.md',
    'agent_03_context_mapping':      'outputs/03_context_map.md',
    'agent_04_architecture_decision':'outputs/04_architecture_decision.md',
    'agent_05_service_design':       'outputs/05_service_design.md',
    'agent_06_epics':                'outputs/06_epics.md',
    'agent_07_user_stories':         'outputs/07_user_stories.md',
    'agent_08_implementation':       'outputs/08_implementation_breakdown.md',
    'agent_09_sprint_plan':          'outputs/09_sprint_plan',
    'agent_10_api_specification':    'outputs/10_api_specification.yaml',
    'agent_11_implementation_contract': 'outputs/11_implementation_contract.md',
}

# Fallback: also check project root (framework repo mode)
def find_artifact(path):
    if os.path.exists(path):
        return path
    base = os.path.basename(path)
    if os.path.exists(base):
        return base
    return None

for agent_name, expected in AGENT_FILES.items():
    found = find_artifact(expected)
    if found:
        mtime = os.path.getmtime(found)
        state['agents'][agent_name] = {
            'status':       'completed',
            'artifact':     found,
            'completed_at': datetime.fromtimestamp(mtime, timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
        }
    else:
        state['agents'][agent_name] = {'status': 'pending'}

# ----------------------------------------------------------------------------
# Scan .project-state/sprint_*_*_tasks.json for task progress
# ----------------------------------------------------------------------------
for task_file in sorted(glob.glob('.project-state/sprint_*_*_tasks.json')):
    fname = os.path.basename(task_file)
    m = re.match(r'sprint_(\d+)_(.+)_tasks\.json', fname)
    if not m:
        continue
    sprint_id = m.group(1)
    wave_name = m.group(2)

    try:
        with open(task_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except (IOError, json.JSONDecodeError):
        continue

    tasks = data.get('tasks', [])
    total     = len(tasks)
    completed = sum(1 for t in tasks if t.get('status') == 'completed')
    in_prog   = sum(1 for t in tasks if t.get('status') == 'in_progress')

    if sprint_id not in state['sprints']:
        state['sprints'][sprint_id] = {'waves': {}}

    state['sprints'][sprint_id]['waves'][wave_name] = {
        'total':       total,
        'completed':   completed,
        'in_progress': in_prog,
        'pending':     total - completed - in_prog,
        'pct':         round(100.0 * completed / total, 2) if total else 0.0,
    }

# ----------------------------------------------------------------------------
# Merge completeness reports from outputs/compliance/
# ----------------------------------------------------------------------------
for comp_file in sorted(glob.glob('outputs/compliance/sprint_*_completeness.json')):
    try:
        with open(comp_file, 'r', encoding='utf-8') as f:
            comp = json.load(f)
    except (IOError, json.JSONDecodeError):
        continue

    sprint_id = comp.get('sprint')
    if not sprint_id:
        continue
    if sprint_id not in state['sprints']:
        state['sprints'][sprint_id] = {'waves': {}}

    state['sprints'][sprint_id]['completeness'] = {
        'report':      comp_file,
        'totals':      comp.get('totals', {}),
        'generated_at':comp.get('generated_at'),
    }

# ----------------------------------------------------------------------------
# Atomic write
# ----------------------------------------------------------------------------
tmp_file = status_file + '.tmp'
with open(tmp_file, 'w', encoding='utf-8') as f:
    json.dump(state, f, indent=2)

os.replace(tmp_file, status_file)

print(f"OK: {status_file} regenerated")
print(f"  agents:  {sum(1 for a in state['agents'].values() if a['status'] == 'completed')}/{len(state['agents'])} completed")
print(f"  sprints: {len(state['sprints'])} tracked")
PYEOF

PY_EXIT=$?

if [ $PY_EXIT -ne 0 ]; then
    echo "ERROR: failed to regenerate $STATUS_FILE"
    exit 1
fi

exit 0
