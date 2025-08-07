# Pure Bliss Grafana Enhancement: Automation & Break-Fix Guide

## Overview
This guide documents the automation, enhancement, and troubleshooting steps for the Pure Bliss Grafana container, focusing on HTTPS, Vault integration, and elite container standards. All actions are logged to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`.

## Enhancement Summary
- **HTTPS Support:** Entrypoint script (`vault-entrypoint.sh`) generates self-signed certs if Vault PKI is unavailable, ensuring HTTPS is always enabled.
- **Vault Integration:** All secrets and credentials are dynamically sourced from Vault. No hardcoded secrets in Dockerfile or scripts.
- **Container Build:** Multi-phase Dockerfile with progressive validation. All phases pass health checks.
- **Naming Standard:** Container is named `purebliss-grafana` and uses the `purebliss-net` network.
- **Health Validation:** After every build or config change, `/opt/dev-purebliss/validate-container-health.sh grafana enhancement` is run. Exit code 0 is required to proceed.
- **Upstream Notification:** Entrypoint supports smart upstream notification for Nginx integration.

## Validation Steps
1. Build enhanced container: `./container-scaffold.sh build grafana 6 --no-cache`
2. Validate health: `/opt/dev-purebliss/validate-container-health.sh grafana enhancement`
3. Test HTTPS endpoint: `curl -fk https://localhost:3000/`
4. Confirm logs: `tail -50 /opt/my-secure-ha-stack/logs/dev-environment-setup.log`

## Break-Fix Procedures
- **Build Fails (apt-get or COPY):**
  - Remove invalid RUN/COPY lines from Dockerfile. Use only relative paths.
  - Ensure all scripts are executable before build context is sent.
- **Entrypoint Permission Error:**
  - Remove `RUN chmod` from Dockerfile. Set executable bit on script in source.
- **HTTPS Not Working:**
  - Check `/etc/grafana/certs/` for certs. Entrypoint will auto-generate if missing.
  - Review logs for Vault PKI or OpenSSL errors.
- **Container Unhealthy:**
  - Run health validation script and review logs for root cause.

## Autonomous Script Enhancement
- All resolved issues result in Dockerfile or entrypoint script enhancements to prevent recurrence.
- Health validation and logging are updated after each fix.

## Compliance
- No hardcoded secrets. All credentials from Vault.
- All enhancements and fixes logged with timestamp and root cause.
- Documentation updated after each enhancement.

## Vault Dynamic Credentials Integration (2025-08-07)

### Overview
Grafana is now fully integrated with Vault dynamic database credentials. This integration eliminates all hardcoded passwords, provides automatic credential rotation, and serves as the gold standard template for all database-backed services in Pure Bliss.

### Key Achievements
- **Vault Database Secrets Engine:** Configured at `database/` path with `postgres-grafana` connection and `grafana-role`.
- **Dynamic Credentials:** Vault-generated user (e.g., `v-token-grafana--A47HkN3PLvLgvNlzsI5q-1754542313`) with 1-hour TTL.
- **Database Permissions:** Enhanced role with CREATE and schema permissions for dynamic users.
- **Container Integration:** Uses `GF_DATABASE_*` environment variables with Vault-sourced credentials.
- **Health Validation:** All integration steps validated with `/opt/dev-purebliss/validate-container-health.sh grafana vault-integration-final`.
- **Enhanced Troubleshooting:** `/opt/dev-purebliss/services/grafana/grafana-enhanced-troubleshoot.sh` created for root cause analysis and prevention of circular troubleshooting.

### Replicable Integration Pattern
1. **Database Setup:** Create service-specific database and user in PostgreSQL.
2. **Vault Secrets Engine:** Configure Vault connection and role with schema permissions.
3. **Container Integration:** Use Vault-generated credentials as environment variables.
4. **Validation:** Run health validation and test database permissions (e.g., table creation).
5. **Documentation:** Log all actions and update automation guides.

### Troubleshooting & Root Cause Analysis
- **Issue:** `pq: permission denied for schema public` during migrations.
- **Root Cause:** Dynamic users lacked schema creation permissions.
- **Solution:** Enhanced Vault database role with full schema and table privileges.
- **Prevention:** Pattern-based troubleshooting script and documentation update.

### Security & Compliance
- **Zero Hardcoded Passwords:** All credentials are dynamic and time-limited.
- **Least Privilege:** Database permissions scoped to Grafana database only.
- **Audit Trail:** All credential access logged in Vault.

### Template for All Services
This integration pattern is now the gold standard for all Pure Bliss services requiring database access. Replicate the steps above for Keycloak, Plane, Prometheus, Loki, and others.

_Last updated: 2025-08-07_
