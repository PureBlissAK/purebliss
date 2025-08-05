#!/bin/bash
set -euo pipefail
# Orchestrator Agent: Google Workspace SSO Integration (Simplified)
# Creates realm, identity provider, and configures SAML SSO
# Logs to /opt/my-secure-ha-stack/logs/dev-environment-setup.log

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
KEYCLOAK_CONTAINER="purebliss-keycloak"
IDP_METADATA="/opt/my-secure-ha-stack/GoogleIDPMetadata.xml"
REALM="PureBless-Google-Workspace"

log() {
    echo "[$(date)] SSO-INTEGRATION: $1" | tee -a "$LOG_FILE"
}

log "Starting Google Workspace SSO integration with Keycloak."

# 1. Use Keycloak's default admin configuration
KEYCLOAK_BASE_URL="http://localhost:8080"
KC_ADMIN="/opt/keycloak/bin/kcadm.sh"

# Check environment variables for admin credentials
ADMIN_USER=$(docker exec $KEYCLOAK_CONTAINER printenv KEYCLOAK_ADMIN_USER 2>/dev/null || echo "admin")
ADMIN_PASS=$(docker exec $KEYCLOAK_CONTAINER printenv KEYCLOAK_ADMIN_PASSWORD 2>/dev/null || echo "admin")

log "Using admin credentials from environment: $ADMIN_USER"

# 2. Authenticate with Keycloak
log "Authenticating with Keycloak..."
if docker exec $KEYCLOAK_CONTAINER $KC_ADMIN config credentials --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>/dev/null; then
    log "SUCCESS: Authenticated with Keycloak"
else
    log "Authentication failed. Checking if Keycloak is ready..."
    sleep 10
    if docker exec $KEYCLOAK_CONTAINER $KC_ADMIN config credentials --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>/dev/null; then
        log "SUCCESS: Authenticated with Keycloak after retry"
    else
        log "ERROR: Failed to authenticate with Keycloak"
        exit 1
    fi
fi

# 3. Create the PureBless-Google-Workspace realm
log "Creating realm: $REALM"
if docker exec $KEYCLOAK_CONTAINER $KC_ADMIN get realms/$REALM --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>/dev/null; then
    log "Realm $REALM already exists."
else
    log "Creating new realm: $REALM"
    docker exec $KEYCLOAK_CONTAINER $KC_ADMIN create realms -s realm=$REALM -s enabled=true -s displayName="Pure Bliss Google Workspace" --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>&1 | tee -a "$LOG_FILE"
fi

# 4. Create Google Workspace SAML Identity Provider
log "Configuring Google Workspace SAML Identity Provider..."

# Extract information from GoogleIDPMetadata.xml
if [[ -f "$IDP_METADATA" ]]; then
    GOOGLE_SSO_URL=$(grep -o 'Location="[^"]*' "$IDP_METADATA" | head -1 | sed 's/Location="//')
    GOOGLE_ENTITY_ID=$(grep -o 'entityID="[^"]*' "$IDP_METADATA" | sed 's/entityID="//')

    log "Google SSO URL: $GOOGLE_SSO_URL"
    log "Google Entity ID: $GOOGLE_ENTITY_ID"

    # Create the identity provider
    cat > /tmp/google-idp.json << EOF
{
  "alias": "google-workspace",
  "displayName": "Google Workspace SSO",
  "providerId": "saml",
  "enabled": true,
  "config": {
    "singleSignOnServiceUrl": "$GOOGLE_SSO_URL",
    "entityId": "$GOOGLE_ENTITY_ID",
    "nameIDPolicyFormat": "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
    "postBindingResponse": "true",
    "postBindingAuthnRequest": "true",
    "wantAuthnRequestsSigned": "false",
    "validateSignature": "true",
    "signatureAlgorithm": "RSA_SHA256"
  }
}
EOF

    # Copy to container and create IDP
    docker cp /tmp/google-idp.json $KEYCLOAK_CONTAINER:/tmp/google-idp.json
    docker exec $KEYCLOAK_CONTAINER $KC_ADMIN create identity-provider/instances -r $REALM -f /tmp/google-idp.json --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>&1 | tee -a "$LOG_FILE"

    rm /tmp/google-idp.json
else
    log "ERROR: GoogleIDPMetadata.xml not found at $IDP_METADATA"
    exit 1
fi

# 5. Configure attribute mappers
log "Configuring attribute mappers for Google Workspace..."
cat > /tmp/email-mapper.json << EOF
{
  "name": "email",
  "identityProviderAlias": "google-workspace",
  "identityProviderMapper": "saml-user-attribute-idp-mapper",
  "config": {
    "syncMode": "INHERIT",
    "attribute.name": "email",
    "user.attribute": "email"
  }
}
EOF

docker cp /tmp/email-mapper.json $KEYCLOAK_CONTAINER:/tmp/email-mapper.json
docker exec $KEYCLOAK_CONTAINER $KC_ADMIN create identity-provider/instances/google-workspace/mappers -r $REALM -f /tmp/email-mapper.json --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>&1 | tee -a "$LOG_FILE"

rm /tmp/email-mapper.json

# 6. Create a test client application
log "Creating test client application..."
CLIENT_SECRET=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-24)

cat > /tmp/test-client.json << EOF
{
  "clientId": "purebliss-app",
  "name": "Pure Bliss Application",
  "enabled": true,
  "clientAuthenticatorType": "client-secret",
  "secret": "$CLIENT_SECRET",
  "redirectUris": ["https://dev.purebliss.app/*"],
  "webOrigins": ["https://dev.purebliss.app"],
  "protocol": "openid-connect",
  "publicClient": false,
  "standardFlowEnabled": true,
  "implicitFlowEnabled": false,
  "directAccessGrantsEnabled": true,
  "serviceAccountsEnabled": false
}
EOF

docker cp /tmp/test-client.json $KEYCLOAK_CONTAINER:/tmp/test-client.json
docker exec $KEYCLOAK_CONTAINER $KC_ADMIN create clients -r $REALM -f /tmp/test-client.json --server "$KEYCLOAK_BASE_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS" 2>&1 | tee -a "$LOG_FILE"
rm /tmp/test-client.json

# 7. Save configuration for future Vault storage
log "Saving configuration for Vault storage..."
cat > /opt/my-secure-ha-stack/logs/sso-config.txt << EOF
# SSO Configuration Generated: $(date)
REALM=$REALM
GOOGLE_ENTITY_ID=$GOOGLE_ENTITY_ID
GOOGLE_SSO_URL=$GOOGLE_SSO_URL
KEYCLOAK_BASE_URL=$KEYCLOAK_BASE_URL
CLIENT_SECRET=$CLIENT_SECRET
ADMIN_USER=$ADMIN_USER
ADMIN_PASS=$ADMIN_PASS
SSO_LOGIN_URL=https://dev.purebliss.app/keycloak/realms/$REALM/broker/google-workspace/login
ADMIN_URL=https://dev.purebliss.app/keycloak/admin/
EOF

# 8. Display configuration summary
log "=== SSO INTEGRATION SUMMARY ==="
log "Realm: $REALM"
log "Identity Provider: google-workspace"
log "Keycloak Admin URL: https://dev.purebliss.app/keycloak/admin/"
log "Realm URL: https://dev.purebliss.app/keycloak/realms/$REALM"
log "SSO Login URL: https://dev.purebliss.app/keycloak/realms/$REALM/broker/google-workspace/login"
log "Client ID: purebliss-app"
log "Client Secret: $CLIENT_SECRET"

# 9. Test the SSO endpoint
log "Testing SSO endpoint..."
SSO_URL="https://dev.purebliss.app/keycloak/realms/$REALM/broker/google-workspace/login"
HTTP_CODE=$(curl -s -k -o /dev/null -w "%{http_code}" "$SSO_URL")
log "SSO endpoint test result: HTTP $HTTP_CODE"

log "Google Workspace SSO integration completed successfully!"
log "Configuration saved to: /opt/my-secure-ha-stack/logs/sso-config.txt"
log ""
log "Next steps:"
log "1. Configure Google Workspace SAML app with Keycloak metadata"
log "2. Test SSO flow from Google Workspace"
log "3. Store secrets in Vault when it becomes available"
log "4. Configure application to use Keycloak for authentication"
