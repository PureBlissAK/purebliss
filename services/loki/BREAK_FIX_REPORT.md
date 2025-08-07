# Loki Break-Fix Report (Pure Bliss Elite Standards)

## Recent Issues & Root Causes

### 2025-08-07: Loki Not Using Intended Config File
- **Symptom:** Container started, but health endpoint failed and logs showed Loki was not using `/etc/loki/local-config.yaml`.
- **Root Cause:** Dockerfile used CMD, but Loki image has ENTRYPOINT set, so CMD was ignored. Loki defaulted to internal config.
- **Resolution:** Patched Dockerfile to override ENTRYPOINT with `["/usr/bin/loki", "-config.file=/etc/loki/local-config.yaml"]`.
- **Validation:** Manual run confirmed Loki starts, but health endpoint still not ready. Further investigation required.
- **Prevention:** Always use ENTRYPOINT override for config-driven services. Documented in AUTOMATION_GUIDE.md and central log.

## Preventive Enhancements
- All future Loki builds must set ENTRYPOINT for config file.
- Health validation script to check for config usage in logs.
- Log all root causes and fixes to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`.

## Next Steps
- Investigate health endpoint readiness delay.
- Update health validation and entrypoint scripts if new root causes are found.

---

_Last updated: 2025-08-07_
