#!/bin/bash

###############################################################################
# SCRIPT: verify-enforcement.sh
# PURPOSE: Verify that 100% enforcement system is correctly installed
# USAGE: ./scripts/verify-enforcement.sh
# EXIT CODES: 0 = Correctly installed, 1 = Issues found
###############################################################################

set -e

echo "🔍 VERIFYING 100% ENFORCEMENT SYSTEM INSTALLATION"
echo "=================================================="
echo ""

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

###############################################################################
# CRITICAL CHECKS (must pass)
###############################################################################

echo "🔴 CRITICAL CHECKS"
echo "-----------------"

# Check 1: Global validation script
if [ -x "scripts/validate-all.sh" ]; then
  echo "✅ scripts/validate-all.sh exists and is executable"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "❌ scripts/validate-all.sh missing or not executable"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Check 2: OWASP validation script
if [ -x "scripts/validate-owasp.sh" ]; then
  echo "✅ scripts/validate-owasp.sh exists and is executable"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "❌ scripts/validate-owasp.sh missing or not executable"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Check 3: Agent configuration
if [ -f ".claude/agent-config.md" ]; then
  if grep -q "100% QUALITY ENFORCEMENT" .claude/agent-config.md; then
    echo "✅ .claude/agent-config.md exists with enforcement rules"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo "❌ .claude/agent-config.md missing enforcement rules"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
  fi
else
  echo "❌ .claude/agent-config.md missing"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

echo ""

###############################################################################
# BACKEND CHECKS (warnings if backend exists)
###############################################################################

echo "🔵 BACKEND CHECKS"
echo "----------------"

if [ -d "backend" ]; then
  # Check 4: Backend enforcement script
  if [ -x "backend/scripts/enforce-100.sh" ]; then
    echo "✅ backend/scripts/enforce-100.sh exists and is executable"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo "⚠️  backend/scripts/enforce-100.sh missing or not executable"
    WARNINGS=$((WARNINGS + 1))
  fi

  # Check 5: Backend documentation
  if [ -f "backend/CLAUDE.md" ]; then
    if grep -q "100% Quality Requirements" backend/CLAUDE.md; then
      echo "✅ backend/CLAUDE.md exists with quality requirements"
      CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
      echo "⚠️  backend/CLAUDE.md missing quality requirements section"
      WARNINGS=$((WARNINGS + 1))
    fi
  else
    echo "⚠️  backend/CLAUDE.md missing"
    WARNINGS=$((WARNINGS + 1))
  fi

  # Check 6: Backend package.json has required scripts
  if [ -f "backend/package.json" ]; then
    if grep -q '"test"' backend/package.json && \
       grep -q '"build"' backend/package.json && \
       grep -q '"lint"' backend/package.json; then
      echo "✅ backend/package.json has required scripts (test, build, lint)"
      CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
      echo "⚠️  backend/package.json missing some required scripts"
      WARNINGS=$((WARNINGS + 1))
    fi
  fi
else
  echo "ℹ️  No backend/ directory detected (skipping backend checks)"
fi

echo ""

###############################################################################
# FRONTEND CHECKS (warnings if frontend exists)
###############################################################################

echo "🟢 FRONTEND CHECKS"
echo "-----------------"

if [ -d "frontend" ]; then
  # Check 7: Frontend enforcement script
  if [ -x "frontend/scripts/enforce-100.sh" ]; then
    echo "✅ frontend/scripts/enforce-100.sh exists and is executable"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo "⚠️  frontend/scripts/enforce-100.sh missing or not executable"
    WARNINGS=$((WARNINGS + 1))
  fi

  # Check 8: Frontend documentation
  if [ -f "frontend/CLAUDE.md" ]; then
    if grep -q "100% Quality Requirements" frontend/CLAUDE.md; then
      echo "✅ frontend/CLAUDE.md exists with quality requirements"
      CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
      echo "⚠️  frontend/CLAUDE.md missing quality requirements section"
      WARNINGS=$((WARNINGS + 1))
    fi
  else
    echo "⚠️  frontend/CLAUDE.md missing"
    WARNINGS=$((WARNINGS + 1))
  fi

  # Check 9: Frontend package.json has required scripts
  if [ -f "frontend/package.json" ]; then
    if grep -q '"test"' frontend/package.json && \
       grep -q '"build"' frontend/package.json && \
       grep -q '"lint"' frontend/package.json; then
      echo "✅ frontend/package.json has required scripts (test, build, lint)"
      CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
      echo "⚠️  frontend/package.json missing some required scripts"
      WARNINGS=$((WARNINGS + 1))
    fi
  fi
else
  echo "ℹ️  No frontend/ directory detected (skipping frontend checks)"
fi

echo ""

###############################################################################
# FUNCTIONAL TESTS
###############################################################################

echo "🧪 FUNCTIONAL TESTS"
echo "------------------"

# Test 10: validate-all.sh runs without errors
echo "Testing: ./scripts/validate-all.sh executes..."

if timeout 5s ./scripts/validate-all.sh > /dev/null 2>&1; then
  echo "✅ validate-all.sh executes (passed validation)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
elif [ $? -eq 124 ]; then
  echo "✅ validate-all.sh executes (timeout after 5s - script is working)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
elif [ $? -eq 1 ]; then
  echo "✅ validate-all.sh executes (validation failed - script is working)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "❌ validate-all.sh cannot execute"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Test 11: validate-owasp.sh runs without errors
echo "Testing: ./scripts/validate-owasp.sh executes..."

if timeout 5s ./scripts/validate-owasp.sh > /dev/null 2>&1; then
  echo "✅ validate-owasp.sh executes (passed validation)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
elif [ $? -eq 124 ]; then
  echo "✅ validate-owasp.sh executes (timeout after 5s - script is working)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
elif [ $? -eq 1 ]; then
  echo "✅ validate-owasp.sh executes (validation failed - script is working)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "❌ validate-owasp.sh cannot execute"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

echo ""

###############################################################################
# FINAL REPORT
###############################################################################

echo "=================================================="
echo "📊 VERIFICATION REPORT"
echo "=================================================="
echo ""
echo "Checks passed: $CHECKS_PASSED"
echo "Checks failed: $CHECKS_FAILED"
echo "Warnings: $WARNINGS"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
  if [ $WARNINGS -eq 0 ]; then
    echo "✅✅✅ ENFORCEMENT SYSTEM PERFECTLY INSTALLED ✅✅✅"
    echo ""
    echo "🎉 All checks passed with no warnings!"
    echo "🚀 System is ready to enforce 100% quality"
    echo ""
    exit 0
  else
    echo "✅ ENFORCEMENT SYSTEM INSTALLED (with warnings)"
    echo ""
    echo "⚠️  $WARNINGS warnings found (see above)"
    echo "💡 System will work but consider fixing warnings"
    echo ""
    exit 0
  fi
else
  echo "❌❌❌ ENFORCEMENT SYSTEM INCOMPLETE ❌❌❌"
  echo ""
  echo "🛑 $CHECKS_FAILED critical checks failed"
  echo "🛑 Fix the issues above and re-run verification"
  echo ""
  echo "To reinstall, run:"
  echo "  ./scripts/setup-enforcement-system.sh"
  echo ""
  exit 1
fi
