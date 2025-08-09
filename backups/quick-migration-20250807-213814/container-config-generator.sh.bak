#!/bin/bash
# container-config-generator.sh - Generate configuration files for container scaffolding
# Creates phase-specific configuration files for each service

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="/opt/dev-purebliss/container-configs"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo -e "${timestamp} - CONFIG_GEN ${level}: ${message}"
    echo "${timestamp} - CONFIG_GEN ${level}: ${message}" >> "$LOG_FILE"
}

# Setup configuration directories
setup_config_dirs() {
    mkdir -p "$CONFIG_DIR"/{nginx,redis,postgres,vault,prometheus,grafana,loki}
    log_message "INFO" "Configuration directories created"
}

# Generate Nginx configurations
generate_nginx_configs() {
    local nginx_dir="$CONFIG_DIR/nginx"

    # Basic configuration
    cat > "$nginx_dir/nginx-basic.conf" << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    server {
        listen 80;
        server_name localhost;

        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        location / {
            return 200 "Nginx Phase 1 - Basic";
            add_header Content-Type text/plain;
        }
    }
}
EOF

    # Enhanced configuration
    cat > "$nginx_dir/nginx-enhanced.conf" << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log info;
pid /var/run/nginx.pid;

events {
    worker_connections 2048;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format enhanced '$remote_addr - $remote_user [$time_local] "$request" '
                       '$status $body_bytes_sent "$http_referer" '
                       '"$http_user_agent" "$http_x_forwarded_for" '
                       'rt=$request_time uct="$upstream_connect_time" '
                       'uht="$upstream_header_time" urt="$upstream_response_time"';

    access_log /var/log/nginx/access.log enhanced;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    client_max_body_size 100M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 10240;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    server {
        listen 80;
        listen 443 ssl http2;
        server_name localhost;

        # SSL configuration
        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;

        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        location / {
            return 200 "Nginx Phase 2 - Enhanced";
            add_header Content-Type text/plain;
        }
    }
}
EOF

    # Additional configs
    cat > "$nginx_dir/ssl-params.conf" << 'EOF'
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_stapling on;
ssl_stapling_verify on;
add_header Strict-Transport-Security "max-age=63072000" always;
EOF

    cat > "$nginx_dir/upstream.conf" << 'EOF'
upstream backend {
    least_conn;
    server backend1:8080 max_fails=3 fail_timeout=30s;
    server backend2:8080 max_fails=3 fail_timeout=30s;
    keepalive 32;
}
EOF

    cat > "$nginx_dir/security-headers.conf" << 'EOF'
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
EOF

    log_message "SUCCESS" "Generated Nginx configuration files"
}

# Generate Redis configurations
generate_redis_configs() {
    local redis_dir="$CONFIG_DIR/redis"

    # Basic configuration
    cat > "$redis_dir/redis-basic.conf" << 'EOF'
# Redis Phase 1 - Basic Configuration
bind 0.0.0.0
port 6379
timeout 0
tcp-keepalive 300

# Logging
loglevel notice
logfile ""

# Persistence
save 900 1
save 300 10
save 60 10000

dbfilename dump.rdb
dir ./

# Memory management
maxmemory 256mb
maxmemory-policy allkeys-lru
EOF

    # Enhanced configuration
    cat > "$redis_dir/redis-enhanced.conf" << 'EOF'
# Redis Phase 2 - Enhanced Configuration
bind 0.0.0.0
port 6379
timeout 0
tcp-keepalive 300

# Logging
loglevel notice
logfile "/var/log/redis/redis.log"
syslog-enabled yes
syslog-ident redis

# Persistence
save 900 1
save 300 10
save 60 10000

# RDB Configuration
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir ./

# AOF Configuration
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Memory management
maxmemory 512mb
maxmemory-policy allkeys-lru
maxmemory-samples 5

# Slow log
slowlog-log-slower-than 10000
slowlog-max-len 128

# Performance
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
EOF

    log_message "SUCCESS" "Generated Redis configuration files"
}

# Generate basic monitoring configurations
generate_monitoring_configs() {
    local nginx_dir="$CONFIG_DIR/nginx"
    local redis_dir="$CONFIG_DIR/redis"

    # Nginx monitoring
    cat > "$nginx_dir/monitoring.conf" << 'EOF'
# Nginx monitoring endpoints
location /nginx_status {
    stub_status on;
    access_log off;
    allow 127.0.0.1;
    allow 10.0.0.0/8;
    allow 172.16.0.0/12;
    allow 192.168.0.0/16;
    deny all;
}

location /metrics {
    access_log off;
    allow 127.0.0.1;
    allow 10.0.0.0/8;
    allow 172.16.0.0/12;
    allow 192.168.0.0/16;
    deny all;
    return 200 "# Nginx metrics placeholder\n";
    add_header Content-Type text/plain;
}
EOF

    # Redis monitoring
    cat > "$redis_dir/redis-monitoring.conf" << 'EOF'
# Redis monitoring configuration
# Enable command statistics
latency-monitor-threshold 100

# Client output buffer limits
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

# TCP backlog
tcp-backlog 511

# Memory usage tracking
tracking-table-max-keys 1000000
EOF

    log_message "SUCCESS" "Generated monitoring configuration files"
}

# Generate health check scripts
generate_health_checks() {
    local health_dir="$CONFIG_DIR/health-checks"
    mkdir -p "$health_dir"

    # Nginx health check
    cat > "$health_dir/nginx-health.sh" << 'EOF'
#!/bin/sh
# Nginx health check script

# Test basic connectivity
if ! curl -f -s -o /dev/null http://localhost/health; then
    echo "ERROR: Nginx health endpoint failed"
    exit 1
fi

# Test configuration
if ! nginx -t 2>/dev/null; then
    echo "ERROR: Nginx configuration test failed"
    exit 1
fi

# Test process
if ! pgrep nginx >/dev/null; then
    echo "ERROR: Nginx process not running"
    exit 1
fi

echo "OK: Nginx is healthy"
exit 0
EOF

    # Redis health check
    cat > "$health_dir/redis-health.sh" << 'EOF'
#!/bin/sh
# Redis health check script

# Test basic connectivity
if ! redis-cli ping >/dev/null 2>&1; then
    echo "ERROR: Redis ping failed"
    exit 1
fi

# Test memory usage
MEMORY_USAGE=$(redis-cli info memory | grep used_memory_human | cut -d: -f2 | tr -d '\r')
if [ -z "$MEMORY_USAGE" ]; then
    echo "ERROR: Could not get Redis memory usage"
    exit 1
fi

# Test persistence
if ! redis-cli lastsave >/dev/null 2>&1; then
    echo "WARNING: Redis persistence check failed"
fi

echo "OK: Redis is healthy (Memory: $MEMORY_USAGE)"
exit 0
EOF

    chmod +x "$health_dir"/*.sh
    log_message "SUCCESS" "Generated health check scripts"
}

# Generate Docker Compose override for phases
generate_compose_overrides() {
    local compose_dir="$CONFIG_DIR/compose"
    mkdir -p "$compose_dir"

    for phase in {1..6}; do
        cat > "$compose_dir/docker-compose.phase$phase.yml" << EOF
version: '3.8'

# Phase $phase overrides
services:
  nginx:
    image: nginx:phase$phase
    build:
      context: /opt/my-secure-ha-stack
      dockerfile: /opt/dev-purebliss/container-builds/Dockerfile.nginx
      target: phase$phase
    environment:
      - BUILD_PHASE=$phase

  redis:
    image: redis:phase$phase
    build:
      context: /opt/my-secure-ha-stack
      dockerfile: /opt/dev-purebliss/container-builds/Dockerfile.redis
      target: phase$phase
    environment:
      - BUILD_PHASE=$phase

  # Add other services as needed
EOF
    done

    log_message "SUCCESS" "Generated Docker Compose override files"
}

# Main function
main() {
    local command=${1:-"all"}

    case $command in
        "nginx")
            setup_config_dirs
            generate_nginx_configs
            ;;
        "redis")
            setup_config_dirs
            generate_redis_configs
            ;;
        "monitoring")
            setup_config_dirs
            generate_monitoring_configs
            ;;
        "health")
            setup_config_dirs
            generate_health_checks
            ;;
        "compose")
            setup_config_dirs
            generate_compose_overrides
            ;;
        "all")
            echo -e "${BLUE}Generating all container configuration files...${NC}"
            setup_config_dirs
            generate_nginx_configs
            generate_redis_configs
            generate_monitoring_configs
            generate_health_checks
            generate_compose_overrides
            echo -e "${GREEN}✓ All configuration files generated successfully${NC}"
            echo -e "${YELLOW}Configuration files location: $CONFIG_DIR${NC}"
            ;;
        "help")
            echo "Usage: $0 <command>"
            echo ""
            echo "Commands:"
            echo "  nginx       Generate Nginx configuration files"
            echo "  redis       Generate Redis configuration files"
            echo "  monitoring  Generate monitoring configurations"
            echo "  health      Generate health check scripts"
            echo "  compose     Generate Docker Compose overrides"
            echo "  all         Generate all configuration files"
            echo "  help        Show this help message"
            ;;
        *)
            echo "Unknown command: $command"
            echo "Use '$0 help' for usage information."
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
