#!/bin/bash

###############################################################################
# POST-HOOK: E2E Tests Validation
#
# Purpose: Validates that ALL E2E tests execute and PASS with 100%
#
# This hook MUST be executed after any agent reports "E2E tests complete"
#
# Exit Codes:
#   0 = All E2E tests passed
#   1 = Tests failed or did not execute properly
###############################################################################

set -e

echo "=================================================="
echo "POST-HOOK: E2E Tests Validation"
echo "=================================================="
echo ""

# Change to frontend directory
cd "$(dirname "$0")/../frontend" || exit 1

echo "Step 1: Verifying frontend builds..."
npm run build > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ FRONTEND BUILD FAILED"
    echo "E2E tests cannot run if frontend doesn't build"
    exit 1
fi
echo "✅ Frontend builds"
echo ""

echo "Step 2: Checking if backend is running..."
BACKEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8020/api/health 2>/dev/null || echo "000")

if [ "$BACKEND_RESPONSE" != "200" ]; then
    echo "⚠️  WARNING: Backend not responding on port 8020"
    echo "E2E tests require backend to be running"
    echo "Start backend with: cd backend && PORT=8020 DB_PORT=5434 npm run start:dev"
    exit 1
fi
echo "✅ Backend is running"
echo ""

echo "Step 3: Checking if frontend is running..."
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3010 2>/dev/null || echo "000")

if [ "$FRONTEND_RESPONSE" != "200" ]; then
    echo "⚠️  WARNING: Frontend not responding on port 3010"
    echo "E2E tests require frontend to be running"
    echo "Start frontend with: cd frontend && npm run dev"
    exit 1
fi
echo "✅ Frontend is running"
echo ""

echo "Step 4: Running E2E tests..."
echo ""

# Run E2E tests and capture output
OUTPUT=$(npx playwright test 2>&1)
EXIT_CODE=$?

# Show output
echo "$OUTPUT"
echo ""

# Check if tests passed
if [ $EXIT_CODE -ne 0 ]; then
    echo "❌❌❌ E2E TESTS FAILED ❌❌❌"
    echo ""
    echo "Tests did not pass. Work is INCOMPLETE."
    echo "Fix failing tests before reporting work as complete."
    exit 1
fi

# Parse test results
TOTAL_TESTS=$(echo "$OUTPUT" | grep -oP '\d+(?= passed)' | tail -1)

if [ -z "$TOTAL_TESTS" ] || [ "$TOTAL_TESTS" -eq 0 ]; then
    echo "❌❌❌ NO E2E TESTS EXECUTED ❌❌❌"
    echo ""
    echo "E2E tests exist but did not execute."
    echo "This indicates a configuration or setup issue."
    exit 1
fi

echo "=================================================="
echo "✅✅✅ POST-HOOK PASSED ✅✅✅"
echo ""
echo "E2E Tests: $TOTAL_TESTS passed"
echo "All tests executed successfully with 100% pass rate"
echo "=================================================="

exit 0
