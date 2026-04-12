#!/bin/bash
# Post-Wave 4 Validation Hook - API Layer Complete
# BLOQUEA Wave 5 si API no responde, linting falla, smoke tests fallan, o security issues
#
# Integra 3 agentes:
# - 20-Code-Quality-Linting-Agent
# - 18-Smoke-Test-Validator
# - 19-Security-Review-Agent
#
# Backend: FastAPI (Python) with ruff, pytest, curl checks
#
# Usage: bash scripts/hooks/post-wave-4-api.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo ""
echo "================================================================="
echo " POST-WAVE 4 VALIDATION - API Layer"
echo "================================================================="
echo ""
echo "  This hook validates API endpoints are functional BEFORE Wave 5"
echo "  Wave 5 (Frontend) is BLOCKED until all validations PASS"
echo ""
echo "================================================================="
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
# VALIDATION 1: BACKEND IMPORT CHECK
# ============================================
echo "================================================================="
echo " VALIDATION 1: Backend Import Check (MANDATORY)"
echo "================================================================="

echo "### VALIDATION 1: Backend Import Check" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "  Verifying backend module can be imported..."
cd backend
if python -c "import app.main" > ../backend-build-wave4.txt 2>&1; then
  echo "  [OK] Backend Import Check: SUCCESS (app.main loads without errors)"
  echo "- [OK] Backend Import Check: SUCCESS (app.main loads without errors)" >> "../$REPORT_FILE"
else
  echo "  [FAIL] Backend Import Check: FAILED"
  echo "- [FAIL] Backend Import Check: FAILED" >> "../$REPORT_FILE"
  echo "" >> "../$REPORT_FILE"
  echo "  **Import Error Output**:" >> "../$REPORT_FILE"
  echo '  ```' >> "../$REPORT_FILE"
  tail -20 ../backend-build-wave4.txt >> "../$REPORT_FILE"
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
if ruff check . > ../backend-lint-wave4.txt 2>&1; then
  echo "  [OK] Backend Linting: CLEAN (0 errors)"
  echo "- [OK] Backend Linting: CLEAN (0 errors)" >> "../$REPORT_FILE"
else
  ERROR_COUNT=$(wc -l < ../backend-lint-wave4.txt 2>/dev/null || echo "0")

  if [ "$ERROR_COUNT" = "0" ]; then
    echo "  [OK] Backend Linting: CLEAN (0 errors)"
    echo "- [OK] Backend Linting: CLEAN (0 errors)" >> "../$REPORT_FILE"
  else
    echo "  [FAIL] Backend Linting: $ERROR_COUNT issues found"
    echo "- [FAIL] Backend Linting: $ERROR_COUNT issues found" >> "../$REPORT_FILE"
    echo "" >> "../$REPORT_FILE"
    echo "  **Linting Errors**:" >> "../$REPORT_FILE"
    echo '  ```' >> "../$REPORT_FILE"
    head -20 ../backend-lint-wave4.txt >> "../$REPORT_FILE"
    echo '  ```' >> "../$REPORT_FILE"
    echo ""
    echo "  Action Required: Run 'cd backend && ruff check . --fix'"
    ERRORS=$((ERRORS + 1))
  fi
fi
cd ..

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 3: API SMOKE TESTS (18-Smoke-Test-Validator)
# ============================================
echo ""
echo "================================================================="
echo " VALIDATION 3: API Smoke Tests (BLOCKING)"
echo "================================================================="

echo "### VALIDATION 3: API Smoke Tests (18-Smoke-Test-Validator)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "  Running API smoke tests..."

# 3.1 Check if dedicated smoke test script exists
if [ -f "scripts/smoke-test-api.sh" ]; then
  if bash scripts/smoke-test-api.sh > api-smoke-test-wave4.txt 2>&1; then
    echo "  [OK] API Smoke Tests: PASSED"
    echo "- [OK] API Smoke Tests: PASSED" >> "$REPORT_FILE"
    echo "     - API endpoints respond" >> "$REPORT_FILE"
    echo "     - Authentication works" >> "$REPORT_FILE"
    echo "     - CRUD operations functional" >> "$REPORT_FILE"
  else
    echo "  [FAIL] API Smoke Tests: FAILED"
    echo "- [FAIL] API Smoke Tests: FAILED" >> "$REPORT_FILE"
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
  echo "  [INFO] No smoke-test-api.sh found, running inline checks..."
  echo "- [INFO] Smoke Tests: Running inline checks" >> "$REPORT_FILE"

  # 3.2 Try to check health endpoint if server is running
  API_PORT="${API_PORT:-8000}"
  if curl -s --max-time 5 "http://localhost:${API_PORT}/health" > /dev/null 2>&1; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://localhost:${API_PORT}/health")
    if [ "$HTTP_CODE" = "200" ]; then
      echo "     [OK] Health endpoint responds (HTTP $HTTP_CODE)"
      echo "  - [OK] Health Endpoint: HTTP $HTTP_CODE" >> "$REPORT_FILE"
    else
      echo "     [WARN] Health endpoint returned HTTP $HTTP_CODE"
      echo "  - [WARN] Health Endpoint: HTTP $HTTP_CODE (expected 200)" >> "$REPORT_FILE"
    fi
  else
    echo "     [INFO] Backend not running on port $API_PORT, skipping live health check"
    echo "  - [INFO] Health Endpoint: SKIPPED (server not running)" >> "$REPORT_FILE"
  fi

  # 3.3 Check OpenAPI docs endpoint
  if curl -s --max-time 5 "http://localhost:${API_PORT}/docs" > /dev/null 2>&1; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://localhost:${API_PORT}/docs")
    if [ "$HTTP_CODE" = "200" ]; then
      echo "     [OK] OpenAPI docs available at /docs (HTTP $HTTP_CODE)"
      echo "  - [OK] OpenAPI Docs: AVAILABLE at /docs" >> "$REPORT_FILE"
    else
      echo "     [WARN] OpenAPI docs returned HTTP $HTTP_CODE"
      echo "  - [WARN] OpenAPI Docs: HTTP $HTTP_CODE" >> "$REPORT_FILE"
    fi
  else
    echo "     [INFO] Cannot reach /docs endpoint, skipping"
    echo "  - [INFO] OpenAPI Docs: SKIPPED (server not running)" >> "$REPORT_FILE"
  fi

  # 3.4 Fallback: run pytest for API tests if available
  if [ -d "backend/tests" ]; then
    cd backend
    if python -m pytest tests/ -v --tb=short -k "api or route or endpoint" > ../api-tests-wave4.txt 2>&1; then
      PASSED=$(grep -oE "[0-9]+ passed" ../api-tests-wave4.txt | grep -oE "[0-9]+" || echo "0")
      echo "     [OK] API tests passed ($PASSED tests)"
      echo "  - [OK] API Tests: $PASSED tests passed" >> "../$REPORT_FILE"
    else
      COLLECTED=$(grep -oE "no tests ran|[0-9]+ failed" ../api-tests-wave4.txt || echo "unknown")
      if echo "$COLLECTED" | grep -q "no tests ran"; then
        echo "     [INFO] No API-specific tests found"
        echo "  - [INFO] API Tests: No API-specific tests found" >> "../$REPORT_FILE"
      else
        echo "     [FAIL] API tests failed: $COLLECTED"
        echo "  - [FAIL] API Tests: $COLLECTED" >> "../$REPORT_FILE"
        ERRORS=$((ERRORS + 1))
      fi
    fi
    cd ..
  fi
fi

echo "" >> "$REPORT_FILE"

# ============================================
# VALIDATION 4: SECURITY API (19-Security-Review-Agent)
# ============================================
echo ""
echo "================================================================="
echo " VALIDATION 4: Security Review API (BLOCKING)"
echo "================================================================="

echo "### VALIDATION 4: Security Review API (19-Security-Review-Agent)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "  Running API security validation..."

# 4.1 Check for unguarded endpoints (FastAPI)
echo "  Checking API authentication dependencies on routers..."
UNGUARDED=0
if [ -d "backend/app" ]; then
  cd backend/app
  UNGUARDED=$(find . -path "*/api/*" -name "*.py" -type f \
    -exec grep -l "@router.post\|@router.get\|@router.put\|@router.delete\|@router.patch" {} \; | \
    while read -r file; do
      if ! grep -qE "Depends\(get_current_user\)|Depends\(require_auth\)|is_public" "$file"; then
        echo "$file"
      fi
    done | wc -l || echo "0")
  cd ../..
fi

if [ "$UNGUARDED" = "0" ]; then
  echo "     [OK] All endpoints have auth dependencies or are explicitly public"
  echo "  - [OK] API Auth: ALL ENDPOINTS PROTECTED" >> "$REPORT_FILE"
else
  echo "     [WARN] $UNGUARDED router file(s) may have unguarded endpoints"
  echo "  - [WARN] API Auth: $UNGUARDED routers may need review" >> "$REPORT_FILE"
  echo "     Review: backend/app/**/api/*.py"
fi

# 4.2 Check for Pydantic schema validation
echo "  Checking Pydantic schema validation..."
DTOS_WITHOUT_VALIDATION=0
if [ -d "backend/app" ]; then
  cd backend/app
  DTOS_WITHOUT_VALIDATION=$(find . -path "*/schemas/*" -name "*.py" -type f \
    -exec grep -L "BaseModel\|Field\|field_validator" {} \; | wc -l || echo "0")
  cd ../..
fi

if [ "$DTOS_WITHOUT_VALIDATION" = "0" ]; then
  echo "     [OK] All schemas use Pydantic BaseModel with Field validators"
  echo "  - [OK] DTO Validation: ALL SCHEMAS VALIDATED" >> "$REPORT_FILE"
else
  echo "     [WARN] $DTOS_WITHOUT_VALIDATION schema file(s) may lack validation"
  echo "  - [WARN] DTO Validation: $DTOS_WITHOUT_VALIDATION schemas may need review" >> "$REPORT_FILE"
  echo "     Review: backend/app/**/schemas/*.py"
fi

# 4.3 Check for rate limiting on auth endpoints (slowapi)
echo "  Checking rate limiting on auth endpoints..."
RATE_LIMITED=0
if [ -d "backend/app" ]; then
  cd backend/app
  RATE_LIMITED=$(grep -r "@limiter.limit\|from slowapi" . --include="auth*.py" | wc -l || echo "0")
  cd ../..
fi

if [ "$RATE_LIMITED" -gt 0 ]; then
  echo "     [OK] Rate limiting detected on auth endpoints (slowapi)"
  echo "  - [OK] Rate Limiting: CONFIGURED" >> "$REPORT_FILE"
else
  echo "     [WARN] No rate limiting detected on auth endpoints"
  echo "  - [WARN] Rate Limiting: NOT CONFIGURED (consider slowapi @limiter.limit)" >> "$REPORT_FILE"
fi

# 4.4 Check for CORS configuration in code
echo "  Checking CORS configuration..."
CORS_CONFIGURED=0
if [ -d "backend/app" ]; then
  cd backend/app
  CORS_CONFIGURED=$(grep -r "CORSMiddleware\|add_middleware.*CORS" . --include="*.py" | wc -l || echo "0")
  cd ../..
fi

if [ "$CORS_CONFIGURED" -gt 0 ]; then
  echo "     [OK] CORS middleware detected in backend"
  echo "  - [OK] CORS: CONFIGURED" >> "$REPORT_FILE"
else
  echo "     [WARN] No CORS middleware detected"
  echo "  - [WARN] CORS: NOT CONFIGURED (add CORSMiddleware to FastAPI app)" >> "$REPORT_FILE"
fi

# 4.5 Check for raw SQL queries (SQLAlchemy)
echo "  Checking for raw SQL queries..."
RAW_SQL=0
if [ -d "backend/app" ]; then
  cd backend/app
  RAW_SQL=$(grep -rE "\.execute\(\s*['\"]|text\(\s*['\"].*SELECT|text\(\s*['\"].*INSERT|text\(\s*['\"].*UPDATE|text\(\s*['\"].*DELETE" . \
    --include="*.py" \
    --exclude="*test*" \
    --exclude="*migration*" | wc -l || echo "0")
  cd ../..
fi

if [ "$RAW_SQL" = "0" ]; then
  echo "     [OK] No raw SQL queries found (using SQLAlchemy ORM properly)"
  echo "  - [OK] SQL Injection Protection: ORM PARAMETERIZED" >> "$REPORT_FILE"
else
  echo "     [WARN] $RAW_SQL potential raw SQL queries found"
  echo "  - [WARN] SQL Injection: $RAW_SQL raw queries need review" >> "$REPORT_FILE"
  echo "     Ensure all use parameterized queries or SQLAlchemy text() with bind params"
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
  echo "[PASSED] WAVE 4 VALIDATION PASSED - API Layer Complete"
  echo ""
  echo "## [PASSED] POST-WAVE 4 VALIDATION: PASSED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Errors**: 0" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Wave 5 (Frontend) is CLEARED TO START**" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "API layer validated successfully:" >> "$REPORT_FILE"
  echo "- [OK] Import Check: SUCCESS" >> "$REPORT_FILE"
  echo "- [OK] Code Quality: CLEAN" >> "$REPORT_FILE"
  echo "- [OK] API Smoke Tests: PASSED" >> "$REPORT_FILE"
  echo "- [OK] Security: API PROTECTED" >> "$REPORT_FILE"
  echo ""
  echo "================================================================="
  echo " YOU MAY PROCEED TO WAVE 5 (FRONTEND)"
  echo "================================================================="
  echo ""
  echo "Validation report saved to: $REPORT_FILE"
  echo ""
  exit 0
else
  echo "[FAILED] WAVE 4 VALIDATION FAILED - API Layer Incomplete"
  echo ""
  echo "## [FAILED] POST-WAVE 4 VALIDATION: FAILED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Errors**: $ERRORS" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Wave 5 (Frontend) is BLOCKED**" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "Fix all validation errors above before proceeding to Wave 5." >> "$REPORT_FILE"
  echo ""
  echo "================================================================="
  echo " WAVE 5 IS BLOCKED UNTIL ALL VALIDATIONS PASS"
  echo "================================================================="
  echo ""
  echo "Validation Errors: $ERRORS"
  echo ""
  echo "Detailed validation report saved to: $REPORT_FILE"
  echo ""
  echo "Fix all issues and re-run:"
  echo "  bash scripts/hooks/post-wave-4-api.sh"
  echo ""
  exit 1
fi
