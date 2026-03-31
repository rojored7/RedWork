#!/bin/bash
# scripts/integration-test.sh
# Run all integration tests

set -e

echo "=== INTEGRATION TESTS ==="

# 1. Levantar servicios de test
echo "Starting test services..."
docker-compose -f docker-compose.test.yml up -d
sleep 5

# 2. Ejecutar integration tests backend
echo "Running backend integration tests..."
cd backend
npm run test:integration || (echo "❌ Backend integration tests failed" && exit 1)
cd ..

# 3. Ejecutar E2E tests
echo "Running E2E tests..."
npm run test:e2e || (echo "❌ E2E tests failed" && exit 1)

# 4. Limpiar
echo "Cleaning up test services..."
docker-compose -f docker-compose.test.yml down

echo "✅ ALL INTEGRATION TESTS PASSED"
