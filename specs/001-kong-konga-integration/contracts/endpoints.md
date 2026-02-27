# Service Endpoints Contract

**Feature**: 001-kong-konga-integration
**Date**: 2026-02-27

## Overview

This document defines the network endpoints exposed by the Kong CE + Konga deployment stack.

## Endpoint Summary

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Kong Proxy | 8000 | HTTP | API proxy (incoming traffic) |
| Kong Proxy SSL | 8443 | HTTPS | Secure API proxy |
| Kong Admin API | 8001 | HTTP | Kong administration |
| Kong Admin SSL | 8444 | HTTPS | Secure Kong administration |
| Kong Manager | 8002 | HTTP | Kong built-in GUI (Enterprise feature, limited in CE) |
| Konga GUI | 1337 | HTTP | Third-party Kong management GUI |
| PostgreSQL | 5432 | TCP | Database (internal, optionally exposed) |

## Kong Proxy Endpoints

### HTTP Proxy
- **Port**: 8000 (configurable via `KONG_PROXY_HTTP_PORT`)
- **Protocol**: HTTP
- **Purpose**: Primary proxy for API requests
- **Contract**: Proxies requests to configured upstream services based on routes

### HTTPS Proxy
- **Port**: 8443 (configurable via `KONG_PROXY_HTTPS_PORT`)
- **Protocol**: HTTPS
- **Purpose**: Secure proxy for API requests
- **Contract**: Requires SSL certificate configuration

## Kong Admin API

### Admin HTTP
- **Port**: 8001 (configurable via `KONG_ADMIN_HTTP_PORT`)
- **Protocol**: HTTP
- **Purpose**: REST API for Kong configuration
- **Base URL**: `http://localhost:8001`

**Key Endpoints**:

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Kong version and configuration |
| GET | `/status` | Server status and metrics |
| GET | `/services` | List all services |
| POST | `/services` | Create a service |
| GET | `/services/{id}` | Get service details |
| PATCH | `/services/{id}` | Update service |
| DELETE | `/services/{id}` | Delete service |
| GET | `/routes` | List all routes |
| POST | `/routes` | Create a route |
| GET | `/routes/{id}` | Get route details |
| PATCH | `/routes/{id}` | Update route |
| DELETE | `/routes/{id}` | Delete route |
| GET | `/plugins` | List all plugins |
| POST | `/plugins` | Create a plugin |
| GET | `/plugins/{id}` | Get plugin details |
| PATCH | `/plugins/{id}` | Update plugin |
| DELETE | `/plugins/{id}` | Delete plugin |
| GET | `/consumers` | List all consumers |
| POST | `/consumers` | Create a consumer |
| GET | `/consumers/{id}` | Get consumer details |
| DELETE | `/consumers/{id}` | Delete consumer |

### Admin HTTPS
- **Port**: 8444 (configurable via `KONG_ADMIN_HTTPS_PORT`)
- **Protocol**: HTTPS
- **Purpose**: Secure admin access

## Konga GUI

### Web Interface
- **Port**: 1337 (configurable via `KONGA_PORT`)
- **Protocol**: HTTP
- **Purpose**: Web-based Kong management interface
- **Base URL**: `http://localhost:1337`

**Initial Setup Flow**:
1. First access presents setup screen
2. Create admin user account
3. Configure connection to Kong Admin API (http://kong:8001)
4. Dashboard displays Kong services, routes, plugins

## PostgreSQL

### Database Connection
- **Port**: 5432 (configurable via `POSTGRES_PORT`)
- **Protocol**: PostgreSQL wire protocol
- **Purpose**: Persistent storage for Kong and Konga
- **Security**: Should NOT be exposed in production

**Databases**:
- `kong`: Kong CE configuration
- `konga`: Konga application data

## Network Isolation

```
┌─────────────────────────────────────────────────────────────┐
│                        External                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                 Exposed Ports                         │   │
│  │  8000 (Proxy HTTP)  │  8443 (Proxy HTTPS)             │   │
│  │  8001 (Admin HTTP)  │  8444 (Admin HTTPS)             │   │
│  │  1337 (Konga GUI)   │  8002 (Kong Manager)            │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    kong-net (Docker Network)                 │
│                                                              │
│  ┌─────────┐    ┌─────────┐    ┌─────────────┐              │
│  │  Kong   │◄──►│ Konga   │◄──►│ PostgreSQL  │              │
│  │ :8000   │    │ :1337   │    │ :5432       │              │
│  │ :8001   │    │         │    │ (internal)  │              │
│  └─────────┘    └─────────┘    └─────────────┘              │
│                                                              │
│  Internal communication via container names                  │
└─────────────────────────────────────────────────────────────┘
```

## Configuration

All ports are configurable via environment variables in `.env`:

```env
# Kong Ports
KONG_PROXY_HTTP_PORT=8000
KONG_PROXY_HTTPS_PORT=8443
KONG_ADMIN_HTTP_PORT=8001
KONG_ADMIN_HTTPS_PORT=8444
KONG_MANAGER_PORT=8002

# Konga Port
KONGA_PORT=1337

# PostgreSQL Port (optional, for external access)
POSTGRES_PORT=5432
```
