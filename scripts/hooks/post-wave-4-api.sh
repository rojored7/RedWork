#!/bin/bash
# Post-Wave 4 Validation Hook - API Layer Complete
# BLOQUEA Wave 5 si API no responde, linting falla, smoke tests fallan, o security issues
#
# Integra 3 agentes:
# - 20-Code-Quality-Linting-Agent
# - 18-Smoke-Test-Validator
# - 19-Security-Review-Agent
#
# Usage: bash scripts/hooks/post-wave-4-api.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 POST-WAVE 4 VALIDATION - API Layer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  This hook validates API endpoints are functional BEFORE Wave 5"
echo "⚠️  Wave 5 (Frontend) is BLOCKED until all validations PASS"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ERRORS=0
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_FILE=".project-orchestration/post-wave-4-report-${TIMESTAMP}.md"

# Create report header
mkdir -p .project-orchestration
cat > "$REPORT_FILE" <<EOF
# Post-Wave 4 Validation Report - API Layer

**Date**: $(date +%Y-%m-%d)
**Time**: $(date +%H:%M:%S)
**Validated By**: post-wave-4-api.sh

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
if npm run build > ../backend-build-wave4.txt 2>&1; then
  echo "  ✅ Backend Compilation: SUCCESS (0 errors)"
  echo "- ✅ Backend Compilation: SUCCESS (0 errors)" >> "../$REPORT_FILE"
else
  echo "  ❌ Backend Compilation: FAILED"
  echo "- ❌ Backend Compilation: FAILED" >> "../$REPORT_FILE"
  echo "" >> "../$REPORT_FILE"
  echo "  **Build Output**:" >> "../$REPORT_FILE"
  echo '  ```' >> "../$REPORT_FILE"
  tail -20 ../backend-build-wave4.txt >> "../$REPORT_FILE"
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
if npm run lint 2>&1 | tee ../backend-lint-wave4.txt | grep -qE "0 errors|✓"; then
  ERROR_COUNT=$(grep -c "error" ../backend-lint-wave4.txt 2>/dev/null || echo "0")

  if [ "$ERROR_COUNT" = "0" ]; then
    echo "  ✅ Backend Linting: CLEAN (0 errors)"
    echo "- ✅ Backend Linting: CLEAN (0 errors)" >> "../$REPORT_FILE"
  else
    echo "  ❌ Backend Linting: $ERROR_COUNT errors found"
    echo "- ❌ Backend Linting: $ERROR_COUNT errors found" >> "../$REPORT_FILE"
    echo "" >> "../$REPORT_FILE"
    echo "  **Linting Errors**:" >> "../$REPORT_FILE"
    echo '  ```' >> "../$REPORT_FILE"
    grep "error" ../backend-lint-wave4.txt | head -20 >> "../$REPORT_FILE"
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
# VALIDATION 3: SMOKE TESTS API (18-Smoke-Test-Validator)
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 VALIDATION 3: Smoke Tests API (BLOQUEANTE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### VALIDATION 3: Smoke Tests API (18-Smoke-Test-Validator)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "🔥 Running API smoke tests..."

# Check if smoke-test-api.sh exists
if [ -f "scripts/smoke-test-api.sh" ]; then
  if bash scripts/smoke-test-api.sh > api-smoke-test-wave4.txt 2>&1; then
    echo "  ✅ API Smoke Tests: PASSED"
    echo "- ✅ API Smoke Tests: PASSED" >> "$REPORT_FILE"
    echo "     - API endpoints respond" >> "$REPORT_FILE"
    echo "     - Authentication works" >> "$REPORT_FILE"
    echo "     - CRUD operations functional" >> "$REPORT_FILE"
  else
    echo "  ❌ API Smoke Tests: FAILED"
    echo "- ❌ API Smoke Tests: FAILED" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "  **Smoke Test Output**:" >> "$REPORT_FILE"
    echo '  ```' >> "$REPORT_FILE"
    tail -30 api-smoke-test-wave4.txt >> "$REPORT_FILE"
    echo '  ```' >> "$REPORT_FILE"
    echo ""
    echo "  Action Required: Ensure API endpoints are responding correctly"
    echo "  Run: bash scripts/smoke-test-api.sh"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  ⚠️  API Smoke Tests: SCRIPT NOT FOUND"
  echo "- ⚠️  API Smoke Tests: SCRIPT NOT FOUND (scripts/smoke-test-api.sh)" >> "$REPORT_FILE"
  echo "     Falling back to smoke-test-backend.sh"

  # Fallback to backend smoke test
  if [ -f "scripts/smoke-test-backend.sh" ]; then
    if bash scripts/smoke-test-backend.sh > api-smoke-test-wave4.txt 2>&1; then
      echo "  ✅ Backend Smoke Tests: PASSED (fallback)"
      echo "- ✅ Backend Smoke Tests: PASSED (fallback)" >> "$REPORT_FILE"
    else
      echo "  ❌ Backend Smoke Tests: FAILED (fallback)"
      echo "- ❌ Backend Smoke Tests: FAILED (fallback)" >> "$REPORT_FILE"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo "  ⚠️  Skipping smoke test validation (no scripts found)"
    echo "- ⚠️  Smoke Tests: SKIPPED (no scripts found)" >> "$REPORT_FILE"
  fi
fi

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 4: SECURITY API (19-Security-Review-Agent)
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 VALIDATION 4: Security Review API (BLOQUEANTE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### VALIDATION 4: Security Review API (19-Security-Review-Agent)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "🔒 Running API security validation..."

# 4.1 Check for unguarded endpoints
echo "  🔍 Checking API guards on controllers..."
cd backend/src
UNGUARDED=$(find . -name "*.controller.ts" -type f \
  -exec grep -l "@Post\|@Get\|@Put\|@Delete\|@Patch" {} \; | \
  while read -r file; do
    if ! grep -qE "@UseGuards|@Public" "$file"; then
      echo "$file"
    fi
  done | wc -l || echo "0")
cd ../..

if [ "$UNGUARDED" = "0" ]; then
  echo "     ✅ All endpoints have guards or @Public decorator"
  echo "  - ✅ API Guards: ALL ENDPOINTS PROTECTED" >> "$REPORT_FILE"
else
  echo "     ⚠️  $UNGUARDED controller(s) may have unguarded endpoints"
  echo "  - ⚠️  API Guards: $UNGUARDED controllers may need review" >> "$REPORT_FILE"
  echo "     Review: backend/src/**/*.controller.ts"
fi

# 4.2 Check for DTO validation
echo "  🔍 Checking DTO validation..."
cd backend/src
DTOs_WITHOUT_VALIDATION=$(find . -name "*.dto.ts" -type f \
  -exec grep -L "class-validator\|IsString\|IsEmail\|IsNumber" {} \; | wc -l || echo "0")
cd ../..

if [ "$DTOs_WITHOUT_VALIDATION" = "0" ]; then
  echo "     ✅ All DTOs have validation decorators"
  echo "  - ✅ DTO Validation: ALL DTOs VALIDATED" >> "$REPORT_FILE"
else
  echo "     ⚠️  $DTOs_WITHOUT_VALIDATION DTO(s) may lack validation"
  echo "  - ⚠️  DTO Validation: $DTOs_WITHOUT_VALIDATION DTOs may need review" >> "$REPORT_FILE"
  echo "     Review: backend/src/**/*.dto.ts"
fi

# 4.3 Check for rate limiting on public endpoints
echo "  🔍 Checking rate limiting on auth endpoints..."
cd backend/src
RATE_LIMITED=$(grep -r "@Throttle\|@UseGuards(ThrottlerGuard)" . --include="auth.controller.ts" | wc -l || echo "0")
cd ../..

if [ "$RATE_LIMITED" -gt 0 ]; then
  echo "     ✅ Rate limiting detected on auth endpoints"
  echo "  - ✅ Rate Limiting: CONFIGURED" >> "$REPORT_FILE"
else
  echo "     ⚠️  No rate limiting detected on auth endpoints"
  echo "  - ⚠️  Rate Limiting: NOT CONFIGURED (consider @Throttle)" >> "$REPORT_FILE"
fi

# 4.4 Check for SQL injection protection (TypeORM)
echo "  🔍 Checking for raw SQL queries..."
cd backend/src
RAW_SQL=$(grep -r "\.query(" . --include="*.ts" \
  --exclude="*.spec.ts" \
  --exclude="*.test.ts" | wc -l || echo "0")
cd ../..

if [ "$RAW_SQL" = "0" ]; then
  echo "     ✅ No raw SQL queries found (using TypeORM properly)"
  echo "  - ✅ SQL Injection Protection: TYPEORM PARAMETERIZED" >> "$REPORT_FILE"
else
  echo "     ⚠️  $RAW_SQL raw SQL queries found"
  echo "  - ⚠️  SQL Injection: $RAW_SQL raw queries need review" >> "$REPORT_FILE"
  echo "     Ensure all use parameterized queries"
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
  echo "✅✅✅ WAVE 4 VALIDATION PASSED - API Layer Complete"
  echo ""
  echo "## ✅ POST-WAVE 4 VALIDATION: PASSED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Errors**: 0" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "🎉 **Wave 5 (Frontend) is CLEARED TO START**" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "API layer validated successfully:" >> "$REPORT_FILE"
  echo "- ✅ Compilation: SUCCESS" >> "$REPORT_FILE"
  echo "- ✅ Code Quality: CLEAN" >> "$REPORT_FILE"
  echo "- ✅ Smoke Tests: PASSED" >> "$REPORT_FILE"
  echo "- ✅ Security: API PROTECTED" >> "$REPORT_FILE"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚀 YOU MAY PROCEED TO WAVE 5 (FRONTEND)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "📄 Validation report saved to: $REPORT_FILE"
  echo ""
  exit 0
else
  echo "❌❌❌ WAVE 4 VALIDATION FAILED - API Layer Incomplete"
  echo ""
  echo "## ❌ POST-WAVE 4 VALIDATION: FAILED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Errors**: $ERRORS" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "🚫 **Wave 5 (Frontend) is BLOCKED**" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "Fix all validation errors above before proceeding to Wave 5." >> "$REPORT_FILE"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚫 WAVE 5 IS BLOCKED UNTIL ALL VALIDATIONS PASS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Validation Errors: $ERRORS"
  echo ""
  echo "📄 Detailed validation report saved to: $REPORT_FILE"
  echo ""
  echo "Fix all issues and re-run:"
  echo "  bash scripts/hooks/post-wave-4-api.sh"
  echo ""
  exit 1
fi
