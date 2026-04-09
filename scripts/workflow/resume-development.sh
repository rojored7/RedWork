#!/bin/bash
# Resume Development Script
# Resumes development from last completed task after disconnection
#
# Usage: bash scripts/workflow/resume-development.sh [sprint] [agent]
# Examples:
#   bash scripts/workflow/resume-development.sh 01 backend
#   bash scripts/workflow/resume-development.sh 02 frontend
#   bash scripts/workflow/resume-development.sh    # Auto-detect from current_context.json
#
# Exit codes:
#   0 = resume successful
#   1 = validation failed
#   2 = no tasks to resume
#   3 = state file error

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "======================================"
echo "Resume Development"
echo "======================================"

# Check if .project-state exists
echo -n "Checking if .project-state exists... "
if [ ! -d ".project-state" ]; then
    echo -e "${RED}FAILED${NC}"
    echo "ERROR: .project-state directory not found"
    echo "This directory should be created by Agent 25 (Development Orchestrator)"
    echo ""
    echo "Solution:"
    echo "  1. Run Agent 25 first to initialize project state"
    echo "  2. Or start a new development session"
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Determine sprint and agent
if [ $# -eq 2 ]; then
    # Arguments provided
    SPRINT="$1"
    AGENT_TYPE="$2"
    echo "Using provided arguments: Sprint $SPRINT, Agent: $AGENT_TYPE"
elif [ $# -eq 0 ]; then
    # Auto-detect from current_context.json
    echo -n "Auto-detecting from current_context.json... "

    if [ ! -f ".project-state/current_context.json" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "ERROR: current_context.json not found"
        echo ""
        echo "Usage: bash scripts/workflow/resume-development.sh <sprint> <agent>"
        echo "Example: bash scripts/workflow/resume-development.sh 01 backend"
        exit 1
    fi

    SPRINT=$(python3 -c "import json; f=open('.project-state/current_context.json'); d=json.load(f); print(d.get('active_sprint', ''))" 2>/dev/null)
    AGENT_FULL=$(python3 -c "import json; f=open('.project-state/current_context.json'); d=json.load(f); print(d.get('active_agent', ''))" 2>/dev/null)

    if [ -z "$SPRINT" ] || [ -z "$AGENT_FULL" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "ERROR: No active sprint/agent found in current_context.json"
        echo ""
        echo "Usage: bash scripts/workflow/resume-development.sh <sprint> <agent>"
        exit 1
    fi

    # Convert agent full name to short type
    case "$AGENT_FULL" in
        "backend-fastapi-dev")
            AGENT_TYPE="backend"
            ;;
        "frontend-development")
            AGENT_TYPE="frontend"
            ;;
        "backend-test-agent")
            AGENT_TYPE="backend_test"
            ;;
        "frontend-test-auditor")
            AGENT_TYPE="frontend_test"
            ;;
        *)
            echo -e "${RED}FAILED${NC}"
            echo "ERROR: Unknown agent type: $AGENT_FULL"
            exit 1
            ;;
    esac

    echo -e "${GREEN}OK${NC}"
    echo "  Detected: Sprint $SPRINT, Agent: $AGENT_TYPE ($AGENT_FULL)"
else
    echo -e "${RED}ERROR: Invalid arguments${NC}"
    echo ""
    echo "Usage:"
    echo "  bash scripts/workflow/resume-development.sh              # Auto-detect"
    echo "  bash scripts/workflow/resume-development.sh 01 backend   # Explicit"
    exit 1
fi

# Normalize sprint number (add leading zero if needed)
if [ ${#SPRINT} -eq 1 ]; then
    SPRINT="0$SPRINT"
fi

# Validate sprint format
if ! echo "$SPRINT" | grep -qE '^[0-9]{2}$'; then
    echo -e "${RED}ERROR: Invalid sprint format${NC}"
    echo "Sprint must be 2-digit number (01, 02, etc.)"
    echo "Received: $SPRINT"
    exit 1
fi

# Determine agent full name and task file pattern
case "$AGENT_TYPE" in
    "backend" | "be")
        AGENT_FULL="backend-fastapi-dev"
        TASK_FILE="sprint_${SPRINT}_backend_tasks.json"
        AGENT_NUMBER="10"
        ;;
    "frontend" | "fe")
        AGENT_FULL="frontend-development"
        TASK_FILE="sprint_${SPRINT}_frontend_tasks.json"
        AGENT_NUMBER="11"
        ;;
    "backend_test" | "be_test")
        AGENT_FULL="backend-test-agent"
        TASK_FILE="sprint_${SPRINT}_backend_test_tasks.json"
        AGENT_NUMBER="13"
        ;;
    "frontend_test" | "fe_test")
        AGENT_FULL="frontend-test-auditor"
        TASK_FILE="sprint_${SPRINT}_frontend_test_tasks.json"
        AGENT_NUMBER="14"
        ;;
    *)
        echo -e "${RED}ERROR: Unknown agent type: $AGENT_TYPE${NC}"
        echo ""
        echo "Valid types: backend, frontend, backend_test, frontend_test"
        exit 1
        ;;
esac

echo ""
echo -e "${CYAN}Resume Configuration:${NC}"
echo "  Sprint: $SPRINT"
echo "  Agent: $AGENT_FULL (Agent $AGENT_NUMBER)"
echo "  Task File: $TASK_FILE"
echo ""

# Check if task file exists
TASK_FILE_PATH=".project-state/$TASK_FILE"
echo -n "Checking if task file exists... "
if [ ! -f "$TASK_FILE_PATH" ]; then
    echo -e "${RED}FAILED${NC}"
    echo "ERROR: Task file not found: $TASK_FILE_PATH"
    echo ""
    echo "Available task files:"
    ls -1 .project-state/*.json 2>/dev/null || echo "  (none)"
    echo ""
    echo "Solution: Verify sprint number and agent type are correct"
    exit 3
fi
echo -e "${GREEN}OK${NC}"

# Parse task state
echo -n "Loading task state... "
TASK_STATE=$(cat "$TASK_FILE_PATH")
TOTAL_TASKS=$(echo "$TASK_STATE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d['tasks']))" 2>/dev/null)
COMPLETED_TASKS=$(echo "$TASK_STATE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(sum(1 for t in d['tasks'] if t['status']=='completed'))" 2>/dev/null)
IN_PROGRESS_TASKS=$(echo "$TASK_STATE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(sum(1 for t in d['tasks'] if t['status']=='in_progress'))" 2>/dev/null)
PENDING_TASKS=$(echo "$TASK_STATE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(sum(1 for t in d['tasks'] if t['status']=='pending'))" 2>/dev/null)

if [ -z "$TOTAL_TASKS" ]; then
    echo -e "${RED}FAILED${NC}"
    echo "ERROR: Could not parse task file"
    exit 3
fi
echo -e "${GREEN}OK${NC}"

# Display progress
echo ""
echo -e "${BLUE}Task Progress:${NC}"
echo "  Total Tasks: $TOTAL_TASKS"
echo "  Completed: $COMPLETED_TASKS"
echo "  In Progress: $IN_PROGRESS_TASKS"
echo "  Pending: $PENDING_TASKS"
echo ""

# Check if all tasks are completed
if [ "$COMPLETED_TASKS" -eq "$TOTAL_TASKS" ]; then
    echo -e "${GREEN}All tasks completed!${NC}"
    echo ""
    echo "Sprint $SPRINT ($AGENT_TYPE) is 100% complete."
    echo "No tasks to resume."
    echo ""
    echo "Next steps:"
    echo "  - Start next sprint with Agent 25"
    echo "  - Or run different agent for this sprint"
    exit 2
fi

# Find next task to execute
echo "Finding next task to execute..."
NEXT_TASK=$(python3 -c "
import json
import sys

with open('$TASK_FILE_PATH', 'r') as f:
    state = json.load(f)

# Find first task that is:
# 1. in_progress (interrupted task)
# 2. pending with all dependencies completed
for task in state['tasks']:
    if task['status'] == 'in_progress':
        print(json.dumps(task))
        sys.exit(0)

for task in state['tasks']:
    if task['status'] == 'pending':
        # Check if all dependencies are completed
        all_deps_done = True
        for dep_id in task.get('dependencies', []):
            dep_task = next((t for t in state['tasks'] if t['id'] == dep_id), None)
            if dep_task is None or dep_task['status'] != 'completed':
                all_deps_done = False
                break

        if all_deps_done:
            print(json.dumps(task))
            sys.exit(0)

# No executable task found
print('{}')
" 2>/dev/null)

if [ -z "$NEXT_TASK" ] || [ "$NEXT_TASK" = "{}" ]; then
    echo -e "${RED}ERROR: No executable task found${NC}"
    echo ""
    echo "Possible reasons:"
    echo "  - All pending tasks have incomplete dependencies"
    echo "  - All tasks are in 'blocked' or 'failed' status"
    echo ""
    echo "Solution: Review task state file and resolve blocking issues"
    exit 2
fi

# Parse next task details
NEXT_TASK_ID=$(echo "$NEXT_TASK" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null)
NEXT_TASK_DESC=$(echo "$NEXT_TASK" | python3 -c "import json,sys; print(json.load(sys.stdin)['description'])" 2>/dev/null)
NEXT_TASK_STATUS=$(echo "$NEXT_TASK" | python3 -c "import json,sys; print(json.load(sys.stdin)['status'])" 2>/dev/null)

echo ""
echo -e "${GREEN}Next Task Found:${NC}"
echo "  ID: $NEXT_TASK_ID"
echo "  Description: $NEXT_TASK_DESC"
echo "  Status: $NEXT_TASK_STATUS"
echo ""

# Update task status to in_progress
echo -n "Updating task status to in_progress... "
python3 -c "
import json
from datetime import datetime

with open('$TASK_FILE_PATH', 'r') as f:
    state = json.load(f)

for task in state['tasks']:
    if task['id'] == '$NEXT_TASK_ID':
        task['status'] = 'in_progress'
        if task.get('started_at') is None:
            task['started_at'] = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
        break

state['last_updated'] = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

with open('$TASK_FILE_PATH', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}FAILED${NC}"
    echo "WARNING: Could not update task status"
    echo "Proceeding anyway..."
fi

# Display resume instructions
echo ""
echo "======================================"
echo -e "${GREEN}Ready to Resume Development${NC}"
echo "======================================"
echo ""
echo -e "${CYAN}Instructions:${NC}"
echo ""
echo "1. Agent $AGENT_NUMBER ($AGENT_FULL) should now:"
echo "   - Read task file: $TASK_FILE_PATH"
echo "   - Execute task: $NEXT_TASK_ID"
echo "   - Follow task description: $NEXT_TASK_DESC"
echo ""
echo "2. After completing the task, run:"
echo "   bash scripts/workflow/auto-commit-task.sh $NEXT_TASK_ID \"$NEXT_TASK_DESC\""
echo ""
echo "3. Agent will then automatically continue to next task"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC}"
echo "  This script has identified the next task and updated its status."
echo "  You must now manually invoke Agent $AGENT_NUMBER to execute the task."
echo ""
echo "  Example invocation (via Claude Code Task tool):"
echo "    subagent_type: $AGENT_NUMBER-$AGENT_TYPE"
echo "    prompt: Resume Sprint $SPRINT from task $NEXT_TASK_ID: $NEXT_TASK_DESC"
echo ""
echo "======================================"

exit 0
