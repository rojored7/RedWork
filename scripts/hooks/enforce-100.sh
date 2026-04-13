#!/bin/bash
# Enforce-100: Unified Quality Check Runner
# Runs all quality checks in one command and reports pass/fail
#
# Checks: ruff, mypy, pytest (backend) + eslint, tsc (frontend if exists)
#
# Usage: bash scripts/hooks/enforce-100.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo ""
echo "================================================================="
echo " ENFORCE-100: Full Quality Gate"
echo "================================================================="
echo ""

ERRORS=0
CHECKS=0

# --- BACKEND CHECKS ---
if [ -d "backend" ]; then
  echo " [BACKEND]"
  cd backend

  # Ruff
  CHECKS=$((CHECKS + 1))
  if command -v ruff > /dev/null 2>&1; then
    if ruff check . > /dev/null 2>&1; then
      echo "  [OK] ruff: clean"
    else
      echo "  [FAIL] ruff: errors found"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo "  [SKIP] ruff: not installed"
  fi

  # Mypy
  CHECKS=$((CHECKS + 1))
  if command -v mypy > /dev/null 2>&1; then
    if mypy app/ > /dev/null 2>&1; then
      echo "  [OK] mypy: clean"
    else
      MYPY_ERRORS=$(mypy app/ 2>&1 | grep -c "error:" || echo "0")
      if [ "$MYPY_ERRORS" = "0" ]; then
        echo "  [OK] mypy: clean"
      else
        echo "  [FAIL] mypy: $MYPY_ERRORS type errors"
        ERRORS=$((ERRORS + 1))
      fi
    fi
  else
    echo "  [SKIP] mypy: not installed"
  fi

  # Pytest
  CHECKS=$((CHECKS + 1))
  if [ -d "tests" ]; then
    if python -m pytest tests/ -q --tb=line > /dev/null 2>&1; then
      echo "  [OK] pytest: all tests passed"
    else
      echo "  [FAIL] pytest: tests failed"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo "  [SKIP] pytest: no tests/ directory"
  fi

  cd ..
  echo ""
fi

# --- FRONTEND CHECKS ---
if [ -d "frontend" ]; then
  echo " [FRONTEND]"
  cd frontend

  # ESLint
  CHECKS=$((CHECKS + 1))
  if [ -f "node_modules/.bin/eslint" ] || command -v npx > /dev/null 2>&1; then
    if npx eslint src/ --quiet > /dev/null 2>&1; then
      echo "  [OK] eslint: clean"
    else
      echo "  [FAIL] eslint: errors found"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo "  [SKIP] eslint: not available"
  fi

  # TypeScript
  CHECKS=$((CHECKS + 1))
  if [ -f "tsconfig.json" ]; then
    if npx tsc --noEmit > /dev/null 2>&1; then
      echo "  [OK] tsc: no type errors"
    else
      echo "  [FAIL] tsc: type errors found"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo "  [SKIP] tsc: no tsconfig.json"
  fi

  # Vitest
  CHECKS=$((CHECKS + 1))
  if [ -f "node_modules/.bin/vitest" ] || command -v npx > /dev/null 2>&1; then
    if npx vitest run --reporter=dot > /dev/null 2>&1; then
      echo "  [OK] vitest: all tests passed"
    else
      echo "  [FAIL] vitest: tests failed"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo "  [SKIP] vitest: not available"
  fi

  cd ..
  echo ""
fi

# --- VERDICT ---
echo "================================================================="
if [ $ERRORS -eq 0 ]; then
  echo " [PASSED] ENFORCE-100: $CHECKS checks run, 0 failures"
  echo "================================================================="
  exit 0
else
  echo " [FAILED] ENFORCE-100: $ERRORS/$CHECKS checks failed"
  echo "================================================================="
  exit 1
fi
