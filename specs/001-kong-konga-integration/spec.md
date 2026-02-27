# Feature Specification: Kong CE + Konga Integration

**Feature Branch**: `001-kong-konga-integration`
**Created**: 2026-02-27
**Status**: Draft
**Input**: User description: "update this repository to match current version / match architecture"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Deploy Complete API Gateway Stack (Priority: P1)

As a DevOps engineer, I want to deploy a complete API gateway stack with a single command so that I can quickly set up production-ready infrastructure for managing APIs.

**Why this priority**: This is the core MVP - without a working deployment, all other features are useless. Users need a working system first.

**Independent Test**: Can be fully tested by running `./setup.sh` and verifying all services (Kong, Konga, PostgreSQL) are healthy and accessible via their respective endpoints.

**Acceptance Scenarios**:

1. **Given** a clean environment with Docker installed, **When** I run `./setup.sh`, **Then** all containers start successfully and health checks pass
2. **Given** the deployment is complete, **When** I access the Kong Admin API at port 8001, **Then** I receive a valid response with Kong version information
3. **Given** the deployment is complete, **When** I access Konga GUI at port 1337, **Then** I see the Konga dashboard and can configure a connection to Kong

---

### User Story 2 - Manage APIs via Web GUI (Priority: P2)

As an API administrator, I want to manage Kong configuration through a web-based GUI (Konga) so that I can create services, routes, and plugins without using command-line tools.

**Why this priority**: Web GUI management significantly improves user experience and reduces the learning curve for Kong administration. Builds on P1.

**Independent Test**: Can be tested by accessing Konga, creating a connection to Kong, and verifying CRUD operations on services and routes work correctly.

**Acceptance Scenarios**:

1. **Given** Konga is running, **When** I access the dashboard and create a new Kong connection, **Then** the connection is saved and I can view Kong's configured services
2. **Given** a Kong connection is configured, **When** I create a new service through Konga, **Then** the service appears in both Konga and Kong Admin API
3. **Given** a service exists, **When** I add a route through Konga, **Then** requests to that route are proxied correctly by Kong

---

### User Story 3 - Upgrade Kong Version (Priority: P3)

As a platform engineer, I want to upgrade Kong to the latest version while preserving all configuration so that I can stay current with security patches and new features.

**Why this priority**: Version upgrades are important for long-term maintenance but not required for initial deployment. Builds on P1 and P2.

**Independent Test**: Can be tested by changing the version variable, running migration commands, and verifying all existing services/routes are preserved.

**Acceptance Scenarios**:

1. **Given** Kong is running an older version with configured services, **When** I update the version and run migrations, **Then** Kong starts with the new version and all services remain functional
2. **Given** migrations are in progress, **When** I check migration status, **Then** I can see which migrations have been applied
3. **Given** an upgrade is complete, **When** I test existing routes, **Then** all routing behavior remains unchanged

---

### User Story 4 - Backup and Restore Configuration (Priority: P4)

As a site reliability engineer, I want to backup and restore the Kong configuration database so that I can recover from failures or migrate to new infrastructure.

**Why this priority**: Disaster recovery is essential for production but can be implemented after core functionality is stable.

**Independent Test**: Can be tested by creating a backup, making configuration changes, restoring the backup, and verifying the original state is restored.

**Acceptance Scenarios**:

1. **Given** Kong has configured services and routes, **When** I run the backup command, **Then** a SQL dump file is created containing all configuration data
2. **Given** a backup file exists, **When** I run the restore command on a fresh database, **Then** all services and routes from the backup are restored
3. **Given** a restore is complete, **When** I test restored routes, **Then** they behave identically to the pre-backup state

---

### Edge Cases

- What happens when PostgreSQL runs out of disk space?
- How does the system handle a Konga container crash while database writes are in progress?
- What happens if Kong migrations fail partway through?
- How does the system behave when the database container is stopped while Kong is processing requests?
- What happens if environment variables contain special characters or are malformed?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST deploy Kong CE (Community Edition) version 3.9 or newer with PostgreSQL 16 database
- **FR-002**: System MUST deploy Konga web GUI with its own PostgreSQL database for storing Konga configuration
- **FR-003**: System MUST provide a single setup script (`setup.sh`) that initializes all services in correct dependency order
- **FR-004**: System MUST include health checks for all containers (Kong, Konga, both PostgreSQL instances)
- **FR-005**: System MUST expose Kong Admin API on configurable port (default 8001)
- **FR-006**: System MUST expose Kong Proxy on configurable ports (default 8000 HTTP, 8443 HTTPS)
- **FR-007**: System MUST expose Konga web GUI on configurable port (default 1337)
- **FR-008**: System MUST persist all data in Docker volumes that survive container restarts
- **FR-009**: System MUST support environment-based configuration via `.env` file
- **FR-010**: System MUST provide backup and restore scripts for PostgreSQL databases
- **FR-011**: System MUST run database migrations automatically during initial setup
- **FR-012**: System MUST isolate all services on a dedicated Docker network
- **FR-013**: System MUST include documented upgrade procedures for version changes

### Key Entities

- **Kong Service**: An upstream API/service that Kong proxies to; has name, URL, and configuration
- **Kong Route**: A path/pattern that maps incoming requests to a Service; has path, methods, and hosts
- **Kong Plugin**: Extends Kong functionality (rate limiting, authentication, etc.); attached to services or routes
- **Kong Consumer**: An entity that uses Kong routes; can have authentication credentials and plugin configurations
- **Konga Connection**: Configuration linking Konga to a Kong Admin API endpoint
- **Konga User**: An administrator account in Konga with permissions to manage Kong configuration

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Complete stack deployment completes in under 3 minutes from `./setup.sh` execution
- **SC-002**: All four services (Kong DB, Konga DB, Kong, Konga) pass health checks within 60 seconds of startup
- **SC-003**: Administrators can create a new service and route through Konga in under 2 minutes
- **SC-004**: Database backup completes in under 30 seconds for configurations with up to 100 services
- **SC-005**: 100% of existing routes remain functional after version upgrade when following documented procedure
- **SC-006**: Setup script succeeds on first run with no manual intervention on a clean Docker environment

## Assumptions

- Docker and Docker Compose are pre-installed on the target system
- Sufficient system resources available (minimum 2GB RAM, 10GB disk)
- Network ports 8000, 8001, 8002, 8443, 8444, 5432, 1337 are available or can be reconfigured
- Users have basic familiarity with API gateway concepts
- Production deployments will implement additional security (TLS certificates, network isolation, authentication)
