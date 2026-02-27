#!/bin/bash
# health-check.sh - Verify all services are healthy
# Usage: ./scripts/health-check.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "=== Kong Docker Health Check ==="
echo ""

# Check if docker-compose is available
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed"
    exit 1
fi

# Function to check container health
check_container() {
    local container="$1"
    local expected_status="${2:-healthy}"

    if docker ps --filter "name=^${container}$" --filter "health=${expected_status}" | grep -q "${container}"; then
        echo "✓ $container: $expected_status"
        return 0
    else
        echo "✗ $container: not $expected_status"
        return 1
    fi
}

# Function to check HTTP endpoint
check_http() {
    local url="$1"
    local name="$2"
    local expected_code="${3:-200}"

    if command -v curl &> /dev/null; then
        response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
        if [ "$response" = "$expected_code" ]; then
            echo "✓ $name: HTTP $response"
            return 0
        else
            echo "✗ $name: HTTP $response (expected $expected_code)"
            return 1
        fi
    else
        echo "? $name: curl not available"
        return 0
    fi
}

failed=0

echo "Container Health Status:"
echo "------------------------"

# Check containers
check_container "kong-database" "healthy" || failed=$((failed + 1))
check_container "kong" "healthy" || failed=$((failed + 1))
check_container "konga" "healthy" || failed=$((failed + 1))

echo ""
echo "HTTP Endpoint Status:"
echo "---------------------"

# Check Kong Admin API
check_http "http://localhost:8001" "Kong Admin API" "200" || failed=$((failed + 1))

# Check Kong Proxy
check_http "http://localhost:8000" "Kong Proxy" "200" || true  # May return 404 if no routes

# Check Konga
check_http "http://localhost:1337" "Konga GUI" "200" || failed=$((failed + 1))

echo ""
echo "=============================="
if [ "$failed" -gt 0 ]; then
    echo "RESULT: $failed check(s) failed"
    exit 1
else
    echo "RESULT: All checks passed!"
    exit 0
fi
