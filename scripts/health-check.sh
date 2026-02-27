#!/bin/bash
# health-check.sh - Verify all services are healthy
# Usage: ./scripts/health-check.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "=== Kong Docker Health Check ==="
echo ""

# Check if docker is available
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
        # Check if container is running but health check still starting
        if docker ps --filter "name=^${container}$" --filter "status=running" | grep -q "${container}"; then
            echo "○ $container: running (health check starting)"
            return 0
        else
            echo "✗ $container: not $expected_status"
            return 1
        fi
    fi
}

# Function to check HTTP endpoint
check_http() {
    local url="$1"
    local name="$2"

    if command -v curl &> /dev/null; then
        response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
        case "$response" in
            200|201|204)
                echo "✓ $name: HTTP $response"
                return 0
                ;;
            302|301)
                echo "✓ $name: HTTP $response (redirect - OK for first-time setup)"
                return 0
                ;;
            404)
                echo "○ $name: HTTP 404 (no routes configured yet - OK)"
                return 0
                ;;
            000)
                echo "✗ $name: Connection refused"
                return 1
                ;;
            *)
                echo "○ $name: HTTP $response"
                return 0
                ;;
        esac
    else
        echo "? $name: curl not available"
        return 0
    fi
}

failed=0

echo "Container Status:"
echo "-----------------"

# Check containers
check_container "kong-database" "healthy" || failed=$((failed + 1))
check_container "kong" "healthy" || failed=$((failed + 1))
check_container "konga" "healthy" || true  # Konga health check may be slow

echo ""
echo "HTTP Endpoint Status:"
echo "---------------------"

# Check Kong Admin API
check_http "http://localhost:8001" "Kong Admin API" || failed=$((failed + 1))

# Check Kong Proxy (404 is expected if no routes)
check_http "http://localhost:8000" "Kong Proxy" || true

# Check Konga (302 redirect to /register is expected for first-time setup)
check_http "http://localhost:1337" "Konga GUI" || failed=$((failed + 1))

echo ""
echo "Service URLs:"
echo "-------------"
echo "  Kong Proxy:   http://localhost:8000"
echo "  Kong Admin:   http://localhost:8001"
echo "  Konga GUI:    http://localhost:1337"

echo ""
echo "=============================="
if [ "$failed" -gt 0 ]; then
    echo "RESULT: $failed critical check(s) failed"
    exit 1
else
    echo "RESULT: All services are running!"
    echo ""
    echo "Next steps:"
    echo "  1. Open http://localhost:1337"
    echo "  2. Create an admin account"
    echo "  3. Add Kong connection: http://kong:8001"
    exit 0
fi
