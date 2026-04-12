#!/bin/bash
# Git Setup Validation Script
# Validates git repository is properly configured before development starts
#
# Usage: bash scripts/workflow/validate-git-setup.sh
# Exit codes:
#   0 = validation passed
#   1 = validation failed

set -e

echo "======================================"
echo "Git Setup Validation"
echo "======================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validation failure flag
VALIDATION_FAILED=0

# Check 1: Git repository exists
echo -n "Checking if git repository exists... "
if [ ! -d ".git" ]; then
    echo -e "${RED}FAILED${NC}"
    echo "ERROR: No git repository found in current directory"
    echo "Solution: Run 'git init' to initialize a git repository"
    VALIDATION_FAILED=1
else
    echo -e "${GREEN}OK${NC}"
fi

# Check 2: Remote URL is configured
if [ $VALIDATION_FAILED -eq 0 ]; then
    echo -n "Checking if git remote is configured... "
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")

    if [ -z "$REMOTE_URL" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "ERROR: No git remote 'origin' configured"
        echo "Solution: Run 'git remote add origin <your-gitlab-url>'"
        echo "Example: git remote add origin https://gitlab.com/user/project.git"
        VALIDATION_FAILED=1
    else
        echo -e "${GREEN}OK${NC}"
        echo "  Remote URL: $REMOTE_URL"
    fi
fi

# Check 3: Not in framework repository
if [ $VALIDATION_FAILED -eq 0 ]; then
    echo -n "Checking if not in framework repository... "

    # Check for framework-specific directories
    if [ -d "agents" ] && [ -d ".framework" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "ERROR: You are in the framework repository!"
        echo "Development must be done in a PROJECT repository, not the framework itself."
        echo ""
        echo "Solution:"
        echo "  1. Navigate out of framework: cd .."
        echo "  2. Create new project: python install.py init my-project"
        echo "  3. Navigate to project: cd my-project"
        echo "  4. Run development from there"
        VALIDATION_FAILED=1
    elif [ -d "agents" ] && [ ! -d ".framework" ]; then
        # We're in framework repo but no .framework directory
        echo -e "${RED}FAILED${NC}"
        echo "ERROR: You appear to be in the framework repository!"
        echo "Development must be done in a PROJECT repository."
        echo ""
        echo "Solution: Same as above"
        VALIDATION_FAILED=1
    else
        echo -e "${GREEN}OK${NC}"
    fi
fi

# Check 4: Can connect to remote (optional but recommended)
if [ $VALIDATION_FAILED -eq 0 ] && [ -n "$REMOTE_URL" ]; then
    echo -n "Checking if can connect to remote... "

    if git ls-remote "$REMOTE_URL" > /dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}WARNING${NC}"
        echo "WARNING: Cannot connect to remote repository"
        echo "This might be a network issue or invalid URL"
        echo "Remote URL: $REMOTE_URL"
        echo ""
        echo "Possible causes:"
        echo "  - Network connectivity issues"
        echo "  - Invalid repository URL"
        echo "  - Authentication not configured (check SSH keys or credentials)"
        echo ""
        echo "You can continue, but auto-commits will fail until this is resolved."
        echo ""
        # Don't fail validation, just warn
    fi
fi

# Check 5: .project-state directory exists (for development tracking)
echo -n "Checking if .project-state directory exists... "
if [ ! -d ".project-state" ]; then
    echo -e "${YELLOW}NOT FOUND${NC}"
    echo "INFO: .project-state directory doesn't exist yet"
    echo "This directory will be created by Agent 25 (Development Orchestrator)"
    echo "when you start your first development task."
else
    echo -e "${GREEN}OK${NC}"
fi

echo "======================================"

if [ $VALIDATION_FAILED -eq 1 ]; then
    echo -e "${RED}Git Setup Validation: FAILED${NC}"
    echo ""
    echo "Please fix the errors above before starting development."
    exit 1
else
    echo -e "${GREEN}Git Setup Validation: PASSED${NC}"
    echo ""
    echo "Your git repository is properly configured."
    echo "You can now proceed with development."
    exit 0
fi
