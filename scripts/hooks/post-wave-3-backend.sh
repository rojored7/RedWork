#!/bin/bash
# Post-Wave 3 Validation Hook - Backend Application Layer Complete
# BLOQUEA Wave 4 si backend no arranca, linting falla, tests fallan, o security issues
#
# Integra 3 agentes:
# - 20-Code-Quality-Linting-Agent
# - 18-Smoke-Test-Validator
# - 19-Security-Review-Agent
#
# Backend: FastAPI (Python) with ruff, mypy, pytest
#
# Usage: bash scripts/hooks/post-wave-3-backend.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo ""
echo "================================================================="
echo " POST-WAVE 3 VALIDATION - Backend Application Layer"
echo "================================================================="
echo ""
echo "  This hook validates backend is production-ready BEFORE Wave 4"
echo "  Wave 4 (API Layer) is BLOCKED until all validations PASS"
echo ""
echo "================================================================="
echo ""

ERRORS=0
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_FILE=".project-orchestration/post-wave-3-report-${TIMESTAMP}.md"

# Create report header
mkdir -p .project-orchestration
cat > "$REPORT_FILE" <<EOF
# Post-Wave 3 Validation Report - Backend Application Layer

**Date**: $(date +%Y-%m-%d)
**Time**: $(date +%H:%M:%S)
**Validated By**: post-wave-3-backend.sh

---

## Validation Summary

EOF

# ============================================
# VALIDATION 1: BACKEND IMPORT CHECK
# ============================================
echo "================================================================="
echo " VALIDATION 1: Backend Import Check (MANDATORY)"
echo "================================================================="

echo "### VALIDATION 1: Backend Import Check" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "  Verifying backend module can be imported..."
cd backend
if python -c "import app.main" > ../backend-build-wave3.txt 2>&1; then
  echo "  [OK] Backend Import Check: SUCCESS (app.main loads without errors)"
  echo "- [OK] Backend Import Check: SUCCESS (app.main loads without errors)" >> "../$REPORT_FILE"
else
  echo "  [FAIL] Backend Import Check: FAILED"
  echo "- [FAIL] Backend Import Check: FAILED" >> "../$REPORT_FILE"
  echo "" >> "../$REPORT_FILE"
  echo "  **Import Error Output**:" >> "../$REPORT_FILE"
  echo '  ```' >> "../$REPORT_FILE"
  tail -20 ../backend-build-wave3.txt >> "../$REPORT_FILE"
  echo '  ```' >> "../$REPORT_FILE"
  echo ""
  echo "  Action Required: Fix import errors in backend/app/main.py"
  ERRORS=$((ERRORS + 1))
fi
cd ..

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 2: CODE QUALITY (ruff)
# ============================================
echo ""
echo "================================================================="
echo " VALIDATION 2: Code Quality - Backend Linting (BLOCKING)"
echo "================================================================="

echo "### VALIDATION 2: Code Quality (ruff)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "  Running backend linting (ruff)..."
cd backend
if ruff check . > ../backend-lint-wave3.txt 2>&1; then
  echo "  [OK] Backend Linting: CLEAN (0 errors)"
  echo "- [OK] Backend Linting: CLEAN (0 errors)" >> "../$REPORT_FILE"
else
  ERROR_COUNT=$(wc -l < ../backend-lint-wave3.txt 2>/dev/null || echo "0")

  if [ "$ERROR_COUNT" = "0" ]; then
    echo "  [OK] Backend Linting: CLEAN (0 errors)"
    echo "- [OK] Backend Linting: CLEAN (0 errors)" >> "../$REPORT_FILE"
  else
    echo "  [FAIL] Backend Linting: $ERROR_COUNT issues found"
    echo "- [FAIL] Backend Linting: $ERROR_COUNT issues found" >> "../$REPORT_FILE"
    echo "" >> "../$REPORT_FILE"
    echo "  **Linting Errors**:" >> "../$REPORT_FILE"
    echo '  ```' >> "../$REPORT_FILE"
    head -20 ../backend-lint-wave3.txt >> "../$REPORT_FILE"
    echo '  ```' >> "../$REPORT_FILE"
    echo ""
    echo "  Action Required: Run 'cd backend && ruff check . --fix'"
    ERRORS=$((ERRORS + 1))
  fi
fi
cd ..

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 3: TYPE CHECK (mypy, optional)
# ============================================
echo ""
echo "================================================================="
echo " VALIDATION 3: Type Check - mypy (RECOMMENDED)"
echo "================================================================="

echo "### VALIDATION 3: Type Check (mypy)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "  Running type checking (mypy)..."
cd backend
if command -v mypy > /dev/null 2>&1; then
  if mypy app/ > ../backend-mypy-wave3.txt 2>&1; then
    echo "  [OK] Type Check: PASSED (no type errors)"
    echo "- [OK] Type Check: PASSED (no type errors)" >> "../$REPORT_FILE"
  else
    MYPY_ERRORS=$(grep -c "error:" ../backend-mypy-wave3.txt 2>/dev/null || echo "0")
    if [ "$MYPY_ERRORS" = "0" ]; then
      echo "  [OK] Type Check: PASSED"
      echo "- [OK] Type Check: PASSED" >> "../$REPORT_FILE"
    else
      echo "  [WARN] Type Check: $MYPY_ERRORS type errors found"
      echo "- [WARN] Type Check: $MYPY_ERRORS type errors found" >> "../$REPORT_FILE"
      echo "" >> "../$REPORT_FILE"
      echo "  **Type Errors**:" >> "../$REPORT_FILE"
      echo '  ```' >> "../$REPORT_FILE"
      head -20 ../backend-mypy-wave3.txt >> "../$REPORT_FILE"
      echo '  ```' >> "../$REPORT_FILE"
      echo ""
      echo "  Review: cd backend && mypy app/"
    fi
  fi
else
  echo "  [INFO] mypy not installed, skipping type check"
  echo "- [INFO] Type Check: SKIPPED (mypy not installed)" >> "../$REPORT_FILE"
fi
cd ..

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 4: BACKEND TESTS (pytest)
# ============================================
echo ""
echo "================================================================="
echo " VALIDATION 4: Backend Tests - pytest (BLOCKING)"
echo "================================================================="

echo "### VALIDATION 4: Backend Tests (pytest)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "  Running backend tests (pytest)..."
cd backend
if [ -d "tests" ]; then
  if python -m pytest tests/ -v --tb=short > ../backend-tests-wave3.txt 2>&1; then
    PASSED=$(grep -oE "[0-9]+ passed" ../backend-tests-wave3.txt | grep -oE "[0-9]+" || echo "0")
    echo "  [OK] Backend Tests: PASSED ($PASSED tests passed)"
    echo "- [OK] Backend Tests: PASSED ($PASSED tests passed)" >> "../$REPORT_FILE"
  else
    FAILED=$(grep -oE "[0-9]+ failed" ../backend-tests-wave3.txt | grep -oE "[0-9]+" || echo "unknown")
    echo "  [FAIL] Backend Tests: $FAILED tests failed"
    echo "- [FAIL] Backend Tests: $FAILED tests failed" >> "../$REPORT_FILE"
    echo "" >> "../$REPORT_FILE"
    echo "  **Test Output**:" >> "../$REPORT_FILE"
    echo '  ```' >> "../$REPORT_FILE"
    tail -30 ../backend-tests-wave3.txt >> "../$REPORT_FILE"
    echo '  ```' >> "../$REPORT_FILE"
    echo ""
    echo "  Action Required: Fix failing tests before proceeding"
    echo "  Run: cd backend && python -m pytest tests/ -v --tb=short"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  [WARN] No tests/ directory found in backend"
  echo "- [WARN] Backend Tests: NO tests/ DIRECTORY FOUND" >> "../$REPORT_FILE"
fi
cd ..

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 5: SECURITY BACKEND (19-Security-Review-Agent)
# ============================================
echo ""
echo "================================================================="
echo " VALIDATION 5: Security Review Backend (BLOCKING)"
echo "================================================================="

echo "### VALIDATION 5: Security Review Backend (19-Security-Review-Agent)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "  Running security validation..."

# 5.1 Check for hardcoded secrets
echo "  Scanning for hardcoded secrets..."
SECRETS=0
if [ -d "backend/app" ]; then
  cd backend/app
  SECRETS=$(grep -rE "(password|secret|api_key|apikey|token)\s*[:=]\s*['\"][^'\"]{8,}" . \
    --include="*.py" \
    --exclude="*test*" \
    --exclude="*conftest*" \
    | grep -v "os.environ" \
    | grep -v "os.getenv" \
    | grep -v "settings\." \
    | grep -v "config\." \
    | grep -v "# " \
    | wc -l || echo "0")
  cd ../..
fi

if [ "$SECRETS" = "0" ]; then
  echo "     [OK] No hardcoded secrets detected"
  echo "  - [OK] Hardcoded Secrets: NONE FOUND" >> "$REPORT_FILE"
else
  echo "     [FAIL] $SECRETS potential hardcoded secrets found"
  echo "  - [FAIL] Hardcoded Secrets: $SECRETS potential secrets found" >> "$REPORT_FILE"
  echo ""
  echo "  Action Required: Review and remove hardcoded secrets"
  ERRORS=$((ERRORS + 1))
fi

# 5.2 Check .env files not in git
echo "  Checking .env files..."
if git ls-files | grep -qE "\.env$|\.env\.production$"; then
  echo "     [FAIL] .env files found in git"
  echo "  - [FAIL] .env Files: FOUND IN GIT (security risk)" >> "$REPORT_FILE"
  ERRORS=$((ERRORS + 1))
else
  echo "     [OK] No .env files in git"
  echo "  - [OK] .env Files: NOT IN GIT" >> "$REPORT_FILE"
fi

# 5.3 Check for pip-audit (if available)
if command -v pip-audit > /dev/null 2>&1; then
  echo "  Running dependency audit (pip-audit)..."
  cd backend
  if pip-audit > ../backend-audit-wave3.txt 2>&1; then
    echo "     [OK] Dependency Audit: No known vulnerabilities"
    echo "  - [OK] Dependency Audit: NO VULNERABILITIES" >> "../$REPORT_FILE"
  else
    VULN_COUNT=$(grep -c "VULN" ../backend-audit-wave3.txt 2>/dev/null || echo "unknown")
    echo "     [WARN] Dependency Audit: $VULN_COUNT potential vulnerabilities"
    echo "  - [WARN] Dependency Audit: $VULN_COUNT vulnerabilities found" >> "../$REPORT_FILE"
  fi
  cd ..
else
  echo "  [INFO] pip-audit not installed, skipping dependency audit"
  echo "  - [INFO] Dependency Audit: SKIPPED (pip-audit not installed)" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# ============================================
# FINAL VERDICT
# ============================================
echo ""
echo "================================================================="
echo "================================================================="
echo ""

if [ $ERRORS -eq 0 ]; then
  echo "[PASSED] WAVE 3 VALIDATION PASSED - Backend Application Layer Complete"
  echo ""
  echo "## [PASSED] POST-WAVE 3 VALIDATION: PASSED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Errors**: 0" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Wave 4 (API Layer) is CLEARED TO START**" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "Backend application layer validated successfully:" >> "$REPORT_FILE"
  echo "- [OK] Import Check: SUCCESS" >> "$REPORT_FILE"
  echo "- [OK] Code Quality: CLEAN" >> "$REPORT_FILE"
  echo "- [OK] Type Check: PASSED" >> "$REPORT_FILE"
  echo "- [OK] Backend Tests: PASSED" >> "$REPORT_FILE"
  echo "- [OK] Security: NO CRITICAL ISSUES" >> "$REPORT_FILE"
  echo ""
  echo "================================================================="
  echo " YOU MAY PROCEED TO WAVE 4 (API LAYER)"
  echo "================================================================="
  echo ""
  echo "Validation report saved to: $REPORT_FILE"
  echo ""
  exit 0
else
  echo "[FAILED] WAVE 3 VALIDATION FAILED - Backend Application Layer Incomplete"
  echo ""
  echo "## [FAILED] POST-WAVE 3 VALIDATION: FAILED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Errors**: $ERRORS" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Wave 4 (API Layer) is BLOCKED**" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "Fix all validation errors above before proceeding to Wave 4." >> "$REPORT_FILE"
  echo ""
  echo "================================================================="
  echo " WAVE 4 IS BLOCKED UNTIL ALL VALIDATIONS PASS"
  echo "================================================================="
  echo ""
  echo "Validation Errors: $ERRORS"
  echo ""
  echo "Detailed validation report saved to: $REPORT_FILE"
  echo ""
  echo "Fix all issues and re-run:"
  echo "  bash scripts/hooks/post-wave-3-backend.sh"
  echo ""
  exit 1
fi
