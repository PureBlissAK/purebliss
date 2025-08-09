# Loki Container Scaffolding (Pure Bliss)

**Generated:** 2025-08-08
**Purpose:** Loki log aggregation container for Pure Bliss stack
**Consolidation Type:** automation
**Services Covered:** Loki

## Overview
This directory contains the scaffolding for the Loki log aggregation container, following the Pure Bliss one-container-at-a-time methodology. Loki is configured for local development with persistent storage and robust health validation.

## Service-Specific Information
- **Image:** grafana/loki:2.9.0
- **Config:** `loki-config.yaml` (local, minimal, production-ready)
- **Health Check:** Inline nc command on `/ready` endpoint
- **Network:** purebliss-net (shared with other core services)
- **Volume:** loki-data (persistent log/index storage)
- **Ports:** 3100 (HTTP API)

## Usage

```bash
# Start Loki container
cd /opt/dev-purebliss/scaffolding/loki

docker compose -f docker-compose.loki.yml up -d

# Validate health
/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh purebliss-loki loki-initial-build
```

## Health Validation
- Docker health: `docker ps | grep purebliss-loki | grep healthy`
- Endpoint: `curl -f http://localhost:3100/ready`
- Restart test: `docker restart purebliss-loki && sleep 10 && curl -f http://localhost:3100/ready`
- Log validation: `docker logs purebliss-loki --since=5m | grep -i 'error\|critical\|fatal'`

## Documentation
- All steps and results must be logged to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`
- See `/opt/dev-purebliss/Documentation/automation/SCRIPT_REFERENCE_GUIDE.md` for script usage
- See `/opt/dev-purebliss/Documentation/automation/DONT_REINVENT_THE_WHEEL.md` for reusability guidelines

---
