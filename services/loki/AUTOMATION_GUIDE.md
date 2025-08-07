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

---

_Last updated: 2025-08-07_
