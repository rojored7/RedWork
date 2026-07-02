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
# validate-sprint-completeness.sh
# ============================================================================
# Sprint Completeness Gate — THE MISSING STRUCTURAL PIECE
#
# Parses 09_sprint_plan/sprint_NN/*_tasks.md + .project-state/sprint_NN_*_tasks.json
# and diffs them against the actual repo tree. Emits a per-task JSON report.
#
# This is the script that answers: "of the N planned tasks, how many are
# physically present in the repo?" — the question nobody was asking before.
#
# Usage:
#   bash validate-sprint-completeness.sh <sprint-number> [--wave <wave-name>]
#
# Examples:
#   bash validate-sprint-completeness.sh 01
#   bash validate-sprint-completeness.sh 02 --wave backend
#
# Exit codes:
#   0 = 100% implemented (safe to close wave/sprint)
#   1 = missing tasks detected (blocks wave closure)
#   2 = sprint plan not found or unparseable
#   3 = invalid arguments
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

# ----------------------------------------------------------------------------
# Argument parsing
# ----------------------------------------------------------------------------
if [ $# -lt 1 ]; then
    echo "ERROR: Sprint number required"
    echo "Usage: $0 <sprint-number> [--wave <wave-name>]"
    echo "Example: $0 01"
    exit 3
fi

SPRINT_NUM=$(printf "%02d" "$1" 2>/dev/null || echo "$1")
WAVE_FILTER=""

shift || true
while [ $# -gt 0 ]; do
    case "$1" in
        --wave)
            WAVE_FILTER="$2"
            shift 2
            ;;
        *)
            echo "ERROR: Unknown argument: $1"
            exit 3
            ;;
    esac
done

SPRINT_DIR="09_sprint_plan/sprint_${SPRINT_NUM}"
STATE_DIR=".project-state"
OUTPUT_DIR="outputs/compliance"
OUTPUT_FILE="${OUTPUT_DIR}/sprint_${SPRINT_NUM}_completeness.json"

echo "============================================================================"
echo "Sprint ${SPRINT_NUM} Completeness Validation"
echo "============================================================================"
echo "Sprint dir:  $SPRINT_DIR"
echo "State dir:   $STATE_DIR"
echo "Wave filter: ${WAVE_FILTER:-<all>}"
echo "Output:      $OUTPUT_FILE"
echo ""

# ----------------------------------------------------------------------------
# Preflight
# ----------------------------------------------------------------------------
if [ ! -d "$SPRINT_DIR" ]; then
    echo "ERROR: Sprint directory not found: $SPRINT_DIR"
    echo "Expected tasks files at: $SPRINT_DIR/*_tasks.md"
    exit 2
fi

TASK_FILES=$(find "$SPRINT_DIR" -maxdepth 1 -name "*_tasks.md" -type f 2>/dev/null)
if [ -z "$TASK_FILES" ]; then
    echo "ERROR: No *_tasks.md files found in $SPRINT_DIR"
    exit 2
fi

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    echo "ERROR: "$PYTHON_BIN" is required but not installed"
    exit 2
fi

mkdir -p "$OUTPUT_DIR"

# ----------------------------------------------------------------------------
# Main: delegate parsing + walking to Python (safer than bash for JSON)
# ----------------------------------------------------------------------------
"$PYTHON_BIN" - "$SPRINT_NUM" "$SPRINT_DIR" "$STATE_DIR" "$OUTPUT_FILE" "$WAVE_FILTER" <<'PYEOF'
import sys
import os
import re
import json
import glob
from datetime import datetime, timezone

sprint_num   = sys.argv[1]
sprint_dir   = sys.argv[2]
state_dir    = sys.argv[3]
output_file  = sys.argv[4]
wave_filter  = sys.argv[5] if len(sys.argv) > 5 else ""

# ----------------------------------------------------------------------------
# Parse tasks from *_tasks.md files
# ----------------------------------------------------------------------------
# Expected format per task (convention enforced by Agent 08):
#
#   ### Task S1-BE-007: <description>
#   ...
#   ### Expected Files:
#   - backend/app/endpoints/auth.py
#   - backend/app/schemas/auth.py
#   ...
#
# The script is tolerant: if a task has no Expected Files section, it is
# marked "unverifiable" and the aggregate score is reduced proportionally.

TASK_ID_RE = re.compile(r'^#{1,6}\s*(?:Task\s+)?(S\d+-[A-Z]{2,5}-\d{3})\b[:\s]*(.*)$', re.IGNORECASE)
EXPECTED_HEADER_RE = re.compile(r'^#{1,6}\s*Expected\s+Files\s*:?\s*$', re.IGNORECASE)
LIST_ITEM_RE = re.compile(r'^\s*[-*]\s+`?([^`\n]+?)`?\s*$')
HEADER_RE = re.compile(r'^#{1,6}\s+')

def parse_task_file(path):
    tasks = []
    current = None
    in_expected_block = False

    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()

    for raw in lines:
        line = raw.rstrip('\n')

        m_task = TASK_ID_RE.match(line)
        if m_task:
            if current:
                tasks.append(current)
            current = {
                'id': m_task.group(1),
                'description': m_task.group(2).strip().lstrip(':').strip(),
                'expected_files': [],
                'source_file': os.path.basename(path),
            }
            in_expected_block = False
            continue

        if current is None:
            continue

        if EXPECTED_HEADER_RE.match(line):
            in_expected_block = True
            continue

        if in_expected_block:
            if HEADER_RE.match(line):
                in_expected_block = False
                continue
            m_item = LIST_ITEM_RE.match(line)
            if m_item:
                pattern = m_item.group(1).strip()
                if pattern and not pattern.startswith('<'):
                    current['expected_files'].append(pattern)

    if current:
        tasks.append(current)

    return tasks

all_tasks = []
for task_file in sorted(glob.glob(os.path.join(sprint_dir, '*_tasks.md'))):
    all_tasks.extend(parse_task_file(task_file))

if not all_tasks:
    print(f"ERROR: No tasks parsed from {sprint_dir}/*_tasks.md", file=sys.stderr)
    print("Hint: each task needs a heading like '### S1-BE-007: description'", file=sys.stderr)
    sys.exit(2)

# ----------------------------------------------------------------------------
# Apply wave filter (BE -> backend, API -> api, FE -> frontend, INFRA -> infra, TEST -> test)
# ----------------------------------------------------------------------------
WAVE_MAP = {
    'backend':  ['BE'],
    'api':      ['API'],
    'frontend': ['FE'],
    'infra':    ['INFRA', 'INF'],
    'test':     ['TEST', 'QA'],
}

if wave_filter:
    allowed = WAVE_MAP.get(wave_filter.lower(), [wave_filter.upper()])
    def task_wave(t):
        m = re.match(r'S\d+-([A-Z]+)-\d+', t['id'])
        return m.group(1) if m else ''
    all_tasks = [t for t in all_tasks if task_wave(t) in allowed]

# ----------------------------------------------------------------------------
# Merge state from .project-state/sprint_NN_*_tasks.json (commit SHA, status)
# ----------------------------------------------------------------------------
state_index = {}
state_glob = os.path.join(state_dir, f'sprint_{sprint_num}_*_tasks.json')
for state_file in glob.glob(state_glob):
    try:
        with open(state_file, 'r', encoding='utf-8') as f:
            state = json.load(f)
        for st in state.get('tasks', []):
            tid = st.get('id')
            if tid:
                state_index[tid] = st
    except (IOError, json.JSONDecodeError) as e:
        print(f"WARN: could not read {state_file}: {e}", file=sys.stderr)

# ----------------------------------------------------------------------------
# Walk repo once — build a set of tracked files via git ls-files fallback to walk
# ----------------------------------------------------------------------------
import subprocess
try:
    result = subprocess.run(
        ['git', 'ls-files'],
        capture_output=True, text=True, check=True
    )
    tracked_files = set(result.stdout.splitlines())
    # Also include untracked-but-present files (new work pre-commit)
    result2 = subprocess.run(
        ['git', 'ls-files', '--others', '--exclude-standard'],
        capture_output=True, text=True, check=True
    )
    tracked_files.update(result2.stdout.splitlines())
except (subprocess.CalledProcessError, FileNotFoundError):
    tracked_files = set()
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if d not in ('.git', 'node_modules', '.venv', '__pycache__')]
        for f in files:
            rel = os.path.relpath(os.path.join(root, f)).replace('\\', '/')
            tracked_files.add(rel)

# ----------------------------------------------------------------------------
# Check each task: match expected_files globs against tracked_files
# ----------------------------------------------------------------------------
import fnmatch

def glob_match(pattern, files):
    """Match a task-expected pattern against the file set.
    Supports: exact paths, directory prefixes (ending /), and glob patterns."""
    pattern = pattern.replace('\\', '/').strip()
    if not pattern:
        return []

    if pattern.endswith('/'):
        prefix = pattern
        return [f for f in files if f.startswith(prefix)]

    if '*' in pattern or '?' in pattern or '[' in pattern:
        return [f for f in files if fnmatch.fnmatch(f, pattern)]

    if pattern in files:
        return [pattern]

    return [f for f in files if f == pattern or f.endswith('/' + pattern)]

planned = 0
implemented = 0
missing = 0
unverifiable = 0

task_reports = []
for task in all_tasks:
    planned += 1
    tid = task['id']
    expected = task['expected_files']

    state = state_index.get(tid, {})
    state_status = state.get('status', 'unknown')
    commit_sha = state.get('commit_sha')

    if not expected:
        task_reports.append({
            'id': tid,
            'description': task['description'],
            'status': 'unverifiable',
            'reason': 'no Expected Files section in task',
            'source': task['source_file'],
            'state_status': state_status,
            'commit_sha': commit_sha,
        })
        unverifiable += 1
        continue

    found_map = {}
    missing_patterns = []
    for pat in expected:
        matches = glob_match(pat, tracked_files)
        if matches:
            found_map[pat] = matches
        else:
            missing_patterns.append(pat)

    if not missing_patterns:
        status = 'implemented'
        implemented += 1
    else:
        status = 'missing'
        missing += 1

    task_reports.append({
        'id': tid,
        'description': task['description'],
        'status': status,
        'expected': expected,
        'found': found_map,
        'missing_patterns': missing_patterns,
        'source': task['source_file'],
        'state_status': state_status,
        'commit_sha': commit_sha,
    })

# ----------------------------------------------------------------------------
# Emit report
# ----------------------------------------------------------------------------
verifiable = max(planned - unverifiable, 1)
completion_pct = round(100.0 * implemented / verifiable, 2)

report = {
    'sprint': sprint_num,
    'wave_filter': wave_filter or None,
    'generated_at': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'totals': {
        'planned':      planned,
        'implemented':  implemented,
        'missing':      missing,
        'unverifiable': unverifiable,
        'completion_pct': completion_pct,
    },
    'tasks': task_reports,
}

os.makedirs(os.path.dirname(output_file), exist_ok=True)
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(report, f, indent=2)

print(f"Report written: {output_file}")
print(f"  Planned:       {planned}")
print(f"  Implemented:   {implemented}")
print(f"  Missing:       {missing}")
print(f"  Unverifiable:  {unverifiable}")
print(f"  Completion:    {completion_pct}%")

if missing > 0:
    print("")
    print("MISSING TASKS:")
    for t in task_reports:
        if t['status'] == 'missing':
            print(f"  - {t['id']}: {t['description']}")
            for p in t.get('missing_patterns', [])[:3]:
                print(f"      expected: {p}")
    sys.exit(1)

if unverifiable > 0 and implemented == 0:
    print("")
    print("ERROR: all tasks are unverifiable (no Expected Files sections)")
    print("Fix: ensure Agent 08 emits '### Expected Files:' for each task")
    sys.exit(1)

sys.exit(0)
PYEOF

PY_EXIT=$?

echo ""
if [ $PY_EXIT -eq 0 ]; then
    echo "RESULT: PASS - Sprint ${SPRINT_NUM} completeness gate CLEARED"
elif [ $PY_EXIT -eq 1 ]; then
    echo "RESULT: FAIL - Sprint ${SPRINT_NUM} has missing tasks (wave closure BLOCKED)"
else
    echo "RESULT: ERROR - Sprint plan unparseable or invalid arguments"
fi

exit $PY_EXIT
