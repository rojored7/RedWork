#!/bin/bash
# Pre-Wave 2 Validation Hook - Application Layer Prerequisites
# Validates Wave 1 is complete BEFORE Wave 2 (Application Layer) starts
#
# Usage: bash scripts/hooks/pre-hook-wave-2.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo ""
echo "================================================================="
echo " PRE-WAVE 2 VALIDATION - Application Layer Prerequisites"
echo "================================================================="
echo ""

ERRORS=0

# Check domain entities exist
echo "  Checking domain layer artifacts..."
DOMAIN_FILES=0
if [ -d "backend/app" ]; then
  DOMAIN_FILES=$(find backend/app -path "*/domain/*.py" -not -name "__init__.py" 2>/dev/null | wc -l || echo "0")
fi

if [ "$DOMAIN_FILES" -gt 0 ]; then
  echo "  [OK] Domain layer: $DOMAIN_FILES domain files found"
else
  echo "  [FAIL] No domain files found in backend/app/*/domain/"
  echo "         Wave 1 must create domain entities before Wave 2 starts"
  ERRORS=$((ERRORS + 1))
fi

# Check Wave 1 tests exist
echo "  Checking Wave 1 tests..."
DOMAIN_TESTS=0
if [ -d "backend/tests" ]; then
  DOMAIN_TESTS=$(find backend/tests -name "test_*domain*" -o -name "test_*entity*" -o -name "test_*value_object*" 2>/dev/null | wc -l || echo "0")
fi

if [ "$DOMAIN_TESTS" -gt 0 ]; then
  echo "  [OK] Domain tests: $DOMAIN_TESTS test files found"
else
  echo "  [FAIL] No domain test files found"
  echo "         Wave 1 tests must pass before Wave 2 starts"
  ERRORS=$((ERRORS + 1))
fi

# Check Wave 1 tests pass
echo "  Running Wave 1 tests..."
if [ -d "backend/tests" ] && [ "$DOMAIN_TESTS" -gt 0 ]; then
  cd backend
  if python -m pytest tests/ -v --tb=short -q > /dev/null 2>&1; then
    echo "  [OK] Wave 1 tests: ALL PASSED"
  else
    echo "  [FAIL] Wave 1 tests: SOME FAILED"
    echo "         Fix failing tests before starting Wave 2"
    ERRORS=$((ERRORS + 1))
  fi
  cd ..
fi

# Check post-wave-1 report if it exists
echo "  Checking post-wave-1 report..."
LATEST_REPORT=$(ls -t .project-orchestration/post-wave-1-report-*.md 2>/dev/null | head -1)
if [ -n "$LATEST_REPORT" ]; then
  if grep -q "PASSED" "$LATEST_REPORT" 2>/dev/null; then
    echo "  [OK] Post-Wave 1 report: PASSED"
  else
    echo "  [FAIL] Post-Wave 1 report shows FAILED"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  [INFO] No post-wave-1 report found (run post-hook-wave-1.sh first)"
fi

echo ""
echo "================================================================="
if [ $ERRORS -eq 0 ]; then
  echo " [PASSED] PRE-WAVE 2: Wave 1 completion validated"
  echo " Wave 2 (Application Layer) is CLEARED TO START"
  echo "================================================================="
  exit 0
else
  echo " [FAILED] PRE-WAVE 2: $ERRORS validation(s) failed"
  echo " Wave 2 (Application Layer) is BLOCKED"
  echo "================================================================="
  exit 1
fi
