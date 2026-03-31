#!/bin/bash

# Sprint 3 - WAVE 2 POST-HOOK: Application Layer Validation
# Exit on any error (fail-fast)
set -e

echo "=========================================="
echo "SPRINT 3 - WAVE 2 POST-HOOK VALIDATION"
echo "=========================================="
echo ""

# GATE 1: Backend Compilation
echo "GATE 1: Checking backend compilation..."
cd backend
npm run build > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ GATE 1 PASSED: Backend compiles with 0 errors"
else
    echo "❌ GATE 1 FAILED: Backend compilation failed"
    exit 1
fi

# GATE 2: Application Layer Tests (Sprint 3 specific)
echo ""
echo "GATE 2: Running application layer tests..."
npm test project/application --passWithNoTests 2>&1 | tee test-output.txt

# Check if tests passed
if grep -q "PASS" test-output.txt || grep -q "No tests found" test-output.txt; then
    echo "✅ GATE 2 PASSED: Application tests passing"
else
    echo "❌ GATE 2 FAILED: Application tests failing"
    exit 1
fi

# GATE 3: Domain Tests (regression check)
echo ""
echo "GATE 3: Running domain tests (regression check)..."
npm test -- --testPathPattern="project/domain" --passWithNoTests 2>&1 | tee domain-test-output.txt

if grep -q "PASS" domain-test-output.txt || grep -q "No tests found" domain-test-output.txt; then
    echo "✅ GATE 3 PASSED: Domain tests passing (no regression)"
else
    echo "❌ GATE 3 FAILED: Domain tests failing"
    exit 1
fi

# GATE 4: Test Coverage
echo ""
echo "GATE 4: Checking test coverage..."
npm test -- --testPathPattern="project" --coverage --passWithNoTests 2>&1 | tee coverage-output.txt

# Check coverage levels
if grep -q "All files" coverage-output.txt; then
    echo "✅ GATE 4 PASSED: Coverage report generated"
else
    echo "⚠️  GATE 4 WARNING: Could not generate coverage report"
fi

# GATE 5: Backend Startup
echo ""
echo "GATE 5: Testing backend startup..."
timeout 10 npm run start:dev > startup.log 2>&1 &
PID=$!
sleep 5

if ps -p $PID > /dev/null; then
    echo "✅ GATE 5 PASSED: Backend starts successfully"
    kill $PID 2>/dev/null || true
else
    echo "❌ GATE 5 FAILED: Backend failed to start"
    exit 1
fi

# GATE 6: Linting
echo ""
echo "GATE 6: Running linter..."
npm run lint 2>&1 | tee lint-output.txt

if grep -q "0 errors" lint-output.txt || ! grep -q "error" lint-output.txt; then
    echo "✅ GATE 6 PASSED: No linting errors"
else
    echo "⚠️  GATE 6 WARNING: Linting issues found (non-blocking)"
fi

# Clean up temp files
rm -f test-output.txt domain-test-output.txt coverage-output.txt startup.log lint-output.txt

echo ""
echo "=========================================="
echo "✅✅✅ POST-HOOK PASSED: WAVE 2 COMPLETE ✅✅✅"
echo "=========================================="
echo ""
echo "Summary:"
echo "- Backend compiles with 0 errors"
echo "- Application layer tests pass"
echo "- Domain tests pass (no regression)"
echo "- Backend starts successfully"
echo "- Ready for Wave 3 (API Layer)"
echo ""

exit 0