#!/usr/bin/env bash

# =============================================================================
# Kong CE + Konga Setup Script
# =============================================================================
# This script initializes and starts all services in the correct order.
# Usage: ./setup.sh [--skip-migrations]
#
# Prerequisites:
#   - Docker and Docker Compose must be installed
#   - Ports 8000-8002, 8443-8444, 5432, 1337 must be available
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

# Parse arguments
SKIP_MIGRATIONS=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-migrations)
            SKIP_MIGRATIONS=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--skip-migrations]"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kong CE + Konga Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker is not installed${NC}"
    exit 1
fi
if ! docker compose version &> /dev/null; then
    echo -e "${RED}ERROR: Docker Compose is not available${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker and Docker Compose are available${NC}"
echo ""

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env from default.env...${NC}"
    cp default.env .env
    echo -e "${GREEN}✓ .env created${NC}"
else
    echo -e "${GREEN}✓ .env already exists${NC}"
fi
echo ""

# Step 1: Start PostgreSQL database
echo -e "${YELLOW}Step 1: Starting PostgreSQL database...${NC}"
docker compose up -d kong-database
echo ""

# Step 2: Wait for database to be healthy
echo -e "${YELLOW}Step 2: Waiting for database to be healthy...${NC}"
for i in {1..30}; do
    if docker compose ps kong-database | grep -q "(healthy)"; then
        echo -e "${GREEN}✓ Database is healthy${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}ERROR: Database failed to become healthy${NC}"
        exit 1
    fi
    echo "  Waiting... ($i/30)"
    sleep 5
done
echo ""

# Step 3: Run Kong migrations
if [ "$SKIP_MIGRATIONS" = false ]; then
    echo -e "${YELLOW}Step 3: Running Kong migrations...${NC}"
    docker compose run --rm kong-migrations
    echo -e "${GREEN}✓ Migrations complete${NC}"
else
    echo -e "${YELLOW}Step 3: Skipping migrations (--skip-migrations)${NC}"
fi
echo ""

# Step 4: Start Kong
echo -e "${YELLOW}Step 4: Starting Kong gateway...${NC}"
docker compose up -d kong
echo ""

# Step 5: Wait for Kong to be healthy
echo -e "${YELLOW}Step 5: Waiting for Kong to be healthy...${NC}"
for i in {1..30}; do
    if docker compose ps kong | grep -q "(healthy)"; then
        echo -e "${GREEN}✓ Kong is healthy${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}ERROR: Kong failed to become healthy${NC}"
        exit 1
    fi
    echo "  Waiting... ($i/30)"
    sleep 5
done
echo ""

# Step 6: Start Konga
echo -e "${YELLOW}Step 6: Starting Konga GUI...${NC}"
docker compose up -d konga
echo ""

# Step 7: Wait for Konga to be ready
echo -e "${YELLOW}Step 7: Waiting for Konga to be ready...${NC}"
for i in {1..30}; do
    if curl -s http://localhost:1337 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Konga is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${YELLOW}Warning: Konga may still be starting. Check http://localhost:1337${NC}"
        break
    fi
    echo "  Waiting... ($i/30)"
    sleep 5
done
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Services are running:"
echo ""
echo "  🌐 Kong Proxy:"
echo "     HTTP:  http://localhost:8000"
echo "     HTTPS: https://localhost:8443"
echo ""
echo "  🔧 Kong Admin API:"
echo "     HTTP:  http://localhost:8001"
echo "     HTTPS: https://localhost:8444"
echo ""
echo "  🖥️  Konga Web GUI:"
echo "     http://localhost:1337"
echo ""
echo "First-time Konga setup:"
echo "  1. Open http://localhost:1337"
echo "  2. Create an admin account"
echo "  3. Add Kong connection with URL: http://kong:8001"
echo ""
echo "Health check:"
echo "  ./scripts/health-check.sh"
echo ""
