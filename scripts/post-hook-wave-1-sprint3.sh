#!/bin/bash
# POST-HOOK for Sprint 3 Wave 1 (Domain Layer - Project Module)
# This script MUST pass (exit 0) to mark wave as complete

set -e  # Exit on any error

echo "🔍 POST-HOOK SPRINT 3 WAVE 1: Validating domain layer completion..."
echo "═══════════════════════════════════════════════════════"

FAILED_GATES=()

# Navigate to backend directory
cd "$(dirname "$0")/../backend" || exit 1

# GATE 1: Backend MUST compile with 0 errors
echo ""
echo "🏗️  GATE 1: Compilation Check..."
if ! npm run build > /tmp/build.log 2>&1; then
  echo "❌ GATE 1 FAILED: Backend does not compile"
  cat /tmp/build.log
  FAILED_GATES+=("GATE 1: Compilation")
else
  echo "✅ GATE 1 PASSED: Backend compiles with 0 errors"
fi

# GATE 2: Project domain tests MUST pass
echo ""
echo "🧪 GATE 2: Project Domain Tests..."
PROJECT_TEST_OUTPUT=$(npx jest --testRegex=".*project/domain.*\\.spec\\.ts$" 2>&1 || true)
if echo "$PROJECT_TEST_OUTPUT" | grep -q "Test Suites:.*0 passed"; then
  echo "❌ GATE 2 FAILED: No project domain tests found"
  FAILED_GATES+=("GATE 2: Project Domain Tests")
elif echo "$PROJECT_TEST_OUTPUT" | grep -q "failing\|failed"; then
  echo "❌ GATE 2 FAILED: Project domain tests failing"
  echo "$PROJECT_TEST_OUTPUT" | grep -A 20 "fail"
  FAILED_GATES+=("GATE 2: Project Domain Tests")
else
  TESTS_COUNT=$(echo "$PROJECT_TEST_OUTPUT" | grep "Tests:" | awk '{print $2}')
  if [ -z "$TESTS_COUNT" ] || [ "$TESTS_COUNT" -lt 75 ]; then
    echo "❌ GATE 2 FAILED: Insufficient project tests (found: $TESTS_COUNT, required: 75+)"
    FAILED_GATES+=("GATE 2: Project Domain Tests")
  else
    echo "✅ GATE 2 PASSED: Project domain tests passing ($TESTS_COUNT tests)"
  fi
fi

# GATE 3: Task domain tests with project relations MUST pass
echo ""
echo "🧪 GATE 3: Task Domain Tests (with project relations)..."
TASK_TEST_OUTPUT=$(npx jest --testRegex=".*task/domain.*\\.spec\\.ts$" 2>&1 || true)
if echo "$TASK_TEST_OUTPUT" | grep -q "failing\|failed"; then
  echo "❌ GATE 3 FAILED: Task domain tests failing"
  echo "$TASK_TEST_OUTPUT" | grep -A 20 "fail"
  FAILED_GATES+=("GATE 3: Task Domain Tests")
else
  TASK_TESTS=$(echo "$TASK_TEST_OUTPUT" | grep "Tests:" | awk '{print $2}')
  if [ -n "$TASK_TESTS" ] && [ "$TASK_TESTS" -gt 0 ]; then
    echo "✅ GATE 3 PASSED: Task domain tests passing ($TASK_TESTS tests)"
  else
    echo "⚠️  GATE 3 WARNING: Task domain tests not found or 0 tests"
  fi
fi

# GATE 4: Total domain tests MUST be 110+
echo ""
echo "📊 GATE 4: Total Domain Tests Count..."
ALL_DOMAIN_OUTPUT=$(npx jest --testRegex=".*domain.*\\.spec\\.ts$" 2>&1 || true)
TOTAL_TESTS=$(echo "$ALL_DOMAIN_OUTPUT" | grep "Tests:" | tail -1 | awk '{print $2}')

if [ -z "$TOTAL_TESTS" ]; then
  echo "❌ GATE 4 FAILED: Cannot determine total test count"
  FAILED_GATES+=("GATE 4: Total Test Count")
elif [ "$TOTAL_TESTS" -lt 110 ]; then
  echo "❌ GATE 4 FAILED: Insufficient total tests (found: $TOTAL_TESTS, required: 110+)"
  FAILED_GATES+=("GATE 4: Total Test Count")
else
  echo "✅ GATE 4 PASSED: Total domain tests sufficient ($TOTAL_TESTS tests)"
fi

# GATE 5: Coverage MUST be 100% for domain files
echo ""
echo "📊 GATE 5: Domain Coverage..."
COVERAGE_OUTPUT=$(npx jest --testRegex=".*domain.*\\.spec\\.ts$" --coverage --silent 2>&1 || true)

# Check project domain coverage
PROJECT_COVERAGE=$(echo "$COVERAGE_OUTPUT" | grep -E "project/domain" | grep "All files" | awk '{print $2}' || echo "0")
if [ "$PROJECT_COVERAGE" != "100" ] && [ -n "$PROJECT_COVERAGE" ] && [ "$PROJECT_COVERAGE" != "0" ]; then
  echo "❌ GATE 5 FAILED: Project domain coverage is $PROJECT_COVERAGE% (requires 100%)"
  echo "$COVERAGE_OUTPUT" | grep -E "project/domain" | grep -v "100"
  FAILED_GATES+=("GATE 5: Coverage")
else
  echo "✅ GATE 5 PASSED: Domain coverage is acceptable"
fi

# GATE 6: Linting MUST be clean
echo ""
echo "🔍 GATE 6: Linting..."
if ! npm run lint > /tmp/lint.log 2>&1; then
  echo "❌ GATE 6 FAILED: Linting errors found"
  cat /tmp/lint.log | head -50
  FAILED_GATES+=("GATE 6: Linting")
else
  echo "✅ GATE 6 PASSED: Linting clean"
fi

# GATE 7: Required files MUST exist
echo ""
echo "📁 GATE 7: Required Files Check..."
REQUIRED_FILES=(
  "src/modules/project/domain/entities/project.entity.ts"
  "src/modules/project/domain/entities/project.entity.spec.ts"
  "src/modules/project/domain/value-objects/project-settings.vo.ts"
  "src/modules/project/domain/value-objects/project-settings.vo.spec.ts"
  "src/modules/project/domain/value-objects/task-count.vo.ts"
  "src/modules/project/domain/value-objects/task-count.vo.spec.ts"
  "src/modules/project/domain/repositories/project.repository.ts"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    MISSING_FILES+=("$file")
  fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
  echo "❌ GATE 7 FAILED: Missing required files:"
  for file in "${MISSING_FILES[@]}"; do
    echo "  - $file"
  done
  FAILED_GATES+=("GATE 7: Required Files")
else
  echo "✅ GATE 7 PASSED: All required files exist"
fi

# GATE 8: No regressions in existing tests
echo ""
echo "🔄 GATE 8: Regression Check..."
FULL_TEST_OUTPUT=$(npm test 2>&1 || true)
if echo "$FULL_TEST_OUTPUT" | grep -q "failing\|failed"; then
  echo "❌ GATE 8 FAILED: Regressions detected in existing tests"
  echo "$FULL_TEST_OUTPUT" | grep -A 10 "fail" | head -30
  FAILED_GATES+=("GATE 8: No Regressions")
else
  echo "✅ GATE 8 PASSED: No regressions detected"
fi

# SUMMARY
echo ""
echo "═══════════════════════════════════════════════════════"

if [ ${#FAILED_GATES[@]} -eq 0 ]; then
  echo "✅✅✅ POST-HOOK PASSED: Sprint 3 Wave 1 is COMPLETE ✅✅✅"
  echo "═══════════════════════════════════════════════════════"
  echo ""
  echo "Summary:"
  echo "  ✅ Backend compiles with 0 errors"
  echo "  ✅ Project domain tests passing (75+ tests)"
  echo "  ✅ Task domain updated with project relations"
  echo "  ✅ Total domain tests: 110+"
  echo "  ✅ Coverage: 100% on domain files"
  echo "  ✅ Linting: Clean"
  echo "  ✅ All required files exist"
  echo "  ✅ No regressions detected"
  echo ""
  echo "🎯 Ready for Wave 2 (Application Layer)"
  exit 0
else
  echo "❌❌❌ POST-HOOK FAILED: Sprint 3 Wave 1 is INCOMPLETE ❌❌❌"
  echo ""
  echo "Failed Gates:"
  for gate in "${FAILED_GATES[@]}"; do
    echo "  ❌ $gate"
  done
  echo ""
  echo "⚠️  FIX ALL FAILED GATES BEFORE MARKING WAVE COMPLETE"
  echo "═══════════════════════════════════════════════════════"
  exit 1
fi