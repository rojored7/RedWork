#!/bin/bash
#
# GATE ENFORCEMENT SCRIPT
#
# This script enforces ALL quality gates before allowing code to proceed.
# It runs all validators and ensures 100% quality standards.
#
# Usage:
#   ./enforce-gates.sh [--skip-backend] [--skip-frontend]
#
# Exit codes:
#   0 = All gates passed
#   1 = One or more gates failed
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VALIDATORS_DIR="$SCRIPT_DIR/../validators"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Parse arguments
SKIP_BACKEND=0
SKIP_FRONTEND=0

for arg in "$@"; do
    case $arg in
        --skip-backend)
            SKIP_BACKEND=1
            shift
            ;;
        --skip-frontend)
            SKIP_FRONTEND=1
            shift
            ;;
        --help)
            echo "Usage: $0 [--skip-backend] [--skip-frontend]"
            echo ""
            echo "Options:"
            echo "  --skip-backend    Skip backend validation"
            echo "  --skip-frontend   Skip frontend validation"
            echo "  --help            Show this help message"
            exit 0
            ;;
    esac
done

# Banner
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}${BLUE}           🛡️  QUALITY GATE ENFORCEMENT  🛡️${NC}            ${CYAN}║${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}║${NC}         ${YELLOW}Ensuring 100% Quality Standards${NC}                 ${CYAN}║${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Track overall result
ALL_GATES_PASSED=1

# ============================================
# GATE 1: Frontend Validation
# ============================================
if [ $SKIP_FRONTEND -eq 0 ]; then
    echo -e "${BOLD}${BLUE}[GATE 1/2] Frontend Validation${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if bash "$VALIDATORS_DIR/validate-frontend.sh"; then
        echo -e "${GREEN}✓ GATE 1 PASSED: Frontend validation successful${NC}"
    else
        echo -e "${RED}✗ GATE 1 FAILED: Frontend validation failed${NC}"
        ALL_GATES_PASSED=0
    fi

    echo ""
else
    echo -e "${YELLOW}⊘ GATE 1 SKIPPED: Frontend validation${NC}"
    echo ""
fi

# ============================================
# GATE 2: Backend Validation
# ============================================
if [ $SKIP_BACKEND -eq 0 ]; then
    echo -e "${BOLD}${BLUE}[GATE 2/2] Backend Validation${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if bash "$VALIDATORS_DIR/validate-backend.sh"; then
        echo -e "${GREEN}✓ GATE 2 PASSED: Backend validation successful${NC}"
    else
        echo -e "${RED}✗ GATE 2 FAILED: Backend validation failed${NC}"
        ALL_GATES_PASSED=0
    fi

    echo ""
else
    echo -e "${YELLOW}⊘ GATE 2 SKIPPED: Backend validation${NC}"
    echo ""
fi

# ============================================
# FINAL RESULT
# ============================================
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                            ║${NC}"

if [ $ALL_GATES_PASSED -eq 1 ]; then
    echo -e "${CYAN}║${NC}  ${BOLD}${GREEN}           ✓✓✓ ALL GATES PASSED ✓✓✓${NC}                  ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}║${NC}         ${GREEN}100% Quality Standards Met${NC}                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}         ${GREEN}Code is ready to proceed${NC}                      ${CYAN}║${NC}"
else
    echo -e "${CYAN}║${NC}  ${BOLD}${RED}           ✗✗✗ GATES FAILED ✗✗✗${NC}                     ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}║${NC}         ${RED}Quality standards not met${NC}                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}         ${YELLOW}Fix errors above before proceeding${NC}              ${CYAN}║${NC}"
fi

echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ $ALL_GATES_PASSED -eq 1 ]; then
    exit 0
else
    exit 1
fi
