#!/bin/bash
# Post-Wave 1 Validation Hook - Domain Layer Complete
# BLOQUEA Wave 2 si domain layer incompleto, linting falla, o tests fallan
#
# Domain Layer must contain:
# - Entity files in backend/app/modules/*/domain/
# - Value objects
# - Repository interfaces
# - All tests passing
#
# Usage: bash scripts/hooks/post-hook-wave-1.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo ""
echo "================================================================="
echo " POST-WAVE 1 VALIDATION - Domain Layer"
echo "================================================================="
echo ""
echo "  This hook validates domain layer is complete BEFORE Wave 2"
echo "  Wave 2 (Application Layer) is BLOCKED until all validations PASS"
echo ""
echo "================================================================="
echo ""

ERRORS=0
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_FILE=".project-orchestration/post-wave-1-report-${TIMESTAMP}.md"

mkdir -p .project-orchestration
cat > "$REPORT_FILE" <<EOF
# Post-Wave 1 Validation Report - Domain Layer

**Date**: $(date +%Y-%m-%d)
**Time**: $(date +%H:%M:%S)
**Validated By**: post-hook-wave-1.sh

---

## Validation Summary

EOF

# VALIDATION 1: Domain Entities Exist
echo "================================================================="
echo " VALIDATION 1: Domain Entities Check (MANDATORY)"
echo "================================================================="

echo "### VALIDATION 1: Domain Entities" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

ENTITY_COUNT=0
if [ -d "backend/app" ]; then
  ENTITY_COUNT=$(find backend/app -path "*/domain/*.py" -not -name "__init__.py" 2>/dev/null | wc -l || echo "0")
fi

if [ "$ENTITY_COUNT" -gt 0 ]; then
  echo "  [OK] Domain Entities: $ENTITY_COUNT files found"
  echo "- [OK] Domain Entities: $ENTITY_COUNT files found" >> "$REPORT_FILE"
else
  echo "  [FAIL] No domain entity files found"
  echo "- [FAIL] Domain Entities: NONE FOUND" >> "$REPORT_FILE"
  ERRORS=$((ERRORS + 1))
fi

echo "" >> "$REPORT_FILE"

# VALIDATION 2: Code Quality (ruff)
echo ""
echo "================================================================="
echo " VALIDATION 2: Code Quality - Linting (BLOCKING)"
echo "================================================================="

echo "### VALIDATION 2: Code Quality (ruff)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ -d "backend" ]; then
  cd backend
  if command -v ruff > /dev/null 2>&1; then
    if ruff check . > ../domain-lint-wave1.txt 2>&1; then
      echo "  [OK] Linting: CLEAN"
      echo "- [OK] Linting: CLEAN (0 errors)" >> "../$REPORT_FILE"
    else
      ERROR_COUNT=$(wc -l < ../domain-lint-wave1.txt 2>/dev/null || echo "0")
      echo "  [FAIL] Linting: $ERROR_COUNT issues"
      echo "- [FAIL] Linting: $ERROR_COUNT issues found" >> "../$REPORT_FILE"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo "  [INFO] ruff not installed, skipping"
    echo "- [INFO] Linting: SKIPPED (ruff not installed)" >> "../$REPORT_FILE"
  fi
  cd ..
fi

echo "" >> "$REPORT_FILE"

# VALIDATION 3: Type Check (mypy)
echo ""
echo "================================================================="
echo " VALIDATION 3: Type Check (RECOMMENDED)"
echo "================================================================="

echo "### VALIDATION 3: Type Check (mypy)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ -d "backend" ]; then
  cd backend
  if command -v mypy > /dev/null 2>&1; then
    if mypy app/ > ../domain-mypy-wave1.txt 2>&1; then
      echo "  [OK] Type Check: PASSED"
      echo "- [OK] Type Check: PASSED" >> "../$REPORT_FILE"
    else
      MYPY_ERRORS=$(grep -c "error:" ../domain-mypy-wave1.txt 2>/dev/null || echo "0")
      echo "  [WARN] Type Check: $MYPY_ERRORS errors"
      echo "- [WARN] Type Check: $MYPY_ERRORS errors" >> "../$REPORT_FILE"
    fi
  else
    echo "  [INFO] mypy not installed, skipping"
    echo "- [INFO] Type Check: SKIPPED" >> "../$REPORT_FILE"
  fi
  cd ..
fi

echo "" >> "$REPORT_FILE"

# VALIDATION 4: Domain Tests
echo ""
echo "================================================================="
echo " VALIDATION 4: Domain Tests (BLOCKING)"
echo "================================================================="

echo "### VALIDATION 4: Domain Tests (pytest)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ -d "backend/tests" ]; then
  cd backend
  if python -m pytest tests/ -v --tb=short > ../domain-tests-wave1.txt 2>&1; then
    PASSED=$(grep -oE "[0-9]+ passed" ../domain-tests-wave1.txt | grep -oE "[0-9]+" || echo "0")
    echo "  [OK] Domain Tests: $PASSED tests passed"
    echo "- [OK] Domain Tests: $PASSED tests passed" >> "../$REPORT_FILE"
  else
    FAILED=$(grep -oE "[0-9]+ failed" ../domain-tests-wave1.txt | grep -oE "[0-9]+" || echo "unknown")
    echo "  [FAIL] Domain Tests: $FAILED tests failed"
    echo "- [FAIL] Domain Tests: $FAILED tests failed" >> "../$REPORT_FILE"
    ERRORS=$((ERRORS + 1))
  fi
  cd ..
else
  echo "  [FAIL] No tests/ directory in backend"
  echo "- [FAIL] Domain Tests: NO tests/ DIRECTORY" >> "$REPORT_FILE"
  ERRORS=$((ERRORS + 1))
fi

echo "" >> "$REPORT_FILE"

# FINAL VERDICT
echo ""
echo "================================================================="
echo "================================================================="
echo ""

if [ $ERRORS -eq 0 ]; then
  echo "[PASSED] WAVE 1 VALIDATION PASSED - Domain Layer Complete"
  echo "" >> "$REPORT_FILE"
  echo "## [PASSED] POST-WAVE 1 VALIDATION: PASSED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Errors**: 0" >> "$REPORT_FILE"
  echo "**Wave 2 (Application Layer) is CLEARED TO START**" >> "$REPORT_FILE"
  echo ""
  echo "================================================================="
  echo " YOU MAY PROCEED TO WAVE 2 (APPLICATION LAYER)"
  echo "================================================================="
  echo ""
  echo "Report: $REPORT_FILE"
  exit 0
else
  echo "[FAILED] WAVE 1 VALIDATION FAILED - Domain Layer Incomplete"
  echo "" >> "$REPORT_FILE"
  echo "## [FAILED] POST-WAVE 1 VALIDATION: FAILED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Errors**: $ERRORS" >> "$REPORT_FILE"
  echo "**Wave 2 (Application Layer) is BLOCKED**" >> "$REPORT_FILE"
  echo ""
  echo "================================================================="
  echo " WAVE 2 IS BLOCKED UNTIL ALL VALIDATIONS PASS"
  echo "================================================================="
  echo ""
  echo "Errors: $ERRORS"
  echo "Report: $REPORT_FILE"
  echo ""
  echo "Fix all issues and re-run:"
  echo "  bash scripts/hooks/post-hook-wave-1.sh"
  exit 1
fi
