# Pure Bliss Container Naming Standards

## Overview
This document outlines the standardized naming conventions for Docker containers in the Pure Bliss development environment to ensure consistency, maintainability, and compliance with organizational standards.

## Standard Naming Convention

### Primary Pattern
All containers MUST follow the pattern: `purebliss-<service>`

### Examples of Correct Naming
- `purebliss-vault` - Vault secrets management service
- `purebliss-postgres` - PostgreSQL database service
- `purebliss-redis` - Redis caching service
- `purebliss-keycloak` - Keycloak authentication service
- `purebliss-nginx` - Nginx gateway/proxy service
- `purebliss-prometheus` - Prometheus metrics service
- `purebliss-grafana` - Grafana visualization service
- `purebliss-loki` - Loki logging service
- `purebliss-codeserver` - VS Code server development environment

### Service Variants and Extensions
For service variants or supporting containers, use descriptive suffixes:
- `purebliss-vault-agent` - Vault Agent sidecar
- `purebliss-postgres-exporter` - PostgreSQL metrics exporter
- `purebliss-nginx-simple` - Simplified Nginx configuration

## Naming Rules

### DO ✅
- Use lowercase letters only
- Use hyphens (-) to separate words
- Start with `purebliss-` prefix
- Use descriptive service names that match the actual service
- Be consistent across docker-compose files
- Match container names with service directories under `/opt/dev-purebliss/services/`

### DON'T ❌
- Use underscores (_) in container names
- Mix uppercase and lowercase letters
- Use generic names like `test-vault` or `vault-dev`
- Omit the `purebliss-` prefix
- Use temporary or development-specific suffixes in production configs

## Implementation Guidelines

### Docker Compose Files
Every `docker-compose.yml` file MUST include explicit `container_name` declarations:

```yaml
services:
  servicename:
    image: some-image:latest
    container_name: purebliss-servicename
    # ... other configuration
```

### Docker Run Commands
When using `docker run` directly, always specify the `--name` parameter:

```bash
docker run -d --name purebliss-servicename some-image:latest
```

### Container Discovery
This naming convention supports:
- Easy container identification: `docker ps | grep purebliss-`
- Service-specific operations: `docker logs purebliss-vault`
- Loki log queries: `{container_name="purebliss-vault"}`
- Prometheus metrics: `container_memory_usage_bytes{container_name="purebliss-vault"}`

## Service Directory Mapping

Container names should correspond to service directories:
```
/opt/dev-purebliss/services/vault/     → purebliss-vault
/opt/dev-purebliss/services/postgres/  → purebliss-postgres
/opt/dev-purebliss/services/redis/     → purebliss-redis
/opt/dev-purebliss/services/keycloak/  → purebliss-keycloak
/opt/dev-purebliss/services/nginx/     → purebliss-nginx
```

## Compliance Verification

### Quick Check Commands
```bash
# List all Pure Bliss containers
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep purebliss-

# Verify naming compliance
docker ps -a --format "{{.Names}}" | grep -v "purebliss-" | grep -v "NAMES"
```

### Automated Compliance
The start-all-services.sh script includes naming convention validation:
- Verifies all containers follow the `purebliss-<service>` pattern
- Logs violations to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`
- Prevents startup of non-compliant containers

## Common Issues and Fixes

### Issue: Containers with incorrect names
**Symptoms**: Containers named `vault-dev`, `test-postgres`, etc.

**Fix**:
```bash
# Stop and remove incorrectly named container
docker stop incorrect-name
docker rm incorrect-name

# Start with correct name
docker run -d --name purebliss-service correct-image:tag
```

### Issue: Missing container_name in docker-compose
**Symptoms**: Auto-generated container names like `services_vault_1`

**Fix**: Add explicit `container_name` to docker-compose.yml:
```yaml
services:
  vault:
    image: vault:latest
    container_name: purebliss-vault  # Add this line
```

## References
- Pure Bliss Copilot Instructions: `/opt/.github/copilot-instructions.md`
- SSL/TLS Compliance Project: `/opt/dev-purebliss/SSL_TLS_Compliance_Project.md`
- Service Documentation: `/opt/dev-purebliss/services/`

## Changelog
- 2025-08-06: Initial creation and standardization
- 2025-08-06: Fixed `purebliss-vault-dev` to `purebliss-vault` for compliance
