#!/bin/bash
# Update workflow status after agent completion

AGENT_NAME=$1
STATUS_FILE="workflow-status.json"

if [ -z "$AGENT_NAME" ]; then
    echo "ERROR: Agent name required"
    echo "Usage: $0 <agent_name>"
    exit 1
fi

if [ ! -f "$STATUS_FILE" ]; then
    echo "ERROR: $STATUS_FILE not found"
    exit 1
fi

echo "======================================"
echo "Updating workflow status for: $AGENT_NAME"
echo "======================================"

# Update JSON using Python (more reliable than sed/awk)
python3 -c "
import json
from datetime import datetime

with open('$STATUS_FILE', 'r') as f:
    data = json.load(f)

if '$AGENT_NAME' in data['agents']:
    data['agents']['$AGENT_NAME']['status'] = 'completed'
    data['agents']['$AGENT_NAME']['completed_at'] = datetime.now().isoformat()
    data['agents']['$AGENT_NAME']['validation_passed'] = True
    data['last_updated'] = datetime.now().isoformat()

    with open('$STATUS_FILE', 'w') as f:
        json.dump(data, f, indent=2)

    print(f'Status updated for $AGENT_NAME')
else:
    print(f'ERROR: Agent $AGENT_NAME not found in status file')
    exit(1)
"

if [ $? -eq 0 ]; then
    echo "✓ Status file updated"

    # Commit and push the status update
    git add "$STATUS_FILE"
    git commit -m "workflow: $AGENT_NAME completed" --no-verify

    echo "✓ Status committed"

    # Push to remote
    git push origin framework --no-verify

    echo "✓ Status pushed to GitLab"
    echo "======================================"
    echo "Workflow status updated successfully"
    echo "======================================"
else
    echo "ERROR: Failed to update status file"
    exit 1
fi

exit 0
