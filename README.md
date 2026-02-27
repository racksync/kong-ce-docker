# 🐳 Kong CE + Konga Docker Deployment

Kong CE (Community Edition) API Gateway with Konga web GUI - deployed with Docker Compose and PostgreSQL.

## Overview

This deployment provides a complete API gateway solution with:
- **Kong CE 3.9+**: High-performance API gateway with plugin ecosystem
- **Konga**: Web-based GUI for Kong administration
- **PostgreSQL 16**: Persistent storage for Kong configuration

### Features

| Feature | Description |
|---------|-------------|
| 🔐 Authentication | JWT, Key Auth, OAuth2, and more |
| 📊 Rate Limiting | Control API usage and prevent abuse |
| 🔄 Traffic Control | Canary releases, request/response transformations |
| 📈 Analytics | Request logging and monitoring |
| 🔌 Plugin System | Extend functionality with 80+ plugins |
| ⚖️ Load Balancing | Distribute traffic across upstream services |
| 🏥 Health Checks | Monitor upstream service health |
| 🍎 Apple Silicon | Native support for M1/M2/M3 Macs |

## Architecture

```
    ┌─────────────────────────────────────────────────────────────────────────┐
    │                           External Clients                               │
    │            (Web Apps, Mobile Apps, IoT Devices, Partners)               │
    └───────────────────────────────────┬─────────────────────────────────────┘
                                        │
                                        ▼
    ┌─────────────────────────────────────────────────────────────────────────┐
    │                              Kong Gateway                                │
    │  ┌─────────────────────────────────────────────────────────────────┐    │
    │  │  Kong Proxy (API Gateway)                                        │    │
    │  │  :8000 (HTTP)  :8443 (HTTPS)                                     │    │
    │  │                                                                  │    │
    │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │    │
    │  │  │ Rate     │ │ Auth     │ │ Transform│ │ Logging  │            │    │
    │  │  │ Limit    │ │ (JWT/Key)│ │          │ │          │            │    │
    │  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘            │    │
    │  └─────────────────────────────────────────────────────────────────┘    │
    │                                                                          │
    │  ┌─────────────────────┐    ┌─────────────────────┐                     │
    │  │ Kong Admin API      │    │ Konga Web GUI       │                     │
    │  │ :8001 (HTTP)        │    │ :1337               │                     │
    │  │ :8444 (HTTPS)       │    │ (Admin Dashboard)   │                     │
    │  └──────────┬──────────┘    └──────────┬──────────┘                     │
    │             │                          │                                │
    │             ▼                          │                                │
    │  ┌─────────────────────────┐           │                                │
    │  │   PostgreSQL 16         │           │                                │
    │  │   DB: kong              │           │                                │
    │  │   (Routes, Services,    │           │                                │
    │  │    Plugins, etc.)      │           │                                │
    │  └─────────────────────────┘           ▼                                │
    │                             ┌─────────────────────┐                     │
    │                             │ Konga localDB       │                     │
    │                             │ (SQLite - embedded) │                     │
    │                             │ (Users, Connections)│                     │
    │                             └─────────────────────┘                     │
    │                                                                          │
    └───────────────────────────────────┬──────────────────────────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
                    ▼                   ▼                   ▼
    ┌───────────────────────┐ ┌───────────────────────┐ ┌───────────────────────┐
    │   Upstream Services   │ │   Upstream Services   │ │   Upstream Services   │
    │                       │ │                       │ │                       │
    │  🌐 Web Application   │ │  📱 Mobile API        │ │  🔌 External API      │
    │  http://webapp:3000   │ │  http://mobile-api:80 │ │  https://api.partner  │
    └───────────────────────┘ └───────────────────────┘ └───────────────────────┘
```

## Quick Start

### Prerequisites

- Docker 20.x+
- Docker Compose 2.x+
- Ports available: 8000, 8001, 8002, 8443, 8444, 5432, 1337

### Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux x86_64 | ✅ Fully Supported | Native AMD64 images |
| Linux ARM64 | ✅ Fully Supported | Native ARM64 images |
| macOS Intel | ✅ Fully Supported | Native AMD64 images |
| macOS Apple Silicon (M1/M2/M3) | ✅ Supported | Konga uses Rosetta 2 |

### Deploy

```bash
# 1. Copy environment file
cp default.env .env

# 2. Run setup script
./setup.sh
```

The setup script will:
1. Start PostgreSQL database
2. Run Kong migrations
3. Start Kong gateway
4. Start Konga GUI

### Access Services

| Service | URL | Purpose |
|---------|-----|---------|
| Kong Proxy | http://localhost:8000 | API proxy endpoint |
| Kong Admin API | http://localhost:8001 | REST API for configuration |
| Konga GUI | http://localhost:1337 | Web management interface |

### First-Time Konga Setup

1. Open http://localhost:1337
2. Create an admin account
3. Add a new Kong connection:
   - **Name**: `local-kong`
   - **Kong Admin URL**: `http://kong:8001` (use internal Docker network)
4. Start managing your APIs through the GUI!

## Configuration

### Environment Variables

Copy `default.env` to `.env` and customize:

```bash
cp default.env .env
```

| Variable | Default | Description |
|----------|---------|-------------|
| **Kong Configuration** |||
| `KONG_VERSION` | 3.9 | Kong CE version |
| `KONG_PROXY_HTTP_PORT` | 8000 | Kong HTTP proxy port |
| `KONG_PROXY_HTTPS_PORT` | 8443 | Kong HTTPS proxy port |
| `KONG_ADMIN_HTTP_PORT` | 8001 | Kong Admin HTTP port |
| `KONG_ADMIN_HTTPS_PORT` | 8444 | Kong Admin HTTPS port |
| **Konga Configuration** |||
| `KONGA_PORT` | 1337 | Konga web UI port |
| `KONGA_TOKEN_SECRET` | *change-me* | Session secret (generate with `openssl rand -hex 32`) |
| **Database Configuration** |||
| `POSTGRES_VERSION` | 16-alpine | PostgreSQL version |
| `KONG_PG_USER` | kong | Kong database user |
| `KONG_PG_PASSWORD` | kong | Kong database password |
| `KONG_PG_DATABASE` | kong | Kong database name |

⚠️ **Security Warning**: Change all default passwords before production deployment!

> **Note**: Konga uses embedded SQLite (localDB) for its configuration storage, which is sufficient for development and single-instance deployments.

## Manual Deployment

If you prefer step-by-step deployment:

```bash
# 1. Start database
docker compose up -d kong-database

# 2. Wait for database to be healthy
while ! docker compose ps kong-database | grep -q "(healthy)"; do sleep 2; done

# 3. Run migrations
docker compose run --rm kong-migrations

# 4. Start Kong
docker compose up -d kong

# 5. Wait for Kong to be healthy
while ! docker compose ps kong | grep -q "(healthy)"; do sleep 2; done

# 6. Start Konga
docker compose up -d konga
```

## Operations

### Health Check

```bash
# Check all services
./scripts/health-check.sh

# Or manually
curl http://localhost:8001/status
```

### Backup Kong Database

```bash
# Create timestamped backup
./backup.sh

# Backups saved to ./backups/
```

### Restore Kong Database

```bash
# Restore from backup
./restore.sh backups/kong_20260227_120000.sql
```

### Upgrade Kong Version

```bash
# Upgrade to new version (with automatic backup)
./upgrade.sh 3.10
```

### Stop Services

```bash
# Stop all services
docker compose down

# Stop and remove all data (WARNING: destructive)
docker compose down -v
```

## Using Konga

### Creating Services and Routes via GUI

1. In Konga, navigate to **Services** → **Add Service**
2. Enter service details:
   - **Name**: `my-api`
   - **Host**: `api.example.com`
   - **Port**: `443`
   - **Protocol**: `https`
3. Add a route to the service:
   - **Paths**: `/api`
   - **Methods**: `GET, POST`
4. Test the route: `curl http://localhost:8000/api`

### Connection URL Notes

When configuring Kong connections in Konga:
- **Inside Docker network**: Use `http://kong:8001`
- **From host machine**: Use `http://localhost:8001`

## Platform Compatibility

### Linux

All scripts are written in POSIX-compliant bash and work on:
- Ubuntu 20.04+ / Debian 11+
- CentOS 8+ / RHEL 8+ / Rocky Linux 8+
- Amazon Linux 2023
- Alpine Linux

```bash
# Install Docker on Ubuntu/Debian
sudo apt update && sudo apt install -y docker.io docker-compose-plugin

# Run setup
./setup.sh
```

### macOS (Apple Silicon M1/M2/M3)

Konga uses Rosetta 2 emulation (configured automatically in docker-compose.yml):

```bash
# Ensure Rosetta 2 is enabled (Docker Desktop > Settings > General)
# Then run normally
./setup.sh
```

## Troubleshooting

### Container won't start

```bash
# Check container logs
docker compose logs kong
docker compose logs konga
docker compose logs kong-database

# Check container status
docker compose ps
```

### Database connection issues

```bash
# Verify database is running
docker compose ps kong-database

# Test database connectivity
docker exec kong-database pg_isready -U kong
```

### Konga can't connect to Kong

1. Verify Kong is running: `curl http://localhost:8001/status`
2. In Konga, use the internal Docker URL: `http://kong:8001`
3. Check network: `docker network inspect kong_kong-net`

### Reset Konga (forgot password)

```bash
# Stop and remove Konga data, then restart
docker compose down konga && docker volume rm kong_konga_data
docker compose up -d konga
```

### Port already in use

```bash
# Find what's using the port
lsof -i :8000

# Either stop the conflicting service or change port in .env
```

## Security Considerations

For production deployments:

- ✅ Change all default passwords in `.env`
- ✅ Use HTTPS for all external connections
- ✅ Implement network segmentation (don't expose database port)
- ✅ Apply Kong security plugins (rate limiting, IP restriction)
- ✅ Enable authentication on Konga
- ✅ Regular security updates
- ✅ Restrict access to Admin API (port 8001)

## Files Structure

```
kong-docker/
├── docker-compose.yml      # Main orchestration
├── default.env             # Default environment variables
├── setup.sh                # Automated setup script
├── backup.sh               # Database backup script
├── restore.sh              # Database restore script
├── upgrade.sh              # Kong upgrade script
├── scripts/
│   ├── health-check.sh     # Health verification
│   ├── wait-for.sh         # Service readiness helper
│   └── init-databases.sh   # PostgreSQL init script
├── config/
│   └── kong.yaml           # Optional declarative config
└── backups/                # Backup storage (created on first backup)
```

## Documentation

- [Kong Documentation](https://docs.konghq.com/gateway/latest/)
- [Konga GitHub](https://github.com/pantsel/konga)
- [Kong Plugin Hub](https://docs.konghq.com/hub/)

## 🏢 [RACKSYNC CO., LTD.](https://racksync.com)

RACKSYNC Co., Ltd. specializes in automation and smart solutions. We provide comprehensive consulting and implementation services for API gateways, microservices architecture, and enterprise integrations.

📍 Suratthani, Thailand 84000
📧 Email: devops@racksync.com
📞 Tel: +66 85 880 8885

[![GitHub](https://img.shields.io/github/followers/racksync?style=for-the-badge)](https://github.com/racksync)
[![Website](https://img.shields.io/website?down_color=grey&down_message=Offline&style=for-the-badge&up_color=green&up_message=Online&url=https%3A%2F%2Fracksync.com)](https://racksync.com)
