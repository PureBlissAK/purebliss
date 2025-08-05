#!/bin/bash
set -euo pipefail

# Keycloak Vault Integration Enhancement Script
# Configures Keycloak with Vault KV v2 secrets and database integration
# Priority: High - Authentication service with PostgreSQL dependency
# Last Updated: August 5, 2025

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

function log_action() {
    echo "[$(date)] KEYCLOAK_ENHANCE: $1" | tee -a "$LOG_FILE"
    echo "🔧 $1"
}

function log_success() {
    echo "[$(date)] KEYCLOAK_ENHANCE: ✅ SUCCESS: $1" | tee -a "$LOG_FILE"
    echo "✅ $1"
}

function log_error() {
    echo "[$(date)] KEYCLOAK_ENHANCE: ❌ ERROR: $1" | tee -a "$LOG_FILE"
    echo "❌ $1"
}

function main() {
    log_action "Starting Keycloak Vault integration enhancement..."

    # Use universal enhancement script with Keycloak-specific configuration
    if [[ -x "/opt/dev-purebliss/enhance-container-with-vault.sh" ]]; then
        /opt/dev-purebliss/enhance-container-with-vault.sh keycloak kv_secrets
    else
        log_error "Universal enhancement script not found"
        exit 1
    fi

    # Keycloak-specific post-enhancement configuration
    log_action "Applying Keycloak-specific configurations..."

    # Create Keycloak-specific Vault entrypoint
    create_keycloak_vault_entrypoint

    # Create Keycloak realm configuration
    create_keycloak_realm_config

    # Update Keycloak Docker Compose with database integration
    update_keycloak_compose_with_database

    log_success "Keycloak Vault integration enhancement completed!"
}

function create_keycloak_vault_entrypoint() {
    log_action "Creating Keycloak-specific Vault entrypoint..."

    local keycloak_dir="/opt/dev-purebliss/services/keycloak"
    mkdir -p "$keycloak_dir"
    
    local entrypoint_file="$keycloak_dir/keycloak-vault-entrypoint.sh"

    cat > "$entrypoint_file" << 'EOF'
#!/bin/bash
set -euo pipefail

# Keycloak Vault Integration Entrypoint
# Fetches admin credentials and database configuration from Vault

VAULT_ADDR="${VAULT_ADDR:-https://purebliss-vault:8200}"
VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-true}"

# Wait for Vault to be ready
echo "Waiting for Vault to be ready..."
for i in {1..30}; do
    if curl -sk "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; then
        echo "Vault is ready"
        break
    fi
    if [[ $i -eq 30 ]]; then
        echo "ERROR: Vault not ready after 30 attempts"
        exit 1
    fi
    sleep 2
done

# Fetch Keycloak secrets from Vault
echo "Fetching Keycloak secrets from Vault..."
if [[ -f "/vault-token" ]]; then
    VAULT_TOKEN=$(cat /vault-token)
    export VAULT_TOKEN
    
    # Fetch Keycloak secrets
    KEYCLOAK_SECRETS=$(vault kv get -format=json secret/keycloak 2>/dev/null || echo '{}')
    
    if [[ "$KEYCLOAK_SECRETS" != '{}' ]]; then
        # Extract and export secrets
        export KEYCLOAK_ADMIN_PASSWORD=$(echo "$KEYCLOAK_SECRETS" | jq -r '.data.data.admin_password')
        export KC_DB_PASSWORD=$(echo "$KEYCLOAK_SECRETS" | jq -r '.data.data.db_password')
        export KEYCLOAK_MASTER_PASSWORD=$(echo "$KEYCLOAK_SECRETS" | jq -r '.data.data.master_password // .data.data.admin_password')
        
        # Set standard Keycloak environment variables
        export KEYCLOAK_ADMIN=admin
        export KC_DB=postgres
        export KC_DB_URL="jdbc:postgresql://purebliss-postgres:5432/keycloak"
        export KC_DB_USERNAME=keycloak
        export KC_HOSTNAME=dev.purebliss.app
        export KC_HOSTNAME_PORT=8443
        export KC_HOSTNAME_STRICT=false
        export KC_HTTP_ENABLED=true
        export KC_PROXY=edge
        
        echo "Keycloak secrets successfully loaded from Vault"
        echo "Admin user: $KEYCLOAK_ADMIN"
        echo "Database URL: $KC_DB_URL"
    else
        echo "ERROR: No Keycloak secrets found in Vault"
        exit 1
    fi
else
    echo "ERROR: Vault token not found at /vault-token"
    exit 1
fi

echo "Keycloak Vault integration initialization completed"

# Start Keycloak with proper command
exec /opt/keycloak/bin/kc.sh start --optimized
EOF

    chmod +x "$entrypoint_file"
    log_success "Keycloak Vault entrypoint created"
}

function create_keycloak_realm_config() {
    log_action "Creating Keycloak realm configuration..."

    local keycloak_dir="/opt/dev-purebliss/services/keycloak"
    local realm_config="$keycloak_dir/keycloak-realm-setup.sh"

    cat > "$realm_config" << 'EOF'
#!/bin/bash
# Keycloak Realm Setup with Vault-managed Configuration
# Creates realms and clients for Pure Bliss services

KEYCLOAK_ADMIN_URL="http://localhost:8080"
KEYCLOAK_ADMIN_USER="admin"

# Get admin password from Vault
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=1
export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

KEYCLOAK_ADMIN_PASSWORD=$(vault kv get -field=admin_password secret/keycloak)

# Wait for Keycloak to be ready
echo "Waiting for Keycloak to be ready..."
for i in {1..60}; do
    if curl -s "$KEYCLOAK_ADMIN_URL" >/dev/null 2>&1; then
        echo "Keycloak is ready"
        break
    fi
    if [[ $i -eq 60 ]]; then
        echo "ERROR: Keycloak not ready after 60 attempts"
        exit 1
    fi
    sleep 5
done

# Create realms using Keycloak Admin CLI
echo "Creating Pure Bliss realms..."

# CodeServer realm
/opt/keycloak/bin/kcadm.sh create realms \
    -s realm=codeserver \
    -s enabled=true \
    -s displayName="Pure Bliss Code Server" \
    --server "$KEYCLOAK_ADMIN_URL" \
    --realm master \
    --user "$KEYCLOAK_ADMIN_USER" \
    --password "$KEYCLOAK_ADMIN_PASSWORD"

# Plane realm  
/opt/keycloak/bin/kcadm.sh create realms \
    -s realm=planerealm \
    -s enabled=true \
    -s displayName="Pure Bliss Plane" \
    --server "$KEYCLOAK_ADMIN_URL" \
    --realm master \
    --user "$KEYCLOAK_ADMIN_USER" \
    --password "$KEYCLOAK_ADMIN_PASSWORD"

echo "Keycloak realms created successfully"
EOF

    chmod +x "$realm_config"
    log_success "Keycloak realm configuration created"
}

function update_keycloak_compose_with_database() {
    log_action "Updating Keycloak Docker Compose with database integration..."

    local keycloak_dir="/opt/dev-purebliss/services/keycloak"
    local compose_file="$keycloak_dir/keycloak-docker-compose-vault-enhanced.yml"

    # Update the generated compose file with Keycloak-specific configuration
    if [[ -f "$compose_file" ]]; then
        # Create enhanced version with database dependency
        cat > "${compose_file}.tmp" << 'EOF'
version: '3.8'

services:
  keycloak:
    image: quay.io/keycloak/keycloak:24.0.5
    container_name: purebliss-keycloak
    restart: unless-stopped
    environment:
      # Vault integration
      VAULT_ADDR: https://purebliss-vault:8200
      VAULT_SKIP_VERIFY: "true"
      # Database configuration (populated by entrypoint)
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://purebliss-postgres:5432/keycloak
      KC_DB_USERNAME: keycloak
      # Admin configuration (populated by entrypoint)
      KEYCLOAK_ADMIN: admin
      # Hostname configuration
      KC_HOSTNAME: dev.purebliss.app
      KC_HOSTNAME_PORT: 8443
      KC_HOSTNAME_STRICT: "false"
      KC_HTTP_ENABLED: "true"
      KC_PROXY: edge
    volumes:
      - ./keycloak-vault-entrypoint.sh:/opt/keycloak/bin/vault-entrypoint.sh:ro
      - keycloak_data:/opt/keycloak/data
    ports:
      - "8080:8080"
    networks:
      - purebliss-net
    healthcheck:
      test: ["CMD-SHELL", "exec 3<>/dev/tcp/localhost/8080 && echo -e 'GET / HTTP/1.1\\r\\nHost: localhost\\r\\n\\r\\n' >&3 && read -t1 response <&3 && exec 3<&- && exec 3>&-"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s
    depends_on:
      - vault
      - postgres
    entrypoint: ["/opt/keycloak/bin/vault-entrypoint.sh"]
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  keycloak_data:

networks:
  purebliss-net:
    external: true
EOF

        mv "${compose_file}.tmp" "$compose_file"
        log_success "Keycloak Docker Compose updated with database integration"
    else
        log_error "Keycloak Docker Compose file not found"
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
