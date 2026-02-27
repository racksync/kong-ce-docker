#!/bin/bash
# =============================================================================
# Kong + Konga Backup Script
# =============================================================================
# Create timestamped backups of both Kong and Konga databases
# Usage: ./backup.sh [output_directory]
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

OUTPUT_DIR="${1:-backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kong + Konga Database Backup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Create backup directory
mkdir -p "$OUTPUT_DIR"

# Check if database container is running
if ! docker ps --filter "name=kong-database" --filter "status=running" | grep -q "kong-database"; then
    echo -e "${RED}ERROR: PostgreSQL container is not running${NC}"
    echo "Start the stack first: ./setup.sh"
    exit 1
fi

echo "Backup directory: $OUTPUT_DIR"
echo "Timestamp: $TIMESTAMP"
echo ""

# Backup Kong database
echo -e "${YELLOW}Backing up Kong database...${NC}"
KONG_BACKUP="${OUTPUT_DIR}/kong_${TIMESTAMP}.sql"
if docker exec kong-database pg_dump -U kong kong > "$KONG_BACKUP"; then
    SIZE=$(ls -lh "$KONG_BACKUP" | awk '{print $5}')
    echo -e "${GREEN}✓ Kong backup: $KONG_BACKUP ($SIZE)${NC}"
else
    echo -e "${RED}✗ Kong backup failed${NC}"
    rm -f "$KONG_BACKUP"
fi

# Backup Konga database
echo -e "${YELLOW}Backing up Konga database...${NC}"
KONGA_BACKUP="${OUTPUT_DIR}/konga_${TIMESTAMP}.sql"
if docker exec kong-database pg_dump -U konga konga > "$KONGA_BACKUP"; then
    SIZE=$(ls -lh "$KONGA_BACKUP" | awk '{print $5}')
    echo -e "${GREEN}✓ Konga backup: $KONGA_BACKUP ($SIZE)${NC}"
else
    echo -e "${RED}✗ Konga backup failed${NC}"
    rm -f "$KONGA_BACKUP"
fi

# Create combined backup info
BACKUP_INFO="${OUTPUT_DIR}/backup_${TIMESTAMP}.info"
cat > "$BACKUP_INFO" << EOF
Backup created: $(date)
Kong version: $(curl -s http://localhost:8001 2>/dev/null | grep -o '"version":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
PostgreSQL version: $(docker exec kong-database psql -V 2>/dev/null || echo "unknown")
Files:
  - $(basename "$KONG_BACKUP")
  - $(basename "$KONGA_BACKUP")
EOF

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Backup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Files created:"
echo "  - $KONG_BACKUP"
echo "  - $KONGA_BACKUP"
echo "  - $BACKUP_INFO"
echo ""
echo "To restore, use: ./restore.sh $KONG_BACKUP [--konga $KONGA_BACKUP]"
