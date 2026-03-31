#!/bin/bash
# scripts/health-check.sh
# Health check for all services

set -e

echo "=== HEALTH CHECK ==="

# Backend
echo -n "Backend health... "
curl -f http://localhost:8010/health -s > /dev/null && echo "✅ OK" || (echo "❌ FAIL" && exit 1)

# Database
echo -n "Database health... "
curl -f http://localhost:8010/health/db -s > /dev/null && echo "✅ OK" || (echo "❌ FAIL" && exit 1)

# Redis
echo -n "Redis health... "
curl -f http://localhost:8010/health/redis -s > /dev/null && echo "✅ OK" || (echo "❌ FAIL" && exit 1)

# Frontend
echo -n "Frontend serving... "
curl -f http://localhost:3010 -s > /dev/null && echo "✅ OK" || (echo "❌ FAIL" && exit 1)

echo "✅ ALL HEALTH CHECKS PASSED"
