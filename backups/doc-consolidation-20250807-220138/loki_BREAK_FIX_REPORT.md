# Loki Vault Integration & RAID Migration: Break-Fix Report

## 1. Issue: Loki Not Using Intended Config
- **Root Cause:** Dockerfile did not override ENTRYPOINT; Loki defaulted to internal config.
- **Fix:** Set ENTRYPOINT to `/usr/bin/loki -config.file=/etc/loki/local-config.yaml` in Dockerfile.
- **Prevention:** Always set ENTRYPOINT explicitly for custom configs.

## 2. Issue: Data Loss Risk During RAID Migration
- **Root Cause:** Migration to RAID storage could overwrite or lose existing data.
- **Fix:** Performed full backup with `docker cp` before migration.
- **Prevention:** Mandatory backup step before any storage migration.

## 3. Issue: RAID Storage Not Mounted in Container
- **Root Cause:** Docker run command missing `-v /raid-storage/loki:/raid-storage/loki`.
- **Fix:** Updated run command to mount RAID storage.
- **Prevention:** Validate all required volumes are mounted before container start.

## 4. Issue: Log Ingestion Succeeds, Query Fails
- **Root Cause:** Initial misconfiguration of storage path and volume mount; Loki could not write/read logs.
- **Fix:** Patched config, fixed volume mount, re-tested ingestion and query.
- **Prevention:** Validate storage accessibility and run end-to-end ingestion/query tests after migration.

## 5. Issue: Health Validation/Secret Rotation Fails
- **Root Cause:** Entrypoint or config errors, or Vault token not refreshed.
- **Fix:** Enhanced entrypoint to validate Vault health, AppRole, and dynamic secret access before starting Loki.
- **Prevention:** Health validation script checks all Vault and storage dependencies before startup.

---

## Logging
All actions, root causes, and fixes are logged to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`.

---

## References
- [AUTOMATION_GUIDE.md](AUTOMATION_GUIDE.md)
- [PROJECT_PLAN_ENHANCED.md](../../PROJECT_PLAN_ENHANCED.md)

# Loki Break-Fix Report (Pure Bliss Elite Standards)

## Recent Issues & Root Causes

### 2025-08-07: Loki Not Using Intended Config File
- **Symptom:** Container started, but health endpoint failed and logs showed Loki was not using `/etc/loki/local-config.yaml`.
- **Root Cause:** Dockerfile used CMD, but Loki image has ENTRYPOINT set, so CMD was ignored. Loki defaulted to internal config.
- **Resolution:** Patched Dockerfile to override ENTRYPOINT with `["/usr/bin/loki", "-config.file=/etc/loki/local-config.yaml"]`.
- **Validation:** Manual run confirmed Loki starts, but health endpoint still not ready. Further investigation required.
- **Prevention:** Always use ENTRYPOINT override for config-driven services. Documented in AUTOMATION_GUIDE.md and central log.

### 2025-08-07: Vault Integration - Dynamic Secrets & Zero Hardcoded Credentials
- **Symptom:** Need to eliminate all hardcoded credentials and securely source Loki storage secrets at runtime.
- **Root Cause:** Prior config/scripts required static credentials for storage backend.
- **Resolution:**
    - Entrypoint authenticates to Vault using AppRole, fetches dynamic secrets, and exports as env vars.
    - Loki config references these env vars for S3/minio storage.
    - No static secrets remain in config, scripts, or Dockerfile.
    - All actions and validation steps logged to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`.
- **Validation:**
    - `/opt/dev-purebliss/validate-container-health.sh loki vault-integration` passes (exit code 0).
    - grep confirms no hardcoded secrets in config/scripts.
- **Prevention:**
    - All future Loki enhancements must use Vault dynamic secrets for credentials.
    - Health validation and entrypoint scripts updated to enforce this standard.
    - Documented in AUTOMATION_GUIDE.md and central log.

## Preventive Enhancements
- All future Loki builds must set ENTRYPOINT for config file.
- Health validation script to check for config usage in logs.
- Log all root causes and fixes to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`.

## Next Steps
- Investigate health endpoint readiness delay.
- Update health validation and entrypoint scripts if new root causes are found.

---

_Last updated: 2025-08-07_
