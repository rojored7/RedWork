#!/bin/bash

###############################################################################
# POST-HOOK: Integration Tests Validation
#
# Purpose: Validates that ALL integration tests execute and PASS with 100%
#
# This hook MUST be executed after any agent reports "integration tests complete"
#
# Exit Codes:
#   0 = All integration tests passed
#   1 = Tests failed or did not execute properly
###############################################################################

set -e

echo "=================================================="
echo "POST-HOOK: Integration Tests Validation"
echo "=================================================="
echo ""

# Change to backend directory
cd "$(dirname "$0")/../backend" || exit 1

echo "Step 1: Verifying backend compiles..."
npm run build > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ BACKEND COMPILATION FAILED"
    echo "Integration tests cannot run if backend doesn't compile"
    exit 1
fi
echo "✅ Backend compiles"
echo ""

echo "Step 2: Running integration tests..."
echo ""

# Run integration tests and capture output
OUTPUT=$(npm run test:integration 2>&1)
EXIT_CODE=$?

# Show output
echo "$OUTPUT"
echo ""

# Check if tests passed
if [ $EXIT_CODE -ne 0 ]; then
    echo "❌❌❌ INTEGRATION TESTS FAILED ❌❌❌"
    echo ""
    echo "Tests did not pass. Work is INCOMPLETE."
    echo "Fix failing tests before reporting work as complete."
    exit 1
fi

# Parse test results
TOTAL_TESTS=$(echo "$OUTPUT" | grep -oP '\d+(?= passed)' | head -1)

if [ -z "$TOTAL_TESTS" ] || [ "$TOTAL_TESTS" -eq 0 ]; then
    echo "❌❌❌ NO INTEGRATION TESTS EXECUTED ❌❌❌"
    echo ""
    echo "Integration tests exist but did not execute."
    echo "This indicates a configuration or setup issue."
    exit 1
fi

echo "=================================================="
echo "✅✅✅ POST-HOOK PASSED ✅✅✅"
echo ""
echo "Integration Tests: $TOTAL_TESTS passed"
echo "All tests executed successfully with 100% pass rate"
echo "=================================================="

exit 0
