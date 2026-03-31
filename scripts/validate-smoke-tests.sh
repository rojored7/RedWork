#!/bin/bash

# Sprint 3 Smoke Test Validation Script
# This script performs comprehensive smoke testing for the Task Manager application

set -e

BACKEND_URL="http://localhost:8010"
FRONTEND_URL="http://localhost:3010"
TEST_EMAIL="smoke_test_$(date +%s)@test.com"
TEST_PASSWORD="Test123!@#"
TEST_NAME="Smoke Test"

echo "========================================="
echo "Sprint 3 Smoke Test Validation"
echo "========================================="
echo ""

# Function to check if service is running
check_service() {
    local service=$1
    local port=$2
    if netstat -an | grep -q ":$port.*LISTEN"; then
        echo "✅ $service is running on port $port"
        return 0
    else
        echo "❌ $service is NOT running on port $port"
        return 1
    fi
}

# Function to make API request
api_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local token=$4

    if [ -z "$token" ]; then
        if [ -z "$data" ]; then
            curl -s -X "$method" "$BACKEND_URL$endpoint" -w "\nHTTP_STATUS:%{http_code}\n"
        else
            curl -s -X "$method" "$BACKEND_URL$endpoint" \
                -H "Content-Type: application/json" \
                -d "$data" \
                -w "\nHTTP_STATUS:%{http_code}\n"
        fi
    else
        if [ -z "$data" ]; then
            curl -s -X "$method" "$BACKEND_URL$endpoint" \
                -H "Authorization: Bearer $token" \
                -w "\nHTTP_STATUS:%{http_code}\n"
        else
            curl -s -X "$method" "$BACKEND_URL$endpoint" \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $token" \
                -d "$data" \
                -w "\nHTTP_STATUS:%{http_code}\n"
        fi
    fi
}

echo "1. Infrastructure Validation"
echo "----------------------------"

# Check Docker services
echo "Checking Docker services..."
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "taskmanager|redis" || true
echo ""

# Check port availability
echo "Checking port availability..."
check_service "Backend" 8010
check_service "Frontend" 3010
check_service "PostgreSQL" 5434
check_service "Redis" 6381
echo ""

echo "2. Backend API Tests"
echo "--------------------"

# Test health endpoint
echo "Testing health endpoint..."
HEALTH_RESPONSE=$(api_request GET /health)
HTTP_STATUS=$(echo "$HEALTH_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Health check passed (HTTP $HTTP_STATUS)"
else
    echo "❌ Health check failed (HTTP $HTTP_STATUS)"
fi
echo ""

# Test user registration
echo "Testing user registration..."
REGISTER_DATA="{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"name\":\"$TEST_NAME\"}"
REGISTER_RESPONSE=$(api_request POST /api/auth/register "$REGISTER_DATA")
HTTP_STATUS=$(echo "$REGISTER_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
if [ "$HTTP_STATUS" = "201" ]; then
    echo "✅ Registration successful (HTTP $HTTP_STATUS)"
    USER_ID=$(echo "$REGISTER_RESPONSE" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
    echo "   User ID: $USER_ID"
else
    echo "❌ Registration failed (HTTP $HTTP_STATUS)"
fi
echo ""

# Test user login
echo "Testing user login..."
LOGIN_DATA="{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}"
LOGIN_RESPONSE=$(api_request POST /api/auth/login "$LOGIN_DATA")
HTTP_STATUS=$(echo "$LOGIN_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Login successful (HTTP $HTTP_STATUS)"
    JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
    echo "   Token received: ${JWT_TOKEN:0:20}..."
else
    echo "❌ Login failed (HTTP $HTTP_STATUS)"
fi
echo ""

# Test protected endpoint - Create task
echo "Testing task creation (protected endpoint)..."
TASK_DATA="{\"title\":\"Smoke Test Task\",\"description\":\"Automated smoke test\",\"priority\":\"HIGH\"}"
TASK_RESPONSE=$(api_request POST /tasks "$TASK_DATA" "$JWT_TOKEN")
HTTP_STATUS=$(echo "$TASK_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
if [ "$HTTP_STATUS" = "201" ]; then
    echo "✅ Task created successfully (HTTP $HTTP_STATUS)"
    TASK_ID=$(echo "$TASK_RESPONSE" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
    echo "   Task ID: $TASK_ID"
else
    echo "❌ Task creation failed (HTTP $HTTP_STATUS)"
fi
echo ""

# Test task retrieval
echo "Testing task retrieval..."
TASKS_RESPONSE=$(api_request GET /tasks "" "$JWT_TOKEN")
HTTP_STATUS=$(echo "$TASKS_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Tasks retrieved successfully (HTTP $HTTP_STATUS)"
else
    echo "❌ Task retrieval failed (HTTP $HTTP_STATUS)"
fi
echo ""

echo "3. Frontend Tests"
echo "-----------------"

# Test frontend availability
echo "Testing frontend availability..."
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL")
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo "✅ Frontend is accessible (HTTP $FRONTEND_STATUS)"
else
    echo "❌ Frontend is not accessible (HTTP $FRONTEND_STATUS)"
fi

# Check frontend title
FRONTEND_TITLE=$(curl -s "$FRONTEND_URL" | grep -o "<title>[^<]*</title>" | sed 's/<[^>]*>//g')
if [[ "$FRONTEND_TITLE" == *"Task Manager"* ]]; then
    echo "✅ Frontend title correct: $FRONTEND_TITLE"
else
    echo "❌ Frontend title incorrect: $FRONTEND_TITLE"
fi
echo ""

echo "========================================="
echo "Smoke Test Summary"
echo "========================================="
echo ""

# Count successes and failures
SUCCESSES=$(grep -c "✅" "$0" 2>/dev/null || echo "0")
FAILURES=$(grep -c "❌" "$0" 2>/dev/null || echo "0")

if [ "$FAILURES" -eq 0 ]; then
    echo "✅✅✅ ALL SMOKE TESTS PASSED ✅✅✅"
    echo ""
    echo "Sprint 3 is ready for completion!"
    exit 0
else
    echo "⚠️  SMOKE TESTS FAILED"
    echo "   Successes: $SUCCESSES"
    echo "   Failures: $FAILURES"
    echo ""
    echo "Please fix the failing tests before marking Sprint 3 complete."
    exit 1
fi