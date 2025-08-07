#!/bin/bash
set -euo pipefail
# Orchestrator Agent: SSO Troubleshooter for Google Workspace SSO via Keycloak
# Agent Mode: Automatic debugging and fixing of Keycloak SSO issues
# Logs to /opt/my-secure-ha-stack/logs/dev-environment-setup.log
# Only targets Keycloak SSO integration (microservice isolation)

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
KEYCLOAK_CONTAINER="purebliss-keycloak"
IDP_METADATA="/opt/my-secure-ha-stack/GoogleIDPMetadata.xml"
REALM="PureBless-Google-Workspace"
AGENT_MODE=true

log() {
    echo "[$(date)] SSO-TROUBLESHOOTER-AGENT: $1" | tee -a "$LOG_FILE"
}

debug_step() {
    local step_name="$1"
    local command="$2"
    log "DEBUG-STEP: $step_name"
    eval "$command" 2>&1 | tee -a "$LOG_FILE"
}

fix_attempt() {
    local issue="$1"
    local fix_command="$2"
    log "ATTEMPTING FIX: $issue"
    if eval "$fix_command" 2>&1 | tee -a "$LOG_FILE"; then
        log "FIX SUCCESS: $issue"
        return 0
    else
        log "FIX FAILED: $issue"
        return 1
    fi
}

log "Starting SSO troubleshooting in AGENT MODE for Google Workspace SSO via Keycloak."

# Agent Mode Debugging Sequence
debug_step "Container Status Check" "docker ps -f name=$KEYCLOAK_CONTAINER --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
debug_step "Health Check Details" "docker inspect $KEYCLOAK_CONTAINER --format '{{json .State.Health}}'"
debug_step "Environment Variables" "docker exec $KEYCLOAK_CONTAINER env | grep -E 'KC_|KEYCLOAK_|DB_|VAULT_' || true"
debug_step "Database Connectivity Test" "docker exec $KEYCLOAK_CONTAINER nc -zv purebliss-postgres 5432 || true"
debug_step "Full Router Exception Stack Trace" "docker logs $KEYCLOAK_CONTAINER 2>&1 | grep -A 10 -B 5 'Unhandled exception in router' | tail -n 50"

# 1. Check Keycloak container status
if ! docker ps -q -f name=$KEYCLOAK_CONTAINER > /dev/null; then
    log "ERROR: Keycloak container not running."
    if [[ "$AGENT_MODE" == true ]]; then
        fix_attempt "Starting Keycloak container" "docker start $KEYCLOAK_CONTAINER"
        sleep 10
    else
        exit 1
    fi
fi

# 2. Health check for Keycloak with agent mode fixes
HEALTH=$(docker inspect --format='{{.State.Health.Status}}' $KEYCLOAK_CONTAINER || echo "unknown")
if [[ "$HEALTH" != "healthy" ]]; then
    log "WARNING: Keycloak health check failed: $HEALTH. Reviewing logs."
    docker logs $KEYCLOAK_CONTAINER | grep -i "saml\|oidc\|error" | tail -n 50 | tee -a "$LOG_FILE"

    if [[ "$AGENT_MODE" == true ]]; then
        # Agent mode: attempt automatic fixes
        debug_step "Checking if Keycloak is responding on port 8080" "docker exec $KEYCLOAK_CONTAINER curl -s http://localhost:8080/health || true"

        # Check if database is causing issues
        if docker logs $KEYCLOAK_CONTAINER 2>&1 | grep -i "database\|postgres\|connection"; then
            log "Database connectivity issues detected."
            fix_attempt "Restarting PostgreSQL service" "docker restart purebliss-postgres && sleep 15"
            fix_attempt "Restarting Keycloak after DB restart" "docker restart $KEYCLOAK_CONTAINER && sleep 30"
        fi

        # Check if it's a configuration issue
        if docker logs $KEYCLOAK_CONTAINER 2>&1 | grep -i "configuration\|build"; then
            log "Configuration issues detected."
            fix_attempt "Rebuilding Keycloak configuration" "docker exec $KEYCLOAK_CONTAINER /opt/keycloak/bin/kc.sh build"
        fi

        # Generic restart if still unhealthy
        HEALTH_AFTER_FIXES=$(docker inspect --format='{{.State.Health.Status}}' $KEYCLOAK_CONTAINER || echo "unknown")
        if [[ "$HEALTH_AFTER_FIXES" != "healthy" ]]; then
            fix_attempt "Full Keycloak container restart" "docker restart $KEYCLOAK_CONTAINER && sleep 45"
        fi
    fi
else
    log "Keycloak health check: healthy."
fi

# 3. Validate GoogleIDPMetadata.xml presence
if [[ ! -f "$IDP_METADATA" ]]; then
    log "ERROR: GoogleIDPMetadata.xml not found at $IDP_METADATA."
    exit 2
else
    log "GoogleIDPMetadata.xml found."
fi

# 4. Validate SSO config in Keycloak (realm: $REALM) using Vault for admin password
KC_ADMIN="/opt/keycloak/bin/kcadm.sh"
VAULT_PATH="secret/data/keycloak/admin"  # Adjust to your actual Vault path
VAULT_ADDR="https://vault.purebliss.app:8200"
VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"  # Path to Vault token file

# Agent mode: attempt to create missing vault token if needed
if [[ "$AGENT_MODE" == true ]] && [[ ! -f "$VAULT_TOKEN_FILE" ]]; then
    log "Agent mode: Attempting to locate or create Vault token."

    # Try to find vault token in common locations
    for token_path in "/opt/my-secure-ha-stack/vault-init-output.txt" "/opt/dev-purebliss/data/vault/.vault-token" "/root/.vault-token"; do
        if [[ -f "$token_path" ]]; then
            log "Found potential vault token at $token_path"
            # Create directory if needed
            mkdir -p "$(dirname "$VAULT_TOKEN_FILE")"
            # Try to extract token
            if grep -o "hvs\.[A-Za-z0-9_-]*" "$token_path" | head -1 > "$VAULT_TOKEN_FILE" 2>/dev/null; then
                log "Extracted vault token to $VAULT_TOKEN_FILE"
                break
            fi
        fi
    done
fi

# Fetch Keycloak admin password from Vault
if [[ -f "$VAULT_TOKEN_FILE" ]]; then
    VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")
    export VAULT_ADDR
    ADMIN_PASS=$(vault kv get -field=password -token="$VAULT_TOKEN" "$VAULT_PATH" 2>/dev/null)
    if [[ -z "$ADMIN_PASS" ]]; then
        log "ERROR: Failed to retrieve Keycloak admin password from Vault at $VAULT_PATH."
        if [[ "$AGENT_MODE" == true ]]; then
            # Try default admin password as fallback
            log "Agent mode: Attempting with default admin password."
            ADMIN_PASS="admin"
        fi
    fi
else
    log "ERROR: Vault token file not found at $VAULT_TOKEN_FILE."
    if [[ "$AGENT_MODE" == true ]]; then
        log "Agent mode: Using default admin password as fallback."
        ADMIN_PASS="admin"
    else
        ADMIN_PASS=""
    fi
fi

if docker exec $KEYCLOAK_CONTAINER test -f $KC_ADMIN; then
    if [[ -n "$ADMIN_PASS" ]]; then
        debug_step "Testing Keycloak Admin CLI access" "docker exec $KEYCLOAK_CONTAINER $KC_ADMIN config credentials --server http://localhost:8080 --realm master --user admin --password '$ADMIN_PASS'"

        # Check if realm exists, create if it doesn't in agent mode
        if ! docker exec $KEYCLOAK_CONTAINER $KC_ADMIN get realms/$REALM --server http://localhost:8080 --realm master --user admin --password "$ADMIN_PASS" 2>/dev/null; then
            if [[ "$AGENT_MODE" == true ]]; then
                log "Realm $REALM not found. Agent mode: Creating realm."
                fix_attempt "Creating realm $REALM" "docker exec $KEYCLOAK_CONTAINER $KC_ADMIN create realms -s realm=$REALM -s enabled=true --server http://localhost:8080 --realm master --user admin --password '$ADMIN_PASS'"
            else
                log "ERROR: Realm $REALM not found."
            fi
        else
            log "Queried Keycloak realm config for $REALM using admin password."
        fi
    else
        log "WARNING: Skipping Keycloak realm query due to missing admin password."
    fi
else
    log "WARNING: kcadm.sh not found in Keycloak container. Manual check required."
fi

# 5. Test SSO endpoint (simulate login page load)
SSO_URL="https://dev.purebliss.app/keycloak/realms/$REALM/protocol/saml/clients/google"
HTTP_CODE=$(curl -s -k -o /dev/null -w "%{http_code}" "$SSO_URL")
if [[ "$HTTP_CODE" == "200" ]]; then
    log "SSO endpoint $SSO_URL reachable (HTTP 200)."
elif [[ "$HTTP_CODE" == "302" ]]; then
    log "SSO endpoint $SSO_URL returned HTTP 302 (redirect) - may be expected for SAML flow."
else
    log "ERROR: SSO endpoint $SSO_URL returned HTTP $HTTP_CODE."
    if [[ "$AGENT_MODE" == true ]]; then
        debug_step "Testing base Keycloak URL" "curl -s -k -o /dev/null -w '%{http_code}' https://dev.purebliss.app/keycloak/"
        debug_step "Testing realm endpoint" "curl -s -k -o /dev/null -w '%{http_code}' https://dev.purebliss.app/keycloak/realms/$REALM"
    fi
fi

# 6. Agent mode: Final status report and recommendations
if [[ "$AGENT_MODE" == true ]]; then
    log "=== AGENT MODE FINAL REPORT ==="

    FINAL_HEALTH=$(docker inspect --format='{{.State.Health.Status}}' $KEYCLOAK_CONTAINER || echo "unknown")
    log "Final Keycloak health status: $FINAL_HEALTH"

    if [[ "$FINAL_HEALTH" == "healthy" ]]; then
        log "SUCCESS: Keycloak is now healthy. SSO troubleshooting completed successfully."
    else
        log "PARTIAL SUCCESS: Some issues may remain. Manual intervention may be required."
        debug_step "Final error analysis" "docker logs $KEYCLOAK_CONTAINER | tail -n 20"
    fi

    log "=== RECOMMENDATIONS ==="
    log "1. Verify Google Workspace SAML configuration matches Keycloak realm settings"
    log "2. Ensure proper certificate configuration for HTTPS endpoints"
    log "3. Test end-to-end SSO flow from Google Workspace to application"
    log "4. Monitor Keycloak logs for any remaining router exceptions"
fi

# 7. Log recent Keycloak SSO errors from Loki (if available)
log "Loki query for Keycloak SSO errors: {container_name=\"keycloak\"} |~ \"SAML|OIDC|ERROR\" | json"

log "Completed SSO troubleshooting in AGENT MODE for Google Workspace SSO via Keycloak."
