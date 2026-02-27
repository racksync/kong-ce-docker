# Data Model: Kong CE + Konga Integration

**Feature**: 001-kong-konga-integration
**Date**: 2026-02-27

## Overview

This deployment uses PostgreSQL with two independent databases:
1. **kong** - Kong CE configuration data
2. **konga** - Konga application data (connections, users, dashboards)

## Database Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   PostgreSQL 16                          │
│  (Container: kong-database)                              │
│                                                          │
│  ┌─────────────────────┐  ┌─────────────────────────┐   │
│  │   Database: kong    │  │   Database: konga       │   │
│  │                     │  │                         │   │
│  │  Kong CE schemas    │  │  Konga schemas          │   │
│  │  (managed by Kong   │  │  (managed by Konga      │   │
│  │   migrations)       │  │   waterline ORM)        │   │
│  └─────────────────────┘  └─────────────────────────┘   │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Kong Database Entities

*Note: Kong manages its own schema via migrations. The following are the key entities stored.*

### Kong Service
- **Purpose**: Represents an upstream API/service to proxy to
- **Key Attributes**:
  - `id`: UUID (primary key)
  - `name`: Unique identifier
  - `host`: Upstream host
  - `port`: Upstream port
  - `path`: Path prefix
  - `protocol`: http/https/grpc
  - `connect_timeout`: Connection timeout ms
  - `read_timeout`: Read timeout ms
  - `write_timeout`: Write timeout ms
  - `retries`: Number of retries
  - `created_at`, `updated_at`: Timestamps

### Kong Route
- **Purpose**: Maps incoming requests to Services
- **Key Attributes**:
  - `id`: UUID (primary key)
  - `name`: Optional identifier
  - `protocols`: ["http", "https"]
  - `hosts`: Host patterns
  - `paths`: Path patterns
  - `methods`: HTTP methods
  - `service`: Foreign key to Service
  - `strip_path`: Boolean
  - `preserve_host`: Boolean
  - `created_at`, `updated_at`: Timestamps

### Kong Plugin
- **Purpose**: Extends Kong functionality
- **Key Attributes**:
  - `id`: UUID
  - `name`: Plugin name (e.g., "rate-limiting", "jwt")
  - `config`: JSON configuration
  - `service`: Optional FK to Service
  - `route`: Optional FK to Route
  - `consumer`: Optional FK to Consumer
  - `enabled`: Boolean
  - `created_at`: Timestamp

### Kong Consumer
- **Purpose**: Entity that uses Kong routes
- **Key Attributes**:
  - `id`: UUID
  - `username`: Unique identifier
  - `custom_id`: Optional external ID
  - `created_at`: Timestamp

## Konga Database Entities

*Note: Konga uses Waterline ORM with auto-migration.*

### Konga User
- **Purpose**: Administrator account for Konga
- **Key Attributes**:
  - `id`: Auto-increment or UUID
  - `username`: Unique login name
  - `password`: Hashed password
  - `email`: Optional email
  - `active`: Boolean
  - `admin`: Boolean (super admin flag)
  - `createdAt`, `updatedAt`: Timestamps

### Konga Connection
- **Purpose**: Configuration linking Konga to Kong Admin API
- **Key Attributes**:
  - `id`: Auto-increment or UUID
  - `name`: Display name
  - `kong_admin_url`: URL to Kong Admin API
  - `kong_version`: Detected Kong version
  - `active`: Boolean (currently selected)
  - `createdAt`, `updatedAt`: Timestamps

### Konga Dashboard
- **Purpose**: Saved dashboard configurations
- **Key Attributes**:
  - `id`: Auto-increment or UUID
  - `name`: Dashboard name
  - `widgets`: JSON configuration
  - `connection`: FK to Connection
  - `createdAt`, `updatedAt`: Timestamps

## Data Relationships

```
┌─────────────────┐
│  Kong Service   │
└────────┬────────┘
         │ 1:N
         ▼
┌─────────────────┐       ┌─────────────────┐
│   Kong Route    │       │  Kong Plugin    │
└─────────────────┘       └────────┬────────┘
                                   │ N:M
         ┌─────────────────────────┼─────────────────────┐
         │                         │                     │
         ▼                         ▼                     ▼
┌─────────────────┐       ┌─────────────────┐   ┌───────────────┐
│  Kong Service   │       │   Kong Route    │   │ Kong Consumer │
└─────────────────┘       └─────────────────┘   └───────────────┘
```

## Storage Requirements

| Entity Type | Estimated Size per Record | Growth Rate |
|-------------|---------------------------|-------------|
| Service | ~500 bytes | Low (10s-100s) |
| Route | ~1 KB | Medium (100s-1000s) |
| Plugin | ~2 KB | Medium (depends on usage) |
| Consumer | ~200 bytes | High (depends on auth model) |

## Backup Strategy

Both databases should be backed together to maintain consistency:
- Full SQL dump of both databases
- Backup frequency: Daily for production, on-demand for dev
- Retention: 7 days rolling minimum

## Migration Strategy

- **Kong migrations**: Run via `kong migrations bootstrap` (initial) and `kong migrations up` (upgrades)
- **Konga migrations**: Automatic via Waterline ORM on startup
