#!/bin/bash
# =============================================================================
# Kong Upgrade Script
# =============================================================================
# Safely upgrade Kong to a new version with database backup and migrations
# Usage: ./upgrade.sh [new_version]
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

NEW_VERSION="${1:-}"
CURRENT_VERSION=$(grep -E "^KONG_VERSION=" .env 2>/dev/null | cut -d'=' -f2 || echo "3.9")

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kong Version Upgrade${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ -z "$NEW_VERSION" ]; then
    echo -e "${YELLOW}Usage: $0 <new_version>${NC}"
    echo "Current version: $CURRENT_VERSION"
    echo ""
    echo "Example: $0 3.10"
    exit 1
fi

echo "Current version: $CURRENT_VERSION"
echo "Target version:  $NEW_VERSION"
echo ""

# Confirm upgrade
read -p "Continue with upgrade? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Upgrade cancelled."
    exit 0
fi

# Step 1: Backup
echo ""
echo -e "${YELLOW}Step 1: Creating backup...${NC}"
if [ -f ./backup.sh ]; then
    ./backup.sh
else
    echo -e "${RED}WARNING: backup.sh not found. Creating manual backup...${NC}"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    mkdir -p backups
    docker exec kong-database pg_dump -U kong kong > "backups/kong_pre_upgrade_${TIMESTAMP}.sql"
    echo "Backup saved to: backups/kong_pre_upgrade_${TIMESTAMP}.sql"
fi

# Step 2: Update version in .env
echo ""
echo -e "${YELLOW}Step 2: Updating .env with new version...${NC}"
if grep -q "^KONG_VERSION=" .env; then
    sed -i.bak "s/^KONG_VERSION=.*/KONG_VERSION=${NEW_VERSION}/" .env
else
    echo "KONG_VERSION=${NEW_VERSION}" >> .env
fi
echo -e "${GREEN}✓ KONG_VERSION updated to ${NEW_VERSION}${NC}"

# Step 3: Pull new image
echo ""
echo -e "${YELLOW}Step 3: Pulling Kong ${NEW_VERSION} image...${NC}"
docker compose pull kong

# Step 4: Run migrations up
echo ""
echo -e "${YELLOW}Step 4: Running migrations up...${NC}"
docker compose run --rm kong kong migrations up --vv
echo -e "${GREEN}✓ Migrations up completed${NC}"

# Step 5: Finish migrations
echo ""
echo -e "${YELLOW}Step 5: Finishing migrations...${NC}"
docker compose run --rm kong kong migrations finish --vv
echo -e "${GREEN}✓ Migrations finished${NC}"

# Step 6: Restart Kong
echo ""
echo -e "${YELLOW}Step 6: Restarting Kong service...${NC}"
docker compose up -d kong

# Step 7: Wait for health check
echo ""
echo -e "${YELLOW}Step 7: Waiting for Kong to become healthy...${NC}"
for i in {1..30}; do
    if docker compose ps kong | grep -q "(healthy)"; then
        echo -e "${GREEN}✓ Kong is healthy!${NC}"
        break
    fi
    echo "  Waiting... ($i/30)"
    sleep 5
done

# Step 8: Verify
echo ""
echo -e "${YELLOW}Step 8: Verifying upgrade...${NC}"
VERSION=$(curl -s http://localhost:8001 | grep -o '"version":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
echo -e "${GREEN}Kong version: $VERSION${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Upgrade complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "If something went wrong, restore from backup:"
echo "  ./restore.sh backups/kong_pre_upgrade_*.sql"
