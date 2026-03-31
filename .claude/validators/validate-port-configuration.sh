#!/bin/bash

###############################################################################
# VALIDATOR: Port Configuration Enforcement
#
# Purpose: PREVENTS unauthorized port changes in code
#
# Validates that ports in code match runtime-infrastructure.json
#
# This validator runs:
# - Before commits (pre-commit hook)
# - Before reporting work complete
# - In CI/CD pipeline
#
# Exit Codes:
#   0 = Port configuration is valid
#   1 = UNAUTHORIZED port changes detected - BLOCKS commit/deployment
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUNTIME_CONFIG="$PROJECT_ROOT/.project-orchestration/runtime-infrastructure.json"

echo "============================================================"
echo "VALIDATOR: Port Configuration Enforcement"
echo "============================================================"
echo ""

if [ ! -f "$RUNTIME_CONFIG" ]; then
    echo "❌ CRITICAL: runtime-infrastructure.json NOT FOUND"
    echo "Cannot validate port configuration without official config"
    exit 1
fi

# Extract official ports from runtime-infrastructure.json
OFFICIAL_BACKEND_PORT=$(grep -A 10 '"service_name": "Backend API"' "$RUNTIME_CONFIG" | grep '"final_external_port"' | grep -oP '\d+')
OFFICIAL_FRONTEND_PORT=$(grep -A 10 '"service_name": "Frontend Application"' "$RUNTIME_CONFIG" | grep '"final_external_port"' | grep -oP '\d+')
OFFICIAL_DB_PORT=$(grep -A 10 '"service_name": "PostgreSQL Database"' "$RUNTIME_CONFIG" | grep '"final_external_port"' | grep -oP '\d+')
OFFICIAL_REDIS_PORT=$(grep -A 10 '"service_name": "Redis Cache"' "$RUNTIME_CONFIG" | grep '"final_external_port"' | grep -oP '\d+')

echo "Official Port Configuration (from runtime-infrastructure.json):"
echo "  Backend:  $OFFICIAL_BACKEND_PORT"
echo "  Frontend: $OFFICIAL_FRONTEND_PORT"
echo "  Database: $OFFICIAL_DB_PORT"
echo "  Redis:    $OFFICIAL_REDIS_PORT"
echo ""

ERRORS=0

# Validate backend/src/main.ts
echo "Validating backend/src/main.ts..."
if [ -f "$PROJECT_ROOT/backend/src/main.ts" ]; then
    BACKEND_PORT=$(grep -oP 'process\.env\.PORT \|\| \K\d+' "$PROJECT_ROOT/backend/src/main.ts" || echo "")

    if [ -n "$BACKEND_PORT" ] && [ "$BACKEND_PORT" != "$OFFICIAL_BACKEND_PORT" ]; then
        echo "❌ UNAUTHORIZED PORT CHANGE in backend/src/main.ts"
        echo "   Found: $BACKEND_PORT"
        echo "   Expected: $OFFICIAL_BACKEND_PORT (from runtime-infrastructure.json)"
        echo ""
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ backend/src/main.ts - Port matches official config"
    fi
fi

# Validate frontend/vite.config.ts
echo "Validating frontend/vite.config.ts..."
if [ -f "$PROJECT_ROOT/frontend/vite.config.ts" ]; then
    # Check frontend port
    VITE_PORT=$(grep -oP 'port:\s*\K\d+' "$PROJECT_ROOT/frontend/vite.config.ts" || echo "")

    if [ -n "$VITE_PORT" ] && [ "$VITE_PORT" != "$OFFICIAL_FRONTEND_PORT" ]; then
        echo "❌ UNAUTHORIZED PORT CHANGE in frontend/vite.config.ts (frontend port)"
        echo "   Found: $VITE_PORT"
        echo "   Expected: $OFFICIAL_FRONTEND_PORT (from runtime-infrastructure.json)"
        echo ""
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ frontend/vite.config.ts - Frontend port matches official config"
    fi

    # Check proxy target (backend port)
    PROXY_PORT=$(grep -oP 'target:\s*['"'"'"]http://localhost:\K\d+' "$PROJECT_ROOT/frontend/vite.config.ts" || echo "")

    if [ -n "$PROXY_PORT" ] && [ "$PROXY_PORT" != "$OFFICIAL_BACKEND_PORT" ]; then
        echo "❌ UNAUTHORIZED PORT CHANGE in frontend/vite.config.ts (proxy target)"
        echo "   Found: localhost:$PROXY_PORT"
        echo "   Expected: localhost:$OFFICIAL_BACKEND_PORT (from runtime-infrastructure.json)"
        echo ""
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ frontend/vite.config.ts - Proxy target matches official config"
    fi
fi

# Validate backend/.env files
for ENV_FILE in "$PROJECT_ROOT/backend/.env" "$PROJECT_ROOT/backend/.env.development" "$PROJECT_ROOT/backend/.env.example"; do
    if [ -f "$ENV_FILE" ]; then
        echo "Validating $(basename $ENV_FILE)..."

        # Check PORT
        if grep -q "^PORT=" "$ENV_FILE"; then
            ENV_PORT=$(grep "^PORT=" "$ENV_FILE" | cut -d'=' -f2)
            if [ "$ENV_PORT" != "$OFFICIAL_BACKEND_PORT" ]; then
                echo "❌ UNAUTHORIZED PORT in $ENV_FILE"
                echo "   Found: PORT=$ENV_PORT"
                echo "   Expected: PORT=$OFFICIAL_BACKEND_PORT"
                echo ""
                ERRORS=$((ERRORS + 1))
            else
                echo "✅ $(basename $ENV_FILE) - PORT matches official config"
            fi
        fi

        # Check DATABASE_PORT
        if grep -q "^DATABASE_PORT=" "$ENV_FILE"; then
            ENV_DB_PORT=$(grep "^DATABASE_PORT=" "$ENV_FILE" | cut -d'=' -f2)
            if [ "$ENV_DB_PORT" != "$OFFICIAL_DB_PORT" ]; then
                echo "❌ UNAUTHORIZED DATABASE_PORT in $ENV_FILE"
                echo "   Found: DATABASE_PORT=$ENV_DB_PORT"
                echo "   Expected: DATABASE_PORT=$OFFICIAL_DB_PORT"
                echo ""
                ERRORS=$((ERRORS + 1))
            else
                echo "✅ $(basename $ENV_FILE) - DATABASE_PORT matches official config"
            fi
        fi

        # Check REDIS_PORT
        if grep -q "^REDIS_PORT=" "$ENV_FILE"; then
            ENV_REDIS_PORT=$(grep "^REDIS_PORT=" "$ENV_FILE" | cut -d'=' -f2)
            if [ "$ENV_REDIS_PORT" != "$OFFICIAL_REDIS_PORT" ]; then
                echo "❌ UNAUTHORIZED REDIS_PORT in $ENV_FILE"
                echo "   Found: REDIS_PORT=$ENV_REDIS_PORT"
                echo "   Expected: REDIS_PORT=$OFFICIAL_REDIS_PORT"
                echo ""
                ERRORS=$((ERRORS + 1))
            else
                echo "✅ $(basename $ENV_FILE) - REDIS_PORT matches official config"
            fi
        fi
    fi
done

# Validate docker-compose.yml
if [ -f "$PROJECT_ROOT/docker-compose.yml" ]; then
    echo "Validating docker-compose.yml..."

    # Check backend port mapping
    DOCKER_BACKEND_PORT=$(grep -A 2 'backend:' "$PROJECT_ROOT/docker-compose.yml" | grep -oP '"\K\d+(?=:)' | head -1 || echo "")
    if [ -n "$DOCKER_BACKEND_PORT" ] && [ "$DOCKER_BACKEND_PORT" != "$OFFICIAL_BACKEND_PORT" ]; then
        echo "❌ UNAUTHORIZED PORT in docker-compose.yml (backend)"
        echo "   Found: $DOCKER_BACKEND_PORT"
        echo "   Expected: $OFFICIAL_BACKEND_PORT"
        echo ""
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ docker-compose.yml - Backend port matches official config"
    fi
fi

echo ""
echo "============================================================"

if [ $ERRORS -gt 0 ]; then
    echo "❌❌❌ PORT CONFIGURATION VALIDATION FAILED ❌❌❌"
    echo ""
    echo "UNAUTHORIZED port changes detected: $ERRORS error(s)"
    echo ""
    echo "⚠️  CRITICAL ENFORCEMENT:"
    echo "   - Ports MUST match runtime-infrastructure.json"
    echo "   - NO arbitrary port changes allowed"
    echo "   - This is a BLOCKING error"
    echo ""
    echo "To fix:"
    echo "  1. Review runtime-infrastructure.json for official ports"
    echo "  2. Update code to match official configuration"
    echo "  3. If ports MUST change, update runtime-infrastructure.json FIRST"
    echo "  4. Then update code to match"
    echo ""
    echo "============================================================"
    exit 1
fi

echo "✅✅✅ PORT CONFIGURATION VALID ✅✅✅"
echo ""
echo "All ports in code match runtime-infrastructure.json"
echo "No unauthorized changes detected"
echo "============================================================"

exit 0
