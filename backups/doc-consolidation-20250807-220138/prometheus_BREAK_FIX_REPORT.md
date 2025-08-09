# Prometheus Break-Fix Report (Pure Bliss)

## Common Issues & Resolutions

### 1. HTTPS Not Working
- **Symptom:** Cannot access Prometheus UI on https://dev.purebliss.app/prometheus:9091
- **Resolution:**
  - Check if certs exist in `/etc/prometheus/certs/`. If missing, entrypoint will generate self-signed certs.
  - Review `/opt/my-secure-ha-stack/logs/dev-environment-setup.log` for errors.
  - Validate container health: `/opt/dev-purebliss/validate-container-health.sh prometheus https-enforcement`

### 2. Vault AppRole Authentication Fails
- **Symptom:** Logs show Vault AppRole authentication failed
- **Resolution:**
  - Ensure `VAULT_ROLE_ID` and `VAULT_SECRET_ID` are set in environment
  - Check Vault connectivity and policy
  - Review log for degraded mode warning

### 3. Config Reload Not Working
- **Symptom:** Changes to prometheus.yml do not take effect
- **Resolution:**
  - Confirm watcher is running (see logs)
  - POST to /-/reload endpoint manually to test
  - Check for errors in log

### 4. Healthcheck Fails
- **Symptom:** Container marked unhealthy
- **Resolution:**
  - Ensure HTTPS endpoint is up: `wget -q --spider https://localhost:9091/-/healthy --no-check-certificate`
  - Check logs for startup or cert errors

## Logging & Validation
- All actions and errors are logged to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`
- Always run health validation after changes

## References
- See `AUTOMATION_GUIDE.md` for full operational details
- See `/opt/dev-purebliss/PROJECT_PLAN_ENHANCED.md` for enhancement roadmap
