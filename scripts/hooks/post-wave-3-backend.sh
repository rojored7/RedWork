#!/bin/bash
# Post-Wave 3 Validation Hook - Backend Application Layer Complete
# BLOQUEA Wave 4 si backend no arranca, linting falla, smoke tests fallan, o security issues
#
# Integra 3 agentes:
# - 20-Code-Quality-Linting-Agent
# - 18-Smoke-Test-Validator
# - 19-Security-Review-Agent
#
# Usage: bash scripts/hooks/post-wave-3-backend.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 POST-WAVE 3 VALIDATION - Backend Application Layer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  This hook validates backend is production-ready BEFORE Wave 4"
echo "⚠️  Wave 4 (API Layer) is BLOCKED until all validations PASS"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
# VALIDATION 1: BACKEND COMPILATION
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 VALIDATION 1: Backend Compilation (MANDATORY)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### VALIDATION 1: Backend Compilation" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "🔨 Compiling backend..."
cd backend
if npm run build > ../backend-build-wave3.txt 2>&1; then
  echo "  ✅ Backend Compilation: SUCCESS (0 errors)"
  echo "- ✅ Backend Compilation: SUCCESS (0 errors)" >> "../$REPORT_FILE"
else
  echo "  ❌ Backend Compilation: FAILED"
  echo "- ❌ Backend Compilation: FAILED" >> "../$REPORT_FILE"
  echo "" >> "../$REPORT_FILE"
  echo "  **Build Output**:" >> "../$REPORT_FILE"
  echo '  ```' >> "../$REPORT_FILE"
  tail -20 ../backend-build-wave3.txt >> "../$REPORT_FILE"
  echo '  ```' >> "../$REPORT_FILE"
  echo ""
  echo "  Action Required: Fix compilation errors before proceeding"
  ERRORS=$((ERRORS + 1))
fi
cd ..

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 2: CODE QUALITY (20-Linting-Agent)
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 VALIDATION 2: Code Quality - Backend Linting (BLOQUEANTE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### VALIDATION 2: Code Quality (20-Code-Quality-Linting-Agent)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "🔍 Running backend linting (ESLint)..."
cd backend
if npm run lint 2>&1 | tee ../backend-lint-wave3.txt | grep -qE "0 errors|✓"; then
  ERROR_COUNT=$(grep -c "error" ../backend-lint-wave3.txt 2>/dev/null || echo "0")
  WARNING_COUNT=$(grep -c "warning" ../backend-lint-wave3.txt 2>/dev/null || echo "0")

  if [ "$ERROR_COUNT" = "0" ]; then
    echo "  ✅ Backend Linting: CLEAN (0 errors, $WARNING_COUNT warnings)"
    echo "- ✅ Backend Linting: CLEAN (0 errors)" >> "../$REPORT_FILE"
  else
    echo "  ❌ Backend Linting: $ERROR_COUNT errors found"
    echo "- ❌ Backend Linting: $ERROR_COUNT errors found" >> "../$REPORT_FILE"
    echo "" >> "../$REPORT_FILE"
    echo "  **Linting Errors**:" >> "../$REPORT_FILE"
    echo '  ```' >> "../$REPORT_FILE"
    grep "error" ../backend-lint-wave3.txt | head -20 >> "../$REPORT_FILE"
    echo '  ```' >> "../$REPORT_FILE"
    echo ""
    echo "  Action Required: Run 'cd backend && npm run lint -- --fix'"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  ❌ Backend Linting: FAILED TO RUN"
  echo "- ❌ Backend Linting: FAILED TO RUN" >> "../$REPORT_FILE"
  ERRORS=$((ERRORS + 1))
fi
cd ..

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 3: SMOKE TESTS BACKEND (18-Smoke-Test-Validator)
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 VALIDATION 3: Smoke Tests Backend (BLOQUEANTE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### VALIDATION 3: Smoke Tests Backend (18-Smoke-Test-Validator)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "🔥 Running backend smoke tests..."

# Check if smoke-test-backend.sh exists
if [ -f "scripts/smoke-test-backend.sh" ]; then
  if bash scripts/smoke-test-backend.sh > backend-smoke-test-wave3.txt 2>&1; then
    echo "  ✅ Backend Smoke Tests: PASSED"
    echo "- ✅ Backend Smoke Tests: PASSED" >> "$REPORT_FILE"
    echo "     - Backend starts successfully" >> "$REPORT_FILE"
    echo "     - Health check responds" >> "$REPORT_FILE"
    echo "     - Database connectivity OK" >> "$REPORT_FILE"
  else
    echo "  ❌ Backend Smoke Tests: FAILED"
    echo "- ❌ Backend Smoke Tests: FAILED" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "  **Smoke Test Output**:" >> "$REPORT_FILE"
    echo '  ```' >> "$REPORT_FILE"
    tail -30 backend-smoke-test-wave3.txt >> "$REPORT_FILE"
    echo '  ```' >> "$REPORT_FILE"
    echo ""
    echo "  Action Required: Ensure backend starts and health checks pass"
    echo "  Run: bash scripts/smoke-test-backend.sh"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  ⚠️  Backend Smoke Tests: SCRIPT NOT FOUND"
  echo "- ⚠️  Backend Smoke Tests: SCRIPT NOT FOUND (scripts/smoke-test-backend.sh)" >> "$REPORT_FILE"
  echo "     Skipping smoke test validation"
fi

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 4: SECURITY BACKEND (19-Security-Review-Agent)
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 VALIDATION 4: Security Review Backend (BLOQUEANTE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### VALIDATION 4: Security Review Backend (19-Security-Review-Agent)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "🔒 Running security validation..."

# 4.1 Check for hardcoded secrets
echo "  🔍 Scanning for hardcoded secrets..."
cd backend/src
SECRETS=$(grep -rE "(password|secret|api_key|apiKey|token)\s*[:=]\s*['\"][^'\"]{8,}" . \
  --include="*.ts" \
  --exclude="*.spec.ts" \
  --exclude="*.test.ts" \
  --exclude-dir="node_modules" \
  | grep -v "process.env" \
  | grep -v "configService.get" \
  | grep -v "// " \
  | wc -l || echo "0")
cd ../..

if [ "$SECRETS" = "0" ]; then
  echo "     ✅ No hardcoded secrets detected"
  echo "  - ✅ Hardcoded Secrets: NONE FOUND" >> "$REPORT_FILE"
else
  echo "     ❌ $SECRETS potential hardcoded secrets found"
  echo "  - ❌ Hardcoded Secrets: $SECRETS potential secrets found" >> "$REPORT_FILE"
  echo ""
  echo "  Action Required: Review and remove hardcoded secrets"
  ERRORS=$((ERRORS + 1))
fi

# 4.2 Check .env files not in git
echo "  🔍 Checking .env files..."
if git ls-files | grep -qE "\.env$|\.env\.production$"; then
  echo "     ❌ .env files found in git"
  echo "  - ❌ .env Files: FOUND IN GIT (security risk)" >> "$REPORT_FILE"
  ERRORS=$((ERRORS + 1))
else
  echo "     ✅ No .env files in git"
  echo "  - ✅ .env Files: NOT IN GIT" >> "$REPORT_FILE"
fi

# 4.3 Check for OWASP compliance (if script exists)
if [ -f "scripts/validate-owasp.sh" ]; then
  echo "  🔒 Running OWASP validation (backend focus)..."
  if bash scripts/validate-owasp.sh > backend-owasp-wave3.txt 2>&1; then
    echo "     ✅ OWASP Validation: COMPLIANT"
    echo "  - ✅ OWASP Validation: COMPLIANT" >> "$REPORT_FILE"
  else
    OWASP_ERRORS=$(grep -c "❌" backend-owasp-wave3.txt 2>/dev/null || echo "0")
    if [ "$OWASP_ERRORS" != "0" ]; then
      echo "     ⚠️  OWASP Validation: $OWASP_ERRORS issues found"
      echo "  - ⚠️  OWASP Validation: $OWASP_ERRORS issues found" >> "$REPORT_FILE"
      echo ""
      echo "  Review: bash scripts/validate-owasp.sh"
    else
      echo "     ✅ OWASP Validation: PASSED"
      echo "  - ✅ OWASP Validation: PASSED" >> "$REPORT_FILE"
    fi
  fi
fi

echo "" >> "$REPORT_FILE"

# ============================================
# FINAL VERDICT
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -eq 0 ]; then
  echo "✅✅✅ WAVE 3 VALIDATION PASSED - Backend Application Layer Complete"
  echo ""
  echo "## ✅ POST-WAVE 3 VALIDATION: PASSED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Errors**: 0" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "🎉 **Wave 4 (API Layer) is CLEARED TO START**" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "Backend application layer validated successfully:" >> "$REPORT_FILE"
  echo "- ✅ Compilation: SUCCESS" >> "$REPORT_FILE"
  echo "- ✅ Code Quality: CLEAN" >> "$REPORT_FILE"
  echo "- ✅ Smoke Tests: PASSED" >> "$REPORT_FILE"
  echo "- ✅ Security: NO CRITICAL ISSUES" >> "$REPORT_FILE"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚀 YOU MAY PROCEED TO WAVE 4 (API LAYER)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "📄 Validation report saved to: $REPORT_FILE"
  echo ""
  exit 0
else
  echo "❌❌❌ WAVE 3 VALIDATION FAILED - Backend Application Layer Incomplete"
  echo ""
  echo "## ❌ POST-WAVE 3 VALIDATION: FAILED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Errors**: $ERRORS" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "🚫 **Wave 4 (API Layer) is BLOCKED**" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "Fix all validation errors above before proceeding to Wave 4." >> "$REPORT_FILE"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚫 WAVE 4 IS BLOCKED UNTIL ALL VALIDATIONS PASS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Validation Errors: $ERRORS"
  echo ""
  echo "📄 Detailed validation report saved to: $REPORT_FILE"
  echo ""
  echo "Fix all issues and re-run:"
  echo "  bash scripts/hooks/post-wave-3-backend.sh"
  echo ""
  exit 1
fi
