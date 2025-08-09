# Vault Agent (AppRole Integration) - Operational Pattern

**Generated/Updated**: 2025-08-08
**Purpose**: Document the operational pattern, setup, and validation of the Vault Agent container with AppRole authentication and PKI integration for LetsEncrypt.
**Consolidation Type**: automation|integration|best-practices
**Services Covered**: Vault Agent, Vault, LetsEncrypt

## Overview

This document details the operational pattern for the Vault Agent container, which provides secure AppRole authentication to Vault and enables dynamic certificate issuance for LetsEncrypt via the Vault PKI backend. It covers container setup, credential management, health validation, restart/reboot survival, and security best practices.

## Service-Specific Information

### Vault Agent Container Setup
- **Image**: Official Vault Agent image
- **Configuration**: Located at `/opt/dev-purebliss/dev_scripts/services/vault-agent/`
- **AppRole Credentials**: Mounted from `/opt/dev-purebliss/secrets/` (never hardcoded)
- **PKI Integration**: Connects to Vault PKI backend (`pki-letsencrypt`) for dynamic certificate issuance

### Operational Pattern
1. **Startup**
   - Vault Agent loads config and AppRole credentials at container start.
   - Authenticates to Vault and retrieves a renewable token.
2. **Token Renewal**
   - Vault Agent automatically renews its token before expiry.
   - Renewal events are visible in logs (`docker logs vault-agent | grep "renewed token"`).
3. **PKI Operations**
   - LetsEncrypt interacts with Vault PKI via Vault Agent for certificate issuance/renewal.
   - No direct Vault credentials are exposed to LetsEncrypt.
4. **Restart/Reboot**
   - On restart or reboot, Vault Agent re-authenticates and resumes normal operation.
5. **Health Validation**
   - Run `/opt/dev-purebliss/validate-container-health.sh vault-agent vault-agent-doc` after any change.
   - Confirm healthy status, token renewal, and PKI integration.

### Security Practices
- No static secrets in image or environment
- All secrets sourced from Vault and mounted at runtime
- All actions and health checks logged to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`

### Success Validation
```bash
# Vault Agent health check
docker ps | grep vault-agent
docker logs vault-agent | grep "renewed token" || echo "No renewal events yet"
# Reboot test
docker restart vault-agent && sleep 10 && docker logs vault-agent | grep "authenticated"
# Health validation script
/opt/dev-purebliss/validate-container-health.sh vault-agent vault-agent-doc
```

### Handoff
Vault Agent is production-ready, fully integrated with Vault PKI, and validated for restart/reboot survival. All operational and troubleshooting steps are documented and logged.
