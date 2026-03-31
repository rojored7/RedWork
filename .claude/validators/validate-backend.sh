#!/bin/bash
#
# Backend Validator
# Validates backend code quality: linting and compilation
#
# Exit codes:
#   0 = All validations passed
#   1 = One or more validations failed
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}   BACKEND VALIDATOR${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check if backend directory exists
if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}✗ Backend directory not found: $BACKEND_DIR${NC}"
    exit 1
fi

cd "$BACKEND_DIR"

# Track overall result
VALIDATION_FAILED=0

# ============================================
# GATE 1: ESLint Validation
# ============================================
echo -e "${YELLOW}[1/2] Running ESLint...${NC}"

if npm run lint > /tmp/backend-lint.log 2>&1; then
    # ESLint passed (exit code 0) - check for actual error count
    if grep -q "✖.*([1-9][0-9]* errors" /tmp/backend-lint.log; then
        echo -e "${RED}✗ ESLint failed with errors${NC}"
        cat /tmp/backend-lint.log
        VALIDATION_FAILED=1
    else
        # Count warnings
        WARNING_COUNT=$(grep -oP "\d+ warning" /tmp/backend-lint.log | wc -l || echo "0")
        echo -e "${GREEN}✓ ESLint passed (0 errors, $WARNING_COUNT warnings)${NC}"
    fi
else
    echo -e "${RED}✗ ESLint failed${NC}"
    cat /tmp/backend-lint.log
    VALIDATION_FAILED=1
fi

echo ""

# ============================================
# GATE 2: TypeScript Compilation
# ============================================
echo -e "${YELLOW}[2/2] Running TypeScript compilation (npm run build)...${NC}"

if npm run build > /tmp/backend-build.log 2>&1; then
    echo -e "${GREEN}✓ TypeScript compilation passed (0 errors)${NC}"
else
    echo -e "${RED}✗ TypeScript compilation failed${NC}"
    cat /tmp/backend-build.log
    VALIDATION_FAILED=1
fi

echo ""
echo -e "${BLUE}================================${NC}"

if [ $VALIDATION_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓✓✓ BACKEND VALIDATION PASSED ✓✓✓${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗✗✗ BACKEND VALIDATION FAILED ✗✗✗${NC}"
    echo ""
    echo -e "${YELLOW}Fix the errors above before proceeding.${NC}"
    echo ""
    exit 1
fi
