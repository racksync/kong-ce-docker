#!/bin/bash
# =============================================================================
# Kong + Konga Restore Script
# =============================================================================
# Restore databases from backup files
# Usage: ./restore.sh <kong_backup.sql> [--konga <konga_backup.sql>]
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

KONG_BACKUP=""
KONGA_BACKUP=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --konga)
            KONGA_BACKUP="$2"
            shift 2
            ;;
        *)
            if [ -z "$KONG_BACKUP" ]; then
                KONG_BACKUP="$1"
            fi
            shift
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kong + Konga Database Restore${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ -z "$KONG_BACKUP" ]; then
    echo "Usage: $0 <kong_backup.sql> [--konga <konga_backup.sql>]"
    echo ""
    echo "Examples:"
    echo "  $0 backups/kong_20260227_120000.sql"
    echo "  $0 backups/kong_20260227_120000.sql --konga backups/konga_20260227_120000.sql"
    exit 1
fi

if [ ! -f "$KONG_BACKUP" ]; then
    echo -e "${RED}ERROR: Kong backup file not found: $KONG_BACKUP${NC}"
    exit 1
fi

if [ -n "$KONGA_BACKUP" ] && [ ! -f "$KONGA_BACKUP" ]; then
    echo -e "${RED}ERROR: Konga backup file not found: $KONGA_BACKUP${NC}"
    exit 1
fi

# Check if database container is running
if ! docker ps --filter "name=kong-database" --filter "status=running" | grep -q "kong-database"; then
    echo -e "${RED}ERROR: PostgreSQL container is not running${NC}"
    echo "Start the stack first: ./setup.sh"
    exit 1
fi

echo "Kong backup: $KONG_BACKUP"
[ -n "$KONGA_BACKUP" ] && echo "Konga backup: $KONGA_BACKUP"
echo ""

# WARNING: This is destructive
echo -e "${RED}⚠️  WARNING: This will REPLACE the current database content!${NC}"
echo "All existing services, routes, and plugins will be lost."
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm
if [[ ! "$confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

# Stop Kong and Konga to prevent database access during restore
echo ""
echo -e "${YELLOW}Stopping Kong and Konga services...${NC}"
docker compose stop kong konga

# Restore Kong database
echo ""
echo -e "${YELLOW}Restoring Kong database...${NC}"
# Drop and recreate to ensure clean restore
docker exec kong-database psql -U kong -d postgres -c "DROP DATABASE IF EXISTS kong;" 2>/dev/null || true
docker exec kong-database psql -U kong -d postgres -c "CREATE DATABASE kong OWNER kong;" 2>/dev/null || true
if cat "$KONG_BACKUP" | docker exec -i kong-database psql -U kong kong; then
    echo -e "${GREEN}✓ Kong database restored${NC}"
else
    echo -e "${RED}✗ Kong restore may have issues${NC}"
fi

# Restore Konga database if specified
if [ -n "$KONGA_BACKUP" ]; then
    echo ""
    echo -e "${YELLOW}Restoring Konga database...${NC}"
    docker exec kong-database psql -U kong -d postgres -c "DROP DATABASE IF EXISTS konga;" 2>/dev/null || true
    docker exec kong-database psql -U kong -d postgres -c "CREATE DATABASE konga OWNER konga;" 2>/dev/null || true
    if cat "$KONGA_BACKUP" | docker exec -i kong-database psql -U konga konga; then
        echo -e "${GREEN}✓ Konga database restored${NC}"
    else
        echo -e "${RED}✗ Konga restore may have issues${NC}"
    fi
fi

# Restart services
echo ""
echo -e "${YELLOW}Restarting services...${NC}"
docker compose start kong

# Wait for Kong to be healthy
echo -e "${YELLOW}Waiting for Kong to become healthy...${NC}"
for i in {1..30}; do
    if docker compose ps kong | grep -q "(healthy)"; then
        echo -e "${GREEN}✓ Kong is healthy${NC}"
        break
    fi
    echo "  Waiting... ($i/30)"
    sleep 5
done

docker compose start konga

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Restore complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Verify your configuration:"
echo "  curl http://localhost:8001/services"
echo "  curl http://localhost:8001/routes"
