#!/bin/bash

###############################################################################
# Setup Script: Install Enforcement System
#
# Purpose: Installs all validators and hooks to prevent unauthorized changes
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "============================================================"
echo "Installing Enforcement System"
echo "============================================================"
echo ""

# Step 1: Make validators executable
echo "Step 1: Making validators executable..."
chmod +x "$PROJECT_ROOT/.claude/validators"/*.sh 2>/dev/null || true
chmod +x "$PROJECT_ROOT/.claude/enforcement"/*.sh 2>/dev/null || true
echo "✅ Validators are executable"
echo ""

# Step 2: Install pre-commit hook
echo "Step 2: Installing pre-commit hook..."

if [ ! -d "$PROJECT_ROOT/.git/hooks" ]; then
    mkdir -p "$PROJECT_ROOT/.git/hooks"
fi

cat > "$PROJECT_ROOT/.git/hooks/pre-commit" << 'EOF'
#!/bin/bash
ENFORCEMENT_DIR=".claude/enforcement"
if [ -f "$ENFORCEMENT_DIR/pre-commit-port-validation.sh" ]; then
    bash "$ENFORCEMENT_DIR/pre-commit-port-validation.sh"
    if [ $? -ne 0 ]; then
        exit 1
    fi
fi
exit 0
EOF

chmod +x "$PROJECT_ROOT/.git/hooks/pre-commit"
echo "✅ Pre-commit hook installed"
echo ""

# Step 3: Run initial validation
echo "Step 3: Running initial validation..."
bash "$PROJECT_ROOT/.claude/validators/validate-port-configuration.sh"
VALIDATION_RESULT=$?

if [ $VALIDATION_RESULT -ne 0 ]; then
    echo "⚠️  WARNING: Initial validation FAILED"
else
    echo "✅ Initial validation PASSED"
fi
echo ""

echo "============================================================"
echo "✅✅✅ ENFORCEMENT SYSTEM INSTALLED ✅✅✅"
echo "============================================================"
exit 0
