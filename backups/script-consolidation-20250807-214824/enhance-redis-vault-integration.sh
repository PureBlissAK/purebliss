#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh" 2>/dev/null || true
source "$SCRIPT_DIR/utilities/retry-utils.sh" 2>/dev/null || true

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="[Enhanced with centralized structure]"

set -euo pipefail

# Redis Vault Integration Enhancement Script
# Configures Redis with Vault database plugin for dynamic credential management
# Priority: Next after PostgreSQL completion
# Last Updated: August 5, 2025

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

function log_action() {
    echo "[$(date)] REDIS_ENHANCE: $1" | tee -a "$LOG_FILE"
    echo "🔧 $1"
}

function log_success() {
    echo "[$(date)] REDIS_ENHANCE: ✅ SUCCESS: $1" | tee -a "$LOG_FILE"
    echo "✅ $1"
}

function log_error() {
    echo "[$(date)] REDIS_ENHANCE: ❌ ERROR: $1" | tee -a "$LOG_FILE"
    echo "❌ $1"
}

function main() {
    log_action "Starting Redis Vault integration enhancement..."

    # Use universal enhancement script with Redis-specific configuration
    if [[ -x "/opt/dev-purebliss/dev_scripts/services/enhance-container-with-vault.sh" ]]; then
        /opt/dev-purebliss/dev_scripts/services/enhance-container-with-vault.sh redis database_dynamic
    else
        log_error "Universal enhancement script not found"
        exit 1
    fi

    # Redis-specific post-enhancement configuration
    log_action "Applying Redis-specific configurations..."

    # Create Redis-specific database plugin configuration
    create_redis_database_plugin_config

    # Create Redis monitoring configuration
    create_redis_monitoring_config

    log_success "Redis Vault integration enhancement completed!"
}

function create_redis_database_plugin_config() {
    log_action "Creating Redis database plugin configuration..."

    local redis_dir="/opt/dev-purebliss/services/redis"
    local config_file="$redis_dir/redis-vault-database-config.sh"

    cat > "$config_file" << 'EOF'
#!/bin/bash
# Redis Database Plugin Configuration for Vault
# Configures Vault to manage Redis dynamic credentials

export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=1
export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

# Enable Redis database secrets engine
log_action "Enabling Redis database secrets engine..."
vault secrets enable -path=redis database

# Configure Redis connection
log_action "Configuring Redis database connection..."
vault write redis/config/redis \
    plugin_name=redis-database-plugin \
    connection_url="redis://purebliss-redis:6379" \
    allowed_roles="redis-role" \
    max_open_connections=5 \
    max_idle_connections=0 \
    max_connection_lifetime="1h"

# Create Redis role for dynamic credentials
log_action "Creating Redis role for dynamic credentials..."
vault write redis/roles/redis-role \
    db_name=redis \
    creation_statements='["~*", "&*", "+@all", "-@dangerous"]' \
    default_ttl="1h" \
    max_ttl="24h"

log_success "Redis database plugin configuration completed"
EOF

    chmod +x "$config_file"
    log_success "Redis database plugin configuration script created"
}

function create_redis_monitoring_config() {
    log_action "Creating Redis monitoring configuration..."

    local redis_dir="/opt/dev-purebliss/services/redis"
    local monitor_file="$redis_dir/redis-vault-monitoring.yml"

    cat > "$monitor_file" << 'EOF'
# Redis Monitoring Configuration for Vault Integration
# Prometheus metrics and health checks for Redis with Vault

redis_monitoring:
  metrics:
    enabled: true
    port: 6379
    auth: vault-managed
  health_checks:
    - name: redis_ping
      command: "redis-cli ping"
      expected: "PONG"
    - name: vault_connectivity
      command: "nc -z purebliss-vault 8200"
      expected: "success"
    - name: dynamic_credentials
      command: "vault read redis/creds/redis-role"
      expected: "credentials_generated"
  alerts:
    - name: redis_down
      condition: "redis_ping != PONG"
      severity: critical
    - name: vault_integration_failed
      condition: "dynamic_credentials == failed"
      severity: high
EOF

    log_success "Redis monitoring configuration created"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
