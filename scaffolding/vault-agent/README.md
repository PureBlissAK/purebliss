# Vault Agent Container for LetsEncrypt PKI Integration

**Generated/Updated**: 2025-08-08
**Purpose**: Secure authentication bridge for LetsEncrypt PKI using Vault AppRole
**Consolidation Type**: integration
**Services Covered**: Vault, LetsEncrypt

## Overview
This container runs Vault Agent to provide secure, dynamic authentication for LetsEncrypt PKI operations. It uses the AppRole pattern (role_id/secret_id) and exposes a local token sink for use by certbot or other automation.

## Service-Specific Information
- **Image**: hashicorp/vault:1.17.3
- **Config**: `/etc/vault-agent-config.hcl` (AppRole, file sink, TCP listener)
- **Entrypoint**: `/entrypoint.sh` (checks for credentials, logs to central log)
- **Credential Mount**: `/vault/approle/role_id` and `/vault/approle/secret_id` (mounted at runtime)
- **Token Sink**: `/vault/approle/vault-agent-token` (used by LetsEncrypt jobs)

## Health Validation
- Container must start and log successful authentication
- Token renewal events must appear in logs
- Container must survive restart and reboot

## Integration Pattern
- LetsEncrypt jobs use the Vault Agent token for PKI operations
- No hardcoded secrets; credentials are mounted securely

## References
- [Vault Agent Auto-Auth](https://www.vaultproject.io/docs/agent/autoauth)
- [Pure Bliss Scaffolding Project Plan](../SCAFFOLDING_PROJECT_PLAN.md)
- [LetsEncrypt Integration Steps](../letsencrypt/README.md)
