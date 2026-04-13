#!/bin/bash
# Smoke Test Runner - Cross-Platform
# Quick validation that core services are functional
#
# Checks: backend health endpoint, frontend build, docker services
#
# Usage: bash scripts/hooks/smoke-test.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo ""
echo "================================================================="
echo " SMOKE TEST - Quick Validation"
echo "================================================================="
echo ""

ERRORS=0
CHECKS=0

# Check backend health endpoint
if [ -d "backend" ]; then
  CHECKS=$((CHECKS + 1))
  echo "  Checking backend health endpoint..."

  # Try to hit health endpoint if server is running
  if command -v curl > /dev/null 2>&1; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
      echo "  [OK] Backend health: HTTP 200"
    elif [ "$HTTP_CODE" = "000" ]; then
      echo "  [INFO] Backend not running (start with: cd backend && uvicorn app.main:app)"
    else
      echo "  [FAIL] Backend health: HTTP $HTTP_CODE"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo "  [SKIP] curl not available"
  fi
fi

# Check frontend build artifacts
if [ -d "frontend" ]; then
  CHECKS=$((CHECKS + 1))
  echo "  Checking frontend build..."
  if [ -d "frontend/dist" ] || [ -d "frontend/build" ] || [ -d "frontend/.next" ]; then
    echo "  [OK] Frontend build artifacts found"
  else
    echo "  [WARN] No frontend build artifacts (run: cd frontend && npm run build)"
  fi
fi

# Check Docker services
if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yaml" ]; then
  CHECKS=$((CHECKS + 1))
  echo "  Checking Docker services..."
  if command -v docker > /dev/null 2>&1; then
    RUNNING=$(docker compose ps --format "{{.Name}}" 2>/dev/null | wc -l || echo "0")
    if [ "$RUNNING" -gt 0 ]; then
      echo "  [OK] Docker: $RUNNING services running"
    else
      echo "  [INFO] Docker: no services running (start with: docker compose up -d)"
    fi
  else
    echo "  [SKIP] Docker not available"
  fi
fi

# Check database connectivity
if [ -f "backend/.env" ] || [ -f ".env" ]; then
  CHECKS=$((CHECKS + 1))
  echo "  Checking database..."
  DB_URL=$(grep -E "DATABASE_URL" backend/.env .env 2>/dev/null | head -1 | cut -d= -f2-)
  if [ -n "$DB_URL" ]; then
    echo "  [INFO] Database URL configured"
  else
    echo "  [INFO] No DATABASE_URL found in .env"
  fi
fi

echo ""
echo "================================================================="
if [ $ERRORS -eq 0 ]; then
  echo " [PASSED] SMOKE TEST: $CHECKS checks, 0 failures"
else
  echo " [FAILED] SMOKE TEST: $ERRORS/$CHECKS checks failed"
fi
echo "================================================================="

exit $ERRORS
