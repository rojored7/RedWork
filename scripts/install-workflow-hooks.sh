#!/bin/bash
# ============================================================================
# install-workflow-hooks.sh
# ============================================================================
# Installs the Framework workflow git hooks:
#   1. post-commit: framework-workflow-hook-v2 (agent + task automation)
#   2. pre-commit:  blocking NestJS/Express/Spring contamination check
#
# The post-commit hook carries the marker "framework-workflow-hook-v2" which
# Agent 25 Phase 0 greps for to verify activation.
# ============================================================================

set -e

echo "======================================"
echo "Installing Framework Workflow Hooks v2"
echo "======================================"

# Detect if we're in Framework or in a project
if [ -d ".framework/scripts" ]; then
    SCRIPTS_PATH=".framework/scripts"
    MODE="project"
else
    SCRIPTS_PATH="scripts"
    MODE="framework"
fi

echo "Mode: $MODE"
echo "Scripts path: $SCRIPTS_PATH"

# Make workflow scripts executable
chmod +x $SCRIPTS_PATH/workflow/*.sh 2>/dev/null || true
chmod +x $SCRIPTS_PATH/hooks/post-commit-workflow 2>/dev/null || true
chmod +x $SCRIPTS_PATH/hooks/post-wave-*.sh 2>/dev/null || true

echo "Made scripts executable"

# Check if .git exists
if [ ! -d ".git" ]; then
    echo "ERROR: .git directory not found"
    echo "This script must be run from the repository root"
    exit 1
fi

# ----------------------------------------------------------------------------
# Install post-commit hook (framework-workflow-hook-v2)
# ----------------------------------------------------------------------------
POST_COMMIT=".git/hooks/post-commit"

if [ -f "$POST_COMMIT" ]; then
    # If it's already v2, no need to reinstall
    if grep -q "framework-workflow-hook-v2" "$POST_COMMIT" 2>/dev/null; then
        echo "post-commit hook already at v2 — leaving in place"
    else
        echo "WARNING: existing post-commit hook found (pre-v2)"
        echo "Backing up to post-commit.backup"
        mv "$POST_COMMIT" "$POST_COMMIT.backup"
        cp "$SCRIPTS_PATH/hooks/post-commit-workflow" "$POST_COMMIT"
        chmod +x "$POST_COMMIT"
        echo "Installed post-commit hook v2"
    fi
else
    cp "$SCRIPTS_PATH/hooks/post-commit-workflow" "$POST_COMMIT"
    chmod +x "$POST_COMMIT"
    echo "Installed post-commit hook v2"
fi

# Verify marker present
if grep -q "framework-workflow-hook-v2" "$POST_COMMIT"; then
    echo "Verified: framework-workflow-hook-v2 marker present"
else
    echo "ERROR: post-commit hook is missing the v2 marker"
    exit 1
fi

# ----------------------------------------------------------------------------
# Install pre-commit hook: blocking NestJS contamination check
# ----------------------------------------------------------------------------
PRE_COMMIT=".git/hooks/pre-commit"

cat > "$PRE_COMMIT" <<'HOOKEOF'
#!/bin/bash
# framework-precommit-hook-v2
# Blocks commits that introduce non-FastAPI backend contamination.
# Framework mandate: backend MUST be FastAPI (Python) — no exceptions.

set -e

# Files staged for commit
STAGED=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)

if [ -z "$STAGED" ]; then
    exit 0
fi

ERRORS=0

# ----------------------------------------------------------------------------
# Rule 1: backend/package.json must not declare @nestjs/* / express / typeorm
# ----------------------------------------------------------------------------
if echo "$STAGED" | grep -q "^backend/package\.json$"; then
    if grep -E '"@nestjs/|"express"|"typeorm"' backend/package.json >/dev/null 2>&1; then
        echo "PRE-COMMIT BLOCKED: backend/package.json contains prohibited dependencies"
        echo "  Framework mandate: backend MUST be FastAPI (Python)"
        echo "  Prohibited: @nestjs/*, express, typeorm"
        ERRORS=$((ERRORS + 1))
    fi
fi

# ----------------------------------------------------------------------------
# Rule 2: no staged .ts / .tsx under backend/
# ----------------------------------------------------------------------------
BAD_TS=$(echo "$STAGED" | grep -E '^backend/.*\.tsx?$' || true)
if [ -n "$BAD_TS" ]; then
    echo "PRE-COMMIT BLOCKED: TypeScript files under backend/ are prohibited"
    echo "  Framework mandate: backend MUST be FastAPI (Python)"
    echo "  Offending files:"
    echo "$BAD_TS" | sed 's/^/    /'
    ERRORS=$((ERRORS + 1))
fi

# ----------------------------------------------------------------------------
# Rule 3: no nest-cli.json or pom.xml at backend root
# ----------------------------------------------------------------------------
if echo "$STAGED" | grep -qE '^backend/(nest-cli\.json|pom\.xml|build\.gradle)$'; then
    echo "PRE-COMMIT BLOCKED: NestJS/Java backend config files detected"
    ERRORS=$((ERRORS + 1))
fi

# ----------------------------------------------------------------------------
# Rule 4: Framework-level integrity (only when running inside Framework repo)
# ----------------------------------------------------------------------------
if [ -f "scripts/workflow/validate-no-nestjs-contamination.sh" ] && [ -d "agents" ]; then
    if ! bash scripts/workflow/validate-no-nestjs-contamination.sh >/dev/null 2>&1; then
        echo "PRE-COMMIT BLOCKED: NestJS contamination in Framework agent docs"
        echo "  Run: bash scripts/workflow/validate-no-nestjs-contamination.sh"
        ERRORS=$((ERRORS + 1))
    fi
fi

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "Commit rejected. Fix the issues above and try again."
    echo "To bypass (NOT recommended): git commit --no-verify"
    exit 1
fi

exit 0
HOOKEOF
chmod +x "$PRE_COMMIT"

echo "Installed pre-commit hook (NestJS contamination blocker)"

# ----------------------------------------------------------------------------
# Final summary
# ----------------------------------------------------------------------------
echo ""
echo "======================================"
echo "Framework Hooks Installed v2"
echo "======================================"
echo ""
echo "Hooks:"
echo "  .git/hooks/pre-commit   (FastAPI mandate blocker)"
echo "  .git/hooks/post-commit  (framework-workflow-hook-v2)"
echo ""
echo "Behavior:"
echo "  - Every commit is scanned for NestJS/Express/Spring contamination"
echo "  - Task commits trigger wave detection + post-wave validation"
echo "  - Agent artifact commits are validated and workflow-status.json updated"
echo ""

exit 0
