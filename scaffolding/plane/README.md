# Plane Container Scaffolding (Pure Bliss)

**Generated:** 2025-08-08
**Purpose:** Plane issue tracking container for Pure Bliss stack
**Consolidation Type:** automation
**Services Covered:** Plane

## Overview
This directory contains the scaffolding for the Plane issue tracking container, following the Pure Bliss one-container-at-a-time methodology. Plane is configured for local development with PostgreSQL, Redis, and Vault integration, and robust health validation.

## Service-Specific Information
- **Image:** makeplane/plane:app-latest
- **Health Check:** Inline nc command on `/api/health` endpoint
- **Network:** purebliss-net (shared with other core services)
- **Ports:** 8082 (host) → 8080 (container)
- **Environment:**
  - PLANE_DATABASE_URL (PostgreSQL)
  - PLANE_REDIS_URL (Redis)
  - PLANE_SECRET_KEY (Vault integration recommended)
  - PLANE_VAULT_ADDR (Vault integration)

## Usage

```bash
# Start Plane container
cd /opt/dev-purebliss/scaffolding/plane

docker compose -f docker-compose.plane.yml up -d

# Validate health
/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh purebliss-plane plane-initial-build
```

## Health Validation
- Docker health: `docker ps | grep purebliss-plane | grep healthy`
- Endpoint: `curl -f http://localhost:8082/api/health`
- Restart test: `docker restart purebliss-plane && sleep 10 && curl -f http://localhost:8082/api/health`
- Log validation: `docker logs purebliss-plane --since=5m | grep -i 'error\|critical\|fatal'`

## Documentation
- All steps and results must be logged to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`
- See `/opt/dev-purebliss/Documentation/automation/SCRIPT_REFERENCE_GUIDE.md` for script usage
- See `/opt/dev-purebliss/Documentation/automation/DONT_REINVENT_THE_WHEEL.md` for reusability guidelines

---
