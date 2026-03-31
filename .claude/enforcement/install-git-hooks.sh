#!/bin/bash
#
# Git Hooks Installer
# Installs pre-commit hook that enforces quality gates
#
# Usage:
#   ./install-git-hooks.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GIT_HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}Installing Git Hooks...${NC}"
echo ""

# Check if .git directory exists
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo -e "${YELLOW}Warning: .git directory not found${NC}"
    echo "This script must be run from a git repository"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$GIT_HOOKS_DIR"

# ============================================
# PRE-COMMIT HOOK
# ============================================
cat > "$GIT_HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
#
# Pre-Commit Hook
# Runs quality gates before allowing commit
#

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${YELLOW}Running pre-commit quality gates...${NC}"
echo ""

# Get project root
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Run enforcement script
if bash "$PROJECT_ROOT/.claude/enforcement/enforce-gates.sh"; then
    echo ""
    echo -e "${YELLOW}✓ Pre-commit checks passed. Proceeding with commit.${NC}"
    echo ""
    exit 0
else
    echo ""
    echo -e "${RED}✗ Pre-commit checks failed. Commit aborted.${NC}"
    echo ""
    echo -e "${YELLOW}Fix the errors above before committing.${NC}"
    echo ""
    echo -e "${YELLOW}To bypass this check (NOT recommended):${NC}"
    echo -e "${YELLOW}  git commit --no-verify${NC}"
    echo ""
    exit 1
fi
EOF

chmod +x "$GIT_HOOKS_DIR/pre-commit"

echo -e "${GREEN}✓ Pre-commit hook installed${NC}"
echo ""
echo -e "${BLUE}Location: $GIT_HOOKS_DIR/pre-commit${NC}"
echo ""
echo -e "${GREEN}Git hooks successfully installed!${NC}"
echo ""
echo -e "${YELLOW}From now on, every commit will be validated for quality.${NC}"
echo -e "${YELLOW}Commits with linting or type errors will be automatically rejected.${NC}"
echo ""
