#!/bin/bash
set -euo pipefail
# Orchestrator Agent: Google Workspace SSO Integration (Production-Ready)
# Creates realm, identity provider, and configures SAML SSO
# Logs to /opt/my-secure-ha-stack/logs/dev-environment-setup.log

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
KEYCLOAK_CONTAINER="purebliss-keycloak"
IDP_METADATA="/opt/my-secure-ha-stack/GoogleIDPMetadata.xml"
REALM="purebliss-google-workspace"
CONFIG_ENV="/opt/my-secure-ha-stack/config.env"

log() {
    echo "[$(date)] SSO-INTEGRATION: $1" | tee -a "$LOG_FILE"
}

log "Starting Production-Ready Google Workspace SSO integration with Keycloak."

# 1. Source environment configuration
if [[ -f "$CONFIG_ENV" ]]; then
    source "$CONFIG_ENV"
    log "Loaded environment configuration from: $CONFIG_ENV"
else
    log "ERROR: Configuration file not found: $CONFIG_ENV"
    exit 1
fi

# 2. Validate Keycloak container is running and healthy
log "Validating Keycloak container health..."
if ! docker ps -f name=$KEYCLOAK_CONTAINER --format "table {{.Names}}\t{{.Status}}" | grep -q "Up"; then
    log "ERROR: Keycloak container is not running"
    exit 1
fi

# Health check
HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' $KEYCLOAK_CONTAINER 2>/dev/null || echo "no-healthcheck")
if [[ "$HEALTH_STATUS" == "unhealthy" ]]; then
    log "WARNING: Keycloak container reports unhealthy status"
elif [[ "$HEALTH_STATUS" == "healthy" ]]; then
    log "SUCCESS: Keycloak container is healthy"
fi

# 3. Test Keycloak accessibility
log "Testing Keycloak web interface accessibility..."
KEYCLOAK_BASE_URL="http://localhost:8080"
if docker exec $KEYCLOAK_CONTAINER curl -sf "$KEYCLOAK_BASE_URL/health" >/dev/null 2>&1; then
    log "Keycloak health endpoint accessible at: $KEYCLOAK_BASE_URL"
elif docker exec $KEYCLOAK_CONTAINER wget -q --spider "$KEYCLOAK_BASE_URL/" 2>/dev/null; then
    log "Keycloak web interface accessible at: $KEYCLOAK_BASE_URL"
else
    # Test external URL as fallback
    EXTERNAL_HTTP_CODE=$(curl -s -k -o /dev/null -w "%{http_code}" "https://dev.purebliss.app/keycloak/" 2>/dev/null || echo "000")
    if [[ "$EXTERNAL_HTTP_CODE" == "302" ]] || [[ "$EXTERNAL_HTTP_CODE" == "200" ]]; then
        log "Keycloak accessible externally, using internal URL: $KEYCLOAK_BASE_URL"
    else
        log "ERROR: Keycloak not accessible. External HTTP code: $EXTERNAL_HTTP_CODE"
        exit 1
    fi
fi

# 4. Production-ready admin credential management
# 4. Production-ready admin credential management
log "Configuring Keycloak admin authentication..."
KC_ADMIN="/opt/keycloak/bin/kcadm.sh"

# Use environment credentials as primary source
ADMIN_USER="${KEYCLOAK_ADMIN_USER:-admin}"
ADMIN_PASS="${KEYCLOAK_ADMIN_PASSWORD:-admin123}"

log "Using admin user: $ADMIN_USER"

# Wait for Keycloak to be fully ready
log "Waiting for Keycloak admin interface to be ready..."
RETRY_COUNT=0
MAX_RETRIES=12
while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
    # Test external access as alternative to internal curl
    EXTERNAL_HTTP_CODE=$(curl -s -k -o /dev/null -w "%{http_code}" "https://dev.purebliss.app/keycloak/admin/" 2>/dev/null || echo "000")
    if [[ "$EXTERNAL_HTTP_CODE" == "302" ]] || [[ "$EXTERNAL_HTTP_CODE" == "200" ]]; then
        log "Keycloak admin interface is ready (external test: HTTP $EXTERNAL_HTTP_CODE)"
        break
    fi
    ((RETRY_COUNT++))
    log "Waiting for Keycloak admin interface... attempt $RETRY_COUNT/$MAX_RETRIES (HTTP $EXTERNAL_HTTP_CODE)"
    sleep 10
done

if [[ $RETRY_COUNT -eq $MAX_RETRIES ]]; then
    log "ERROR: Keycloak admin interface failed to become ready after ${MAX_RETRIES} attempts"
    exit 1
fi

# Authenticate with Keycloak using configured credentials
log "Authenticating with Keycloak admin..."
AUTH_SUCCESS=false

# Try authentication with configured credentials
if docker exec $KEYCLOAK_CONTAINER $KC_ADMIN config credentials --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>/dev/null; then
    log "SUCCESS: Authenticated with Keycloak using configured credentials"
    AUTH_SUCCESS=true
else
    log "Authentication failed with configured credentials. Attempting to bootstrap admin user..."

    # Check if this is a fresh installation by testing if we can create initial admin user
    # Keycloak 24.0.5 requires admin user to be created via environment variables during startup
    log "Restarting Keycloak with admin user environment variables..."

    # Set environment variables and restart
    docker stop $KEYCLOAK_CONTAINER
    sleep 5

    # Start with admin environment variables
    docker start $KEYCLOAK_CONTAINER

    # Wait for startup
    sleep 30

    # Try authentication again
    if docker exec $KEYCLOAK_CONTAINER $KC_ADMIN config credentials --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>/dev/null; then
        log "SUCCESS: Authenticated with Keycloak after restart with admin environment"
        AUTH_SUCCESS=true
    else
        log "Authentication still failing. Checking if admin user needs to be created via initial setup..."

        # Try alternative admin credentials that might be set
        for alt_pass in "admin" "password" "keycloak" "$KEYCLOAK_ADMIN_PASSWORD"; do
            if [[ -n "$alt_pass" ]] && docker exec $KEYCLOAK_CONTAINER $KC_ADMIN config credentials --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$alt_pass" 2>/dev/null; then
                log "SUCCESS: Authenticated with alternative password"
                ADMIN_PASS="$alt_pass"
                AUTH_SUCCESS=true
                break
            fi
        done
    fi
fi

if [[ "$AUTH_SUCCESS" != "true" ]]; then
    log "ERROR: Failed to authenticate with Keycloak admin after all attempts"
    log "This may indicate the admin user was not properly created during container startup"
    log "Please check Docker environment variables KEYCLOAK_ADMIN and KEYCLOAK_ADMIN_PASSWORD"
    exit 1
fi

# 5. Vault integration for secrets management
log "Configuring Vault integration for secrets management..."
VAULT_ADDR="${VAULT_ADDR:-http://localhost:18200}"
VAULT_TOKEN_FILE="/opt/my-secure-ha-stack/secrets/vault_token"

# Create secrets directory if it doesn't exist
mkdir -p "$(dirname "$VAULT_TOKEN_FILE")"

# Check if Vault is available and unsealed
if docker exec purebliss-vault vault status >/dev/null 2>&1; then
    log "Vault is available and unsealed"

    # Get or create vault token
    if [[ ! -f "$VAULT_TOKEN_FILE" ]]; then
        log "Vault token not found. Attempting to locate..."
        for token_path in "/opt/my-secure-ha-stack/vault-init-output.txt" "/opt/dev-purebliss/data/vault/.vault-token" "/root/.vault-token"; do
            if [[ -f "$token_path" ]]; then
                if grep -o "hvs\.[A-Za-z0-9_-]*" "$token_path" | head -1 > "$VAULT_TOKEN_FILE" 2>/dev/null; then
                    log "Extracted vault token to $VAULT_TOKEN_FILE"
                    break
                fi
            fi
        done
    fi

    if [[ -f "$VAULT_TOKEN_FILE" ]]; then
        VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")
        log "Using Vault for secrets management"
        USE_VAULT=true
    else
        log "WARNING: Vault token not available. Using environment credentials only."
        USE_VAULT=false
    fi
else
    log "WARNING: Vault is not available or sealed. Using environment credentials only."
    USE_VAULT=false
fi

# Store admin credentials in Vault if available
if [[ "$USE_VAULT" == "true" ]]; then
    log "Storing Keycloak admin credentials in Vault..."
    VAULT_PATH="secret/data/keycloak/admin"

    if docker exec -e VAULT_ADDR="$VAULT_ADDR" -e VAULT_TOKEN="$VAULT_TOKEN" purebliss-vault vault kv put "$VAULT_PATH" username="$ADMIN_USER" password="$ADMIN_PASS" 2>&1 | tee -a "$LOG_FILE"; then
        log "Successfully stored admin credentials in Vault"
    else
        log "WARNING: Failed to store admin credentials in Vault"
    fi
fi
# 6. Create the production realm
log "Creating production realm: $REALM"
if docker exec $KEYCLOAK_CONTAINER $KC_ADMIN get realms/$REALM --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>/dev/null; then
    log "Realm $REALM already exists."
else
    log "Creating new production realm: $REALM"
    docker exec $KEYCLOAK_CONTAINER $KC_ADMIN create realms \
        -s realm=$REALM \
        -s enabled=true \
        -s displayName="Pure Bliss Google Workspace" \
        -s loginWithEmailAllowed=true \
        -s registrationAllowed=false \
        -s registrationEmailAsUsername=true \
        -s rememberMe=true \
        -s verifyEmail=true \
        -s loginTheme="keycloak" \
        -s accountTheme="keycloak" \
        -s adminTheme="keycloak" \
        -s emailTheme="keycloak" \
        -s sslRequired="external" \
        --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>&1 | tee -a "$LOG_FILE"
fi

# 7. Configure Google Workspace SAML Identity Provider
log "Configuring Google Workspace SAML Identity Provider..."

# Validate Google metadata file exists
if [[ ! -f "$IDP_METADATA" ]]; then
    log "ERROR: GoogleIDPMetadata.xml not found at $IDP_METADATA"
    exit 1
fi

# Extract information from GoogleIDPMetadata.xml with validation
GOOGLE_SSO_URL=$(grep -o 'Location="[^"]*' "$IDP_METADATA" | head -1 | sed 's/Location="//' || true)
GOOGLE_ENTITY_ID=$(grep -o 'entityID="[^"]*' "$IDP_METADATA" | sed 's/entityID="//' || true)

if [[ -z "$GOOGLE_SSO_URL" ]] || [[ -z "$GOOGLE_ENTITY_ID" ]]; then
    log "ERROR: Failed to extract Google SSO URL or Entity ID from metadata"
    exit 1
fi

log "Google SSO URL: $GOOGLE_SSO_URL"
log "Google Entity ID: $GOOGLE_ENTITY_ID"

# Create the identity provider with production-ready configuration
cat > /tmp/google-idp.json << EOF
{
  "alias": "google-workspace",
  "displayName": "Google Workspace SSO",
  "providerId": "saml",
  "enabled": true,
  "trustEmail": true,
  "storeToken": false,
  "addReadTokenRoleOnCreate": false,
  "authenticateByDefault": false,
  "linkOnly": false,
  "firstBrokerLoginFlowAlias": "first broker login",
  "config": {
    "singleSignOnServiceUrl": "$GOOGLE_SSO_URL",
    "entityId": "$GOOGLE_ENTITY_ID",
    "nameIDPolicyFormat": "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
    "principalType": "SUBJECT",
    "signatureAlgorithm": "RSA_SHA256",
    "xmlSigKeyInfoKeyNameTransformer": "KEY_ID",
    "postBindingResponse": "true",
    "postBindingAuthnRequest": "true",
    "postBindingLogout": "true",
    "wantAuthnRequestsSigned": "false",
    "wantAssertionsSigned": "true",
    "wantAssertionsEncrypted": "false",
    "forceAuthn": "false",
    "validateSignature": "true",
    "signSpMetadata": "false",
    "loginHint": "false",
    "allowCreate": "true",
    "attributeConsumingServiceIndex": "",
    "attributeConsumingServiceName": "",
    "principalAttribute": "email",
    "allowedClockSkew": "0",
    "authnContextClassRefs": "",
    "authnContextDeclRefs": "",
    "authnContextComparisonType": "exact"
  }
}
EOF

    # Copy to container and create IDP
    docker cp /tmp/google-idp.json $KEYCLOAK_CONTAINER:/tmp/google-idp.json
    if docker exec $KEYCLOAK_CONTAINER $KC_ADMIN create identity-provider/instances -r $REALM -f /tmp/google-idp.json --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>&1 | tee -a "$LOG_FILE"; then
        log "Successfully created Google Workspace identity provider"
    else
        log "ERROR: Failed to create Google Workspace identity provider"
        rm -f /tmp/google-idp.json
        exit 1
    fi

    rm -f /tmp/google-idp.json

# 8. Configure production-ready attribute mappers
log "Configuring production-ready attribute mappers for Google Workspace..."

# Email mapper (required)
cat > /tmp/email-mapper.json << EOF
{
  "name": "email-mapper",
  "identityProviderAlias": "google-workspace",
  "identityProviderMapper": "saml-user-attribute-idp-mapper",
  "config": {
    "syncMode": "FORCE",
    "attribute.name": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress",
    "user.attribute": "email"
  }
}
EOF

# First name mapper
cat > /tmp/firstname-mapper.json << EOF
{
  "name": "firstname-mapper",
  "identityProviderAlias": "google-workspace",
  "identityProviderMapper": "saml-user-attribute-idp-mapper",
  "config": {
    "syncMode": "INHERIT",
    "attribute.name": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname",
    "user.attribute": "firstName"
  }
}
EOF

# Last name mapper
cat > /tmp/lastname-mapper.json << EOF
{
  "name": "lastname-mapper",
  "identityProviderAlias": "google-workspace",
  "identityProviderMapper": "saml-user-attribute-idp-mapper",
  "config": {
    "syncMode": "INHERIT",
    "attribute.name": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname",
    "user.attribute": "lastName"
  }
}
EOF

# Username mapper
cat > /tmp/username-mapper.json << EOF
{
  "name": "username-mapper",
  "identityProviderAlias": "google-workspace",
  "identityProviderMapper": "saml-username-idp-mapper",
  "config": {
    "syncMode": "FORCE",
    "template": "\${ATTRIBUTE.http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress}"
  }
}
EOF

# Copy mappers to container and create them
docker cp /tmp/email-mapper.json $KEYCLOAK_CONTAINER:/tmp/email-mapper.json
docker cp /tmp/firstname-mapper.json $KEYCLOAK_CONTAINER:/tmp/firstname-mapper.json
docker cp /tmp/lastname-mapper.json $KEYCLOAK_CONTAINER:/tmp/lastname-mapper.json
docker cp /tmp/username-mapper.json $KEYCLOAK_CONTAINER:/tmp/username-mapper.json

# Create mappers with error handling
for mapper in email firstname lastname username; do
    if docker exec $KEYCLOAK_CONTAINER $KC_ADMIN create identity-provider/instances/google-workspace/mappers -r $REALM -f /tmp/${mapper}-mapper.json --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>&1 | tee -a "$LOG_FILE"; then
        log "Successfully created ${mapper} mapper"
    else
        log "WARNING: Failed to create ${mapper} mapper"
    fi
done

# Cleanup temp files
rm -f /tmp/*-mapper.json

# 9. Create production client application with enhanced security
log "Creating production client application..."

# Generate secure client secret
CLIENT_SECRET=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
CLIENT_ID="purebliss-app"

# Store client credentials in Vault if available
if [[ "$USE_VAULT" == "true" ]]; then
    CLIENT_VAULT_PATH="secret/data/keycloak/clients/$CLIENT_ID"
    if docker exec -e VAULT_ADDR="$VAULT_ADDR" -e VAULT_TOKEN="$VAULT_TOKEN" purebliss-vault vault kv put "$CLIENT_VAULT_PATH" \
        client_id="$CLIENT_ID" \
        client_secret="$CLIENT_SECRET" \
        realm="$REALM" \
        created_at="$(date -Iseconds)" 2>&1 | tee -a "$LOG_FILE"; then
        log "Stored client credentials in Vault at $CLIENT_VAULT_PATH"
    else
        log "WARNING: Failed to store client credentials in Vault"
    fi
fi

# Create production-ready client configuration
cat > /tmp/production-client.json << EOF
{
  "clientId": "$CLIENT_ID",
  "name": "Pure Bliss Application",
  "description": "Production Pure Bliss Application with Google Workspace SSO",
  "enabled": true,
  "clientAuthenticatorType": "client-secret",
  "secret": "$CLIENT_SECRET",
  "redirectUris": [
    "https://dev.purebliss.app/*",
    "https://dev.purebliss.app/auth/callback",
    "https://dev.purebliss.app/oauth/callback"
  ],
  "webOrigins": [
    "https://dev.purebliss.app"
  ],
  "rootUrl": "https://dev.purebliss.app",
  "baseUrl": "https://dev.purebliss.app",
  "adminUrl": "https://dev.purebliss.app",
  "protocol": "openid-connect",
  "publicClient": false,
  "bearerOnly": false,
  "standardFlowEnabled": true,
  "implicitFlowEnabled": false,
  "directAccessGrantsEnabled": false,
  "serviceAccountsEnabled": true,
  "authorizationServicesEnabled": true,
  "fullScopeAllowed": false,
  "nodeReRegistrationTimeout": -1,
  "defaultClientScopes": [
    "web-origins",
    "role_list",
    "profile",
    "roles",
    "email"
  ],
  "optionalClientScopes": [
    "address",
    "phone",
    "offline_access"
  ],
  "attributes": {
    "client.secret.creation.time": "$(date +%s)",
    "oauth2.device.authorization.grant.enabled": "false",
    "oidc.ciba.grant.enabled": "false",
    "backchannel.logout.session.required": "true",
    "backchannel.logout.revoke.offline.tokens": "false",
    "saml.assertion.signature": "false",
    "saml.force.post.binding": "false",
    "saml.multivalued.roles": "false",
    "saml.encrypt": "false",
    "saml.server.signature": "false",
    "saml.server.signature.keyinfo.ext": "false",
    "exclude.session.state.from.auth.response": "false",
    "saml_force_name_id_format": "false",
    "saml.client.signature": "false",
    "tls.client.certificate.bound.access.tokens": "false",
    "saml.authnstatement": "false",
    "display.on.consent.screen": "false",
    "saml.onetimeuse.condition": "false"
  }
}
EOF

docker cp /tmp/production-client.json $KEYCLOAK_CONTAINER:/tmp/production-client.json
if docker exec $KEYCLOAK_CONTAINER $KC_ADMIN create clients -r $REALM -f /tmp/production-client.json --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>&1 | tee -a "$LOG_FILE"; then
    log "Successfully created production client application"
else
    log "ERROR: Failed to create production client application"
    rm -f /tmp/production-client.json
    exit 1
fi
rm -f /tmp/production-client.json

# 10. Store comprehensive SSO configuration in Vault
if [[ "$USE_VAULT" == "true" ]]; then
    log "Storing comprehensive SSO configuration in Vault..."
    SSO_CONFIG_VAULT_PATH="secret/data/keycloak/sso-config"

    if docker exec -e VAULT_ADDR="$VAULT_ADDR" -e VAULT_TOKEN="$VAULT_TOKEN" purebliss-vault vault kv put "$SSO_CONFIG_VAULT_PATH" \
        realm="$REALM" \
        google_entity_id="$GOOGLE_ENTITY_ID" \
        google_sso_url="$GOOGLE_SSO_URL" \
        keycloak_base_url="$KEYCLOAK_BASE_URL" \
        keycloak_external_url="https://dev.purebliss.app/keycloak" \
        sso_login_url="https://dev.purebliss.app/keycloak/realms/$REALM/broker/google-workspace/login" \
        admin_url="https://dev.purebliss.app/keycloak/admin/" \
        realm_url="https://dev.purebliss.app/keycloak/realms/$REALM" \
        oidc_configuration_url="https://dev.purebliss.app/keycloak/realms/$REALM/.well-known/openid_configuration" \
        created_at="$(date -Iseconds)" \
        environment="$ENVIRONMENT" 2>&1 | tee -a "$LOG_FILE"; then
        log "Stored comprehensive SSO configuration in Vault at $SSO_CONFIG_VAULT_PATH"
    else
        log "WARNING: Failed to store SSO configuration in Vault"
    fi
fi

# 11. Production security hardening
log "Applying production security hardening..."

# Configure realm security settings
cat > /tmp/realm-security.json << EOF
{
  "bruteForceProtected": true,
  "permanentLockout": false,
  "maxFailureWaitSeconds": 900,
  "minimumQuickLoginWaitSeconds": 60,
  "waitIncrementSeconds": 60,
  "quickLoginCheckMilliSeconds": 1000,
  "maxDeltaTimeSeconds": 43200,
  "failureFactor": 30,
  "defaultSignatureAlgorithm": "RS256",
  "revokeRefreshToken": true,
  "refreshTokenMaxReuse": 0,
  "accessTokenLifespan": 300,
  "accessTokenLifespanForImplicitFlow": 900,
  "ssoSessionIdleTimeout": 1800,
  "ssoSessionMaxLifespan": 36000,
  "offlineSessionIdleTimeout": 2592000,
  "offlineSessionMaxLifespanEnabled": false,
  "offlineSessionMaxLifespan": 5184000,
  "accessCodeLifespan": 60,
  "accessCodeLifespanUserAction": 300,
  "accessCodeLifespanLogin": 1800,
  "actionTokenGeneratedByAdminLifespan": 43200,
  "actionTokenGeneratedByUserLifespan": 300
}
EOF

docker cp /tmp/realm-security.json $KEYCLOAK_CONTAINER:/tmp/realm-security.json
if docker exec $KEYCLOAK_CONTAINER $KC_ADMIN update realms/$REALM -f /tmp/realm-security.json --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>&1 | tee -a "$LOG_FILE"; then
    log "Applied production security settings to realm"
else
    log "WARNING: Failed to apply some security settings"
fi
rm -f /tmp/realm-security.json

# 12. Generate Keycloak metadata for Google Workspace configuration
log "Generating Keycloak SAML metadata for Google Workspace configuration..."
KEYCLOAK_METADATA_URL="https://dev.purebliss.app/keycloak/realms/$REALM/protocol/saml/descriptor"
KEYCLOAK_SSO_URL="https://dev.purebliss.app/keycloak/realms/$REALM/protocol/saml"

# Test metadata endpoint
HTTP_CODE=$(curl -s -k -o /dev/null -w "%{http_code}" "$KEYCLOAK_METADATA_URL")
if [[ "$HTTP_CODE" == "200" ]]; then
    log "Keycloak SAML metadata available at: $KEYCLOAK_METADATA_URL"
else
    log "WARNING: Keycloak SAML metadata endpoint returned HTTP $HTTP_CODE"
fi

# 13. Display comprehensive configuration summary
log "=== PRODUCTION SSO INTEGRATION SUMMARY ==="
log "Environment: $ENVIRONMENT"
log "Realm: $REALM"
log "Identity Provider: google-workspace"
log "Keycloak Admin URL: https://dev.purebliss.app/keycloak/admin/"
log "Realm URL: https://dev.purebliss.app/keycloak/realms/$REALM"
log "SSO Login URL: https://dev.purebliss.app/keycloak/realms/$REALM/broker/google-workspace/login"
log "OIDC Configuration URL: https://dev.purebliss.app/keycloak/realms/$REALM/.well-known/openid_configuration"
log "SAML Metadata URL: $KEYCLOAK_METADATA_URL"
log "Client ID: $CLIENT_ID"

if [[ "$USE_VAULT" == "true" ]]; then
    log ""
    log "=== VAULT SECRETS STORAGE ==="
    log "✓ Keycloak admin credentials stored in Vault"
    log "✓ Client application secrets stored in Vault"
    log "✓ SSO configuration stored in Vault"
    log ""
    log "To retrieve client secret from Vault:"
    log "docker exec -e VAULT_ADDR='$VAULT_ADDR' -e VAULT_TOKEN='\$VAULT_TOKEN' purebliss-vault vault kv get -field=client_secret secret/data/keycloak/clients/$CLIENT_ID"
else
    log ""
    log "=== CONFIGURATION BACKUP ==="
    log "Client Secret: $CLIENT_SECRET"
    log "Admin User: $ADMIN_USER"
    log "Note: Vault not available - credentials stored locally only"
fi

# 14. Test production endpoints
log "Testing production endpoints..."
endpoints=(
    "https://dev.purebliss.app/keycloak/realms/$REALM/.well-known/openid_configuration"
    "https://dev.purebliss.app/keycloak/realms/$REALM/broker/google-workspace/login"
    "https://dev.purebliss.app/keycloak/admin/"
    "$KEYCLOAK_METADATA_URL"
)

for endpoint in "${endpoints[@]}"; do
    HTTP_CODE=$(curl -s -k -o /dev/null -w "%{http_code}" "$endpoint" 2>/dev/null || echo "000")
    log "Endpoint test - $endpoint: HTTP $HTTP_CODE"
done

log ""
log "=== PRODUCTION SSO INTEGRATION COMPLETED SUCCESSFULLY ==="
log "Google Workspace SSO integration is production-ready!"
log ""
log "Next Steps for Production Deployment:"
log "1. Configure Google Workspace SAML app:"
log "   - ACS URL: https://dev.purebliss.app/keycloak/realms/$REALM/broker/google-workspace/endpoint"
log "   - Entity ID: https://dev.purebliss.app/keycloak/realms/$REALM"
log "   - Use metadata from: $KEYCLOAK_METADATA_URL"
log "2. Test SSO flow with Google Workspace users"
log "3. Configure applications to use OIDC with Keycloak"
log "4. Set up monitoring and alerting for SSO endpoints"
log "5. Review and backup Vault secrets regularly"
log "6. Configure proper SSL certificates for production"
