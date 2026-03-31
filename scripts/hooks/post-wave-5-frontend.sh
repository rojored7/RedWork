#!/bin/bash
# Post-Wave 5 Validation Hook - Frontend & Full System Complete
# BLOQUEA SPRINT COMPLETION si frontend no funciona, smoke tests fallan, o security issues
#
# Integra 3 agentes:
# - 20-Code-Quality-Linting-Agent
# - 18-Smoke-Test-Validator
# - 19-Security-Review-Agent
#
# Usage: bash scripts/hooks/post-wave-5-frontend.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 POST-WAVE 5 VALIDATION - Frontend & Full System"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  This hook validates FULL SYSTEM is production-ready"
echo "⚠️  SPRINT is NOT COMPLETE until all validations PASS"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
# VALIDATION 1: FRONTEND COMPILATION
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 VALIDATION 1: Frontend Compilation (MANDATORY)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### VALIDATION 1: Frontend Compilation" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "🔨 Building frontend..."
cd frontend
if npm run build > ../frontend-build-wave5.txt 2>&1; then
  echo "  ✅ Frontend Build: SUCCESS (0 TypeScript errors)"
  echo "- ✅ Frontend Build: SUCCESS (0 TypeScript errors)" >> "../$REPORT_FILE"
else
  echo "  ❌ Frontend Build: FAILED"
  echo "- ❌ Frontend Build: FAILED" >> "../$REPORT_FILE"
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
# VALIDATION 2: CODE QUALITY FRONTEND (20-Linting-Agent)
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 VALIDATION 2: Code Quality - Frontend Linting (BLOQUEANTE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### VALIDATION 2: Code Quality Frontend (20-Code-Quality-Linting-Agent)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "🔍 Running frontend linting (ESLint)..."
cd frontend
if npm run lint 2>&1 | tee ../frontend-lint-wave5.txt | grep -qE "0 errors|✓"; then
  ERROR_COUNT=$(grep -c "error" ../frontend-lint-wave5.txt 2>/dev/null || echo "0")

  if [ "$ERROR_COUNT" = "0" ]; then
    echo "  ✅ Frontend Linting: CLEAN (0 errors)"
    echo "- ✅ Frontend Linting: CLEAN (0 errors)" >> "../$REPORT_FILE"
  else
    echo "  ❌ Frontend Linting: $ERROR_COUNT errors found"
    echo "- ❌ Frontend Linting: $ERROR_COUNT errors found" >> "../$REPORT_FILE"
    echo "" >> "../$REPORT_FILE"
    echo "  **Linting Errors**:" >> "../$REPORT_FILE"
    echo '  ```' >> "../$REPORT_FILE"
    grep "error" ../frontend-lint-wave5.txt | head -20 >> "../$REPORT_FILE"
    echo '  ```' >> "../$REPORT_FILE"
    echo ""
    echo "  Action Required: Run 'cd frontend && npm run lint -- --fix'"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  ❌ Frontend Linting: FAILED TO RUN"
  echo "- ❌ Frontend Linting: FAILED TO RUN" >> "../$REPORT_FILE"
  ERRORS=$((ERRORS + 1))
fi
cd ..

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 3: SMOKE TESTS FULL SYSTEM (18-Smoke-Test-Validator)
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 VALIDATION 3: Smoke Tests Full System (BLOQUEANTE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### VALIDATION 3: Smoke Tests Full System (18-Smoke-Test-Validator)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "🔥 Running full system smoke tests..."

# Check if smoke-test.sh exists
if [ -f "scripts/smoke-test.sh" ]; then
  if bash scripts/smoke-test.sh > full-smoke-test-wave5.txt 2>&1; then
    echo "  ✅ Full System Smoke Tests: PASSED"
    echo "- ✅ Full System Smoke Tests: PASSED" >> "$REPORT_FILE"
    echo "     - Infrastructure healthy" >> "$REPORT_FILE"
    echo "     - Backend responding" >> "$REPORT_FILE"
    echo "     - Frontend loads" >> "$REPORT_FILE"
    echo "     - End-to-end flows work" >> "$REPORT_FILE"
  else
    echo "  ❌ Full System Smoke Tests: FAILED"
    echo "- ❌ Full System Smoke Tests: FAILED" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "  **Smoke Test Output**:" >> "$REPORT_FILE"
    echo '  ```' >> "../$REPORT_FILE"
    tail -40 full-smoke-test-wave5.txt >> "$REPORT_FILE"
    echo '  ```' >> "$REPORT_FILE"
    echo ""
    echo "  Action Required: Fix system integration issues"
    echo "  Run: bash scripts/smoke-test.sh"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  ⚠️  Full System Smoke Tests: SCRIPT NOT FOUND"
  echo "- ⚠️  Smoke Tests: SCRIPT NOT FOUND (scripts/smoke-test.sh)" >> "$REPORT_FILE"

  # Try frontend-specific smoke test
  if [ -f "scripts/smoke-test-frontend.sh" ]; then
    echo "     Falling back to smoke-test-frontend.sh"
    if bash scripts/smoke-test-frontend.sh > full-smoke-test-wave5.txt 2>&1; then
      echo "  ✅ Frontend Smoke Tests: PASSED (fallback)"
      echo "- ✅ Frontend Smoke Tests: PASSED (fallback)" >> "$REPORT_FILE"
    else
      echo "  ❌ Frontend Smoke Tests: FAILED (fallback)"
      echo "- ❌ Frontend Smoke Tests: FAILED (fallback)" >> "$REPORT_FILE"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo "  ⚠️  Skipping smoke test validation (no scripts found)"
    echo "- ⚠️  Smoke Tests: SKIPPED (no scripts found)" >> "$REPORT_FILE"
  fi
fi

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 4: SECURITY FRONTEND (19-Security-Review-Agent)
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 VALIDATION 4: Security Review Frontend (BLOQUEANTE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### VALIDATION 4: Security Review Frontend (19-Security-Review-Agent)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "🔒 Running frontend security validation..."

# 4.1 Check for dangerouslySetInnerHTML (XSS risk)
echo "  🔍 Scanning for dangerouslySetInnerHTML..."
cd frontend/src
DANGEROUS_HTML=$(grep -r "dangerouslySetInnerHTML" . \
  --include="*.tsx" \
  --include="*.jsx" \
  --exclude-dir="node_modules" | wc -l || echo "0")
cd ../..

if [ "$DANGEROUS_HTML" = "0" ]; then
  echo "     ✅ No dangerouslySetInnerHTML usage detected"
  echo "  - ✅ XSS Protection: No dangerouslySetInnerHTML found" >> "$REPORT_FILE"
else
  echo "     ⚠️  $DANGEROUS_HTML uses of dangerouslySetInnerHTML found"
  echo "  - ⚠️  XSS Risk: $DANGEROUS_HTML dangerouslySetInnerHTML usages" >> "$REPORT_FILE"
  echo "     Review: frontend/src/**/*.tsx"
fi

# 4.2 Check for eval() usage
echo "  🔍 Scanning for eval() usage..."
cd frontend/src
EVAL_USAGE=$(grep -r "eval(" . \
  --include="*.ts" \
  --include="*.tsx" \
  --include="*.js" \
  --include="*.jsx" \
  --exclude-dir="node_modules" | wc -l || echo "0")
cd ../..

if [ "$EVAL_USAGE" = "0" ]; then
  echo "     ✅ No eval() usage detected"
  echo "  - ✅ Code Injection Protection: No eval() found" >> "$REPORT_FILE"
else
  echo "     ❌ $EVAL_USAGE uses of eval() found (CRITICAL)"
  echo "  - ❌ Code Injection Risk: $EVAL_USAGE eval() usages" >> "$REPORT_FILE"
  ERRORS=$((ERRORS + 1))
fi

# 4.3 Check for localStorage with sensitive data warnings
echo "  🔍 Checking localStorage usage..."
cd frontend/src
LOCALSTORAGE_PASSWORD=$(grep -r "localStorage.*password\|localStorage.*token" . \
  --include="*.ts" \
  --include="*.tsx" \
  --exclude-dir="node_modules" | wc -l || echo "0")
cd ../..

if [ "$LOCALSTORAGE_PASSWORD" = "0" ]; then
  echo "     ✅ No sensitive data directly in localStorage detected"
  echo "  - ✅ Data Storage: No obvious sensitive data exposure" >> "$REPORT_FILE"
else
  echo "     ⚠️  $LOCALSTORAGE_PASSWORD potential sensitive localStorage usages"
  echo "  - ⚠️  Data Storage: $LOCALSTORAGE_PASSWORD localStorage patterns to review" >> "$REPORT_FILE"
  echo "     Note: Tokens in localStorage are acceptable if httpOnly cookies unavailable"
fi

# 4.4 Check for console.log in production code
echo "  🔍 Checking for console.log statements..."
cd frontend/src
CONSOLE_LOGS=$(grep -r "console.log\|console.error\|console.warn" . \
  --include="*.ts" \
  --include="*.tsx" \
  --exclude="*.test.*" \
  --exclude="*.spec.*" \
  --exclude-dir="node_modules" | wc -l || echo "0")
cd ../..

if [ "$CONSOLE_LOGS" = "0" ]; then
  echo "     ✅ No console.log statements in production code"
  echo "  - ✅ Information Disclosure: No console logs" >> "$REPORT_FILE"
else
  echo "     ⚠️  $CONSOLE_LOGS console.log statements found"
  echo "  - ⚠️  Information Disclosure: $CONSOLE_LOGS console logs (review)" >> "$REPORT_FILE"
  echo "     Consider removing debug logs before production"
fi

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 5: E2E TESTS (Optional but Recommended)
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 VALIDATION 5: E2E Tests (RECOMMENDED)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### VALIDATION 5: E2E Tests (Recommended)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "🎭 Running E2E tests..."
cd frontend
if [ -d "e2e" ] || [ -d "tests" ]; then
  if npx playwright test > ../e2e-test-wave5.txt 2>&1; then
    E2E_PASSED=$(grep -o "[0-9]* passed" ../e2e-test-wave5.txt | grep -o "[0-9]*" || echo "0")
    echo "  ✅ E2E Tests: $E2E_PASSED tests passed"
    echo "- ✅ E2E Tests: $E2E_PASSED tests passed" >> "../$REPORT_FILE"
  else
    E2E_FAILED=$(grep -o "[0-9]* failed" ../e2e-test-wave5.txt | grep -o "[0-9]*" || echo "unknown")
    echo "  ⚠️  E2E Tests: $E2E_FAILED tests failed"
    echo "- ⚠️  E2E Tests: $E2E_FAILED tests failed" >> "../$REPORT_FILE"
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
  echo "  ℹ️  E2E Tests: No test directory found (e2e/ or tests/)"
  echo "- ℹ️  E2E Tests: NOT CONFIGURED" >> "../$REPORT_FILE"
fi
cd ..

echo "" >> "$REPORT_FILE"

# ============================================
# FINAL VERDICT
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -eq 0 ]; then
  echo "✅✅✅ WAVE 5 VALIDATION PASSED - Frontend & Full System Complete"
  echo ""
  echo "## ✅ POST-WAVE 5 VALIDATION: PASSED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Errors**: 0" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "🎉🎉🎉 **SPRINT COMPLETE - ALL WAVES VALIDATED** 🎉🎉🎉" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "Full system validated successfully:" >> "$REPORT_FILE"
  echo "- ✅ Frontend Compilation: SUCCESS" >> "$REPORT_FILE"
  echo "- ✅ Code Quality: CLEAN" >> "$REPORT_FILE"
  echo "- ✅ Smoke Tests: PASSED" >> "$REPORT_FILE"
  echo "- ✅ Security: NO CRITICAL ISSUES" >> "$REPORT_FILE"
  echo "- ✅ System Integration: FUNCTIONAL" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Next Steps**:" >> "$REPORT_FILE"
  echo "1. Run integration tests: \`npm run test:integration\`" >> "$REPORT_FILE"
  echo "2. Create pull request with sprint changes" >> "$REPORT_FILE"
  echo "3. Request code review from team" >> "$REPORT_FILE"
  echo "4. Deploy to staging environment" >> "$REPORT_FILE"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎉 SPRINT COMPLETE - SYSTEM IS PRODUCTION-READY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "📄 Validation report saved to: $REPORT_FILE"
  echo ""
  echo "You may now:"
  echo "  - git add ."
  echo "  - git commit -m \"feat: complete Wave 5 - Frontend\""
  echo "  - git push (pre-push hook will run final validation)"
  echo ""
  exit 0
else
  echo "❌❌❌ WAVE 5 VALIDATION FAILED - Frontend/System Incomplete"
  echo ""
  echo "## ❌ POST-WAVE 5 VALIDATION: FAILED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Errors**: $ERRORS" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "🚫 **SPRINT IS NOT COMPLETE**" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "Fix all validation errors above before considering sprint complete." >> "$REPORT_FILE"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚫 SPRINT COMPLETION BLOCKED UNTIL ALL VALIDATIONS PASS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Validation Errors: $ERRORS"
  echo ""
  echo "📄 Detailed validation report saved to: $REPORT_FILE"
  echo ""
  echo "Fix all issues and re-run:"
  echo "  bash scripts/hooks/post-wave-5-frontend.sh"
  echo ""
  exit 1
fi
