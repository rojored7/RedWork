#!/bin/bash
# scripts/smoke-test-frontend.sh
# Smoke tests for frontend

set -e

echo "=== FRONTEND SMOKE TESTS ==="

# 1. Frontend serves HTML
echo -n "1. Frontend serves HTML... "
RESPONSE=$(curl -s http://localhost:3010)
echo $RESPONSE | grep -q "<!DOCTYPE html>" && echo "✅" || (echo "❌" && exit 1)

# 2. JavaScript bundles load
echo -n "2. JavaScript bundles... "
echo $RESPONSE | grep -q "<script" && echo "✅" || (echo "❌" && exit 1)

# 3. No obvious errors in HTML
echo -n "3. No errors in HTML... "
echo $RESPONSE | grep -qi "error" && (echo "❌ Found 'error' in HTML" && exit 1) || echo "✅"

# 4. Build artifacts exist
echo -n "4. Build artifacts... "
[ -d "frontend/dist" ] && echo "✅" || (echo "❌ frontend/dist not found" && exit 1)

echo "✅ ALL FRONTEND SMOKE TESTS PASSED"
