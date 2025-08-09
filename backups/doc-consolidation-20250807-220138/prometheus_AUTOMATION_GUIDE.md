# Prometheus Automation Guide (Pure Bliss)

## Overview
This guide documents the automation, configuration, and operational procedures for the Pure Bliss Prometheus container, including HTTPS enforcement, Vault AppRole integration, and dynamic config management.

## Features
- HTTPS enforced on port 9091 (self-signed fallback, Vault PKI ready)
- Vault AppRole authentication for secrets (if credentials provided)
- Dynamic reload of prometheus.yml on config change
- Healthcheck via /-/healthy endpoint (wget, HTTPS)
- All actions logged to /opt/my-secure-ha-stack/logs/dev-environment-setup.log

## Entrypoint
- `/opt/dev-purebliss/services/prometheus/entrypoint-https.sh` (copied as /entrypoint.sh in container)

## HTTPS Setup
- Certs loaded from `/etc/prometheus/certs/tls.crt` and `tls.key`
- If missing, self-signed cert is generated at startup
- Web config: `/etc/prometheus/certs/web-config.yml`

## Vault Integration
- If `VAULT_ROLE_ID` and `VAULT_SECRET_ID` are set, authenticates to Vault and exports `VAULT_TOKEN`
- Logs success/failure to central log

## Config Management
- Watches `/etc/prometheus/prometheus.yml` for changes
- Triggers Prometheus reload via HTTPS POST to /-/reload

## Health Validation
- Healthcheck: `wget -q --spider https://localhost:9091/-/healthy --no-check-certificate`
- Use `/opt/dev-purebliss/validate-container-health.sh prometheus https-enforcement` after build or config change

## Logging
- All actions, errors, and reloads are logged to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`

## Security
- HTTPS enforced for all UI/API access
- No hardcoded secrets; Vault dynamic secrets only
- Container named `purebliss-prometheus`

## Troubleshooting
- Check central log for errors
- Validate certs in `/etc/prometheus/certs/`
- Use health validation script after any change

## References
- See `/opt/dev-purebliss/PROJECT_PLAN_ENHANCED.md` for enhancement roadmap
- See `/opt/my-secure-ha-stack/logs/dev-environment-setup.log` for all actions
