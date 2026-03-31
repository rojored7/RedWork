#!/bin/bash
#
# Frontend Validator
# Validates frontend code quality: linting and type-checking
#
# Exit codes:
#   0 = All validations passed
#   1 = One or more validations failed
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}   FRONTEND VALIDATOR${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check if frontend directory exists
if [ ! -d "$FRONTEND_DIR" ]; then
    echo -e "${RED}✗ Frontend directory not found: $FRONTEND_DIR${NC}"
    exit 1
fi

cd "$FRONTEND_DIR"

# Track overall result
VALIDATION_FAILED=0

# ============================================
# GATE 1: ESLint Validation
# ============================================
echo -e "${YELLOW}[1/2] Running ESLint...${NC}"

if npm run lint > /tmp/frontend-lint.log 2>&1; then
    # ESLint passed (exit code 0) - check for actual error count
    if grep -q "✖.*([1-9][0-9]* errors" /tmp/frontend-lint.log; then
        echo -e "${RED}✗ ESLint failed with errors${NC}"
        cat /tmp/frontend-lint.log
        VALIDATION_FAILED=1
    else
        # Count warnings
        WARNING_COUNT=$(grep -oP "\d+ warning" /tmp/frontend-lint.log | head -1 | grep -oP "\d+" || echo "0")
        echo -e "${GREEN}✓ ESLint passed (0 errors, $WARNING_COUNT warnings)${NC}"
    fi
else
    echo -e "${RED}✗ ESLint failed${NC}"
    cat /tmp/frontend-lint.log
    VALIDATION_FAILED=1
fi

echo ""

# ============================================
# GATE 2: TypeScript Type Check
# ============================================
echo -e "${YELLOW}[2/2] Running TypeScript type-check...${NC}"

if npm run type-check > /tmp/frontend-typecheck.log 2>&1; then
    echo -e "${GREEN}✓ TypeScript type-check passed (0 errors)${NC}"
else
    echo -e "${RED}✗ TypeScript type-check failed${NC}"
    cat /tmp/frontend-typecheck.log
    VALIDATION_FAILED=1
fi

echo ""
echo -e "${BLUE}================================${NC}"

if [ $VALIDATION_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓✓✓ FRONTEND VALIDATION PASSED ✓✓✓${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗✗✗ FRONTEND VALIDATION FAILED ✗✗✗${NC}"
    echo ""
    echo -e "${YELLOW}Fix the errors above before proceeding.${NC}"
    echo ""
    exit 1
fi
