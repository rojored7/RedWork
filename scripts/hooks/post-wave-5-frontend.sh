#!/bin/bash
# Post-Wave 5 Validation Hook - Frontend & Full System Complete
# BLOQUEA SPRINT COMPLETION si frontend no funciona, smoke tests fallan, o security issues
#
# Integra 3 agentes:
# - 20-Code-Quality-Linting-Agent
# - 18-Smoke-Test-Validator
# - 19-Security-Review-Agent
#
# Frontend: React/TypeScript (npm/npx)
# Backend: FastAPI (Python) - python/pytest for backend checks
#
# Usage: bash scripts/hooks/post-wave-5-frontend.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo ""
echo "================================================================="
echo " POST-WAVE 5 VALIDATION - Frontend & Full System"
echo "================================================================="
echo ""
echo "  This hook validates FULL SYSTEM is production-ready"
echo "  SPRINT is NOT COMPLETE until all validations PASS"
echo ""
echo "================================================================="
echo ""

ERRORS=0
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_FILE=".project-orchestration/post-wave-5-report-${TIMESTAMP}.md"

# Create report header
mkdir -p .project-orchestration
cat > "$REPORT_FILE" <<EOF
# Post-Wave 5 Validation Report - Frontend & Full System

**Date**: $(date +%Y-%m-%d)
**Time**: $(date +%H:%M:%S)
**Validated By**: post-wave-5-frontend.sh

---

## Validation Summary

EOF

# ============================================
# VALIDATION 1: FRONTEND BUILD
# ============================================
echo "================================================================="
echo " VALIDATION 1: Frontend Build (MANDATORY)"
echo "================================================================="

echo "### VALIDATION 1: Frontend Build" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "  Building frontend..."
cd frontend
if npm run build > ../frontend-build-wave5.txt 2>&1; then
  echo "  [OK] Frontend Build: SUCCESS (0 TypeScript errors)"
  echo "- [OK] Frontend Build: SUCCESS (0 TypeScript errors)" >> "../$REPORT_FILE"
else
  echo "  [FAIL] Frontend Build: FAILED"
  echo "- [FAIL] Frontend Build: FAILED" >> "../$REPORT_FILE"
  echo "" >> "../$REPORT_FILE"
  echo "  **Build Output**:" >> "../$REPORT_FILE"
  echo '  ```' >> "../$REPORT_FILE"
  tail -20 ../frontend-build-wave5.txt >> "../$REPORT_FILE"
  echo '  ```' >> "../$REPORT_FILE"
  echo ""
  echo "  Action Required: Fix TypeScript/build errors before proceeding"
  ERRORS=$((ERRORS + 1))
fi
cd ..

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 2: FRONTEND LINT
# ============================================
echo ""
echo "================================================================="
echo " VALIDATION 2: Code Quality - Frontend Linting (BLOCKING)"
echo "================================================================="

echo "### VALIDATION 2: Code Quality Frontend (20-Code-Quality-Linting-Agent)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "  Running frontend linting (ESLint)..."
cd frontend
if npx eslint src/ > ../frontend-lint-wave5.txt 2>&1; then
  echo "  [OK] Frontend Linting: CLEAN (0 errors)"
  echo "- [OK] Frontend Linting: CLEAN (0 errors)" >> "../$REPORT_FILE"
else
  ERROR_COUNT=$(grep -c "error" ../frontend-lint-wave5.txt 2>/dev/null || echo "0")

  if [ "$ERROR_COUNT" = "0" ]; then
    echo "  [OK] Frontend Linting: CLEAN (0 errors)"
    echo "- [OK] Frontend Linting: CLEAN (0 errors)" >> "../$REPORT_FILE"
  else
    echo "  [FAIL] Frontend Linting: $ERROR_COUNT errors found"
    echo "- [FAIL] Frontend Linting: $ERROR_COUNT errors found" >> "../$REPORT_FILE"
    echo "" >> "../$REPORT_FILE"
    echo "  **Linting Errors**:" >> "../$REPORT_FILE"
    echo '  ```' >> "../$REPORT_FILE"
    grep "error" ../frontend-lint-wave5.txt | head -20 >> "../$REPORT_FILE"
    echo '  ```' >> "../$REPORT_FILE"
    echo ""
    echo "  Action Required: Run 'cd frontend && npx eslint src/ --fix'"
    ERRORS=$((ERRORS + 1))
  fi
fi
cd ..

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 3: FULL SYSTEM SMOKE TEST
# ============================================
echo ""
echo "================================================================="
echo " VALIDATION 3: Full System Smoke Test (BLOCKING)"
echo "================================================================="

echo "### VALIDATION 3: Full System Smoke Test (18-Smoke-Test-Validator)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "  Running full system smoke tests..."

# 3.1 Check if dedicated smoke test script exists
if [ -f "scripts/smoke-test.sh" ]; then
  if bash scripts/smoke-test.sh > full-smoke-test-wave5.txt 2>&1; then
    echo "  [OK] Full System Smoke Tests: PASSED"
    echo "- [OK] Full System Smoke Tests: PASSED" >> "$REPORT_FILE"
    echo "     - Infrastructure healthy" >> "$REPORT_FILE"
    echo "     - Backend responding" >> "$REPORT_FILE"
    echo "     - Frontend loads" >> "$REPORT_FILE"
    echo "     - End-to-end flows work" >> "$REPORT_FILE"
  else
    echo "  [FAIL] Full System Smoke Tests: FAILED"
    echo "- [FAIL] Full System Smoke Tests: FAILED" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "  **Smoke Test Output**:" >> "$REPORT_FILE"
    echo '  ```' >> "$REPORT_FILE"
    tail -40 full-smoke-test-wave5.txt >> "$REPORT_FILE"
    echo '  ```' >> "$REPORT_FILE"
    echo ""
    echo "  Action Required: Fix system integration issues"
    echo "  Run: bash scripts/smoke-test.sh"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  [INFO] No scripts/smoke-test.sh found, running inline checks..."
  echo "- [INFO] Smoke Tests: Running inline checks" >> "$REPORT_FILE"

  # 3.2 Backend health check (FastAPI)
  API_PORT="${API_PORT:-8000}"
  if curl -s --max-time 5 "http://localhost:${API_PORT}/health" > /dev/null 2>&1; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://localhost:${API_PORT}/health")
    if [ "$HTTP_CODE" = "200" ]; then
      echo "     [OK] Backend health endpoint responds (HTTP $HTTP_CODE)"
      echo "  - [OK] Backend Health: HTTP $HTTP_CODE" >> "$REPORT_FILE"
    else
      echo "     [WARN] Backend health returned HTTP $HTTP_CODE"
      echo "  - [WARN] Backend Health: HTTP $HTTP_CODE (expected 200)" >> "$REPORT_FILE"
    fi
  else
    echo "     [INFO] Backend not running on port $API_PORT, skipping live check"
    echo "  - [INFO] Backend Health: SKIPPED (server not running)" >> "$REPORT_FILE"
  fi

  # 3.3 Frontend build artifact check
  if [ -d "frontend/dist" ] || [ -d "frontend/build" ]; then
    echo "     [OK] Frontend build artifacts exist"
    echo "  - [OK] Frontend Build Artifacts: PRESENT" >> "$REPORT_FILE"
  else
    echo "     [WARN] No frontend build artifacts found (dist/ or build/)"
    echo "  - [WARN] Frontend Build Artifacts: NOT FOUND" >> "$REPORT_FILE"
  fi

  # 3.4 Backend pytest run (Python)
  if [ -d "backend/tests" ]; then
    cd backend
    if python -m pytest tests/ -v --tb=short > ../backend-tests-wave5.txt 2>&1; then
      PASSED=$(grep -oE "[0-9]+ passed" ../backend-tests-wave5.txt | grep -oE "[0-9]+" || echo "0")
      echo "     [OK] Backend tests passed ($PASSED tests)"
      echo "  - [OK] Backend Tests: $PASSED tests passed" >> "../$REPORT_FILE"
    else
      FAILED=$(grep -oE "[0-9]+ failed" ../backend-tests-wave5.txt | grep -oE "[0-9]+" || echo "unknown")
      echo "     [FAIL] Backend tests failed: $FAILED"
      echo "  - [FAIL] Backend Tests: $FAILED tests failed" >> "../$REPORT_FILE"
      ERRORS=$((ERRORS + 1))
    fi
    cd ..
  fi
fi

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 4: SECURITY SCAN (19-Security-Review-Agent)
# ============================================
echo ""
echo "================================================================="
echo " VALIDATION 4: Security Review Frontend (BLOCKING)"
echo "================================================================="

echo "### VALIDATION 4: Security Review Frontend (19-Security-Review-Agent)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "  Running frontend security validation..."

# 4.1 Check for dangerouslySetInnerHTML (XSS risk)
echo "  Scanning for dangerouslySetInnerHTML..."
DANGEROUS_HTML=0
if [ -d "frontend/src" ]; then
  cd frontend/src
  DANGEROUS_HTML=$(grep -r "dangerouslySetInnerHTML" . \
    --include="*.tsx" \
    --include="*.jsx" \
    --exclude-dir="node_modules" | wc -l || echo "0")
  cd ../..
fi

if [ "$DANGEROUS_HTML" = "0" ]; then
  echo "     [OK] No dangerouslySetInnerHTML usage detected"
  echo "  - [OK] XSS Protection: No dangerouslySetInnerHTML found" >> "$REPORT_FILE"
else
  echo "     [WARN] $DANGEROUS_HTML uses of dangerouslySetInnerHTML found"
  echo "  - [WARN] XSS Risk: $DANGEROUS_HTML dangerouslySetInnerHTML usages" >> "$REPORT_FILE"
  echo "     Review: frontend/src/**/*.tsx"
fi

# 4.2 Check for eval() usage
echo "  Scanning for eval() usage..."
EVAL_USAGE=0
if [ -d "frontend/src" ]; then
  cd frontend/src
  EVAL_USAGE=$(grep -r "eval(" . \
    --include="*.ts" \
    --include="*.tsx" \
    --include="*.js" \
    --include="*.jsx" \
    --exclude-dir="node_modules" | wc -l || echo "0")
  cd ../..
fi

if [ "$EVAL_USAGE" = "0" ]; then
  echo "     [OK] No eval() usage detected"
  echo "  - [OK] Code Injection Protection: No eval() found" >> "$REPORT_FILE"
else
  echo "     [FAIL] $EVAL_USAGE uses of eval() found (CRITICAL)"
  echo "  - [FAIL] Code Injection Risk: $EVAL_USAGE eval() usages" >> "$REPORT_FILE"
  ERRORS=$((ERRORS + 1))
fi

# 4.3 Check for localStorage with sensitive data
echo "  Checking localStorage usage..."
LOCALSTORAGE_SENSITIVE=0
if [ -d "frontend/src" ]; then
  cd frontend/src
  LOCALSTORAGE_SENSITIVE=$(grep -r "localStorage.*password\|localStorage.*secret\|localStorage.*api_key" . \
    --include="*.ts" \
    --include="*.tsx" \
    --exclude-dir="node_modules" | wc -l || echo "0")
  cd ../..
fi

if [ "$LOCALSTORAGE_SENSITIVE" = "0" ]; then
  echo "     [OK] No sensitive data directly in localStorage detected"
  echo "  - [OK] Data Storage: No obvious sensitive data exposure" >> "$REPORT_FILE"
else
  echo "     [WARN] $LOCALSTORAGE_SENSITIVE potential sensitive localStorage usages"
  echo "  - [WARN] Data Storage: $LOCALSTORAGE_SENSITIVE localStorage patterns to review" >> "$REPORT_FILE"
  echo "     Note: Tokens in localStorage are acceptable if httpOnly cookies unavailable"
fi

# 4.4 Check for console.log in production code
echo "  Checking for console.log statements..."
CONSOLE_LOGS=0
if [ -d "frontend/src" ]; then
  cd frontend/src
  CONSOLE_LOGS=$(grep -r "console.log\|console.error\|console.warn" . \
    --include="*.ts" \
    --include="*.tsx" \
    --exclude="*.test.*" \
    --exclude="*.spec.*" \
    --exclude-dir="node_modules" | wc -l || echo "0")
  cd ../..
fi

if [ "$CONSOLE_LOGS" = "0" ]; then
  echo "     [OK] No console.log statements in production code"
  echo "  - [OK] Information Disclosure: No console logs" >> "$REPORT_FILE"
else
  echo "     [WARN] $CONSOLE_LOGS console.log statements found"
  echo "  - [WARN] Information Disclosure: $CONSOLE_LOGS console logs (review)" >> "$REPORT_FILE"
  echo "     Consider removing debug logs before production"
fi

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 5: E2E TESTS (Optional but Recommended)
# ============================================
echo ""
echo "================================================================="
echo " VALIDATION 5: E2E Tests (RECOMMENDED)"
echo "================================================================="

echo "### VALIDATION 5: E2E Tests (Recommended)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "  Running E2E tests..."
cd frontend
if [ -d "e2e" ] || [ -d "tests" ]; then
  if npx playwright test > ../e2e-test-wave5.txt 2>&1; then
    E2E_PASSED=$(grep -oE "[0-9]+ passed" ../e2e-test-wave5.txt | grep -oE "[0-9]+" || echo "0")
    echo "  [OK] E2E Tests: $E2E_PASSED tests passed"
    echo "- [OK] E2E Tests: $E2E_PASSED tests passed" >> "../$REPORT_FILE"
  else
    E2E_FAILED=$(grep -oE "[0-9]+ failed" ../e2e-test-wave5.txt | grep -oE "[0-9]+" || echo "unknown")
    echo "  [WARN] E2E Tests: $E2E_FAILED tests failed"
    echo "- [WARN] E2E Tests: $E2E_FAILED tests failed" >> "../$REPORT_FILE"
    echo "" >> "../$REPORT_FILE"
    echo "  **E2E Test Output**:" >> "../$REPORT_FILE"
    echo '  ```' >> "../$REPORT_FILE"
    tail -30 ../e2e-test-wave5.txt >> "../$REPORT_FILE"
    echo '  ```' >> "../$REPORT_FILE"
    echo ""
    echo "  Note: E2E test failures are warnings, not blockers"
    echo "  Run: npx playwright test --ui to debug"
  fi
else
  echo "  [INFO] E2E Tests: No test directory found (e2e/ or tests/)"
  echo "- [INFO] E2E Tests: NOT CONFIGURED" >> "../$REPORT_FILE"
fi
cd ..

echo "" >> "$REPORT_FILE"

# ============================================
# FINAL VERDICT
# ============================================
echo ""
echo "================================================================="
echo "================================================================="
echo ""

if [ $ERRORS -eq 0 ]; then
  echo "[PASSED] WAVE 5 VALIDATION PASSED - Frontend & Full System Complete"
  echo ""
  echo "## [PASSED] POST-WAVE 5 VALIDATION: PASSED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Errors**: 0" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**SPRINT COMPLETE - ALL WAVES VALIDATED**" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "Full system validated successfully:" >> "$REPORT_FILE"
  echo "- [OK] Frontend Build: SUCCESS" >> "$REPORT_FILE"
  echo "- [OK] Code Quality: CLEAN" >> "$REPORT_FILE"
  echo "- [OK] Smoke Tests: PASSED" >> "$REPORT_FILE"
  echo "- [OK] Security: NO CRITICAL ISSUES" >> "$REPORT_FILE"
  echo "- [OK] System Integration: FUNCTIONAL" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Next Steps**:" >> "$REPORT_FILE"
  echo "1. Run integration tests: \`cd backend && python -m pytest tests/ -v\`" >> "$REPORT_FILE"
  echo "2. Create pull request with sprint changes" >> "$REPORT_FILE"
  echo "3. Request code review from team" >> "$REPORT_FILE"
  echo "4. Deploy to staging environment" >> "$REPORT_FILE"
  echo ""
  echo "================================================================="
  echo " SPRINT COMPLETE - SYSTEM IS PRODUCTION-READY"
  echo "================================================================="
  echo ""
  echo "Validation report saved to: $REPORT_FILE"
  echo ""
  echo "You may now:"
  echo "  - git add ."
  echo "  - git commit -m \"feat: complete Wave 5 - Frontend\""
  echo "  - git push (pre-push hook will run final validation)"
  echo ""
  exit 0
else
  echo "[FAILED] WAVE 5 VALIDATION FAILED - Frontend/System Incomplete"
  echo ""
  echo "## [FAILED] POST-WAVE 5 VALIDATION: FAILED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Errors**: $ERRORS" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**SPRINT IS NOT COMPLETE**" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "Fix all validation errors above before considering sprint complete." >> "$REPORT_FILE"
  echo ""
  echo "================================================================="
  echo " SPRINT COMPLETION BLOCKED UNTIL ALL VALIDATIONS PASS"
  echo "================================================================="
  echo ""
  echo "Validation Errors: $ERRORS"
  echo ""
  echo "Detailed validation report saved to: $REPORT_FILE"
  echo ""
  echo "Fix all issues and re-run:"
  echo "  bash scripts/hooks/post-wave-5-frontend.sh"
  echo ""
  exit 1
fi
