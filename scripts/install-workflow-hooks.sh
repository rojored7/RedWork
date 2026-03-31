#!/bin/bash
# Install workflow automation hooks

echo "======================================"
echo "Installing Workflow Automation Hooks"
echo "======================================"

# Make workflow scripts executable
chmod +x scripts/workflow/validate-agent-01.sh
chmod +x scripts/workflow/update-workflow-status.sh
chmod +x scripts/hooks/post-commit-workflow

echo "✓ Made scripts executable"

# Check if .git exists
if [ ! -d ".git" ]; then
    echo "ERROR: .git directory not found"
    echo "This script must be run from the repository root"
    exit 1
fi

# Install post-commit hook
HOOK_FILE=".git/hooks/post-commit"

if [ -f "$HOOK_FILE" ]; then
    echo "WARNING: post-commit hook already exists"
    echo "Backing up to post-commit.backup"
    mv "$HOOK_FILE" "$HOOK_FILE.backup"
fi

# Copy hook
cp scripts/hooks/post-commit-workflow "$HOOK_FILE"
chmod +x "$HOOK_FILE"

echo "✓ Installed post-commit hook"

# Verify installation
if [ -x "$HOOK_FILE" ]; then
    echo ""
    echo "======================================"
    echo "Workflow hooks installed successfully"
    echo "======================================"
    echo ""
    echo "How it works:"
    echo "1. You execute agent with Claude Code"
    echo "2. Agent generates output file (e.g., 01_product_discovery.md)"
    echo "3. You commit: git add . && git commit -m 'docs: agent_01 completed'"
    echo "4. Post-commit hook runs automatically:"
    echo "   - Validates output file"
    echo "   - Updates workflow-status.json"
    echo "   - Commits and pushes status to GitLab"
    echo "5. GitLab sees the update and marks agent as completed"
    echo ""
else
    echo "ERROR: Failed to install hooks"
    exit 1
fi

exit 0
