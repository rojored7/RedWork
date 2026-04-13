#!/bin/bash
# Pre-Wave 1 Validation Hook - Domain Layer Prerequisites
# Validates prerequisites BEFORE Wave 1 (Domain Layer) starts
#
# Usage: bash scripts/hooks/pre-hook-wave-1.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo ""
echo "================================================================="
echo " PRE-WAVE 1 VALIDATION - Domain Layer Prerequisites"
echo "================================================================="
echo ""

ERRORS=0

# Check Python available
echo "  Checking Python..."
if command -v python > /dev/null 2>&1; then
  PY_VERSION=$(python --version 2>&1)
  echo "  [OK] Python found: $PY_VERSION"
else
  echo "  [FAIL] Python not found"
  ERRORS=$((ERRORS + 1))
fi

# Check backend directory exists
echo "  Checking backend/ directory..."
if [ -d "backend" ]; then
  echo "  [OK] backend/ directory exists"
else
  echo "  [FAIL] backend/ directory not found"
  ERRORS=$((ERRORS + 1))
fi

# Check ruff installed
echo "  Checking ruff..."
if command -v ruff > /dev/null 2>&1; then
  echo "  [OK] ruff available"
else
  echo "  [WARN] ruff not installed (install with: pip install ruff)"
fi

# Check mypy installed
echo "  Checking mypy..."
if command -v mypy > /dev/null 2>&1; then
  echo "  [OK] mypy available"
else
  echo "  [WARN] mypy not installed (install with: pip install mypy)"
fi

# Check Agent 11 contract exists
echo "  Checking implementation contract..."
if [ -f "outputs/11_implementation_contract.md" ] || [ -f "outputs/10_api_specification.md" ]; then
  echo "  [OK] API/Implementation contract found"
else
  echo "  [WARN] No implementation contract found in outputs/"
  echo "         Agents 10-11 should run before development waves"
fi

# Check git is clean (no uncommitted changes that could interfere)
echo "  Checking git status..."
UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l || echo "0")
if [ "$UNCOMMITTED" -lt 10 ]; then
  echo "  [OK] Git working directory manageable ($UNCOMMITTED pending changes)"
else
  echo "  [WARN] $UNCOMMITTED uncommitted changes - consider committing first"
fi

echo ""
echo "================================================================="
if [ $ERRORS -eq 0 ]; then
  echo " [PASSED] PRE-WAVE 1: Prerequisites validated"
  echo " Wave 1 (Domain Layer) is CLEARED TO START"
  echo "================================================================="
  exit 0
else
  echo " [FAILED] PRE-WAVE 1: $ERRORS prerequisite(s) missing"
  echo " Wave 1 (Domain Layer) is BLOCKED"
  echo "================================================================="
  exit 1
fi
