#!/bin/bash
# scripts/validate-wave.sh <wave_number>
# Validate completion of a specific wave

set -e

WAVE=$1

if [ -z "$WAVE" ]; then
  echo "Usage: ./validate-wave.sh <wave_number>"
  echo "Example: ./validate-wave.sh 3"
  exit 1
fi

echo "=== VALIDATING WAVE $WAVE ==="

case $WAVE in
  1)
    echo "Wave 1: Infrastructure"
    ./scripts/health-check.sh
    docker-compose ps | grep -q "healthy" || (echo "❌ Services not healthy" && exit 1)
    echo "✅ WAVE 1 VALIDATED"
    ;;

  2)
    echo "Wave 2: Domain Layer"
    cd backend
    npm test -- --testPathPattern="domain" || (echo "❌ Domain tests failed" && exit 1)
    npm test -- --coverage --testPathPattern="domain" | grep -q "80" || (echo "❌ Coverage <80%" && exit 1)
    cd ..
    echo "✅ WAVE 2 VALIDATED"
    ;;

  3)
    echo "Wave 3: Application Layer"
    cd backend
    npm test -- --testPathPattern="use-cases|services" || (echo "❌ Application tests failed" && exit 1)
    cd ..
    ./scripts/smoke-test-backend.sh || (echo "❌ Backend not running" && exit 1)
    echo "✅ WAVE 3 VALIDATED"
    ;;

  4)
    echo "Wave 4: API Layer"
    cd backend
    npm test -- --testPathPattern="controllers|dto|guards" || (echo "❌ API tests failed" && exit 1)
    cd ..
    ./scripts/smoke-test-api.sh || (echo "❌ API smoke tests failed" && exit 1)
    echo "✅ WAVE 4 VALIDATED"
    ;;

  5)
    echo "Wave 5: Frontend"
    cd frontend
    npm test -- --run || (echo "❌ Frontend tests failed" && exit 1)
    npm run build || (echo "❌ Frontend build failed" && exit 1)
    cd ..
    ./scripts/smoke-test-frontend.sh || (echo "❌ Frontend smoke tests failed" && exit 1)
    npm run test:e2e || (echo "❌ E2E tests failed" && exit 1)
    echo "✅ WAVE 5 VALIDATED"
    ;;

  *)
    echo "Invalid wave number: $WAVE"
    echo "Valid waves: 1, 2, 3, 4, 5"
    exit 1
    ;;
esac

echo "✅ WAVE $WAVE VALIDATION COMPLETE"
