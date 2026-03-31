#!/bin/bash
# scripts/smoke-test-api.sh
# Smoke tests for API endpoints

set -e

echo "=== API SMOKE TESTS ==="

# Generar email único
TIMESTAMP=$(date +%s)
EMAIL="smoke-${TIMESTAMP}@test.com"

# 1. Register
echo -n "1. Register endpoint... "
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:8010/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${EMAIL}\",\"password\":\"Test123!@#\",\"firstName\":\"Smoke\",\"lastName\":\"Test\"}")

echo $REGISTER_RESPONSE | grep -q '"id"' && echo "✅" || (echo "❌ $REGISTER_RESPONSE" && exit 1)

# 2. Login
echo -n "2. Login endpoint... "
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8010/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${EMAIL}\",\"password\":\"Test123!@#\"}")

echo $LOGIN_RESPONSE | grep -q '"accessToken"' && echo "✅" || (echo "❌ $LOGIN_RESPONSE" && exit 1)

# Extraer token
ACCESS_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)

# 3. Protected endpoint (ejemplo: GET /auth/me)
echo -n "3. Protected endpoint... "
ME_RESPONSE=$(curl -s http://localhost:8010/auth/me \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

echo $ME_RESPONSE | grep -q '"email"' && echo "✅" || (echo "❌ $ME_RESPONSE" && exit 1)

echo "✅ ALL API SMOKE TESTS PASSED"
