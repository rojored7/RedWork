#!/bin/bash
# Auto-Commit Task Script
# Commits task changes and updates task state in .project-state/
#
# Usage: bash scripts/workflow/auto-commit-task.sh <task-id> "<description>" [--skip-post-hooks]
# Example: bash scripts/workflow/auto-commit-task.sh S1-BE-001 "Setup FastAPI project structure"
#
# Wave detection, post-wave-N triggering, and completeness gate are handled
# AUTOMATICALLY by the framework-workflow-hook-v2 post-commit hook.
# This script only creates the commit and updates task state.
#
# --skip-post-hooks sets FRAMEWORK_SKIP_POSTWAVE=1 so the post-commit hook
# bypasses wave validation (useful for unit tests of this script).
#
# Exit codes:
#   0 = success
#   1 = validation failed
#   2 = git operation failed
#   3 = state update failed

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo -e "${RED}ERROR: Invalid arguments${NC}"
    echo "Usage: bash scripts/workflow/auto-commit-task.sh <task-id> \"<description>\" [--skip-post-hooks]"
    echo "Example: bash scripts/workflow/auto-commit-task.sh S1-BE-001 \"Setup FastAPI project structure\""
    exit 1
fi

TASK_ID="$1"
TASK_DESCRIPTION="$2"

if [ "${3:-}" = "--skip-post-hooks" ]; then
    export FRAMEWORK_SKIP_POSTWAVE=1
    echo "Skipping post-wave hooks (unit test mode)"
fi

echo "======================================"
echo "Auto-Commit Task: $TASK_ID"
echo "======================================"

# Validate task ID format (matches JSON schema pattern: ^S[0-9]+-[A-Z]{2}-[0-9]{3}$)
echo -n "Validating task ID format... "
if ! echo "$TASK_ID" | grep -qE '^S[0-9]+-[A-Z]{2}-[0-9]{3}$'; then
    echo -e "${RED}FAILED${NC}"
    echo "ERROR: Task ID must match pattern S<sprint>-<agent>-<number>"
    echo "Example: S1-BE-001, S2-FE-042"
    echo "Received: $TASK_ID"
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Check if .project-state directory exists
echo -n "Checking if .project-state exists... "
if [ ! -d ".project-state" ]; then
    echo -e "${RED}FAILED${NC}"
    echo "ERROR: .project-state directory not found"
    echo "This directory should be created by Agent 25 (Development Orchestrator)"
    echo "Solution: Run Agent 25 first to initialize project state"
    exit 3
fi
echo -e "${GREEN}OK${NC}"

# Find task state file
echo -n "Finding task state file... "
TASK_STATE_FILE=$(find .project-state -name "sprint_*_tasks.json" -type f | head -n 1)

if [ -z "$TASK_STATE_FILE" ]; then
    echo -e "${RED}FAILED${NC}"
    echo "ERROR: No task state file found in .project-state/"
    echo "Expected file pattern: sprint_XX_[agent]_tasks.json"
    echo "Solution: Run Agent 25 to create task state file"
    exit 3
fi
echo -e "${GREEN}OK${NC}"
echo "  State file: $TASK_STATE_FILE"

# Check if task exists in state file
echo -n "Verifying task exists in state file... "
if ! grep -q "\"id\": \"$TASK_ID\"" "$TASK_STATE_FILE"; then
    echo -e "${YELLOW}WARNING${NC}"
    echo "WARNING: Task $TASK_ID not found in $TASK_STATE_FILE"
    echo "Proceeding with commit anyway, but state will not be updated"
    UPDATE_STATE=false
else
    echo -e "${GREEN}OK${NC}"
    UPDATE_STATE=true
fi

# Check git status
echo -n "Checking git repository... "
if [ ! -d ".git" ]; then
    echo -e "${RED}FAILED${NC}"
    echo "ERROR: No git repository found"
    exit 2
fi
echo -e "${GREEN}OK${NC}"

# Check if there are changes to commit
echo -n "Checking for changes... "
if git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}NO CHANGES${NC}"
    echo "INFO: No changes detected, nothing to commit"
    echo "Task state will still be updated if task exists"
else
    echo -e "${GREEN}CHANGES DETECTED${NC}"
fi

# Stage all changes
echo -n "Staging changes (git add .)... "
if git add . 2>/dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo "ERROR: Failed to stage changes"
    exit 2
fi

# Create commit message
COMMIT_MESSAGE="[TASK-$TASK_ID] $TASK_DESCRIPTION"

echo ""
echo -e "${BLUE}Commit message:${NC}"
echo "  $COMMIT_MESSAGE"
echo ""

# Commit changes
echo -n "Creating commit... "
if git commit -m "$COMMIT_MESSAGE" --allow-empty 2>/dev/null; then
    echo -e "${GREEN}OK${NC}"
    COMMIT_SHA=$(git rev-parse HEAD)
    echo "  Commit SHA: $COMMIT_SHA"
else
    echo -e "${RED}FAILED${NC}"
    echo "ERROR: Failed to create commit"
    exit 2
fi

# Update task state in JSON file (if task exists)
if [ "$UPDATE_STATE" = true ]; then
    echo -n "Updating task state... "

    # Get current timestamp in ISO 8601 format
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Use Python to update JSON (safer than jq for complex updates)
    python3 -c "
import json
import sys
from datetime import datetime

# Read current state
with open('$TASK_STATE_FILE', 'r') as f:
    state = json.load(f)

# Find and update task
task_found = False
for task in state['tasks']:
    if task['id'] == '$TASK_ID':
        task['status'] = 'completed'
        task['completed_at'] = '$TIMESTAMP'
        task['commit_sha'] = '$COMMIT_SHA'
        task_found = True
        break

if not task_found:
    print('ERROR: Task not found', file=sys.stderr)
    sys.exit(1)

# Update last_updated timestamp
state['last_updated'] = '$TIMESTAMP'

# Write updated state
with open('$TASK_STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)

print('SUCCESS')
" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}OK${NC}"
        echo "  Task marked as completed"
        echo "  Timestamp: $TIMESTAMP"
    else
        echo -e "${YELLOW}FAILED${NC}"
        echo "WARNING: Could not update task state"
        echo "Commit was successful, but state file was not updated"
        echo "You may need to update the state manually"
    fi
fi

# Update current_context.json last_updated
if [ -f ".project-state/current_context.json" ]; then
    echo -n "Updating current context... "

    python3 -c "
import json
from datetime import datetime

with open('.project-state/current_context.json', 'r') as f:
    context = json.load(f)

context['last_updated'] = '$TIMESTAMP'

with open('.project-state/current_context.json', 'w') as f:
    json.dump(context, f, indent=2)
" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}WARNING${NC}"
        echo "WARNING: Could not update current_context.json"
    fi
fi

# Push to remote
echo -n "Pushing to remote... "
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")

if [ -z "$REMOTE_URL" ]; then
    echo -e "${YELLOW}SKIPPED${NC}"
    echo "WARNING: No git remote configured"
    echo "Changes committed locally but not pushed"
else
    if git push origin HEAD 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
        echo "  Remote: $REMOTE_URL"
    else
        echo -e "${YELLOW}FAILED${NC}"
        echo "WARNING: Failed to push to remote"
        echo "Changes committed locally but not pushed"
        echo "You may need to push manually: git push origin HEAD"
    fi
fi

echo "======================================"
echo -e "${GREEN}Task Auto-Commit: SUCCESS${NC}"
echo ""
echo "Summary:"
echo "  Task ID: $TASK_ID"
echo "  Commit SHA: $COMMIT_SHA"
echo "  State Updated: $UPDATE_STATE"
echo "  Pushed to Remote: $([ -n "$REMOTE_URL" ] && echo 'Yes' || echo 'No')"
echo ""
echo "Next steps:"
echo "  - Continue with next task in sprint"
echo "  - Or run: bash scripts/workflow/resume-development.sh to resume"
echo "======================================"

exit 0
