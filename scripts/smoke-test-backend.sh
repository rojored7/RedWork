#!/bin/bash
# scripts/smoke-test-backend.sh
# Smoke tests for backend functionality

set -e

echo "=== BACKEND SMOKE TESTS ==="

# 1. Health check
echo -n "1. Health check... "
HEALTH=$(curl -s http://localhost:8010/health)
echo $HEALTH | grep -q '"status":"ok"' && echo "✅" || (echo "❌" && exit 1)

# 2. Database connection
echo -n "2. Database connection... "
DB_HEALTH=$(curl -s http://localhost:8010/health/db)
echo $DB_HEALTH | grep -q '"database":{"status":"up"}' && echo "✅" || (echo "❌" && exit 1)

# 3. Redis connection
echo -n "3. Redis connection... "
REDIS_HEALTH=$(curl -s http://localhost:8010/health/redis)
echo $REDIS_HEALTH | grep -q '"redis":{"status":"up"}' && echo "✅" || (echo "❌" && exit 1)

echo "✅ ALL BACKEND SMOKE TESTS PASSED"
