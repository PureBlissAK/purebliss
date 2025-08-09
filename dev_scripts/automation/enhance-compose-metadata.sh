#!/bin/bash
# PURE BLISS SCRIPT METADATA
# Script: enhance-compose-metadata.sh
# Purpose: Add comprehensive metadata labels to Docker Compose services for improved traceability
# Category: automation
# Dependencies: docker-compose, yq
# Usage: ./enhance-compose-metadata.sh [compose-file]
# Exit Codes: 0=success, 1=error
# Log Output: /opt/my-secure-ha-stack/logs/dev-environment-setup.log
# Health Validation: optional
# Vault Required: no
# Last Enhanced: 2025-08-08
# Enhancement Notes: Initial creation for Docker Compose metadata enhancement
# END METADATA

set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Enhance Docker Compose files with comprehensive metadata labels"

# Logging function
log_compose_message() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - COMPOSE_METADATA_${level}: ${message}" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
}

# Function to enhance Docker Compose with metadata labels
enhance_compose_metadata() {
    local compose_file="${1:-/opt/my-secure-ha-stack/docker-compose.yml}"

    log_compose_message "START" "Enhancing Docker Compose metadata for $compose_file"

    # Create backup
    cp "$compose_file" "${compose_file}.backup-$(date '+%Y%m%d-%H%M%S')"

    # Service metadata mapping
    declare -A service_metadata=(
        ["vault"]="Core secrets management and PKI engine|Phase3|none|vault:8200/v1/sys/health|true"
        ["postgres"]="Primary database backend|Phase3|vault|postgres:5432|true"
        ["redis"]="Caching layer and session storage|Phase3|vault|redis:6379|true"
        ["keycloak"]="Authentication and identity management|Phase3|postgres,redis,vault|keycloak:8080/realms/master|true"
        ["nginx"]="API gateway and reverse proxy|Phase4|vault,keycloak|nginx:80/health|true"
        ["grafana"]="Monitoring dashboards and visualization|Phase4|postgres,prometheus,vault|grafana:3000/api/health|true"
        ["prometheus"]="Metrics collection and monitoring|Phase4|vault|prometheus:9090/-/healthy|true"
        ["loki"]="Log aggregation and query engine|Phase4|vault|loki:3100/ready|true"
        ["plane"]="Issue tracking and project management|Phase5|postgres,redis,vault|plane:8000/api/health|true"
        ["codeserver"]="Web-based development environment|Phase5|vault|codeserver:8080/healthz|true"
        ["letsencrypt"]="SSL/TLS certificate management|Phase4|vault|none|true"
        ["vault-agent"]="Vault API proxy and template processor|Phase3|vault|none|true"
    )

    # Create enhanced compose file
    local temp_file=$(mktemp)

    # Process the compose file line by line
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"

        # Check if this is a service definition
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z0-9_-]+):[[:space:]]*$ ]]; then
            local service_name="${BASH_REMATCH[1]}"

            # Skip non-service entries like 'version', 'services', 'volumes', 'networks'
            if [[ "$service_name" == "version" || "$service_name" == "services" || "$service_name" == "volumes" || "$service_name" == "networks" ]]; then
                continue
            fi

            # Check if we have metadata for this service
            if [[ -n "${service_metadata[$service_name]:-}" ]]; then
                IFS='|' read -r purpose phase dependencies health_endpoint vault_required <<< "${service_metadata[$service_name]}"

                log_compose_message "INFO" "Adding metadata labels for service: $service_name"

                # Add metadata labels
                cat >> "$temp_file" << EOF
    labels:
      - "purebliss.service.name=$service_name"
      - "purebliss.service.purpose=$purpose"
      - "purebliss.service.phase=$phase"
      - "purebliss.service.dependencies=$dependencies"
      - "purebliss.service.health.endpoint=$health_endpoint"
      - "purebliss.service.vault.required=$vault_required"
      - "purebliss.service.network=purebliss-net"
      - "purebliss.service.enhanced=$(date '+%Y-%m-%d')"
      - "purebliss.service.version=1.0"
      - "purebliss.service.environment=development"
EOF
            fi
        fi
    done < "$compose_file"

    # Replace original file
    mv "$temp_file" "$compose_file"

    log_compose_message "SUCCESS" "Docker Compose metadata enhancement completed"
}

# Function to validate compose file syntax
validate_compose_syntax() {
    local compose_file="$1"

    log_compose_message "INFO" "Validating Docker Compose syntax"

    if docker-compose -f "$compose_file" config > /dev/null 2>&1; then
        log_compose_message "SUCCESS" "Docker Compose syntax validation passed"
        return 0
    else
        log_compose_message "ERROR" "Docker Compose syntax validation failed"
        return 1
    fi
}

# Main function
main() {
    local compose_file="${1:-/opt/my-secure-ha-stack/docker-compose.yml}"

    if [[ ! -f "$compose_file" ]]; then
        log_compose_message "ERROR" "Docker Compose file not found: $compose_file"
        exit 1
    fi

    # Enhance metadata
    enhance_compose_metadata "$compose_file"

    # Validate syntax
    if ! validate_compose_syntax "$compose_file"; then
        log_compose_message "ERROR" "Restoring backup due to syntax errors"
        local backup_file=$(ls -t "${compose_file}.backup-"* | head -1)
        cp "$backup_file" "$compose_file"
        exit 1
    fi

    log_compose_message "COMPLETE" "Docker Compose metadata enhancement completed successfully"
}

# Execute main function with all arguments
main "$@"
