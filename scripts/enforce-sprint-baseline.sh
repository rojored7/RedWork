#!/bin/bash
# Sprint Baseline Enforcer - MANDATORY before starting any sprint
# BLOCKS development if baseline is not 100% passing
#
# Usage: bash scripts/enforce-sprint-baseline.sh <sprint_number>
# Example: bash scripts/enforce-sprint-baseline.sh 4

set -e

SPRINT_NUMBER=${1:-"UNKNOWN"}

echo ""
echo "🔒🔒🔒 SPRINT $SPRINT_NUMBER BASELINE ENFORCEMENT 🔒🔒🔒"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  THIS SCRIPT ENFORCES 100% BASELINE BEFORE SPRINT STARTS"
echo "⚠️  DEVELOPMENT IS BLOCKED UNTIL ALL GATES PASS"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

GATE_FAILURES=0
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_FILE=".project-orchestration/sprint-${SPRINT_NUMBER}-baseline-report-${TIMESTAMP}.md"

# Create report header
mkdir -p .project-orchestration
cat > "$REPORT_FILE" <<EOF
# Sprint $SPRINT_NUMBER - Baseline Enforcement Report

**Date**: $(date +%Y-%m-%d)
**Time**: $(date +%H:%M:%S)
**Enforced By**: enforce-sprint-baseline.sh

---

## Enforcement Summary

EOF

# ============================================
# GATE 1: INFRASTRUCTURE HEALTH
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 GATE 1: Infrastructure Health (MANDATORY)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### GATE 1: Infrastructure Health" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Check PostgreSQL
echo "🐘 Checking PostgreSQL..."
if docker ps --filter "name=taskmanager-postgres" --filter "status=running" | grep -q "healthy\|Up"; then
  echo "  ✅ PostgreSQL: HEALTHY"
  echo "- ✅ PostgreSQL: HEALTHY" >> "$REPORT_FILE"
else
  echo "  ❌ PostgreSQL: DOWN or UNHEALTHY"
  echo "- ❌ PostgreSQL: DOWN or UNHEALTHY" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "  **Action Required**: Run \`docker-compose up -d\`" >> "$REPORT_FILE"
  GATE_FAILURES=$((GATE_FAILURES + 1))
fi

# Check Redis
echo "🔴 Checking Redis..."
if docker ps --filter "name=taskmanager-redis" --filter "status=running" | grep -q "healthy\|Up"; then
  echo "  ✅ Redis: HEALTHY"
  echo "- ✅ Redis: HEALTHY" >> "$REPORT_FILE"
else
  echo "  ❌ Redis: DOWN or UNHEALTHY"
  echo "- ❌ Redis: DOWN or UNHEALTHY" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "  **Action Required**: Run \`docker-compose up -d\`" >> "$REPORT_FILE"
  GATE_FAILURES=$((GATE_FAILURES + 1))
fi

# Check port conflicts
echo "🔌 Checking port conflicts..."
PORTS_IN_USE=$(netstat -ano 2>/dev/null | grep -E ":(8010|3010|5434|6381)" | wc -l || echo "0")
if [ "$PORTS_IN_USE" -gt 0 ]; then
  echo "  ⚠️  Ports already in use (may indicate running services)"
  echo "- ⚠️  Ports 8010/3010/5434/6381: IN USE" >> "$REPORT_FILE"
else
  echo "  ✅ Required ports: AVAILABLE"
  echo "- ✅ Required ports: AVAILABLE" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# ============================================
# GATE 2: ENTITY STRUCTURE VALIDATION
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 GATE 2: Entity Structure Validation (MANDATORY)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### GATE 2: Entity Structure Validation" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "📦 Validating entity structure..."
if bash scripts/validate-entities.sh > /dev/null 2>&1; then
  echo "  ✅ Entity Structure: VALID (no duplicates, no obsolete paths)"
  echo "- ✅ Entity Structure: VALID" >> "$REPORT_FILE"
else
  echo "  ❌ Entity Structure: INVALID"
  echo "- ❌ Entity Structure: INVALID" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "  **Action Required**: Run \`bash scripts/validate-entities.sh\` to see details" >> "$REPORT_FILE"
  GATE_FAILURES=$((GATE_FAILURES + 1))
fi

echo "" >> "$REPORT_FILE"

# ============================================
# GATE 3: BACKEND BASELINE
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 GATE 3: Backend Baseline (MANDATORY 100%)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### GATE 3: Backend Baseline" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

cd backend

# Clean dist
echo "🗑️  Cleaning dist/ directory..."
rm -rf dist
echo "  ✅ dist/ cleaned"

# Compilation
echo "🔨 Compiling backend..."
if npm run build > ../backend-build-output.txt 2>&1; then
  echo "  ✅ Backend Compilation: SUCCESS (0 errors)"
  echo "- ✅ Backend Compilation: SUCCESS (0 errors)" >> "../$REPORT_FILE"
else
  echo "  ❌ Backend Compilation: FAILED"
  echo "- ❌ Backend Compilation: FAILED" >> "../$REPORT_FILE"
  echo "" >> "../$REPORT_FILE"
  echo "  **Build Output**:" >> "../$REPORT_FILE"
  echo '  ```' >> "../$REPORT_FILE"
  tail -20 ../backend-build-output.txt >> "../$REPORT_FILE"
  echo '  ```' >> "../$REPORT_FILE"
  GATE_FAILURES=$((GATE_FAILURES + 1))
fi

# Unit Tests
echo "🧪 Running backend unit tests..."
TEST_OUTPUT=$(npm test 2>&1 || true)
echo "$TEST_OUTPUT" > ../backend-test-output.txt

PASSING=$(echo "$TEST_OUTPUT" | grep -o "[0-9]* passing" | grep -o "[0-9]*" || echo "0")
FAILING=$(echo "$TEST_OUTPUT" | grep -o "[0-9]* failing" | grep -o "[0-9]*" || echo "0")

if [ "$FAILING" = "0" ] && [ "$PASSING" != "0" ]; then
  echo "  ✅ Backend Unit Tests: $PASSING passing, 0 failing (100%)"
  echo "- ✅ Backend Unit Tests: $PASSING passing, 0 failing (100%)" >> "../$REPORT_FILE"
else
  echo "  ❌ Backend Unit Tests: $FAILING failing"
  echo "- ❌ Backend Unit Tests: $FAILING failing" >> "../$REPORT_FILE"
  echo "" >> "../$REPORT_FILE"
  echo "  **Failing Tests**:" >> "../$REPORT_FILE"
  echo '  ```' >> "../$REPORT_FILE"
  echo "$TEST_OUTPUT" | grep -A 5 "failing" >> "../$REPORT_FILE"
  echo '  ```' >> "../$REPORT_FILE"
  GATE_FAILURES=$((GATE_FAILURES + 1))
fi

# Linting
echo "🔍 Running backend linting..."
if npm run lint > ../backend-lint-output.txt 2>&1; then
  echo "  ✅ Backend Linting: CLEAN (0 errors)"
  echo "- ✅ Backend Linting: CLEAN" >> "../$REPORT_FILE"
else
  echo "  ❌ Backend Linting: ERRORS FOUND"
  echo "- ❌ Backend Linting: ERRORS FOUND" >> "../$REPORT_FILE"
  GATE_FAILURES=$((GATE_FAILURES + 1))
fi

cd ..
echo "" >> "$REPORT_FILE"

# ============================================
# GATE 4: FRONTEND BASELINE
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 GATE 4: Frontend Baseline (MANDATORY 100%)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### GATE 4: Frontend Baseline" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

cd frontend

# Type Check
echo "🔍 Type checking frontend..."
if npm run type-check > ../frontend-typecheck-output.txt 2>&1; then
  echo "  ✅ Frontend Type Check: SUCCESS (0 errors)"
  echo "- ✅ Frontend Type Check: SUCCESS (0 errors)" >> "../$REPORT_FILE"
else
  echo "  ❌ Frontend Type Check: FAILED"
  echo "- ❌ Frontend Type Check: FAILED" >> "../$REPORT_FILE"
  GATE_FAILURES=$((GATE_FAILURES + 1))
fi

# Build
echo "🔨 Building frontend..."
if npm run build > ../frontend-build-output.txt 2>&1; then
  echo "  ✅ Frontend Build: SUCCESS"
  echo "- ✅ Frontend Build: SUCCESS" >> "../$REPORT_FILE"
else
  echo "  ❌ Frontend Build: FAILED"
  echo "- ❌ Frontend Build: FAILED" >> "../$REPORT_FILE"
  GATE_FAILURES=$((GATE_FAILURES + 1))
fi

# Unit Tests
echo "🧪 Running frontend unit tests..."
if npm test -- --run > ../frontend-test-output.txt 2>&1; then
  FRONTEND_TESTS=$(cat ../frontend-test-output.txt | grep -o "[0-9]* passed" | grep -o "[0-9]*" || echo "0")
  echo "  ✅ Frontend Unit Tests: $FRONTEND_TESTS passing (100%)"
  echo "- ✅ Frontend Unit Tests: $FRONTEND_TESTS passing (100%)" >> "../$REPORT_FILE"
else
  echo "  ❌ Frontend Unit Tests: FAILING"
  echo "- ❌ Frontend Unit Tests: FAILING" >> "../$REPORT_FILE"
  GATE_FAILURES=$((GATE_FAILURES + 1))
fi

# Linting
echo "🔍 Running frontend linting..."
if npm run lint > ../frontend-lint-output.txt 2>&1; then
  echo "  ✅ Frontend Linting: CLEAN (0 errors)"
  echo "- ✅ Frontend Linting: CLEAN" >> "../$REPORT_FILE"
else
  echo "  ❌ Frontend Linting: ERRORS FOUND"
  echo "- ❌ Frontend Linting: ERRORS FOUND" >> "../$REPORT_FILE"
  GATE_FAILURES=$((GATE_FAILURES + 1))
fi

cd ..
echo "" >> "$REPORT_FILE"

# ============================================
# GATE 5: DATABASE SCHEMA VALIDATION
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 GATE 5: Database Schema Validation (MANDATORY)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### GATE 5: Database Schema Validation" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "📊 Checking database schema..."
if docker exec taskmanager-postgres psql -U taskmanager_user -d taskmanager_dev -c "\dt" > /dev/null 2>&1; then
  # Check users table exists
  if docker exec taskmanager-postgres psql -U taskmanager_user -d taskmanager_dev -c "\d users" > /dev/null 2>&1; then
    # Check column count
    COLUMN_COUNT=$(docker exec taskmanager-postgres psql -U taskmanager_user -d taskmanager_dev -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users';" 2>&1 | tr -d ' ')

    if [ "$COLUMN_COUNT" -lt 30 ] && [ "$COLUMN_COUNT" -gt 15 ]; then
      echo "  ✅ Database Schema: VALID ($COLUMN_COUNT columns in users table)"
      echo "- ✅ Database Schema: VALID ($COLUMN_COUNT columns)" >> "$REPORT_FILE"
    else
      echo "  ❌ Database Schema: CORRUPTED ($COLUMN_COUNT columns, expected ~23)"
      echo "- ❌ Database Schema: CORRUPTED ($COLUMN_COUNT columns)" >> "$REPORT_FILE"
      echo "" >> "$REPORT_FILE"
      echo "  **Action Required**: Drop and recreate schema" >> "$REPORT_FILE"
      GATE_FAILURES=$((GATE_FAILURES + 1))
    fi
  else
    echo "  ⚠️  users table does not exist (will be created on backend start)"
    echo "- ⚠️  users table: NOT FOUND" >> "$REPORT_FILE"
  fi
else
  echo "  ❌ Cannot connect to database"
  echo "- ❌ Database: CONNECTION FAILED" >> "$REPORT_FILE"
  GATE_FAILURES=$((GATE_FAILURES + 1))
fi

echo "" >> "$REPORT_FILE"

# ============================================
# GATE 6: GIT HOOKS INSTALLED
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 GATE 6: Git Hooks Validation (MANDATORY)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### GATE 6: Git Hooks Validation" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Check pre-commit
if [ -f ".git/hooks/pre-commit" ] && [ -x ".git/hooks/pre-commit" ]; then
  echo "  ✅ pre-commit hook: INSTALLED & EXECUTABLE"
  echo "- ✅ pre-commit hook: INSTALLED" >> "$REPORT_FILE"
else
  echo "  ❌ pre-commit hook: NOT INSTALLED"
  echo "- ❌ pre-commit hook: NOT INSTALLED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "  **Action Required**: Run \`bash scripts/install-git-hooks.sh\`" >> "$REPORT_FILE"
  GATE_FAILURES=$((GATE_FAILURES + 1))
fi

# Check pre-push
if [ -f ".git/hooks/pre-push" ] && [ -x ".git/hooks/pre-push" ]; then
  echo "  ✅ pre-push hook: INSTALLED & EXECUTABLE"
  echo "- ✅ pre-push hook: INSTALLED" >> "$REPORT_FILE"
else
  echo "  ❌ pre-push hook: NOT INSTALLED"
  echo "- ❌ pre-push hook: NOT INSTALLED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "  **Action Required**: Run \`bash scripts/install-git-hooks.sh\`" >> "$REPORT_FILE"
  GATE_FAILURES=$((GATE_FAILURES + 1))
fi

echo "" >> "$REPORT_FILE"

# ============================================
# GATE 7: SMOKE TESTS VALIDATION (18-Smoke-Test-Validator)
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 GATE 7: Smoke Tests Validation (MANDATORY)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### GATE 7: Smoke Tests Validation (18-Smoke-Test-Validator)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "🔥 Running full system smoke tests..."
if [ -f "scripts/smoke-test.sh" ]; then
  if bash scripts/smoke-test.sh > smoke-test-baseline-output.txt 2>&1; then
    echo "  ✅ Smoke Tests: ALL PASSED"
    echo "- ✅ Smoke Tests: ALL PASSED" >> "$REPORT_FILE"
    echo "     - Infrastructure: healthy" >> "$REPORT_FILE"
    echo "     - Backend: responding" >> "$REPORT_FILE"
    echo "     - Frontend: loads correctly" >> "$REPORT_FILE"
    echo "     - Critical flows: working" >> "$REPORT_FILE"
  else
    echo "  ❌ Smoke Tests: FAILED"
    echo "- ❌ Smoke Tests: FAILED" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "  **Smoke Test Output**:" >> "$REPORT_FILE"
    echo '  ```' >> "$REPORT_FILE"
    tail -40 smoke-test-baseline-output.txt >> "$REPORT_FILE"
    echo '  ```' >> "$REPORT_FILE"
    echo ""
    echo "  **Action Required**: Run \`bash scripts/smoke-test.sh\` to debug"
    GATE_FAILURES=$((GATE_FAILURES + 1))
  fi
elif [ -f "scripts/validate-smoke-tests.sh" ]; then
  if bash scripts/validate-smoke-tests.sh > smoke-test-baseline-output.txt 2>&1; then
    echo "  ✅ Smoke Tests: VALIDATED"
    echo "- ✅ Smoke Tests: VALIDATED" >> "$REPORT_FILE"
  else
    echo "  ❌ Smoke Tests: VALIDATION FAILED"
    echo "- ❌ Smoke Tests: VALIDATION FAILED" >> "$REPORT_FILE"
    GATE_FAILURES=$((GATE_FAILURES + 1))
  fi
else
  echo "  ⚠️  Smoke Tests: SCRIPTS NOT FOUND"
  echo "- ⚠️  Smoke Tests: SCRIPTS NOT FOUND (scripts/smoke-test.sh)" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "  **Action Required**: Create smoke test script"
fi

echo "" >> "$REPORT_FILE"

# ============================================
# GATE 8: OWASP SECURITY VALIDATION (19-Security-Review-Agent)
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 GATE 8: OWASP Security Validation (MANDATORY)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "### GATE 8: OWASP Security Validation (19-Security-Review-Agent)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "🔒 Running OWASP Top 10 validation..."
if [ -f "scripts/validate-owasp.sh" ]; then
  if bash scripts/validate-owasp.sh > owasp-baseline-output.txt 2>&1; then
    echo "  ✅ OWASP Validation: COMPLIANT"
    echo "- ✅ OWASP Validation: COMPLIANT (Top 10)" >> "$REPORT_FILE"
    echo "     - A01 Broken Access Control: ✅" >> "$REPORT_FILE"
    echo "     - A02 Cryptographic Failures: ✅" >> "$REPORT_FILE"
    echo "     - A03 Injection: ✅" >> "$REPORT_FILE"
    echo "     - A04 Insecure Design: ✅" >> "$REPORT_FILE"
    echo "     - A05 Security Misconfiguration: ✅" >> "$REPORT_FILE"
    echo "     - A06 Vulnerable Components: ✅" >> "$REPORT_FILE"
    echo "     - A09 Security Logging Failures: ✅" >> "$REPORT_FILE"
  else
    OWASP_ERRORS=$(grep -c "❌" owasp-baseline-output.txt 2>/dev/null || echo "unknown")
    echo "  ❌ OWASP Validation: NON-COMPLIANT ($OWASP_ERRORS issues)"
    echo "- ❌ OWASP Validation: NON-COMPLIANT ($OWASP_ERRORS issues)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "  **OWASP Issues Found**:" >> "$REPORT_FILE"
    echo '  ```' >> "$REPORT_FILE"
    grep "❌" owasp-baseline-output.txt | head -15 >> "$REPORT_FILE" || echo "See full output" >> "$REPORT_FILE"
    echo '  ```' >> "$REPORT_FILE"
    echo ""
    echo "  **Action Required**: Run \`bash scripts/validate-owasp.sh\` to see details"
    GATE_FAILURES=$((GATE_FAILURES + 1))
  fi
else
  echo "  ⚠️  OWASP Validation: SCRIPT NOT FOUND"
  echo "- ⚠️  OWASP Validation: SCRIPT NOT FOUND (scripts/validate-owasp.sh)" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "  **Action Required**: Create OWASP validation script"
fi

echo "" >> "$REPORT_FILE"

# ============================================
# FINAL VERDICT
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $GATE_FAILURES -eq 0 ]; then
  echo "✅✅✅ ALL GATES PASSED - SPRINT $SPRINT_NUMBER BASELINE: 100%"
  echo ""
  echo "## ✅ BASELINE ENFORCEMENT: PASSED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Gate Failures**: 0" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "🎉 **Sprint $SPRINT_NUMBER is CLEARED TO START**" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "All systems are GO. Development can proceed." >> "$REPORT_FILE"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚀 SPRINT $SPRINT_NUMBER IS CLEARED TO START"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "📄 Enforcement report saved to: $REPORT_FILE"
  echo ""
  exit 0
else
  echo "❌❌❌ BASELINE ENFORCEMENT FAILED - SPRINT $SPRINT_NUMBER BLOCKED"
  echo ""
  echo "## ❌ BASELINE ENFORCEMENT: FAILED" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "**Total Gate Failures**: $GATE_FAILURES" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "🚫 **Sprint $SPRINT_NUMBER is BLOCKED**" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "Fix all gate failures above before starting development." >> "$REPORT_FILE"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚫 DEVELOPMENT IS BLOCKED UNTIL BASELINE IS 100%"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Gate Failures: $GATE_FAILURES"
  echo ""
  echo "📄 Detailed enforcement report saved to: $REPORT_FILE"
  echo ""
  echo "Fix all issues and re-run:"
  echo "  bash scripts/enforce-sprint-baseline.sh $SPRINT_NUMBER"
  echo ""
  exit 1
fi
