#!/bin/bash
# Smoke Test Script for Task Manager MVP

set -e

echo "========================================="
echo "Task Manager MVP - Smoke Test Suite"
echo "========================================="
echo ""

# Configuration
API_URL="${API_URL:-http://localhost:8010}"
FRONTEND_URL="${FRONTEND_URL:-http://localhost:3010}"
POSTGRES_PORT="${POSTGRES_PORT:-5434}"
REDIS_PORT="${REDIS_PORT:-6381}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Function to test endpoint
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_code="$3"

    echo -n "Testing $name... "

    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")

    if [ "$response_code" = "$expected_code" ]; then
        echo -e "${GREEN}✓ PASSED${NC} (HTTP $response_code)"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC} (Expected: $expected_code, Got: $response_code)"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function to test service connectivity
test_service() {
    local name="$1"
    local host="$2"
    local port="$3"

    echo -n "Testing $name connectivity... "

    # Use timeout command if available, otherwise use curl's timeout
    if command -v timeout >/dev/null 2>&1; then
        result=$(timeout 2 bash -c "echo > /dev/tcp/$host/$port" 2>&1)
    else
        result=$(bash -c "echo > /dev/tcp/$host/$port" 2>&1)
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ CONNECTED${NC} (Port $port)"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ NOT REACHABLE${NC} (Port $port)"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "1. INFRASTRUCTURE TESTS"
echo "------------------------"

# Test PostgreSQL connectivity
test_service "PostgreSQL" "localhost" "$POSTGRES_PORT"

# Test Redis connectivity
test_service "Redis" "localhost" "$REDIS_PORT"

echo ""
echo "2. BACKEND API TESTS"
echo "--------------------"

# Test backend health endpoint
test_endpoint "Backend Health" "$API_URL/health" "200"

# Test API docs endpoint
test_endpoint "API Documentation" "$API_URL/api/docs" "200"

# Test auth endpoints exist
test_endpoint "Auth Register Endpoint" "$API_URL/api/auth/register" "400"
test_endpoint "Auth Login Endpoint" "$API_URL/api/auth/login" "400"

echo ""
echo "3. FRONTEND TESTS"
echo "-----------------"

# Test frontend is accessible
test_endpoint "Frontend Homepage" "$FRONTEND_URL/" "200"

echo ""
echo "4. INTEGRATION TESTS"
echo "--------------------"

# Test user registration
echo -n "Testing User Registration... "
TIMESTAMP=$(date +%s)
TEST_EMAIL="test${TIMESTAMP}@example.com"
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/api/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"Test123!@#\",\"firstName\":\"Test\",\"lastName\":\"User\"}" \
    2>/dev/null || echo "{}")

if echo "$REGISTER_RESPONSE" | grep -q "id\|token\|success"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "Response: $REGISTER_RESPONSE"
    ((TESTS_FAILED++))
fi

# Test user login
echo -n "Testing User Login... "
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"Test123!@#\"}" \
    2>/dev/null || echo "{}")

if echo "$LOGIN_RESPONSE" | grep -q "accessToken\|token"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((TESTS_PASSED++))

    # Extract token for protected route test
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)

    if [ -n "$TOKEN" ]; then
        # Test protected route
        echo -n "Testing Protected Route... "
        ME_RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/api/auth/me" \
            -H "Authorization: Bearer $TOKEN" 2>/dev/null)

        HTTP_CODE=$(echo "$ME_RESPONSE" | tail -n 1)

        if [ "$HTTP_CODE" = "200" ]; then
            echo -e "${GREEN}✓ PASSED${NC}"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}✗ FAILED${NC} (HTTP $HTTP_CODE)"
            ((TESTS_FAILED++))
        fi
    fi
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "Response: $LOGIN_RESPONSE"
    ((TESTS_FAILED++))
fi

echo ""
echo "========================================="
echo "SMOKE TEST RESULTS"
echo "========================================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✓ ALL SMOKE TESTS PASSED!${NC}"
    echo "The Task Manager MVP is ready for use."
    exit 0
else
    echo -e "\n${YELLOW}⚠ SOME TESTS FAILED${NC}"
    echo "Please review the failed tests above."
    exit 1
fi