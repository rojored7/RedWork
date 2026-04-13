#!/bin/bash
# Post-Wave 2 Validation Hook - Application Layer / DTOs Complete
# BLOQUEA Wave 3 si application layer incompleta, DTOs invalidos, o tests fallan
#
# Application Layer must contain:
# - Pydantic DTOs/schemas
# - Service/use case files
# - All Wave 1 + Wave 2 tests passing
#
# Usage: bash scripts/hooks/post-hook-wave-2.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo ""
echo "================================================================="
echo " POST-WAVE 2 VALIDATION - Application Layer / DTOs"
echo "================================================================="
echo ""
echo "  This hook validates application layer is complete BEFORE Wave 3"
echo "  Wave 3 (Backend Integration) is BLOCKED until all validations PASS"
echo ""
echo "================================================================="
echo ""

ERRORS=0
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_FILE=".project-orchestration/post-wave-2-report-${TIMESTAMP}.md"

mkdir -p .project-orchestration
cat > "$REPORT_FILE" <<EOF
# Post-Wave 2 Validation Report - Application Layer

**Date**: $(date +%Y-%m-%d)
**Time**: $(date +%H:%M:%S)
**Validated By**: post-hook-wave-2.sh

---

## Validation Summary

EOF

# VALIDATION 1: DTOs / Schemas Exist
echo "================================================================="
echo " VALIDATION 1: DTOs / Pydantic Schemas (MANDATORY)"
echo "================================================================="

echo "### VALIDATION 1: DTOs / Schemas" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

DTO_COUNT=0
if [ -d "backend/app" ]; then
  DTO_COUNT=$(find backend/app -name "*schema*" -o -name "*dto*" -o -name "*request*" -o -name "*response*" 2>/dev/null \
    | grep -E "\.py$" | grep -v "__pycache__" | wc -l || echo "0")
fi

if [ "$DTO_COUNT" -gt 0 ]; then
  echo "  [OK] DTOs/Schemas: $DTO_COUNT files found"
  echo "- [OK] DTOs/Schemas: $DTO_COUNT files found" >> "$REPORT_FILE"
else
  echo "  [FAIL] No DTO/schema files found"
  echo "- [FAIL] DTOs/Schemas: NONE FOUND" >> "$REPORT_FILE"
  ERRORS=$((ERRORS + 1))
fi

echo "" >> "$REPORT_FILE"

# VALIDATION 2: Services / Use Cases Exist
echo ""
echo "================================================================="
echo " VALIDATION 2: Services / Use Cases (MANDATORY)"
echo "================================================================="

echo "### VALIDATION 2: Services / Use Cases" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

SERVICE_COUNT=0
if [ -d "backend/app" ]; then
  SERVICE_COUNT=$(find backend/app -name "*service*" -o -name "*use_case*" 2>/dev/null \
    | grep -E "\.py$" | grep -v "__pycache__" | wc -l || echo "0")
fi

if [ "$SERVICE_COUNT" -gt 0 ]; then
  echo "  [OK] Services: $SERVICE_COUNT files found"
  echo "- [OK] Services: $SERVICE_COUNT files found" >> "$REPORT_FILE"
else
  echo "  [FAIL] No service/use_case files found"
  echo "- [FAIL] Services: NONE FOUND" >> "$REPORT_FILE"
  ERRORS=$((ERRORS + 1))
fi

echo "" >> "$REPORT_FILE"

# VALIDATION 3: Code Quality (ruff)
echo ""
echo "================================================================="
echo " VALIDATION 3: Code Quality - Linting (BLOCKING)"
echo "================================================================="

echo "### VALIDATION 3: Code Quality (ruff)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ -d "backend" ]; then
  cd backend
  if command -v ruff > /dev/null 2>&1; then
    if ruff check . > ../app-lint-wave2.txt 2>&1; then
      echo "  [OK] Linting: CLEAN"
      echo "- [OK] Linting: CLEAN" >> "../$REPORT_FILE"
    else
      ERROR_COUNT=$(wc -l < ../app-lint-wave2.txt 2>/dev/null || echo "0")
      echo "  [FAIL] Linting: $ERROR_COUNT issues"
      echo "- [FAIL] Linting: $ERROR_COUNT issues" >> "../$REPORT_FILE"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo "  [INFO] ruff not installed, skipping"
    echo "- [INFO] Linting: SKIPPED" >> "../$REPORT_FILE"
  fi
  cd ..
fi

echo "" >> "$REPORT_FILE"

# VALIDATION 4: Type Check (mypy)
echo ""
echo "================================================================="
echo " VALIDATION 4: Type Check (RECOMMENDED)"
echo "================================================================="

echo "### VALIDATION 4: Type Check (mypy)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ -d "backend" ]; then
  cd backend
  if command -v mypy > /dev/null 2>&1; then
    if mypy app/ > ../app-mypy-wave2.txt 2>&1; then
      echo "  [OK] Type Check: PASSED"
      echo "- [OK] Type Check: PASSED" >> "../$REPORT_FILE"
    else
      MYPY_ERRORS=$(grep -c "error:" ../app-mypy-wave2.txt 2>/dev/null || echo "0")
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

# VALIDATION 5: All Tests (Wave 1 + Wave 2)
echo ""
echo "================================================================="
echo " VALIDATION 5: All Tests Wave 1+2 (BLOCKING)"
echo "================================================================="

echo "### VALIDATION 5: Tests (pytest)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ -d "backend/tests" ]; then
  cd backend
  if python -m pytest tests/ -v --tb=short > ../app-tests-wave2.txt 2>&1; then
    PASSED=$(grep -oE "[0-9]+ passed" ../app-tests-wave2.txt | grep -oE "[0-9]+" || echo "0")
    echo "  [OK] Tests: $PASSED passed"
    echo "- [OK] Tests: $PASSED passed" >> "../$REPORT_FILE"
  else
    FAILED=$(grep -oE "[0-9]+ failed" ../app-tests-wave2.txt | grep -oE "[0-9]+" || echo "unknown")
    echo "  [FAIL] Tests: $FAILED failed"
    echo "- [FAIL] Tests: $FAILED failed" >> "../$REPORT_FILE"
    ERRORS=$((ERRORS + 1))
  fi
  cd ..
else
  echo "  [FAIL] No tests/ directory in backend"
  echo "- [FAIL] Tests: NO tests/ DIRECTORY" >> "$REPORT_FILE"
  ERRORS=$((ERRORS + 1))
fi

echo "" >> "$REPORT_FILE"

# VALIDATION 6: Security - No Hardcoded Secrets
echo ""
echo "================================================================="
echo " VALIDATION 6: Security Check (BLOCKING)"
echo "================================================================="

echo "### VALIDATION 6: Security" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

SECRETS=0
if [ -d "backend/app" ]; then
  SECRETS=$(grep -rE "(password|secret|api_key|token)\s*[:=]\s*['\"][^'\"]{8,}" backend/app/ \
    --include="*.py" --exclude="*test*" \
    | grep -v "os.environ" | grep -v "os.getenv" | grep -v "settings\." \
    | wc -l 2>/dev/null || echo "0")
fi

if [ "$SECRETS" = "0" ]; then
  echo "  [OK] No hardcoded secrets"
  echo "- [OK] Security: NO HARDCODED SECRETS" >> "$REPORT_FILE"
else
  echo "  [FAIL] $SECRETS potential hardcoded secrets"
  echo "- [FAIL] Security: $SECRETS POTENTIAL SECRETS" >> "$REPORT_FILE"
  ERRORS=$((ERRORS + 1))
fi

echo "" >> "$REPORT_FILE"

# FINAL VERDICT
echo ""
echo "================================================================="
echo "================================================================="
echo ""

if [ $ERRORS -eq 0 ]; then
  echo "[PASSED] WAVE 2 VALIDATION PASSED - Application Layer Complete"
  echo "" >> "$REPORT_FILE"
  echo "## [PASSED] POST-WAVE 2 VALIDATION: PASSED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Errors**: 0" >> "$REPORT_FILE"
  echo "**Wave 3 (Backend Integration) is CLEARED TO START**" >> "$REPORT_FILE"
  echo ""
  echo "================================================================="
  echo " YOU MAY PROCEED TO WAVE 3 (BACKEND INTEGRATION)"
  echo "================================================================="
  echo ""
  echo "Report: $REPORT_FILE"
  exit 0
else
  echo "[FAILED] WAVE 2 VALIDATION FAILED - Application Layer Incomplete"
  echo "" >> "$REPORT_FILE"
  echo "## [FAILED] POST-WAVE 2 VALIDATION: FAILED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Errors**: $ERRORS" >> "$REPORT_FILE"
  echo "**Wave 3 (Backend Integration) is BLOCKED**" >> "$REPORT_FILE"
  echo ""
  echo "================================================================="
  echo " WAVE 3 IS BLOCKED UNTIL ALL VALIDATIONS PASS"
  echo "================================================================="
  echo ""
  echo "Errors: $ERRORS"
  echo "Report: $REPORT_FILE"
  echo ""
  echo "Fix all issues and re-run:"
  echo "  bash scripts/hooks/post-hook-wave-2.sh"
  exit 1
fi
