#!/bin/bash
set -euo pipefail

# Monitoring Stack Vault Integration Enhancement Script
# Configures Grafana, Prometheus, and Loki with Vault KV v2 secrets
# Priority: Medium - Monitoring and observability services
# Last Updated: August 5, 2025

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

function log_action() {
    echo "[$(date)] MONITORING_ENHANCE: $1" | tee -a "$LOG_FILE"
    echo "🔧 $1"
}

function log_success() {
    echo "[$(date)] MONITORING_ENHANCE: ✅ SUCCESS: $1" | tee -a "$LOG_FILE"
    echo "✅ $1"
}

function log_error() {
    echo "[$(date)] MONITORING_ENHANCE: ❌ ERROR: $1" | tee -a "$LOG_FILE"
    echo "❌ $1"
}

function main() {
    log_action "Starting Monitoring Stack Vault integration enhancement..."

    # Enhance each monitoring service
    enhance_grafana
    enhance_prometheus
    enhance_loki

    log_success "Monitoring Stack Vault integration enhancement completed!"
}

function enhance_grafana() {
    log_action "Enhancing Grafana with Vault integration..."

    # Use universal enhancement script for Grafana
    if [[ -x "/opt/dev-purebliss/dev_scripts/services/enhance-container-with-vault.sh" ]]; then
        /opt/dev-purebliss/dev_scripts/services/enhance-container-with-vault.sh grafana monitoring_config
    else
        log_error "Universal enhancement script not found"
        return 1
    fi

    # Create Grafana-specific Vault entrypoint
    create_grafana_vault_entrypoint

    # Create Grafana datasource configuration with Vault
    create_grafana_datasource_config

    log_success "Grafana Vault integration completed"
}

function enhance_prometheus() {
    log_action "Enhancing Prometheus with Vault integration..."

    # Use universal enhancement script for Prometheus
    if [[ -x "/opt/dev-purebliss/dev_scripts/services/enhance-container-with-vault.sh" ]]; then
        /opt/dev-purebliss/dev_scripts/services/enhance-container-with-vault.sh prometheus monitoring_config
    else
        log_error "Universal enhancement script not found"
        return 1
    fi

    # Create Prometheus-specific Vault entrypoint
    create_prometheus_vault_entrypoint

    # Create Prometheus configuration with Vault service discovery
    create_prometheus_vault_config

    log_success "Prometheus Vault integration completed"
}

function enhance_loki() {
    log_action "Enhancing Loki with Vault integration..."

    # Use universal enhancement script for Loki
    if [[ -x "/opt/dev-purebliss/dev_scripts/services/enhance-container-with-vault.sh" ]]; then
        /opt/dev-purebliss/dev_scripts/services/enhance-container-with-vault.sh loki monitoring_config
    else
        log_error "Universal enhancement script not found"
        return 1
    fi

    # Create Loki-specific Vault entrypoint
    create_loki_vault_entrypoint

    log_success "Loki Vault integration completed"
}

function create_grafana_vault_entrypoint() {
    log_action "Creating Grafana Vault entrypoint..."

    local grafana_dir="/opt/dev-purebliss/services/grafana"
    mkdir -p "$grafana_dir"

    local entrypoint_file="$grafana_dir/grafana-vault-entrypoint.sh"

    cat > "$entrypoint_file" << 'EOF'
#!/bin/bash
set -euo pipefail

# Grafana Vault Integration Entrypoint
# Fetches admin credentials and datasource configuration from Vault

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

# Fetch Grafana secrets from Vault
echo "Fetching Grafana secrets from Vault..."
if [[ -f "/vault-token" ]]; then
    VAULT_TOKEN=$(cat /vault-token)
    export VAULT_TOKEN

    # Fetch Grafana secrets
    GRAFANA_SECRETS=$(vault kv get -format=json secret/grafana 2>/dev/null || echo '{}')

    if [[ "$GRAFANA_SECRETS" != '{}' ]]; then
        # Extract and export secrets
        export GF_SECURITY_ADMIN_PASSWORD=$(echo "$GRAFANA_SECRETS" | jq -r '.data.data.admin_password')
        export GF_DATABASE_PASSWORD=$(echo "$GRAFANA_SECRETS" | jq -r '.data.data.database_password // "grafana"')
        export GF_SECURITY_SECRET_KEY=$(echo "$GRAFANA_SECRETS" | jq -r '.data.data.secret_key')

        # Set standard Grafana environment variables
        export GF_SECURITY_ADMIN_USER=admin
        export GF_INSTALL_PLUGINS="grafana-piechart-panel,grafana-worldmap-panel,grafana-clock-panel"
        export GF_USERS_ALLOW_SIGN_UP=false
        export GF_USERS_ALLOW_ORG_CREATE=false
        export GF_USERS_AUTO_ASSIGN_ORG=true
        export GF_USERS_AUTO_ASSIGN_ORG_ROLE=Viewer
        export GF_SERVER_ROOT_URL=https://dev.purebliss.app/grafana/
        export GF_SERVER_SERVE_FROM_SUB_PATH=true

        echo "Grafana secrets successfully loaded from Vault"
        echo "Admin user: $GF_SECURITY_ADMIN_USER"
        echo "Root URL: $GF_SERVER_ROOT_URL"
    else
        echo "ERROR: No Grafana secrets found in Vault"
        exit 1
    fi
else
    echo "ERROR: Vault token not found at /vault-token"
    exit 1
fi

# Create datasource provisioning configuration
create_datasource_config

echo "Grafana Vault integration initialization completed"

# Start Grafana
exec /run.sh

function create_datasource_config() {
    echo "Creating Grafana datasource configuration..."

    mkdir -p /etc/grafana/provisioning/datasources

    # Prometheus datasource
    cat > /etc/grafana/provisioning/datasources/prometheus.yml << DSEOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://purebliss-prometheus:9090
    isDefault: true
    editable: true
    jsonData:
      timeInterval: "30s"
      queryTimeout: "60s"
      httpMethod: GET
    secureJsonData: {}

  - name: Loki
    type: loki
    access: proxy
    url: http://purebliss-loki:3100
    editable: true
    jsonData:
      maxLines: 1000
      timeout: 60
      queryTimeout: 300
    secureJsonData: {}
DSEOF

    echo "Grafana datasource configuration created"
}
EOF

    chmod +x "$entrypoint_file"
    log_success "Grafana Vault entrypoint created"
}

function create_grafana_datasource_config() {
    log_action "Creating Grafana datasource configuration..."

    local grafana_dir="/opt/dev-purebliss/services/grafana"
    local datasource_dir="$grafana_dir/provisioning/datasources"
    mkdir -p "$datasource_dir"

    cat > "$datasource_dir/purebliss-datasources.yml" << 'EOF'
apiVersion: 1

datasources:
  - name: Pure Bliss Prometheus
    type: prometheus
    access: proxy
    url: http://purebliss-prometheus:9090
    isDefault: true
    editable: true
    jsonData:
      timeInterval: "30s"
      queryTimeout: "60s"
      httpMethod: GET
      exemplarTraceIdDestinations:
        - name: traceID
          datasourceUid: loki
          urlDisplayLabel: "View in Loki"

  - name: Pure Bliss Loki
    type: loki
    access: proxy
    url: http://purebliss-loki:3100
    uid: loki
    editable: true
    jsonData:
      maxLines: 1000
      timeout: 60
      queryTimeout: 300
      derivedFields:
        - matcherRegex: "traceID=(\\w+)"
          name: TraceID
          url: "$${__value.raw}"
          datasourceUid: loki

  - name: Pure Bliss Postgres
    type: postgres
    access: proxy
    url: purebliss-postgres:5432
    database: grafana
    user: grafana
    editable: true
    jsonData:
      sslmode: "disable"
      maxOpenConns: 0
      maxIdleConns: 2
      connMaxLifetime: 14400
    secureJsonData:
      password: "${GF_DATABASE_PASSWORD}"
EOF

    log_success "Grafana datasource configuration created"
}

function create_prometheus_vault_entrypoint() {
    log_action "Creating Prometheus Vault entrypoint..."

    local prometheus_dir="/opt/dev-purebliss/services/prometheus"
    mkdir -p "$prometheus_dir"

    local entrypoint_file="$prometheus_dir/prometheus-vault-entrypoint.sh"

    cat > "$entrypoint_file" << 'EOF'
#!/bin/bash
set -euo pipefail

# Prometheus Vault Integration Entrypoint
# Configures Prometheus with Vault service discovery and authentication

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

# Fetch Prometheus configuration from Vault
echo "Fetching Prometheus configuration from Vault..."
if [[ -f "/vault-token" ]]; then
    VAULT_TOKEN=$(cat /vault-token)
    export VAULT_TOKEN

    # Fetch Prometheus secrets
    PROMETHEUS_SECRETS=$(vault kv get -format=json secret/prometheus 2>/dev/null || echo '{}')

    if [[ "$PROMETHEUS_SECRETS" != '{}' ]]; then
        echo "Prometheus secrets successfully loaded from Vault"
    else
        echo "WARNING: No Prometheus secrets found in Vault, using defaults"
    fi
else
    echo "ERROR: Vault token not found at /vault-token"
    exit 1
fi

echo "Prometheus Vault integration initialization completed"

# Start Prometheus
exec /bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/prometheus \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.console.templates=/etc/prometheus/consoles \
    --web.enable-lifecycle \
    --web.external-url=https://dev.purebliss.app/prometheus/ \
    --web.route-prefix=/prometheus/
EOF

    chmod +x "$entrypoint_file"
    log_success "Prometheus Vault entrypoint created"
}

function create_prometheus_vault_config() {
    log_action "Creating Prometheus configuration with Vault integration..."

    local prometheus_dir="/opt/dev-purebliss/services/prometheus"
    local config_file="$prometheus_dir/prometheus.yml"

    cat > "$config_file" << 'EOF'
# Prometheus Configuration with Vault Integration
# Monitors Pure Bliss Microservices Infrastructure

global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'purebliss-dev'
    environment: 'development'

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

scrape_configs:
  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
    metrics_path: '/prometheus/metrics'

  # Vault monitoring
  - job_name: 'vault'
    static_configs:
      - targets: ['purebliss-vault:8200']
    metrics_path: '/v1/sys/metrics'
    params:
      format: ['prometheus']
    scheme: https
    tls_config:
      insecure_skip_verify: true

  # Node Exporter (if available)
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['host.docker.internal:9100']

  # Docker containers monitoring
  - job_name: 'docker-containers'
    static_configs:
      - targets: ['host.docker.internal:9323']

  # PostgreSQL monitoring
  - job_name: 'postgres'
    static_configs:
      - targets: ['purebliss-postgres:5432']

  # Redis monitoring
  - job_name: 'redis'
    static_configs:
      - targets: ['purebliss-redis:6379']

  # Nginx monitoring
  - job_name: 'nginx'
    static_configs:
      - targets: ['purebliss-nginx:80']

  # Keycloak monitoring
  - job_name: 'keycloak'
    static_configs:
      - targets: ['purebliss-keycloak:8080']

  # CodeServer monitoring
  - job_name: 'codeserver'
    static_configs:
      - targets: ['purebliss-codeserver:8080']

  # Plane monitoring
  - job_name: 'plane'
    static_configs:
      - targets: ['purebliss-plane:3000']

  # Grafana monitoring
  - job_name: 'grafana'
    static_configs:
      - targets: ['purebliss-grafana:3000']

  # Loki monitoring
  - job_name: 'loki'
    static_configs:
      - targets: ['purebliss-loki:3100']
EOF

    # Create alerting rules directory and basic rules
    local rules_dir="$prometheus_dir/rules"
    mkdir -p "$rules_dir"

    cat > "$rules_dir/purebliss-alerts.yml" << 'EOF'
groups:
  - name: purebliss.rules
    rules:
      # Service availability alerts
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"
          description: "Service {{ $labels.job }} has been down for more than 1 minute."

      # High memory usage
      - alert: HighMemoryUsage
        expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.container_label_com_docker_compose_service }}"
          description: "Memory usage is above 80% for more than 5 minutes."

      # High CPU usage
      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total[5m]) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.container_label_com_docker_compose_service }}"
          description: "CPU usage is above 80% for more than 5 minutes."

      # Vault seal status
      - alert: VaultSealed
        expr: vault_core_unsealed == 0
        for: 0s
        labels:
          severity: critical
        annotations:
          summary: "Vault is sealed"
          description: "Vault instance is sealed and unavailable."

      # Database connection issues
      - alert: DatabaseConnectionFailure
        expr: pg_up == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "PostgreSQL database connection failed"
          description: "Unable to connect to PostgreSQL database for more than 2 minutes."
EOF

    log_success "Prometheus configuration with Vault integration created"
}

function create_loki_vault_entrypoint() {
    log_action "Creating Loki Vault entrypoint..."

    local loki_dir="/opt/dev-purebliss/services/loki"
    mkdir -p "$loki_dir"

    local entrypoint_file="$loki_dir/loki-vault-entrypoint.sh"

    cat > "$entrypoint_file" << 'EOF'
#!/bin/bash
set -euo pipefail

# Loki Vault Integration Entrypoint
# Configures Loki with Vault-managed storage credentials

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

# Fetch Loki configuration from Vault
echo "Fetching Loki configuration from Vault..."
if [[ -f "/vault-token" ]]; then
    VAULT_TOKEN=$(cat /vault-token)
    export VAULT_TOKEN

    # Fetch Loki secrets (if any)
    LOKI_SECRETS=$(vault kv get -format=json secret/loki 2>/dev/null || echo '{}')

    if [[ "$LOKI_SECRETS" != '{}' ]]; then
        echo "Loki secrets successfully loaded from Vault"
    else
        echo "INFO: No Loki secrets found in Vault, using defaults"
    fi
else
    echo "ERROR: Vault token not found at /vault-token"
    exit 1
fi

echo "Loki Vault integration initialization completed"

# Start Loki
exec /usr/bin/loki -config.file=/etc/loki/local-config.yaml
EOF

    chmod +x "$entrypoint_file"
    log_success "Loki Vault entrypoint created"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
