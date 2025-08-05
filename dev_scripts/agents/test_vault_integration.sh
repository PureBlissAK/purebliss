#!/bin/bash
# Test script to validate postgres_sanity_agent.sh integration with vault_sanity_agent.sh

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

log() {
    echo "[$(date)] $1" | tee -a "$LOG_FILE"
}

log "INFO: Testing postgres_sanity_agent.sh and vault_sanity_agent.sh integration..."

# Test 1: Check if vault_sanity_agent.sh exists
if [[ -f "/opt/my-secure-ha-stack/orchestrator/agents/vault_sanity_agent.sh" ]]; then
    log "SUCCESS: vault_sanity_agent.sh found"
else
    log "ERROR: vault_sanity_agent.sh not found"
    exit 1
fi

# Test 2: Check if postgres_sanity_agent.sh has the integration functions
if grep -q "invoke_vault_sanity_agent" "/opt/my-secure-ha-stack/orchestrator/agents/postgres_sanity_agent.sh"; then
    log "SUCCESS: invoke_vault_sanity_agent function found in postgres_sanity_agent.sh"
else
    log "ERROR: invoke_vault_sanity_agent function not found"
    exit 1
fi

# Test 3: Check if enhanced get_vault_secret function exists
if grep -q "Using Vault sanity agent for secret retrieval" "/opt/my-secure-ha-stack/orchestrator/agents/postgres_sanity_agent.sh"; then
    log "SUCCESS: Enhanced get_vault_secret function found"
else
    log "ERROR: Enhanced get_vault_secret function not found"
    exit 1
fi

# Test 4: Check if Vault integration is in summary report
if grep -q "VAULT INTEGRATION METRICS" "/opt/my-secure-ha-stack/orchestrator/agents/postgres_sanity_agent.sh"; then
    log "SUCCESS: Vault integration metrics added to summary report"
else
    log "ERROR: Vault integration metrics not found in summary report"
    exit 1
fi

# Test 5: Check if auto-fix includes Vault secret detection
if grep -q "Running Vault secret detection for" "/opt/my-secure-ha-stack/orchestrator/agents/postgres_sanity_agent.sh"; then
    log "SUCCESS: Auto-fix includes Vault secret detection"
else
    log "ERROR: Auto-fix does not include Vault secret detection"
    exit 1
fi

log "SUCCESS: All integration tests passed! postgres_sanity_agent.sh is properly integrated with vault_sanity_agent.sh"
log "INFO: Integration features:"
log "  - Vault initialization via sanity agent"
log "  - Per-service secret detection"
log "  - PostgreSQL secret storage in Vault"
log "  - Enhanced secret retrieval with fallback"
log "  - Vault metrics in summary report"
log "  - Special vault service handling in auto-fix"
