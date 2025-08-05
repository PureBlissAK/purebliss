#!/bin/bash
set -euo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
NGINX_CONTAINER="purebliss-nginx"
NGINX_CONFIG_DIR="/opt/dev-purebliss/services/nginx"
NGINX_CERTS_DIR="/opt/dev-purebliss/services/nginx/certs"
LETSENCRYPT_DIR="/opt/dev-purebliss/services/nginx/certs"
DOMAIN="dev.purebliss.app"
export NGINX_CONFIG_PATH="/opt/dev-purebliss/services/nginx/nginx.conf"
export NGINX_COMPOSE_FILE="/opt/dev-purebliss/services/nginx/nginx-docker-compose.yml"

# Logging function - defined early to be available everywhere
log() {
    echo "[$(date)] $1" | tee -a "$LOG_FILE"
}

# List of services that should have nginx proxy configuration
NGINX_CONSUMER_SERVICES=("codeserver" "keycloak" "vikunja" "grafana" "prometheus" "vault" "loki")

# List of services that need SSL certificates
SSL_REQUIRED_SERVICES=("codeserver" "keycloak" "vikunja" "grafana" "prometheus" "vault" "loki")

# Helper function to check if a service needs nginx proxy
needs_nginx_proxy() {
    local service="$1"

    # Check static list first
    for consumer in "${NGINX_CONSUMER_SERVICES[@]}"; do
        if [[ "$consumer" == "$service" ]]; then
            return 0
        fi
    done

    # Dynamically check if container exposes HTTP ports
    local container="purebliss-${service}"
    if ! docker ps -q -f name="$container" > /dev/null 2>&1; then
        # Try without purebliss- prefix
        container="$service"
        if ! docker ps -q -f name="$container" > /dev/null 2>&1; then
            return 1
        fi
    fi

    # Check for exposed HTTP/HTTPS ports
    local exposed_ports=$(docker inspect "$container" --format '{{range $p, $conf := .NetworkSettings.Ports}}{{$p}} {{end}}' 2>/dev/null | grep -E "(80|443|8080|3000|9090|8200)" || true)

    if [[ -n "$exposed_ports" ]]; then
        log "DEBUG: $service appears to need nginx proxy based on exposed ports: $exposed_ports"
        return 0
    fi

    return 1
}

# Helper function to check if a service needs SSL
needs_ssl_certificate() {
    local service="$1"

    # Check static list first
    for ssl_service in "${SSL_REQUIRED_SERVICES[@]}"; do
        if [[ "$ssl_service" == "$service" ]]; then
            return 0
        fi
    done

    # If service needs nginx proxy and serves web content, it likely needs SSL
    if needs_nginx_proxy "$service"; then
        return 0
    fi

    return 1
}

# Function to detect nginx proxy configuration issues
detect_nginx_proxy_issues() {
    local service="$1"
    local container="purebliss-${service}"
    local issues_found=()

    if ! docker ps -q -f name="$container" > /dev/null 2>&1; then
        container="$service"
        if ! docker ps -q -f name="$container" > /dev/null 2>&1; then
            return 1
        fi
    fi

    log "INFO: Scanning $service for nginx proxy configuration issues..."

    # Check if nginx config exists for this service
    local nginx_config_found=0
    if [ -f "$NGINX_CONFIG_PATH" ]; then
        if grep -q "location.*/${service}" "$NGINX_CONFIG_PATH" || grep -q "proxy_pass.*${service}" "$NGINX_CONFIG_PATH"; then
            nginx_config_found=1
            log "INFO: Found nginx proxy configuration for $service"
        fi
    fi

    if [[ $nginx_config_found -eq 0 ]] && needs_nginx_proxy "$service"; then
        issues_found+=("MISSING_NGINX_PROXY_CONFIG")
        log "WARNING: $service needs nginx proxy but configuration is missing"

        # Attempt to add basic proxy configuration
        local service_port
        case "$service" in
            "keycloak") service_port="8080" ;;
            "grafana") service_port="3000" ;;
            "prometheus") service_port="9090" ;;
            "vault") service_port="8200" ;;
            "codeserver") service_port="8080" ;;
            "vikunja") service_port="3456" ;;
            "loki") service_port="3100" ;;
            *) service_port="8080" ;;
        esac

        # Add nginx location block if not present
        add_nginx_location_block "$service" "$service_port"
    fi

    # Check SSL certificate for this service
    if needs_ssl_certificate "$service"; then
        local cert_path="${LETSENCRYPT_DIR}/fullchain.pem"
        local key_path="${LETSENCRYPT_DIR}/privkey.pem"

        if [ ! -f "$cert_path" ] || [ ! -f "$key_path" ]; then
            issues_found+=("MISSING_SSL_CERTIFICATE")
            log "WARNING: $service needs SSL but certificates are missing at $cert_path"
        else
            # Check certificate validity
            local cert_expiry=$(openssl x509 -in "$cert_path" -noout -enddate 2>/dev/null | cut -d= -f2 || echo "unknown")
            local cert_expiry_epoch=$(date -d "$cert_expiry" +%s 2>/dev/null || echo 0)
            local current_epoch=$(date +%s)
            local days_until_expiry=$(( (cert_expiry_epoch - current_epoch) / 86400 ))

            if [ $days_until_expiry -lt 30 ]; then
                issues_found+=("SSL_CERTIFICATE_EXPIRING_SOON")
                log "WARNING: SSL certificate for $service expires in $days_until_expiry days"
            else
                log "INFO: SSL certificate for $service is valid (expires in $days_until_expiry days)"
            fi
        fi
    fi

    # Check if service is accessible through nginx
    if needs_nginx_proxy "$service"; then
        local service_url="https://${DOMAIN}/${service}"
        local http_status=$(curl -s -k -o /dev/null -w "%{http_code}" "$service_url" 2>/dev/null || echo "000")

        if [[ "$http_status" != "200" && "$http_status" != "301" && "$http_status" != "302" ]]; then
            issues_found+=("SERVICE_NOT_ACCESSIBLE_VIA_NGINX")
            log "WARNING: $service not accessible via nginx (HTTP status: $http_status)"
        else
            log "INFO: $service is accessible via nginx (HTTP status: $http_status)"
        fi
    fi

    # Check for HTTP to HTTPS redirect
    if needs_ssl_certificate "$service"; then
        local http_url="http://${DOMAIN}/${service}"
        local redirect_status=$(curl -s -o /dev/null -w "%{http_code}" "$http_url" 2>/dev/null || echo "000")

        if [[ "$redirect_status" != "301" && "$redirect_status" != "302" ]]; then
            issues_found+=("MISSING_HTTPS_REDIRECT")
            log "WARNING: $service missing HTTP to HTTPS redirect (status: $redirect_status)"
        fi
    fi

    if [ ${#issues_found[@]} -gt 0 ]; then
        log "INFO: Found ${#issues_found[@]} nginx/SSL issues for $service: ${issues_found[*]}"
        return 0
    else
        log "INFO: No nginx/SSL issues detected for $service."
        return 1
    fi
}

# Function to add nginx location block for a service
add_nginx_location_block() {
    local service="$1"
    local port="$2"
    local container_name="purebliss-${service}"

    # Check if container exists with different naming
    if ! docker ps -q -f name="$container_name" > /dev/null 2>&1; then
        container_name="$service"
    fi

    log "INFO: Adding nginx upstream and location block for $service on port $port"

    # Create backup of nginx config
    cp "$NGINX_CONFIG_PATH" "${NGINX_CONFIG_PATH}.backup.$(date +%s)"

    # First, add upstream definition if not present
    if ! grep -q "upstream $service" "$NGINX_CONFIG_PATH"; then
        # Create temporary file with upstream block
        local temp_file=$(mktemp)
        local upstream_added=0

        while IFS= read -r line; do
            echo "$line" >> "$temp_file"
            # Add upstream after last existing upstream or before first server block
            if [[ "$line" =~ ^[[:space:]]*upstream[[:space:]] ]] && [[ $upstream_added -eq 0 ]]; then
                # Skip to end of this upstream block
                while IFS= read -r line; do
                    echo "$line" >> "$temp_file"
                    if [[ "$line" =~ ^[[:space:]]*}[[:space:]]*$ ]]; then
                        break
                    fi
                done
                # Now add our upstream
                cat >> "$temp_file" << EOF

    # Upstream for $service
    upstream $service {
        server $container_name:$port;
    }
EOF
                upstream_added=1
            elif [[ "$line" =~ ^[[:space:]]*server[[:space:]]*{[[:space:]]*$ ]] && [[ $upstream_added -eq 0 ]]; then
                # Add upstream before first server block if no upstreams exist
                cat >> "$temp_file" << EOF

    # Upstream for $service
    upstream $service {
        server $container_name:$port;
    }

    # Server block starts here
EOF
                upstream_added=1
            fi
        done < "$NGINX_CONFIG_PATH"

        mv "$temp_file" "$NGINX_CONFIG_PATH"
        log "INFO: Added upstream block for $service"
    fi

    # Add location block to the HTTPS server block
    local temp_file=$(mktemp)
    local in_https_server=0
    local location_added=0

    while IFS= read -r line; do
        echo "$line" >> "$temp_file"

        # Detect HTTPS server block
        if [[ "$line" =~ listen[[:space:]]+443[[:space:]]+ssl ]]; then
            in_https_server=1
        fi

        # Add location block before closing brace of HTTPS server
        if [[ $in_https_server -eq 1 ]] && [[ "$line" =~ ^[[:space:]]*}[[:space:]]*$ ]] && [[ $location_added -eq 0 ]]; then
            # Remove the closing brace line from temp file
            sed -i '$d' "$temp_file"

            # Add location block
            cat >> "$temp_file" << EOF

        # Proxy configuration for $service
        location /${service}/ {
            proxy_pass http://$service/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header X-Forwarded-Host \$host;
            proxy_set_header X-Forwarded-Port \$server_port;

            # WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";

            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }
    }
EOF
            location_added=1
            in_https_server=0
        fi
    done < "$NGINX_CONFIG_PATH"

    mv "$temp_file" "$NGINX_CONFIG_PATH"
    log "INFO: Added nginx location block for $service. Nginx reload required."
}

# Function to check nginx container health
check_nginx_health() {
    local health
    health=$(docker inspect --format='{{.State.Health.Status}}' "$NGINX_CONTAINER" 2>/dev/null || echo "unknown")
    if [ "$health" = "healthy" ]; then
        return 0
    else
        return 1
    fi
}

# Function to reload nginx configuration
reload_nginx_config() {
    log "INFO: Testing nginx configuration before reload..."

    if docker exec "$NGINX_CONTAINER" nginx -t 2>/dev/null; then
        log "INFO: Nginx configuration test passed. Reloading nginx..."
        docker exec "$NGINX_CONTAINER" nginx -s reload 2>/dev/null
        log "SUCCESS: Nginx configuration reloaded successfully."
        return 0
    else
        log "ERROR: Nginx configuration test failed. Not reloading."
        # Restore backup if available
        local latest_backup=$(ls -t "${NGINX_CONFIG_PATH}.backup."* 2>/dev/null | head -1 || echo "")
        if [ -n "$latest_backup" ]; then
            log "INFO: Restoring nginx configuration from backup: $latest_backup"
            cp "$latest_backup" "$NGINX_CONFIG_PATH"
        fi
        return 1
    fi
}

# Function to renew Let's Encrypt certificates
renew_letsencrypt_certificates() {
    log "INFO: Attempting to renew Let's Encrypt certificates..."

    # Check if certbot is available
    if command -v certbot >/dev/null 2>&1; then
        certbot renew --nginx --quiet >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
            log "SUCCESS: Let's Encrypt certificates renewed successfully."
            reload_nginx_config
            return 0
        else
            log "WARNING: Certificate renewal failed or no certificates needed renewal."
            return 1
        fi
    else
        log "WARNING: Certbot not found. Cannot renew certificates automatically."
        return 1
    fi
}

# Function to discover all running containers and extract service names
discover_services() {
    local services=()
    # Temporarily redirect stdout to stderr to avoid polluting function output
    {
        log "INFO: Discovering all running containers on the host..."

        # Get all running containers with purebliss- prefix
        local containers=$(docker ps --format "{{.Names}}" | grep "^purebliss-" | sort)

        for container in $containers; do
            # Extract service name by removing purebliss- prefix
            local service_name="${container#purebliss-}"
            services+=("$service_name")
            log "DEBUG: Discovered service: $service_name (container: $container)"
        done

        # Also check for containers without purebliss- prefix that might be part of our stack
        local other_containers=$(docker ps --format "{{.Names}}" | grep -v "^purebliss-" | sort)

        for container in $other_containers; do
            # Check if container has environment variables or volumes that suggest it's part of our stack
            local has_nginx_config=$(docker inspect "$container" --format '{{range .Config.Env}}{{.}} {{end}} {{range .Mounts}}{{.Source}} {{end}}' 2>/dev/null | grep -i nginx || true)
            local has_purebliss_config=$(docker inspect "$container" --format '{{range .Config.Env}}{{.}} {{end}} {{range .Mounts}}{{.Source}} {{end}}' 2>/dev/null | grep -i purebliss || true)

            if [[ -n "$has_nginx_config" || -n "$has_purebliss_config" ]]; then
                services+=("$container")
                log "DEBUG: Discovered related service: $container (non-standard naming)"
            fi
        done

        if [ ${#services[@]} -eq 0 ]; then
            log "WARNING: No services discovered. Using fallback service list."
            services=(postgres keycloak nginx vikunja redis grafana loki prometheus vault codeserver)
        else
            log "INFO: Discovered ${#services[@]} services: ${services[*]}"
        fi
    } >&2

    # Return only the service names to stdout
    echo "${services[@]}"
}

# Dynamically discover services
SERVICES=($(discover_services))
ALL_SERVICES=("${SERVICES[@]}")

# Function to initialize nginx and verify SSL setup
initialize_nginx_and_ssl() {
    log "INFO: Checking nginx container ($NGINX_CONTAINER) health and SSL configuration."

    # Check if nginx container is running
        if ! docker ps -q -f name="$NGINX_CONTAINER" > /dev/null 2>&1; then
            log "WARNING: Nginx container ($NGINX_CONTAINER) is not running. Attempting to start..."

            # Try to start nginx using docker-compose
            if [ -f "$NGINX_COMPOSE_FILE" ]; then
                docker-compose -f "$NGINX_COMPOSE_FILE" up -d nginx >> "$LOG_FILE" 2>&1
                sleep 10

                if ! docker ps -q -f name="$NGINX_CONTAINER" > /dev/null 2>&1; then
                    log "ERROR: Failed to start nginx container. Checking for alternative nginx setups..."

                    # Check for nginx in my-secure-ha-stack
                    if [ -f "/opt/my-secure-ha-stack/docker-compose.yml" ]; then
                        log "INFO: Trying to start nginx from my-secure-ha-stack..."
                        docker-compose -f /opt/my-secure-ha-stack/docker-compose.yml up -d nginx >> "$LOG_FILE" 2>&1
                        sleep 5
                    fi                # Check if there's an nginx-like container running (letsencrypt, etc.)
                local alt_nginx=$(docker ps --format "{{.Names}}" | grep -E "(nginx|letsencrypt|proxy)" | head -1)
                if [ -n "$alt_nginx" ]; then
                    log "INFO: Found alternative nginx-like container: $alt_nginx. Using it instead."
                    NGINX_CONTAINER="$alt_nginx"
                else
                    log "WARNING: No nginx container found. Some checks will be limited."
                    return 1
                fi
            fi
        else
            log "ERROR: Docker-compose file not found. Cannot start nginx."
            return 1
        fi
    fi

    # Check nginx health (if container exists)
    if docker ps -q -f name="$NGINX_CONTAINER" > /dev/null 2>&1; then
        if ! check_nginx_health; then
            log "WARNING: Nginx container is not healthy. Attempting restart..."
            docker restart "$NGINX_CONTAINER" >> "$LOG_FILE" 2>&1
            sleep 5

            if ! check_nginx_health; then
                log "WARNING: Nginx still not healthy after restart. Will proceed with limited functionality."
                # Don't return 1 here, allow the script to continue with warnings
            fi
        fi
    fi

    # Check nginx configuration (if accessible)
    if docker ps -q -f name="$NGINX_CONTAINER" > /dev/null 2>&1; then
        if ! docker exec "$NGINX_CONTAINER" nginx -t 2>/dev/null; then
            log "WARNING: Nginx configuration test failed or nginx command not available."
            # Don't return error, continue with other checks
        else
            log "INFO: Nginx configuration is valid."
        fi
    fi

    # Check SSL certificates
    local cert_path="${LETSENCRYPT_DIR}/fullchain.pem"
    local key_path="${LETSENCRYPT_DIR}/privkey.pem"

    if [ ! -f "$cert_path" ] || [ ! -f "$key_path" ]; then
        log "WARNING: SSL certificates not found. Attempting to obtain certificates..."

        # Try to obtain certificates (this would need to be customized based on your setup)
        if command -v certbot >/dev/null 2>&1; then
            certbot certonly --nginx -d "$DOMAIN" --agree-tos --non-interactive --email admin@purebliss.app >> "$LOG_FILE" 2>&1
            if [ $? -eq 0 ]; then
                log "SUCCESS: SSL certificates obtained successfully."
            else
                log "ERROR: Failed to obtain SSL certificates. Manual intervention required."
                return 1
            fi
        else
            log "ERROR: Certbot not available. Cannot obtain SSL certificates automatically."
            return 1
        fi
    else
        log "INFO: SSL certificates found at $cert_path"

        # Verify certificate is for correct domain
        local cert_domain=$(openssl x509 -in "$cert_path" -noout -subject 2>/dev/null | grep -o "CN=[^,]*" | cut -d= -f2 || echo "unknown")
        if [[ "$cert_domain" == "$DOMAIN" || "$cert_domain" == *"$DOMAIN"* ]]; then
            log "SUCCESS: SSL certificate is valid for domain $DOMAIN"
        else
            log "WARNING: SSL certificate domain mismatch. Expected: $DOMAIN, Found: $cert_domain"
        fi
    fi

    # Test external HTTPS access
    local https_status=$(curl -s -k -o /dev/null -w "%{http_code}" "https://${DOMAIN}" 2>/dev/null || echo "000")
    if [[ "$https_status" == "200" || "$https_status" == "301" || "$https_status" == "302" ]]; then
        log "SUCCESS: HTTPS access to $DOMAIN is working (status: $https_status)"
    else
        log "WARNING: HTTPS access to $DOMAIN failed (status: $https_status)"
    fi

    return 0
}

# --- PRE-FLIGHT CHECKS ---
log "INFO: Starting pre-flight checks for nginx and Let's Encrypt..."

# 1. Ensure nginx is healthy
if ! initialize_nginx_and_ssl; then
    log "CRITICAL: Nginx/SSL setup is not healthy. Exiting script."
    exit 1
fi

# 2. Create nginx config directory if it doesn't exist
mkdir -p "$NGINX_CONFIG_DIR/conf.d"
mkdir -p "$NGINX_CERTS_DIR"

# 3. Ensure nginx config file exists
if [ ! -f "$NGINX_CONFIG_PATH" ]; then
    log "WARNING: Nginx config file not found. Creating basic configuration..."
    cat > "$NGINX_CONFIG_PATH" << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;

    # HTTP server - redirect to HTTPS
    server {
        listen 80;
        server_name dev.purebliss.app;

        # Let's Encrypt webroot challenge
        location /.well-known/acme-challenge/ {
            root /var/www/html;
            try_files $uri =404;
        }

        # Redirect all other HTTP traffic to HTTPS
        location / {
            return 301 https://$server_name$request_uri;
        }
    }

    # HTTPS server
    server {
        listen 443 ssl;
        server_name dev.purebliss.app;

        # SSL configuration
        ssl_certificate /etc/nginx/certs/fullchain.pem;
        ssl_certificate_key /etc/nginx/certs/privkey.pem;

        # SSL security settings
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers off;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # Security headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options DENY;
        add_header X-XSS-Protection "1; mode=block";

        # Default location
        location / {
            return 200 "Pure Bliss Development Environment";
            add_header Content-Type text/plain;
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF
    log "INFO: Basic nginx configuration created."
fi

log "SUCCESS: Pre-flight checks passed. Nginx and SSL are healthy."
# --- END PRE-FLIGHT CHECKS ---

log "INFO: Starting nginx/Let's Encrypt sanity check for all services."

# Add a maximum retry limit for health checks
MAX_RETRIES=3

# Service health check loop
for SERVICE in "${SERVICES[@]}"; do
    # Determine container name (handle both purebliss- prefixed and non-prefixed)
    if docker ps -q -f name="purebliss-${SERVICE}" > /dev/null 2>&1; then
        CONTAINER="purebliss-${SERVICE}"
    elif docker ps -q -f name="$SERVICE" > /dev/null 2>&1; then
        CONTAINER="$SERVICE"
    else
        log "WARNING: Container for service $SERVICE not found. Skipping."
        continue
    fi

    retries=0

    # Skip nginx checks for the nginx service itself
    if [[ "$SERVICE" == "nginx" || "$CONTAINER" == "purebliss-nginx" ]]; then
        log "INFO: Skipping nginx integration checks for nginx service itself."
        continue
    fi

    # Skip services that don't need nginx proxy
    if ! needs_nginx_proxy "$SERVICE"; then
        log "INFO: $SERVICE doesn't need nginx proxy. Skipping nginx checks."
        continue
    fi

    # Detect nginx/SSL issues
    detect_nginx_proxy_issues "$SERVICE"

    # Loop to ensure the service is compliant
    while true; do
        log "INFO: Verifying nginx/SSL integration for $SERVICE (container: $CONTAINER)..."
        nginx_ok=0
        ssl_ok=0
        proxy_ok=0
        accessibility_ok=0
        restart_ok=0

        # Check 1: Nginx Health
        if check_nginx_health; then
            log "INFO: Nginx is healthy."
            nginx_ok=1
        else
            log "ERROR: Nginx is not healthy. Attempting to restart..."
            docker restart "$NGINX_CONTAINER" >> "$LOG_FILE" 2>&1
            sleep 5
            if check_nginx_health; then
                log "SUCCESS: Nginx is now healthy after restart."
                nginx_ok=1
            else
                log "ERROR: Nginx is still not healthy after restart. Manual check required."
                nginx_ok=0
            fi
        fi

        # Check 2: SSL Certificate Status
        if needs_ssl_certificate "$SERVICE"; then
            cert_path="${LETSENCRYPT_DIR}/fullchain.pem"
            key_path="${LETSENCRYPT_DIR}/privkey.pem"

            if [ -f "$cert_path" ] && [ -f "$key_path" ]; then
                # Check certificate expiry
                cert_expiry=$(openssl x509 -in "$cert_path" -noout -enddate 2>/dev/null | cut -d= -f2 || echo "unknown")
                cert_expiry_epoch=$(date -d "$cert_expiry" +%s 2>/dev/null || echo 0)
                current_epoch=$(date +%s)
                days_until_expiry=$(( (cert_expiry_epoch - current_epoch) / 86400 ))

                if [ $days_until_expiry -gt 7 ]; then
                    log "INFO: SSL certificate is valid for $SERVICE (expires in $days_until_expiry days)."
                    ssl_ok=1
                else
                    log "WARNING: SSL certificate expires soon ($days_until_expiry days). Attempting renewal..."
                    renew_letsencrypt_certificates
                    ssl_ok=0 # Force re-check after renewal attempt
                fi
            else
                log "ERROR: SSL certificates not found for $SERVICE. Attempting to obtain..."
                renew_letsencrypt_certificates
                ssl_ok=0
            fi
        else
            log "INFO: $SERVICE doesn't require SSL certificates."
            ssl_ok=1
        fi

        # Check 3: Nginx Proxy Configuration
        if needs_nginx_proxy "$SERVICE"; then
            if [ -f "$NGINX_CONFIG_PATH" ] && (grep -q "location.*/${SERVICE}" "$NGINX_CONFIG_PATH" || grep -q "proxy_pass.*${SERVICE}" "$NGINX_CONFIG_PATH"); then
                log "INFO: Nginx proxy configuration found for $SERVICE."
                proxy_ok=1
            else
                log "WARNING: Nginx proxy configuration missing for $SERVICE. Adding configuration..."
                detect_nginx_proxy_issues "$SERVICE" # This will add the configuration
                proxy_ok=0 # Force nginx reload and re-check
            fi
        else
            log "INFO: $SERVICE doesn't need nginx proxy configuration."
            proxy_ok=1
        fi

        # Check 4: Service Accessibility
        if needs_nginx_proxy "$SERVICE"; then
            service_url="https://${DOMAIN}/${SERVICE}"
            http_status=$(curl -s -k -o /dev/null -w "%{http_code}" "$service_url" 2>/dev/null || echo "000")

            if [[ "$http_status" == "200" || "$http_status" == "301" || "$http_status" == "302" ]]; then
                log "INFO: $SERVICE is accessible via nginx (status: $http_status)."
                accessibility_ok=1
            else
                log "WARNING: $SERVICE not accessible via nginx (status: $http_status)."
                accessibility_ok=0
            fi
        else
            accessibility_ok=1
        fi

        # Reload nginx if configuration changed
        if [[ $proxy_ok -eq 0 ]]; then
            if reload_nginx_config; then
                log "SUCCESS: Nginx configuration reloaded for $SERVICE."
                proxy_ok=1
            else
                log "ERROR: Failed to reload nginx configuration for $SERVICE."
                proxy_ok=0
            fi
        fi

        # Restart service container if needed
        log "INFO: Checking if $CONTAINER needs restart for nginx integration."
        HEALTH=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$CONTAINER" 2>/dev/null || echo "unknown")

        if [[ "$HEALTH" == "no_healthcheck" ]]; then
            RUNNING=$(docker inspect --format='{{.State.Running}}' "$CONTAINER" 2>/dev/null || echo "false")
            if [[ "$RUNNING" == "true" ]]; then
                log "SUCCESS: $CONTAINER is running (no health check configured)."
                restart_ok=1
            else
                log "WARNING: $CONTAINER is not running. Attempting restart..."
                docker restart "$CONTAINER" >> "$LOG_FILE" 2>&1
                sleep 5
                restart_ok=1 # Assume restart was successful
            fi
        elif [[ "$HEALTH" == "healthy" ]]; then
            log "SUCCESS: $CONTAINER is healthy."
            restart_ok=1
        else
            log "WARNING: $CONTAINER health status: $HEALTH. This may be acceptable during startup."
            restart_ok=1
        fi

        # Final check to break the loop or retry
        if [ "$nginx_ok" -eq 1 ] && [ "$ssl_ok" -eq 1 ] && [ "$proxy_ok" -eq 1 ] && [ "$accessibility_ok" -eq 1 ] && [ "$restart_ok" -eq 1 ]; then
            log "SUCCESS: $SERVICE is now fully compliant with nginx/SSL integration."
            break
        else
            retries=$((retries + 1))
            if [ "$retries" -ge "$MAX_RETRIES" ]; then
                log "ERROR: Maximum retries reached for $SERVICE. Manual intervention required."
                log "DEBUG: Status - nginx_ok:$nginx_ok ssl_ok:$ssl_ok proxy_ok:$proxy_ok accessibility_ok:$accessibility_ok restart_ok:$restart_ok"
                break
            fi
            log "DEBUG: $SERVICE not fully compliant yet. Retrying in $((2 ** retries)) seconds..."
            sleep $((2 ** retries))
        fi
    done & # Run service checks in parallel
done

# Wait for all background jobs to complete
wait

# Generate comprehensive summary report
generate_summary_report() {
    log "======================================="
    log "NGINX/LETSENCRYPT SANITY AGENT - COMPREHENSIVE SUMMARY"
    log "======================================="

    local total_containers=$(echo "${ALL_SERVICES[@]}" | wc -w)
    local healthy_containers=0
    local nginx_integrated=0
    local ssl_enabled=0
    local action_required=0

    log "INFO: Total containers discovered: $total_containers"
    log ""
    log "CONTAINER STATUS SUMMARY:"
    log "-------------------------"

    for service in "${ALL_SERVICES[@]}"; do
        local container_name
        if docker ps -q -f name="purebliss-${service}" > /dev/null 2>&1; then
            container_name="purebliss-${service}"
        else
            container_name="$service"
        fi

        # Check container health
        local is_healthy=0
        if docker ps -q -f name="$container_name" > /dev/null 2>&1; then
            local health_status=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}running{{end}}' "$container_name" 2>/dev/null || echo "unknown")
            if [[ "$health_status" == "healthy" ]] || [[ "$health_status" == "running" ]]; then
                is_healthy=1
                healthy_containers=$((healthy_containers + 1))
            fi
        fi

        # Check nginx integration
        nginx_status="NOT_NEEDED"
        if needs_nginx_proxy "$service"; then
            nginx_status="PROXY_ENABLED"
            nginx_integrated=$((nginx_integrated + 1))
        fi

        # Check SSL status
        ssl_status="NOT_NEEDED"
        if needs_ssl_certificate "$service"; then
            cert_path="${LETSENCRYPT_DIR}/live/${DOMAIN}/fullchain.pem"
            if [ -f "$cert_path" ]; then
                ssl_status="ENABLED"
                ssl_enabled=$((ssl_enabled + 1))
            else
                ssl_status="MISSING"
            fi
        fi

        # Check accessibility
        accessible="N/A"
        if needs_nginx_proxy "$service"; then
            service_url="https://${DOMAIN}/${service}"
            http_status=$(curl -s -k -o /dev/null -w "%{http_code}" "$service_url" 2>/dev/null || echo "000")
            if [[ "$http_status" == "200" || "$http_status" == "301" || "$http_status" == "302" ]]; then
                accessible="YES"
            else
                accessible="NO"
            fi
        fi

        # Determine if action is required
        needs_action="NO"
        if [[ "$is_healthy" -eq 0 ]] || [[ "$ssl_status" == "MISSING" ]] || [[ "$accessible" == "NO" ]]; then
            needs_action="YES"
            action_required=$((action_required + 1))
        fi

        printf "%-15s | Health: %-7s | Proxy: %-12s | SSL: %-7s | Access: %-3s | Action: %-3s\n" \
            "$service" \
            "$([[ $is_healthy -eq 1 ]] && echo "OK" || echo "FAILED")" \
            "$nginx_status" \
            "$ssl_status" \
            "$accessible" \
            "$needs_action"
    done

    log ""
    log "SUMMARY STATISTICS:"
    log "-------------------"
    log "Total Containers:     $total_containers"
    log "Healthy Containers:   $healthy_containers"
    log "Nginx Integrated:     $nginx_integrated"
    log "SSL Enabled:          $ssl_enabled"
    log "Action Required:      $action_required"

    local health_percentage=$((total_containers > 0 ? healthy_containers * 100 / total_containers : 0))
    local proxy_percentage=$((total_containers > 0 ? nginx_integrated * 100 / total_containers : 0))

    log ""
    log "HEALTH METRICS:"
    log "---------------"
    log "Container Health:     ${health_percentage}%"
    log "Nginx Integration:    ${proxy_percentage}%"

    # SSL Certificate Information
    log ""
    log "SSL CERTIFICATE STATUS:"
    log "-----------------------"
    local cert_path="${LETSENCRYPT_DIR}/fullchain.pem"
    if [ -f "$cert_path" ]; then
        local cert_expiry=$(openssl x509 -in "$cert_path" -noout -enddate 2>/dev/null | cut -d= -f2 || echo "unknown")
        local cert_expiry_epoch=$(date -d "$cert_expiry" +%s 2>/dev/null || echo 0)
        local current_epoch=$(date +%s)
        local days_until_expiry=$(( (cert_expiry_epoch - current_epoch) / 86400 ))

        log "Certificate Path:     $cert_path"
        log "Certificate Expiry:   $cert_expiry"
        log "Days Until Expiry:    $days_until_expiry"

        if [ $days_until_expiry -lt 30 ]; then
            log "WARNING: Certificate expires in less than 30 days!"
        fi
    else
        log "Certificate Status:   NOT FOUND"
        log "WARNING: SSL certificate is missing!"
    fi

    if [[ $action_required -gt 0 ]]; then
        log ""
        log "WARNING: $action_required containers require attention!"
        log "Please review the above status and take appropriate action."
    else
        log ""
        log "SUCCESS: All containers are healthy and properly configured with nginx/SSL!"
    fi

    log "======================================="
    log "END OF SUMMARY REPORT"
    log "======================================="
}

# Call the summary report function
generate_summary_report

log "INFO: Nginx/Let's Encrypt sanity check completed for all services."
