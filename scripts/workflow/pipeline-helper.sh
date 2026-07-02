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
# pipeline-helper.sh - GitLab CI/CD Pipeline Helper
# ============================================================================
# Helper script to manage the framework pipeline.
#
# Usage:
#   bash scripts/workflow/pipeline-helper.sh <command>
#
# Commands:
#   validate      Validate .gitlab-ci.yml syntax locally
#   visualize     Show pipeline structure (stages + jobs)
#   lint          Lint YAML using python
#   show-stage    Show jobs in a specific stage
#   show-deps     Show job dependencies (DAG)
#   dry-run       Simulate a stage locally
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PIPELINE_FILE="$FRAMEWORK_ROOT/.gitlab-ci.yml"

# Convert to Windows path if python is native Windows (handles Git Bash on Windows)
# Use forward slashes in the final path to avoid Python escape issues.
if command -v cygpath >/dev/null 2>&1; then
  PIPELINE_FILE_PY="$(cygpath -m "$PIPELINE_FILE")"
else
  PIPELINE_FILE_PY="$PIPELINE_FILE"
fi

COMMAND="${1:-help}"

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
require_python() {
  if ! command -v python >/dev/null 2>&1 && ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    echo "ERROR: "$PYTHON_BIN" is required for this command"
    exit 1
  fi
}

py() {
  if command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    "$PYTHON_BIN" "$@"
  else
    python "$@"
  fi
}

# ----------------------------------------------------------------------------
# Command: validate
# ----------------------------------------------------------------------------
cmd_validate() {
  echo "============================================================"
  echo "  Validating $PIPELINE_FILE"
  echo "============================================================"
  require_python

  py -c "
import yaml, sys
try:
    with open('$PIPELINE_FILE_PY', 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)

    errors = []

    stages = data.get('stages', [])
    if not stages:
        errors.append('Missing stages definition')

    jobs = {k: v for k, v in data.items()
            if not k.startswith('.') and k not in ('stages', 'variables', 'default', 'include', 'workflow')}

    for job_name, job_def in jobs.items():
        if not isinstance(job_def, dict):
            continue
        if 'stage' not in job_def and 'extends' not in job_def:
            errors.append(f'Job {job_name} missing stage')
        job_stage = job_def.get('stage')
        if job_stage and job_stage not in stages:
            errors.append(f'Job {job_name} uses undefined stage: {job_stage}')

    for job_name, job_def in jobs.items():
        if not isinstance(job_def, dict):
            continue
        needs = job_def.get('needs', [])
        if isinstance(needs, list):
            for need in needs:
                need_name = need if isinstance(need, str) else need.get('job', '')
                if need_name and need_name not in jobs:
                    errors.append(f'Job {job_name} needs undefined job: {need_name}')

    if errors:
        print('VALIDATION ERRORS:')
        for e in errors:
            print(f'  - {e}')
        sys.exit(1)

    print('VALIDATION: PASS')
    print(f'  Stages: {len(stages)}')
    print(f'  Jobs:   {len(jobs)}')
except yaml.YAMLError as e:
    print(f'YAML SYNTAX ERROR: {e}')
    sys.exit(1)
"
}

# ----------------------------------------------------------------------------
# Command: visualize
# ----------------------------------------------------------------------------
cmd_visualize() {
  require_python
  py -c "
import yaml
with open('$PIPELINE_FILE_PY', 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f)

stages = data.get('stages', [])
jobs = {k: v for k, v in data.items()
        if not k.startswith('.') and k not in ('stages', 'variables', 'default', 'include', 'workflow')
        and isinstance(v, dict)}

print('')
print('=' * 72)
print('  PIPELINE STRUCTURE')
print('=' * 72)

for i, stage in enumerate(stages, 1):
    stage_jobs = [name for name, job in jobs.items() if job.get('stage') == stage]
    icon = 'STAGE'
    print(f'')
    print(f'  [{i:2d}] {icon} {stage.upper()}')
    print(f'  {\"-\" * 66}')
    if not stage_jobs:
        print(f'       (no jobs defined)')
    for job in stage_jobs:
        manual = ''
        if jobs[job].get('when') == 'manual':
            manual = ' [MANUAL]'
        needs = jobs[job].get('needs', [])
        needs_count = len(needs) if isinstance(needs, list) else 0
        deps_info = f' (needs: {needs_count})' if needs_count else ''
        print(f'       |- {job}{manual}{deps_info}')

print('')
print('=' * 72)
print(f'  Total stages: {len(stages)}')
print(f'  Total jobs:   {len(jobs)}')
print('=' * 72)
print('')
"
}

# ----------------------------------------------------------------------------
# Command: show-deps
# ----------------------------------------------------------------------------
cmd_show_deps() {
  require_python
  py -c "
import yaml
with open('$PIPELINE_FILE_PY', 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f)

jobs = {k: v for k, v in data.items()
        if not k.startswith('.') and k not in ('stages', 'variables', 'default', 'include', 'workflow')
        and isinstance(v, dict)}

print('')
print('=' * 72)
print('  JOB DEPENDENCIES (DAG)')
print('=' * 72)
print('')

for job, config in jobs.items():
    needs = config.get('needs', [])
    if not needs:
        print(f'  {job}')
        print(f'    (root - no dependencies)')
    else:
        print(f'  {job}')
        if isinstance(needs, list):
            for n in needs:
                n_name = n if isinstance(n, str) else n.get('job', str(n))
                print(f'    <- {n_name}')
    print('')
"
}

# ----------------------------------------------------------------------------
# Command: show-stage
# ----------------------------------------------------------------------------
cmd_show_stage() {
  STAGE="${2:-}"
  if [ -z "$STAGE" ]; then
    echo "Usage: $0 show-stage <stage-name>"
    exit 1
  fi
  require_python
  py -c "
import yaml
with open('$PIPELINE_FILE_PY', 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f)

jobs = {k: v for k, v in data.items()
        if not k.startswith('.') and k not in ('stages', 'variables', 'default', 'include', 'workflow')
        and isinstance(v, dict) and v.get('stage') == '$STAGE'}

print(f'Stage: $STAGE')
print(f'Jobs:  {len(jobs)}')
print('')
for name, config in jobs.items():
    print(f'  {name}')
    if config.get('variables'):
        agent = config['variables'].get('AGENT_NAME', '')
        if agent:
            print(f'    Agent: {agent}')
    if config.get('when'):
        print(f'    When:  {config[\"when\"]}')
    needs = config.get('needs', [])
    if needs:
        print(f'    Needs: {len(needs)} jobs')
    print('')
"
}

# ----------------------------------------------------------------------------
# Command: help
# ----------------------------------------------------------------------------
cmd_help() {
  cat <<EOF
============================================================
  Pipeline Helper - Framework GitLab CI/CD
============================================================

Usage: bash $0 <command> [args]

Commands:
  validate              Validate .gitlab-ci.yml syntax and references
  visualize             Show full pipeline structure (stages + jobs)
  show-deps             Show job dependency graph (DAG)
  show-stage <name>     Show jobs in a specific stage
  lint                  Alias for validate
  help                  Show this help

Examples:
  bash $0 validate
  bash $0 visualize
  bash $0 show-stage sprint-wave-1
  bash $0 show-deps

Pipeline file: $PIPELINE_FILE

============================================================
EOF
}

# ----------------------------------------------------------------------------
# Dispatcher
# ----------------------------------------------------------------------------
case "$COMMAND" in
  validate|lint)   cmd_validate ;;
  visualize|viz)   cmd_visualize ;;
  show-deps|deps)  cmd_show_deps ;;
  show-stage)      cmd_show_stage "$@" ;;
  help|--help|-h)  cmd_help ;;
  *)
    echo "Unknown command: $COMMAND"
    cmd_help
    exit 1
    ;;
esac
