#!/bin/bash
# PURE BLISS SCRIPT METADATA
# Script: add-compose-labels.sh
# Purpose: Add metadata labels to specific services in Docker Compose files
# Category: automation
# Dependencies: docker-compose
# Usage: ./add-compose-labels.sh [compose-file]
# Exit Codes: 0=success, 1=error
# Log Output: /opt/my-secure-ha-stack/logs/dev-environment-setup.log
# Health Validation: optional
# Vault Required: no
# Last Enhanced: 2025-08-08
# Enhancement Notes: Manual approach for adding Docker Compose labels without breaking YAML syntax
# END METADATA

set -euo pipefail

# Logging function
log_compose_message() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - COMPOSE_LABELS_${level}: ${message}" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
}

# Function to add labels to a specific service
add_service_labels() {
    local compose_file="$1"
    local service_name="$2"
    local purpose="$3"
    local phase="$4"
    local dependencies="$5"
    local health_endpoint="$6"
    local vault_required="$7"

    log_compose_message "INFO" "Adding labels to service: $service_name"

    # Create backup
    cp "$compose_file" "${compose_file}.backup-$(date '+%Y%m%d-%H%M%S')"

    # Check if service already has labels
    if grep -A 20 "^  $service_name:" "$compose_file" | grep -q "labels:"; then
        log_compose_message "INFO" "Service $service_name already has labels, skipping"
        return 0
    fi

    # Find the service section and add labels after the image line
    awk -v service="$service_name" -v purpose="$purpose" -v phase="$phase" -v deps="$dependencies" -v health="$health_endpoint" -v vault="$vault_required" '
    BEGIN { in_service=0; added_labels=0 }
    /^  [a-zA-Z0-9_-]+:/ {
        if ($0 ~ "^  " service ":") {
            in_service=1
            print $0
        } else {
            in_service=0
            added_labels=0
            print $0
        }
        next
    }
    in_service && /^    image:/ && !added_labels {
        print $0
        print "    labels:"
        print "      - \"purebliss.service.name=" service "\""
        print "      - \"purebliss.service.purpose=" purpose "\""
        print "      - \"purebliss.service.phase=" phase "\""
        print "      - \"purebliss.service.dependencies=" deps "\""
        print "      - \"purebliss.service.health.endpoint=" health "\""
        print "      - \"purebliss.service.vault.required=" vault "\""
        print "      - \"purebliss.service.network=purebliss-net\""
        print "      - \"purebliss.service.enhanced=2025-08-08\""
        added_labels=1
        next
    }
    { print $0 }
    ' "$compose_file" > "${compose_file}.tmp"

    mv "${compose_file}.tmp" "$compose_file"

    log_compose_message "SUCCESS" "Labels added to $service_name"
}

# Main function
main() {
    local compose_file="${1:-/opt/my-secure-ha-stack/docker-compose.yml}"

    log_compose_message "START" "Adding metadata labels to Docker Compose services"

    # Add labels for each service
    add_service_labels "$compose_file" "vault" "Core secrets management and PKI engine" "Phase3" "none" "vault:8200/v1/sys/health" "true"
    add_service_labels "$compose_file" "vault-agent" "Vault API proxy and template processor" "Phase3" "vault" "none" "true"
    add_service_labels "$compose_file" "nginx" "API gateway and reverse proxy" "Phase4" "vault,keycloak" "nginx:80/health" "true"

    # Validate syntax
    if docker-compose -f "$compose_file" config > /dev/null 2>&1; then
        log_compose_message "SUCCESS" "Docker Compose syntax validation passed"
    else
        log_compose_message "ERROR" "Docker Compose syntax validation failed, restoring backup"
        local backup_file=$(ls -t "${compose_file}.backup-"* | head -1)
        cp "$backup_file" "$compose_file"
        exit 1
    fi

    log_compose_message "COMPLETE" "Docker Compose metadata labels added successfully"
}

# Execute main function
main "$@"
