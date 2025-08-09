#!/bin/bash

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Container cleanup and optimization with service-specific backup folders"

# Container Cleanup Script - Pure Bliss Elite Standards
# Moves stale files to service-specific backup folders
# Version: 1.0.0
# Author: PureBliss Development Team

set -euo pipefail

# Load configuration
SERVICES_DIR="/opt/dev-purebliss/services"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Logging function
log_action() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - CONTAINER_CLEANUP: $message" | tee -a "$LOG_FILE"
}

# Function to identify essential files for each service type
get_essential_files() {
    local service="$1"
    local service_dir="$2"

    # Base essential files for all services
    local essential_files=(
        "entrypoint.sh"
        "${service}-dockerfile"
        "${service}-enhanced-dockerfile"
        ".env"
        "AUTOMATION_GUIDE.md"
        "BREAK_FIX_REPORT.md"
    )

    # Service-specific essential files
    case "$service" in
        "nginx")
            essential_files+=(
                "nginx.conf"
                "default.conf"
                "ssl.conf"
                "security-headers.conf"
                "upstream.conf"
                "certs/"
            )
            ;;
        "keycloak")
            essential_files+=(
                "keycloak.conf"
                "realm-config.json"
                "themes/"
                "providers/"
            )
            ;;
        "postgres")
            essential_files+=(
                "postgresql.conf"
                "pg_hba.conf"
                "init-scripts/"
                "backup-scripts/"
            )
            ;;
        "redis")
            essential_files+=(
                "redis.conf"
                "redis-sentinel.conf"
                "dump.rdb"
                "appendonly.aof"
            )
            ;;
        "vault")
            essential_files+=(
                "vault.hcl"
                "vault-config.json"
                "policies/"
                "certs/"
            )
            ;;
        "prometheus")
            essential_files+=(
                "prometheus.yml"
                "rules/"
                "targets/"
            )
            ;;
        "grafana")
            essential_files+=(
                "grafana.ini"
                "dashboards/"
                "plugins/"
                "provisioning/"
            )
            ;;
        "loki")
            essential_files+=(
                "local-config.yaml"
                "loki.yaml"
                "rules/"
            )
            ;;
        "plane")
            essential_files+=(
                "plane.conf"
                "migrations/"
                "static/"
            )
            ;;
        "codeserver")
            essential_files+=(
                "config.yaml"
                "settings.json"
                "extensions/"
                "workspace/"
            )
            ;;
        "letsencrypt")
            essential_files+=(
                "renewal-hooks/"
                "live/"
                "archive/"
                "keys/"
            )
            ;;
    esac

    printf '%s\n' "${essential_files[@]}"
}

# Function to check if file/directory is essential
is_essential() {
    local file="$1"
    local essential_files="$2"

    while IFS= read -r essential_file; do
        if [[ "$file" == "$essential_file" ]] || [[ "$file" =~ ^${essential_file%/} ]]; then
            return 0
        fi
    done <<< "$essential_files"

    return 1
}

# Function to backup stale files for a service
cleanup_service() {
    local service="$1"
    local service_dir="$SERVICES_DIR/$service"

    log_action "Starting cleanup for service: $service"

    if [[ ! -d "$service_dir" ]]; then
        log_action "Service directory not found: $service_dir - SKIPPING"
        return 0
    fi

    # Create backup directory
    local backup_dir="$service_dir/backup"
    mkdir -p "$backup_dir"/{deprecated-configs,test-artifacts,unused-scripts,legacy-dockerfiles}

    # Get essential files for this service
    local essential_files
    essential_files=$(get_essential_files "$service" "$service_dir")

    local files_moved=0
    local total_size=0

    # Process all files in service directory
    while IFS= read -r -d '' file; do
        # Get relative path from service directory
        local rel_path="${file#$service_dir/}"

        # Skip if already in backup directory
        if [[ "$rel_path" =~ ^backup/ ]]; then
            continue
        fi

        # Check if file is essential
        if ! is_essential "$rel_path" "$essential_files"; then
            # Determine backup subdirectory
            local backup_subdir
            if [[ "$rel_path" =~ \.(conf|yaml|yml|json|ini|properties)$ ]]; then
                backup_subdir="deprecated-configs"
            elif [[ "$rel_path" =~ (test|spec|mock|demo|example) ]]; then
                backup_subdir="test-artifacts"
            elif [[ "$rel_path" =~ \.(sh|py|js|ts|pl|rb)$ ]]; then
                backup_subdir="unused-scripts"
            elif [[ "$rel_path" =~ (dockerfile|Dockerfile) ]]; then
                backup_subdir="legacy-dockerfiles"
            else
                backup_subdir="deprecated-configs"
            fi

            # Calculate file size
            if [[ -f "$file" ]]; then
                local file_size
                file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
                total_size=$((total_size + file_size))
            fi

            # Move file to backup
            local target_dir="$backup_dir/$backup_subdir"
            local target_path="$target_dir/$rel_path"

            # Create target directory structure
            mkdir -p "$(dirname "$target_path")"

            # Move file
            mv "$file" "$target_path"
            files_moved=$((files_moved + 1))

            log_action "Moved stale file: $rel_path -> backup/$backup_subdir/$rel_path"
        fi
    done < <(find "$service_dir" -type f -print0)

    # Create cleanup report
    cat > "$backup_dir/cleanup-report-$(date +%Y%m%d-%H%M%S).txt" << EOF
Container Cleanup Report for $service
=====================================
Date: $(date)
Files moved: $files_moved
Total size freed: $((total_size / 1024)) KB
Backup location: $backup_dir

Essential files preserved:
$essential_files

Backup structure:
$(find "$backup_dir" -type f | sort)
EOF

    log_action "Cleanup completed for $service: $files_moved files moved, $((total_size / 1024)) KB freed"
}

# Function to validate container after cleanup
validate_container_post_cleanup() {
    local service="$1"

    log_action "Validating container after cleanup: $service"

    # Use existing health validation script
    if [[ -x "/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh" ]]; then
        if /opt/dev-purebliss/dev_scripts/core/validate-container-health.sh "$service" "post-cleanup"; then
            log_action "Container validation PASSED for $service after cleanup"
            return 0
        else
            log_action "Container validation FAILED for $service after cleanup"
            return 1
        fi
    else
        log_action "Health validation script not found - manual validation required"
        return 0
    fi
}

# Function to rollback cleanup if validation fails
rollback_cleanup() {
    local service="$1"
    local service_dir="$SERVICES_DIR/$service"
    local backup_dir="$service_dir/backup"

    log_action "Rolling back cleanup for $service due to validation failure"

    # Restore files from backup
    if [[ -d "$backup_dir" ]]; then
        find "$backup_dir" -type f -not -name "cleanup-report-*" | while read -r backup_file; do
            local rel_path="${backup_file#$backup_dir/*/}"
            local target_path="$service_dir/$rel_path"

            # Create target directory
            mkdir -p "$(dirname "$target_path")"

            # Restore file
            cp "$backup_file" "$target_path"
            log_action "Restored file: $rel_path"
        done
    fi

    log_action "Rollback completed for $service"
}

# Main execution
main() {
    local services=()
    local validate_only=false
    local force_cleanup=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --service)
                services+=("$2")
                shift 2
                ;;
            --all)
                services=(nginx keycloak postgres redis vault prometheus grafana loki plane codeserver letsencrypt vault-agent)
                shift
                ;;
            --validate-only)
                validate_only=true
                shift
                ;;
            --force)
                force_cleanup=true
                shift
                ;;
            --help)
                cat << EOF
Container Cleanup Script - Pure Bliss Elite Standards

Usage: $0 [OPTIONS]

OPTIONS:
    --service <name>    Clean up specific service
    --all               Clean up all services
    --validate-only     Only validate containers, don't clean up
    --force             Force cleanup without confirmation
    --help              Show this help message

Examples:
    $0 --service nginx
    $0 --all
    $0 --service keycloak --validate-only
EOF
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Default to all services if none specified
    if [[ ${#services[@]} -eq 0 ]]; then
        services=(nginx keycloak postgres redis vault prometheus grafana loki plane codeserver letsencrypt vault-agent)
    fi

    log_action "Starting container cleanup process for services: ${services[*]}"

    # Confirmation prompt unless forced
    if [[ "$force_cleanup" != true && "$validate_only" != true ]]; then
        echo "This will move stale files to backup folders for the following services:"
        printf '  - %s\n' "${services[@]}"
        echo
        read -p "Continue? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cleanup cancelled."
            exit 0
        fi
    fi

    local failed_services=()

    # Process each service
    for service in "${services[@]}"; do
        if [[ "$validate_only" == true ]]; then
            if ! validate_container_post_cleanup "$service"; then
                failed_services+=("$service")
            fi
        else
            # Perform cleanup
            if cleanup_service "$service"; then
                # Validate after cleanup
                if ! validate_container_post_cleanup "$service"; then
                    log_action "Validation failed for $service - attempting rollback"
                    rollback_cleanup "$service"
                    failed_services+=("$service")
                fi
            else
                log_action "Cleanup failed for $service"
                failed_services+=("$service")
            fi
        fi
    done

    # Summary
    if [[ ${#failed_services[@]} -gt 0 ]]; then
        log_action "Container cleanup completed with failures: ${failed_services[*]}"
        exit 1
    else
        log_action "Container cleanup completed successfully for all services"
        exit 0
    fi
}

# Execute main function with all arguments
main "$@"
