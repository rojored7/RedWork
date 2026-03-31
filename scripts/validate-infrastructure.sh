#!/bin/bash
set -e

echo "🔍 Validando Infraestructura Sprint 1 con TDD..."
echo ""

# PostgreSQL
echo "1️⃣  PostgreSQL (puerto 5434)..."
docker exec taskmanager-postgres psql -U taskmanager_user -d taskmanager_dev -c "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'user_management';" -t | grep -q "[1-9]" && echo "   ✅ PostgreSQL: Connected + Tables exist" || (echo "   ❌ PostgreSQL: FAILED" && exit 1)

# Redis
echo "2️⃣  Redis (puerto 6381)..."
docker exec taskmanager-redis redis-cli PING | grep -q "PONG" && echo "   ✅ Redis: PONG" || (echo "   ❌ Redis: FAILED" && exit 1)

# Mailhog
echo "3️⃣  Mailhog (puertos 1025/8025)..."
curl -s -o /dev/null -w "%{http_code}" http://localhost:8025 | grep -q "200" && echo "   ✅ Mailhog: UI accessible" || (echo "   ❌ Mailhog: FAILED" && exit 1)

echo ""
echo "🎉 Infraestructura Sprint 1: 100% Funcional"
echo ""
echo "📊 Resumen:"
echo "   - PostgreSQL: localhost:5434 ✅"
echo "   - Redis: localhost:6381 ✅"
echo "   - Mailhog: localhost:8025 ✅"
echo ""
echo "✅ GATE 1 APROBADO - Listo para Backend Development"