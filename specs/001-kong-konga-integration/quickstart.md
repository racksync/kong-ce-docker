# Quickstart: Kong CE + Konga Integration

**Feature**: 001-kong-konga-integration
**Date**: 2026-02-27

## Prerequisites

- Docker 20.x or later
- Docker Compose 2.x or later
- 2GB RAM minimum
- 10GB disk space minimum
- Ports available: 8000, 8001, 8002, 8443, 8444, 5432, 1337

## Quick Start (5 minutes)

### 1. Clone and Configure

```bash
# Clone the repository
git clone <repository-url>
cd kong-docker

# Copy default environment file
cp default.env .env

# Edit configuration (optional)
vim .env
```

### 2. Deploy the Stack

```bash
# Run the automated setup script
./setup.sh
```

The setup script will:
1. Start PostgreSQL database
2. Initialize both databases (kong, konga)
3. Run Kong migrations
4. Start Kong gateway
5. Start Konga GUI

### 3. Verify Deployment

```bash
# Check all containers are running
docker-compose ps

# Expected output: 4 containers with "(healthy)" status
```

### 4. Access the Services

| Service | URL | Purpose |
|---------|-----|---------|
| Kong Proxy | http://localhost:8000 | API proxy |
| Kong Admin API | http://localhost:8001 | Kong management |
| Konga GUI | http://localhost:1337 | Web management interface |

### 5. Configure Konga (First Time Only)

1. Open http://localhost:1337 in your browser
2. Create an admin account
3. Add a new Kong connection:
   - Name: `local-kong`
   - Kong Admin URL: `http://kong:8001`
4. Start managing your APIs through the GUI

## Manual Deployment (Step by Step)

If you prefer manual control:

```bash
# 1. Start the database
docker-compose up -d kong-database

# 2. Wait for database to be healthy
while ! docker-compose ps kong-database | grep -q "(healthy)"; do sleep 2; done

# 3. Run Kong migrations
docker-compose run --rm kong-migrations

# 4. Start Kong
docker-compose up -d kong

# 5. Wait for Kong to be healthy
while ! docker-compose ps kong | grep -q "(healthy)"; do sleep 2; done

# 6. Start Konga
docker-compose up -d konga

# 7. Verify all services
docker-compose ps
```

## Common Operations

### Create a Service and Route

Via Konga GUI:
1. Navigate to Services → Add Service
2. Enter service details (name, host, port)
3. Add a route to the service
4. Test the route

Via Admin API:
```bash
# Create a service
curl -i -X POST http://localhost:8001/services \
  -d "name=example-service" \
  -d "url=http://httpbin.org"

# Create a route
curl -i -X POST http://localhost:8001/services/example-service/routes \
  -d "paths[]=/example"

# Test the route
curl http://localhost:8000/example/anything
```

### Backup Configuration

```bash
# Run backup script
./backup.sh

# Backups saved to ./backups/ directory
ls -la backups/
```

### Restore Configuration

```bash
# Restore from backup file
./restore.sh backups/kong_20260227_120000.sql
```

### Upgrade Kong Version

```bash
# 1. Backup first
./backup.sh

# 2. Update version in .env
# KONG_VERSION=3.9

# 3. Run upgrade script
./upgrade.sh

# Or manually:
docker-compose run --rm kong kong migrations up
docker-compose run --rm kong kong migrations finish
docker-compose up -d kong
```

### Stop the Stack

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes all data)
docker-compose down -v
```

## Troubleshooting

### Container won't start

```bash
# Check logs
docker-compose logs kong
docker-compose logs konga
docker-compose logs kong-database

# Check container status
docker-compose ps
```

### Database connection issues

```bash
# Verify database is running
docker-compose ps kong-database

# Check database connectivity
docker exec kong-database pg_isready -U kong
```

### Konga can't connect to Kong

1. Verify Kong is healthy: `curl http://localhost:8001/status`
2. In Konga, use internal Docker network URL: `http://kong:8001` (not localhost)
3. Check both containers are on the same network: `docker network inspect kong_kong-net`

### Port already in use

1. Check what's using the port: `lsof -i :8000`
2. Either stop the conflicting service or change the port in `.env`

## Next Steps

1. Add authentication plugins (Key Auth, JWT, OAuth2)
2. Configure rate limiting
3. Set up SSL/TLS certificates
4. Implement health checks for upstream services
5. Configure logging and monitoring
