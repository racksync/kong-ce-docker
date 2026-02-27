<!--
## Sync Impact Report

**Version change**: 0.0.0 → 1.0.0 (Initial constitution creation)

**Modified principles**: N/A (initial creation)

**Added sections**:
- Core Principles (5 principles)
  - I. Container-First Architecture
  - II. Database-Backed State Management
  - III. Security & Production Readiness
  - IV. Declarative Configuration
  - V. Observability & Maintainability
- Technology Stack (PostgreSQL, Docker, Kong CE, Konga)
- Development Workflow (TDD, health checks, backup procedures)

**Removed sections**: N/A

**Templates requiring updates**:
- .specify/templates/plan-template.md ✅ (no changes needed - constitution check section is generic)
- .specify/templates/spec-template.md ✅ (no changes needed - aligns with principles)
- .specify/templates/tasks-template.md ✅ (no changes needed - task structure compatible)

**Follow-up TODOs**: None
-->

# Kong Docker Constitution

## Core Principles

### I. Container-First Architecture

All components MUST be deployed as Docker containers orchestrated via Docker Compose. This principle ensures:

- **Reproducibility**: Identical deployments across development, staging, and production
- **Isolation**: Each service (Kong, Konga, PostgreSQL) runs in its own container with explicit dependencies
- **Scalability**: Container-based deployment enables horizontal scaling when needed
- **Portability**: Deployments work identically on any Docker-compatible platform

**Rationale**: Containerization is foundational to this project's mission of providing a consistent, portable Kong deployment solution.

### II. Database-Backed State Management

Kong CE MUST use PostgreSQL as the backing datastore (not declarative/DB-less mode). Konga MUST connect to the same or dedicated PostgreSQL instance for its configuration storage. This ensures:

- **Persistence**: All API gateway configurations survive container restarts
- **Consistency**: ACID-compliant storage for Kong and Konga state
- **Migrations**: Database migrations MUST be run before starting services (via `kong migrations`)
- **Backup**: Regular database backups are MANDATORY for production deployments

**Rationale**: For production-ready deployments with Konga GUI management, persistent database storage is essential for maintaining configuration state and enabling recovery.

### III. Security & Production Readiness

Security configurations MUST be production-viable by default with clear documentation for customization:

- **Credentials**: Default credentials in `.env` files MUST be changed before production deployment
- **Network Isolation**: Internal services (database) should not be exposed externally without explicit configuration
- **SSL/TLS**: Production deployments MUST use HTTPS for Admin API, Konga, and Proxy endpoints
- **Access Control**: Kong Admin API and Konga MUST be protected (network-level or authentication)
- **Secrets Management**: Sensitive values MUST be injected via environment variables, not hardcoded

**Rationale**: API gateways are security-critical infrastructure; insecure defaults create significant risk.

### IV. Declarative Configuration

Infrastructure and service configuration MUST be declarative and version-controlled:

- **Environment Files**: All configurable values MUST be defined in `.env` files (never hardcoded in compose files)
- **Docker Compose**: Service definitions, networks, and volumes MUST be declared explicitly
- **Version Pinning**: All image versions (Kong, PostgreSQL, Konga) MUST be explicitly pinned
- **Documentation**: Configuration changes MUST be documented in README and inline comments

**Rationale**: Declarative, version-controlled configuration enables reproducibility, auditing, and rollback capabilities.

### V. Observability & Maintainability

Deployments MUST include health verification, monitoring endpoints, and maintenance procedures:

- **Health Checks**: All services MUST have Docker health checks configured
- **Status Endpoints**: Kong's `/status` endpoint MUST be accessible for monitoring
- **Backup Procedures**: Database backup commands MUST be documented and tested
- **Upgrade Path**: Version upgrade procedures MUST be documented (migrations up/finish)
- **Logging**: Container logs MUST be accessible via `docker logs` for debugging

**Rationale**: Production systems require visibility into health and well-defined maintenance procedures for reliability.

## Technology Stack

### Core Components

| Component | Purpose | Version Constraint |
|-----------|---------|-------------------|
| Kong CE | API Gateway (proxy, admin, plugins) | Pinned in `.env` (e.g., `3.x`) |
| Konga | Web GUI for Kong management | Latest stable |
| PostgreSQL | Primary datastore for Kong and Konga | 14-alpine (or newer) |
| Docker | Container runtime | 20.x+ |
| Docker Compose | Orchestration | 2.x+ |

### Network Architecture

- **kong-net**: Internal network for Kong, Konga, and database communication
- Port mappings MUST be configurable via environment variables
- Default ports: Proxy (8000/8443), Admin API (8001), Kong Manager (8002), Konga (1337)

### Storage

- **kong-data**: Docker volume for PostgreSQL persistence
- Volume backup procedures MUST be documented for disaster recovery

## Development Workflow

### Setup Requirements

1. Copy `default.env` to `.env` and customize values
2. Run `./setup.sh` or follow manual deployment steps
3. Verify all services are healthy via health checks

### Configuration Changes

1. Modify `.env` file for variable changes
2. Modify `docker-compose.yml` only for structural changes
3. Restart affected services: `docker-compose up -d <service>`
4. Document changes in README if they affect common workflows

### Version Upgrades

1. Update version pin in `.env`
2. Run migrations: `docker-compose run --rm kong kong migrations up`
3. Finish migrations: `docker-compose run --rm kong kong migrations finish`
4. Restart services: `docker-compose up -d`

### Backup & Recovery

- **Database backup**: `docker exec kong-database pg_dump -U kong kong > backup.sql`
- **Database restore**: `cat backup.sql | docker exec -i kong-database psql -U kong kong`
- Test restore procedures in non-production environment first

## Governance

### Amendment Process

1. Propose changes via pull request with justification
2. Update constitution version following semantic versioning:
   - **MAJOR**: Breaking principle changes or removals
   - **MINOR**: New principles or expanded guidance
   - **PATCH**: Clarifications and wording improvements
3. Update dependent templates if constitution changes affect them
4. Document all amendments in Sync Impact Report

### Compliance

- All new features MUST align with Core Principles
- Security-related changes MUST be reviewed against Principle III
- Infrastructure changes MUST be reviewed against Principle IV
- Pull requests MUST reference which principles are affected

### Versioning

Constitution versions follow semantic versioning (MAJOR.MINOR.PATCH). The version number MUST be updated with every amendment.

**Version**: 1.0.0 | **Ratified**: 2026-02-27 | **Last Amended**: 2026-02-27
