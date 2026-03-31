#!/bin/bash
# Auto-commit agent output after execution

AGENT_FILE=$1

if [ -z "$AGENT_FILE" ]; then
    echo "ERROR: Agent output file required"
    echo "Usage: $0 <output_file>"
    exit 1
fi

if [ ! -f "$AGENT_FILE" ]; then
    echo "ERROR: File $AGENT_FILE not found"
    exit 1
fi

echo "======================================"
echo "Auto-committing agent output: $AGENT_FILE"
echo "======================================"

# Detect which agent based on filename
AGENT_NAME=""
COMMIT_MSG=""

case "$AGENT_FILE" in
    "01_product_discovery.md")
        AGENT_NAME="agent_01"
        COMMIT_MSG="docs: agent_01 product discovery completed"
        ;;
    "02_domain_model.md")
        AGENT_NAME="agent_02"
        COMMIT_MSG="docs: agent_02 domain modeling completed"
        ;;
    "03_context_map.md")
        AGENT_NAME="agent_03"
        COMMIT_MSG="docs: agent_03 context mapping completed"
        ;;
    "04_architecture_decision.md")
        AGENT_NAME="agent_04"
        COMMIT_MSG="docs: agent_04 architecture decision completed"
        ;;
    "05_service_design.md")
        AGENT_NAME="agent_05"
        COMMIT_MSG="docs: agent_05 service design completed"
        ;;
    *)
        AGENT_NAME="unknown"
        COMMIT_MSG="docs: agent output - $AGENT_FILE"
        ;;
esac

echo "Detected agent: $AGENT_NAME"
echo "Commit message: $COMMIT_MSG"
echo ""

# Add and commit
git add "$AGENT_FILE"

if git commit -m "$COMMIT_MSG"; then
    echo ""
    echo "======================================"
    echo "Commit successful"
    echo "Post-commit hook will now run automatically"
    echo "======================================"
else
    echo ""
    echo "ERROR: Commit failed"
    exit 1
fi

exit 0
