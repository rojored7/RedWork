#!/bin/bash

###############################################################################
# POST-HOOK: Sprint 3 Final Validation
#
# Purpose: Validates that Sprint 3 is TRULY complete with ALL quality gates
#
# This hook validates:
# - Backend compilation (0 errors)
# - Backend unit tests (100% passing)
# - Backend integration tests (100% passing)
# - Frontend build (0 errors)
# - Frontend unit tests (100% passing)
# - E2E tests (100% passing)
#
# Exit Codes:
#   0 = Sprint 3 is COMPLETE
#   1 = Sprint 3 has failures
###############################################################################

set -e

echo "============================================================"
echo "POST-HOOK: Sprint 3 Final Validation"
echo "============================================================"
echo ""

SCRIPT_DIR="$(dirname "$0")"
FAILED=0

# Gate 1: Backend Compilation
echo "GATE 1: Backend Compilation"
echo "----------------------------"
cd "$SCRIPT_DIR/../backend" || exit 1
npm run build > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Backend compilation FAILED"
    FAILED=1
else
    echo "✅ Backend compiles (0 errors)"
fi
echo ""

# Gate 2: Backend Unit Tests
echo "GATE 2: Backend Unit Tests"
echo "----------------------------"
OUTPUT=$(npm test 2>&1)
if [ $? -ne 0 ]; then
    echo "❌ Backend unit tests FAILED"
    FAILED=1
else
    TOTAL=$(echo "$OUTPUT" | grep -oP '\d+(?= passed)' | head -1)
    echo "✅ Backend unit tests: $TOTAL passed"
fi
echo ""

# Gate 3: Backend Integration Tests
echo "GATE 3: Backend Integration Tests"
echo "-----------------------------------"
bash "$SCRIPT_DIR/post-hook-integration-tests.sh" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Integration tests FAILED"
    FAILED=1
else
    echo "✅ Integration tests: All passed"
fi
echo ""

# Gate 4: Frontend Build
echo "GATE 4: Frontend Build"
echo "----------------------------"
cd "$SCRIPT_DIR/../frontend" || exit 1
npm run build > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Frontend build FAILED"
    FAILED=1
else
    echo "✅ Frontend builds (0 errors)"
fi
echo ""

# Gate 5: Frontend Unit Tests
echo "GATE 5: Frontend Unit Tests"
echo "----------------------------"
OUTPUT=$(npm test -- --run 2>&1)
if [ $? -ne 0 ]; then
    echo "❌ Frontend unit tests FAILED"
    FAILED=1
else
    TOTAL=$(echo "$OUTPUT" | grep -oP '\d+(?= passed)' | tail -1)
    echo "✅ Frontend unit tests: $TOTAL passed"
fi
echo ""

# Gate 6: E2E Tests
echo "GATE 6: E2E Tests"
echo "----------------------------"
bash "$SCRIPT_DIR/post-hook-e2e-tests.sh" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ E2E tests FAILED or not validated"
    FAILED=1
else
    echo "✅ E2E tests: All passed"
fi
echo ""

# Final Result
echo "============================================================"
if [ $FAILED -eq 1 ]; then
    echo "❌❌❌ SPRINT 3 VALIDATION FAILED ❌❌❌"
    echo ""
    echo "One or more quality gates did not pass."
    echo "Sprint 3 is NOT complete."
    echo "============================================================"
    exit 1
fi

echo "✅✅✅ SPRINT 3 IS COMPLETE ✅✅✅"
echo ""
echo "All quality gates passed:"
echo "  ✅ Backend compilation"
echo "  ✅ Backend unit tests"
echo "  ✅ Backend integration tests"
echo "  ✅ Frontend build"
echo "  ✅ Frontend unit tests"
echo "  ✅ E2E tests"
echo ""
echo "Sprint 3: Project Management Module is 100% COMPLETE"
echo "============================================================"

exit 0
