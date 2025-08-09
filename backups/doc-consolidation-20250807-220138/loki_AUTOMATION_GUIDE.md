# Loki Vault Integration & RAID Migration Automation Guide

## Overview
This guide documents the end-to-end automation, integration, and validation workflow for securing Loki with Vault dynamic secrets, migrating storage to RAID, and ensuring data safety and operational continuity.

---

## 1. Prerequisites
- Loki container and config present in `/opt/dev-purebliss/services/loki/`
- Vault server operational with AppRole and KV secrets engine
- RAID storage mounted at `/raid-storage/loki` on the host
- Backup directory: `/opt/dev-purebliss/services/loki/backup/`
- Central log: `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`

---

## 2. Vault Integration Steps
1. **Validate Vault Health:**
   - Entrypoint script checks `/v1/sys/health` from within the Loki container.
2. **AppRole Authentication:**
   - Entrypoint fetches `role_id` and `secret_id` from Vault, issues token for Loki.
3. **Dynamic Secret Sourcing:**
   - Loki config and entrypoint source all credentials from Vault at startup; no hardcoded secrets.
4. **Audit Logging:**
   - All Vault actions (success/denied) are logged in Vault audit log.
5. **Health Validation:**
   - Run `/opt/dev-purebliss/validate-container-health.sh loki vault-integration` (exit code 0 required).

---

## 3. RAID Migration & Data Safety
1. **Backup Existing Data:**
   - `docker cp purebliss-loki:/loki /opt/dev-purebliss/services/loki/backup/<timestamp>-pre-raid-migration`
2. **Patch Config for RAID:**
   - Update all Loki storage/index paths to `/raid-storage/loki` in `local-config.yaml`.
3. **Update .gitignore:**
   - Add `/raid-storage/` to `.gitignore` to prevent accidental commits.
4. **Mount RAID in Container:**
   - Run Loki with `-v /raid-storage/loki:/raid-storage/loki`.
5. **Validate Storage:**
   - `docker exec purebliss-loki ls -lR /raid-storage/loki`

---

## 4. Integration Testing
1. **Log Ingestion Test:**
   - `curl -XPOST http://localhost:3100/loki/api/v1/push ...` (expect 204)
2. **Log Query Test:**
   - `curl http://localhost:3100/loki/api/v1/query?query={job="test"}` (expect log data)
3. **Label/Job Query:**
   - `curl http://localhost:3100/loki/api/v1/labels`
   - `curl http://localhost:3100/loki/api/v1/label/job/values`
4. **Secret Rotation Test:**
   - Restart Loki container, validate new Vault token and log access.
5. **Health Validation:**
   - `/opt/dev-purebliss/validate-container-health.sh loki raid-migration`

---

## 5. Logging & Documentation
- All actions, root causes, and fixes must be logged to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`.
- Update `BREAK_FIX_REPORT.md` with any issues and resolutions.
- Mark tasks as complete in `PROJECT_PLAN_ENHANCED.md`.

---

## 6. Rollback Procedure
- If migration fails, restore from backup:
  - `docker cp /opt/dev-purebliss/services/loki/backup/<timestamp>-pre-raid-migration/. purebliss-loki:/loki/`
- Restart Loki and re-validate health.

---

## 7. References
- [VAULT_AUTOMATION_GUIDE.md](../vault/VAULT_AUTOMATION_GUIDE.md)
- [vault-break-fix-report.md](../vault/vault-break-fix-report.md)
- [PROJECT_PLAN_ENHANCED.md](../../PROJECT_PLAN_ENHANCED.md)

---

# Loki Automation Guide (Pure Bliss Elite Standards)

## Overview
This guide documents the automation, enhancement, and troubleshooting steps for the Loki service in the Pure Bliss stack, following all organizational and security standards.

## Key Files
- Dockerfile: `/opt/dev-purebliss/container-builds/Dockerfile.loki`
- Entrypoint: `/opt/dev-purebliss/services/loki/entrypoint.sh`
- Config: `/opt/dev-purebliss/services/loki/local-config.yaml`
- Scaffold: `/opt/dev-purebliss/container-scaffold.sh`
- Central Log: `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`

## Enhancement & Troubleshooting Log
- 2025-08-07: Build errors (package manager, permissions, COPY) resolved via multi-phase Dockerfile and container scaffolding.
- 2025-08-07: Health validation failed due to Loki not using intended config. Root cause: ENTRYPOINT not overridden. Fix: Patch Dockerfile to set ENTRYPOINT ["/usr/bin/loki", "-config.file=/etc/loki/local-config.yaml"].
- 2025-08-07: Manual container run confirms Loki starts, but health endpoint not ready. Further investigation required.

## Health Validation
- All builds and config changes must be validated with `/opt/dev-purebliss/validate-container-health.sh loki <task>`.
- Health endpoint: `http://localhost:3100/ready` (must return 200 for healthy).
- All validation results must be logged to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`.

## Best Practices
- Never hardcode secrets; use Vault for all credentials.
- Use the container scaffolding framework for all enhancements.
- Document all root causes and fixes in this guide and the central log.
- After resolving any recurring issue, enhance scripts to prevent recurrence.

## Next Steps
- Complete ENTRYPOINT override and validate health endpoint.
- Document any further fixes or enhancements here.
- Update BREAK_FIX_REPORT.md with any new root causes and prevention steps.

## Vault Integration (2025-08-07)

### Overview
Loki is now fully integrated with HashiCorp Vault using dynamic secrets and AppRole authentication. All credentials are sourced at runtime—no hardcoded secrets remain in config, scripts, or Dockerfile.

### Integration Steps
1. **Vault Health Validation**: Entrypoint checks `/v1/sys/health` at startup and logs results.
2. **AppRole Authentication**: Entrypoint sources `loki-vault-credentials.env` for Vault credentials, authenticates, and exports `VAULT_TOKEN`.
3. **Dynamic Secret Sourcing**: Entrypoint fetches storage credentials from Vault (`secret/data/loki/storage`), exports as env vars, and starts Loki with config referencing these vars.
4. **No Hardcoded Credentials**: All secrets are sourced at runtime; validated by grep and health validation scripts.
5. **Health Validation**: `/opt/dev-purebliss/validate-container-health.sh loki vault-integration` run after every change; exit code 0 required to proceed.
6. **Audit Logging**: All Vault actions are logged in Vault audit log (read-only policy expected for Loki).
7. **Upstream Notification**: Entrypoint notifies nginx of Loki readiness using `upstream-validation.sh`.

### Validation Results
- Loki container passes all health checks and Vault integration validation.
- No hardcoded secrets detected in any config or script.
- All actions, root causes, and fixes logged to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`.

### Troubleshooting
- Check `/loki/loki.log/loki-entrypoint.log` for entrypoint execution details.
- Check `/opt/my-secure-ha-stack/logs/dev-environment-setup.log` for integration and validation logs.
- If Vault authentication fails, verify AppRole credentials and Vault endpoint.
- If dynamic secrets are missing, check Vault policy and secret path.

### References
- [PROJECT_PLAN_ENHANCED.md](../PROJECT_PLAN_ENHANCED.md)
- [entrypoint.sh](entrypoint.sh)
- [local-config.yaml](local-config.yaml)
- [loki-vault-credentials.env](loki-vault-credentials.env)

---
_Last updated: 2025-08-07_
