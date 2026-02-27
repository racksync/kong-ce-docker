# Research: Kong CE + Konga Integration

**Feature**: 001-kong-konga-integration
**Date**: 2026-02-27

## Research Tasks

### 1. Kong CE Current Version and Features

**Decision**: Use Kong CE 3.9.x (latest stable)

**Rationale**:
- Kong 3.9 is the latest stable Community Edition as of February 2026
- Includes improved PostgreSQL 16 support
- Better performance and memory management vs 3.6
- Active security patches and community support

**Alternatives Considered**:
- Kong 3.6 (current in repo): Older, fewer features, still supported but not latest
- Kong 3.x earlier versions: Missing recent improvements
- Kong Enterprise: Requires license, out of scope for this project

### 2. Konga Deployment Best Practices

**Decision**: Use pantsel/konga:latest with dedicated PostgreSQL database

**Rationale**:
- Konga requires persistent storage for its connections and user configurations
- Separate database from Kong's database prevents schema conflicts
- PostgreSQL adapter is more reliable than SQLite for production
- Environment variable configuration aligns with constitution Principle IV

**Alternatives Considered**:
- Konga with SQLite: Not suitable for production, no concurrent access
- Shared database with Kong: Schema conflicts possible, poor separation of concerns
- Kong Manager (Enterprise): Requires Kong Enterprise license

**Konga Environment Variables**:
```
NODE_ENV=production
TOKEN_SECRET=<generated-secret>
DB_ADAPTER=postgres
DB_HOST=konga-database
DB_PORT=5432
DB_USER=konga
DB_PASSWORD=konga
DB_DATABASE=konga
KONGA_HOOK_TIMEOUT=120000
```

### 3. PostgreSQL Configuration for Dual Databases

**Decision**: Single PostgreSQL container with two databases (kong, konga)

**Rationale**:
- Simpler deployment (one database container vs two)
- Shared backup/restore procedures
- Easier resource management
- Databases are independent (no cross-queries)

**Alternatives Considered**:
- Two separate PostgreSQL containers: More complex, higher resource usage
- Single database with schemas: Kong doesn't support custom schemas well

**Database Initialization**:
- Use POSTGRES_MULTIPLE_DATABASES approach or init scripts
- Create both `kong` and `konga` databases on first startup

### 4. Health Check Patterns

**Decision**: Implement Docker-native health checks for all services

**Rationale**:
- Docker Compose depends_on with condition: service_healthy
- Consistent with constitution Principle V
- Enables proper startup ordering without arbitrary sleep commands

**Health Check Commands**:
| Service | Check Command |
|---------|---------------|
| PostgreSQL | `pg_isready -U kong -d kong` |
| Kong | `kong health` (built-in) |
| Konga | HTTP GET on port 1337 (or use node health check) |

### 5. Backup and Restore Procedures

**Decision**: Shell scripts using pg_dump/psql via docker exec

**Rationale**:
- Native PostgreSQL tools are most reliable
- Works with any PostgreSQL version
- SQL dumps are portable and version-independent
- Simple automation via shell scripts

**Backup Script Structure**:
```bash
#!/bin/bash
# backup.sh
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
docker exec kong-database pg_dump -U kong kong > "backups/kong_${TIMESTAMP}.sql"
docker exec kong-database pg_dump -U konga konga > "backups/konga_${TIMESTAMP}.sql"
```

### 6. Upgrade Path Documentation

**Decision**: Document step-by-step migration procedure in README and upgrade.sh script

**Rationale**:
- Kong migrations must be run in specific order (up, then finish)
- Need to handle both minor and major version upgrades
- Clear documentation prevents data loss

**Upgrade Procedure**:
1. Backup databases
2. Update KONG_VERSION in .env
3. Run `docker-compose run --rm kong kong migrations up`
4. Run `docker-compose run --rm kong kong migrations finish`
5. Restart Kong: `docker-compose up -d kong`
6. Verify health and functionality

## Resolved Clarifications

All technical decisions resolved without user clarification needed:

| Item | Resolution |
|------|------------|
| Kong version | 3.9.x (latest stable) |
| Konga database | Separate database in same PostgreSQL instance |
| Health checks | Docker-native with pg_isready and kong health |
| Backup method | pg_dump via docker exec |
| Upgrade automation | upgrade.sh script + README documentation |

## Dependencies Identified

| Dependency | Purpose | Version |
|------------|---------|---------|
| Kong CE | API Gateway | 3.9 |
| Konga | Web GUI | latest (pantsel/konga) |
| PostgreSQL | Datastore | 16-alpine |
| Docker | Container runtime | 20.x+ |
| Docker Compose | Orchestration | 2.x+ |
