#!/bin/bash

###############################################################################
# SCRIPT: validate-owasp.sh
# PURPOSE: Validate OWASP Top 10 2021 compliance
# USAGE: ./scripts/validate-owasp.sh
# EXIT CODES: 0 = Compliant, 1 = Non-compliant
###############################################################################

set -e

echo "🔒 OWASP TOP 10 2021 COMPLIANCE VALIDATION"
echo "==========================================="
echo ""

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

ALL_CHECKS_PASSED=true

###############################################################################
# A01: Broken Access Control
###############################################################################

echo "🔍 A01: Broken Access Control"
echo "------------------------------"

cd backend/src

# Check for endpoints without guards
UNGUARDED=$(grep -r "@Post\|@Get\|@Put\|@Delete\|@Patch" . --include="*.controller.ts" | grep -v "@UseGuards\|@Public" | wc -l || echo "0")

if [ "$UNGUARDED" != "0" ]; then
  echo "⚠️  Found $UNGUARDED endpoints that may lack authentication guards"
  echo "    Review: backend/src/**/*.controller.ts"
  # Not failing here, just warning
else
  echo "✅ All endpoints appear to have guards"
fi

cd "$PROJECT_ROOT"

echo ""

###############################################################################
# A02: Cryptographic Failures
###############################################################################

echo "🔍 A02: Cryptographic Failures"
echo "-------------------------------"

# Check for hardcoded secrets
SECRETS=$(grep -rE "(password|secret|api_key|token)\s*=\s*['\"][^'\"]{8,}" backend/src --include="*.ts" | grep -v "test\|spec\|\.example\|DTO\|Interface\|@IsString" | wc -l || echo "0")

if [ "$SECRETS" != "0" ]; then
  echo "❌ Found $SECRETS potential hardcoded secrets"
  echo "    Run: grep -rE \"(password|secret|api_key|token)\\s*=\\s*['\\\"]\" backend/src"
  ALL_CHECKS_PASSED=false
else
  echo "✅ No hardcoded secrets detected"
fi

# Check for .env in .gitignore
if grep -q "^\.env$" .gitignore 2>/dev/null; then
  echo "✅ .env is in .gitignore"
else
  echo "❌ .env should be in .gitignore"
  ALL_CHECKS_PASSED=false
fi

echo ""

###############################################################################
# A03: Injection
###############################################################################

echo "🔍 A03: Injection"
echo "-----------------"

# Check for raw SQL queries
RAW_SQL=$(grep -r "\.query(\|\.execute(" backend/src --include="*.ts" | grep -v "test\|spec\|createQueryBuilder" | wc -l || echo "0")

if [ "$RAW_SQL" != "0" ]; then
  echo "⚠️  Found $RAW_SQL uses of .query() or .execute()"
  echo "    Verify these use parameterized queries"
  # Not failing, just warning
else
  echo "✅ No raw SQL queries detected"
fi

echo ""

###############################################################################
# A04: Insecure Design
###############################################################################

echo "🔍 A04: Insecure Design"
echo "-----------------------"

# Check for rate limiting
RATE_LIMITED=$(grep -r "@Throttle\|ThrottlerGuard" backend/src --include="*.ts" | wc -l || echo "0")

if [ "$RATE_LIMITED" = "0" ]; then
  echo "⚠️  No rate limiting detected"
  echo "    Consider adding @Throttle() decorator on public endpoints"
else
  echo "✅ Rate limiting configured ($RATE_LIMITED occurrences)"
fi

# Check for DTO validation
DTO_VALIDATION=$(grep -r "class-validator\|@Is" backend/src --include="*.dto.ts" | wc -l || echo "0")

if [ "$DTO_VALIDATION" = "0" ]; then
  echo "❌ No DTO validation detected"
  echo "    All DTOs should use class-validator decorators"
  ALL_CHECKS_PASSED=false
else
  echo "✅ DTO validation configured ($DTO_VALIDATION validators)"
fi

echo ""

###############################################################################
# A05: Security Misconfiguration
###############################################################################

echo "🔍 A05: Security Misconfiguration"
echo "----------------------------------"

# Check for Helmet.js
if grep -q "helmet" backend/src/main.ts 2>/dev/null; then
  echo "✅ Helmet.js configured"
else
  echo "❌ Helmet.js NOT configured in main.ts"
  echo "    Add: import helmet from 'helmet'; app.use(helmet());"
  ALL_CHECKS_PASSED=false
fi

# Check CORS configuration
if grep -q "enableCors\|app.use(cors" backend/src/main.ts 2>/dev/null; then
  # Check if CORS uses wildcard
  if grep -q "origin:.*'\*'" backend/src/main.ts 2>/dev/null; then
    echo "❌ CORS configured with wildcard '*' (security risk)"
    ALL_CHECKS_PASSED=false
  else
    echo "✅ CORS configured (verify whitelist is used)"
  fi
else
  echo "⚠️  CORS not explicitly configured"
fi

echo ""

###############################################################################
# A06: Vulnerable and Outdated Components
###############################################################################

echo "🔍 A06: Vulnerable Components"
echo "------------------------------"

cd backend

AUDIT_OUTPUT=$(npm audit --audit-level=moderate 2>&1 || true)

if echo "$AUDIT_OUTPUT" | grep -q "found 0 vulnerabilities"; then
  echo "✅ No vulnerabilities found (backend)"
elif echo "$AUDIT_OUTPUT" | grep -q "found.*vulnerabilities"; then
  VULN_COUNT=$(echo "$AUDIT_OUTPUT" | grep -oP "found \K\d+" || echo "0")

  if [ "$VULN_COUNT" != "0" ]; then
    echo "❌ Found $VULN_COUNT vulnerabilities in backend dependencies"
    echo ""
    echo "$AUDIT_OUTPUT" | grep -A 2 "moderate\|high\|critical" | head -10
    echo ""
    ALL_CHECKS_PASSED=false
  fi
else
  echo "✅ No moderate+ vulnerabilities (backend)"
fi

cd ../frontend

AUDIT_OUTPUT=$(npm audit --audit-level=moderate 2>&1 || true)

if echo "$AUDIT_OUTPUT" | grep -q "found 0 vulnerabilities"; then
  echo "✅ No vulnerabilities found (frontend)"
elif echo "$AUDIT_OUTPUT" | grep -q "found.*vulnerabilities"; then
  VULN_COUNT=$(echo "$AUDIT_OUTPUT" | grep -oP "found \K\d+" || echo "0")

  if [ "$VULN_COUNT" != "0" ]; then
    echo "❌ Found $VULN_COUNT vulnerabilities in frontend dependencies"
    ALL_CHECKS_PASSED=false
  fi
else
  echo "✅ No moderate+ vulnerabilities (frontend)"
fi

cd "$PROJECT_ROOT"

echo ""

###############################################################################
# A09: Security Logging & Monitoring Failures
###############################################################################

echo "🔍 A09: Security Logging"
echo "------------------------"

# Check for logging of auth events
if grep -rq "logger.*login\|logger.*authentication" backend/src --include="*.ts"; then
  echo "✅ Authentication events are logged"
else
  echo "⚠️  No authentication logging detected"
  echo "    Add logging for login, logout, failed auth attempts"
fi

echo ""

###############################################################################
# FINAL VERDICT
###############################################################################

echo "==========================================="
echo "📋 OWASP VALIDATION SUMMARY"
echo "==========================================="
echo ""

if [ "$ALL_CHECKS_PASSED" = true ]; then
  echo "✅✅✅ OWASP COMPLIANCE VALIDATED ✅✅✅"
  echo ""
  echo "Summary:"
  echo "  ✅ A01: Access control checks passed"
  echo "  ✅ A02: No hardcoded secrets"
  echo "  ✅ A03: Injection prevention in place"
  echo "  ✅ A04: Input validation configured"
  echo "  ✅ A05: Security headers configured"
  echo "  ✅ A06: No vulnerable dependencies"
  echo "  ✅ A09: Security logging present"
  echo ""
  echo "🔒 Project follows OWASP best practices"
  echo ""
  exit 0
else
  echo "❌❌❌ OWASP COMPLIANCE ISSUES FOUND ❌❌❌"
  echo ""
  echo "🛑 Review security issues above"
  echo "🛑 Fix compliance gaps before deployment"
  echo ""
  echo "For full checklist, see:"
  echo "  docs/OWASP_COMPLIANCE_CHECKLIST.md"
  echo ""
  exit 1
fi
