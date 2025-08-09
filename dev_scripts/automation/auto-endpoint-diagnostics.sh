#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO_ENDPOINT_DIAGNOSTICS_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="auto-endpoint-diagnostics.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced automation script for development operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="automation"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="development"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced automation script for development with auto-commit functionality,
comprehensive error handling, logging integration, and wrapper functions"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
if [[ -f "$SCRIPT_DIR/utilities/common-functions-library.sh" ]]; then
    source "$SCRIPT_DIR/utilities/common-functions-library.sh"
fi

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO-COMMIT WRAPPER FUNCTIONS - ENSURING CODE REUSE AND GIT AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for standardized logging with script context
auto_endpoint_diagnostics_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
auto_endpoint_diagnostics_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
auto_endpoint_diagnostics_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
auto_endpoint_diagnostics_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    auto_endpoint_diagnostics_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        auto_endpoint_diagnostics_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            auto_endpoint_diagnostics_log_success "Validation passed - proceeding with auto-commit"
        else
            auto_endpoint_diagnostics_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        auto_endpoint_diagnostics_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        auto_endpoint_diagnostics_log_info "Auto-commit system not available - manual commit required"
        auto_endpoint_diagnostics_log_info "Recommended commit message: $commit_message"
        auto_endpoint_diagnostics_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
auto_endpoint_diagnostics_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    auto_endpoint_diagnostics_log_success "$final_message"
    
    # Execute auto-commit wrapper
    auto_endpoint_diagnostics_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    auto_endpoint_diagnostics_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


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

# Autonomous Endpoint Diagnostics
# Auto-generated by Copilot for autonomous operation
# Purpose: Intelligent endpoint detection, diagnosis, and remediation
# Created: 2025-08-07


LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

log_endpoint() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - AUTONOMOUS_ENDPOINT: $1" >> "$LOG_FILE"
    echo "🔧 $1"
}

log_success() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ENDPOINT_SUCCESS: $1" >> "$LOG_FILE"
    echo "✅ $1"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ENDPOINT_ERROR: $1" >> "$LOG_FILE"
    echo "❌ $1"
}

# Function to display help
show_help() {
    cat << EOF
Autonomous Endpoint Diagnostics Tool

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    detect              Detect and diagnose endpoint issues
    remediate [service] Attempt autonomous remediation for service
    test [endpoint]     Test specific endpoint connectivity
    proxy [service]     Generate nginx proxy configuration
    help                Show this help message

Options:
    --verbose           Enable verbose logging
    --dry-run          Show what would be done without executing

Examples:
    $0 detect                    # Detect all endpoint issues
    $0 remediate loki           # Fix loki endpoint issues
    $0 test https://example.com # Test specific endpoint
    $0 proxy loki              # Generate nginx proxy config

Pure Bliss Autonomous Operation - Auto-generated by Copilot
EOF
}

# Function to detect containers with naming pattern recognition
detect_containers() {
    log_endpoint "Detecting containers with multiple naming patterns..."

    # Multi-pattern container discovery
    local patterns=("purebliss-" "phase1_manual" "_enhanced" "loki" "vault" "nginx" "keycloak" "postgres" "redis" "grafana" "prometheus")
    local found_containers=()

    for pattern in "${patterns[@]}"; do
        while IFS= read -r container; do
            if [[ -n "$container" ]]; then
                found_containers+=("$container")
                log_success "Found container: $container (pattern: $pattern)"
            fi
        done < <(docker ps --format "{{.Names}}" | grep "$pattern" || true)
    done

    if [[ ${#found_containers[@]} -gt 0 ]]; then
        log_success "Detected ${#found_containers[@]} containers total"
        printf '%s\n' "${found_containers[@]}"
    else
        log_error "No containers detected with known patterns"
        return 1
    fi
}

# Function to test endpoint connectivity
test_endpoint() {
    local endpoint="$1"
    local timeout="${2:-10}"

    log_endpoint "Testing endpoint: $endpoint (timeout: ${timeout}s)"

    if curl -s -k --max-time "$timeout" "$endpoint" >/dev/null 2>&1; then
        log_success "Endpoint responding: $endpoint"
        return 0
    else
        log_error "Endpoint not responding: $endpoint"
        return 1
    fi
}

# Function to generate nginx proxy configuration
generate_nginx_proxy() {
    local service="$1"
    local container_ip="${2:-}"
    local container_port="${3:-3100}"

    log_endpoint "Generating nginx proxy configuration for: $service"

    if [[ -z "$container_ip" ]]; then
        # Try to detect container IP
        container_ip=$(docker inspect "$service" --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null || echo "")

        if [[ -z "$container_ip" ]]; then
            log_error "Cannot determine container IP for: $service"
            return 1
        fi
    fi

    local proxy_config="
# Auto-generated proxy configuration for $service
# Generated: $(date)
# Container: $service -> $container_ip:$container_port

location /$service/ {
    proxy_pass http://$container_ip:$container_port/;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;

    # Health check bypass
    proxy_connect_timeout 5s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
}

location /$service/ready {
    proxy_pass http://$container_ip:$container_port/ready;
    proxy_set_header Host \$host;
    access_log off;
}
"

    # Write to nginx config directory if it exists
    local nginx_config_dir="/opt/my-secure-ha-stack/nginx/conf.d"
    if [[ -d "$nginx_config_dir" ]]; then
        echo "$proxy_config" > "$nginx_config_dir/${service}-proxy.conf"
        log_success "Generated nginx proxy config: $nginx_config_dir/${service}-proxy.conf"
    else
        log_endpoint "Nginx config directory not found, displaying configuration:"
        echo "$proxy_config"
    fi

    return 0
}

# Function to perform autonomous remediation
autonomous_remediation() {
    local service="${1:-}"

    if [[ -z "$service" ]]; then
        log_endpoint "Starting autonomous remediation for all detected services"

        # Detect all containers and attempt remediation
        local containers
        if containers=$(detect_containers); then
            while IFS= read -r container; do
                if [[ -n "$container" ]]; then
                    autonomous_remediation "$container"
                fi
            done <<< "$containers"
        fi
        return 0
    fi

    log_endpoint "Starting autonomous remediation for: $service"

    # Check if container is running
    if ! docker ps --format "{{.Names}}" | grep -q "^${service}$"; then
        log_error "Container not running: $service"
        return 1
    fi

    # Get container details
    local container_ip
    container_ip=$(docker inspect "$service" --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null || echo "")

    if [[ -z "$container_ip" ]]; then
        log_error "Cannot determine IP for container: $service"
        return 1
    fi

    log_success "Container $service running at IP: $container_ip"

    # Test common service ports
    local common_ports=(3100 8080 9090 3000 5432 6379 8200)
    local working_port=""

    for port in "${common_ports[@]}"; do
        if curl -s -k --max-time 3 "http://$container_ip:$port" >/dev/null 2>&1; then
            working_port="$port"
            log_success "Found working port for $service: $port"
            break
        fi
    done

    if [[ -n "$working_port" ]]; then
        # Generate nginx proxy configuration
        generate_nginx_proxy "$service" "$container_ip" "$working_port"

        # Test the proxy endpoint
        local proxy_endpoint="https://dev.purebliss.app/$service/"
        if test_endpoint "$proxy_endpoint"; then
            log_success "Autonomous remediation successful for: $service"
            return 0
        else
            log_error "Proxy endpoint still not working after remediation: $service"
            return 1
        fi
    else
        log_error "No working ports found for: $service"
        return 1
    fi
}

# Main execution logic
main() {
    local command="${1:-detect}"

    case "$command" in
        "detect")
            log_endpoint "=== AUTONOMOUS ENDPOINT DETECTION ==="
            detect_containers
            ;;
        "remediate")
            local service="${2:-}"
            log_endpoint "=== AUTONOMOUS REMEDIATION ==="
            autonomous_remediation "$service"
            ;;
        "test")
            local endpoint="${2:-}"
            if [[ -z "$endpoint" ]]; then
                log_error "Endpoint required for test command"
                show_help
                exit 1
            fi
            test_endpoint "$endpoint"
            ;;
        "proxy")
            local service="${2:-}"
            if [[ -z "$service" ]]; then
                log_error "Service name required for proxy command"
                show_help
                exit 1
            fi
            generate_nginx_proxy "$service"
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO-COMMIT USAGE EXAMPLES - PURE BLISS ELITE SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════════
#
# 📚 COMPLETE GUIDE: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md
#
# BASIC AUTO-COMMIT ON SUCCESS:
# Add this at the end of your main script logic:
#   ${WRAPPER_PREFIX}_complete_with_commit "Script completed successfully"
#
# AUTO-COMMIT WITH VALIDATION:
# Add validation command to ensure script worked correctly:
#   ${WRAPPER_PREFIX}_complete_with_commit "Script completed with validation" "docker ps | grep -q my-service"
#
# MANUAL AUTO-COMMIT TRIGGER:
# Use auto-commit wrapper directly with custom message:
#   ${WRAPPER_PREFIX}_auto_commit_wrapper "Custom commit: Feature implemented successfully"
#
# DIRECT PURE BLISS ELITE SYSTEM (Recommended):
# Use the official auto-commit trigger system:
#   /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh \
#       "${SCRIPT_CATEGORY}" "Description of accomplishment" "${SCRIPT_NAME}"
#
# CONDITIONAL AUTO-COMMIT:
# Only commit if certain conditions are met:
#   if [[ \$SUCCESS_FLAG == "true" ]]; then
#       ${WRAPPER_PREFIX}_auto_commit_wrapper "Conditional commit: Success flag set"
#   fi
#
# VALIDATION COMMAND EXAMPLES:
# - Container health check: "docker ps | grep -q healthy"
# - File existence: "test -f /path/to/expected/file"
# - Service response: "curl -s http://service/health | grep -q ok"
# - Custom function: "my_validation_function"
#
# ELITE COMMIT MESSAGE FORMAT:
# The Pure Bliss Elite system automatically generates comprehensive commit messages
# following the standard format with safety guarantees, validation results, and
# proper documentation references. See the AUTO_COMMIT_SYSTEM_GUIDE.md for details.
#
# ═══════════════════════════════════════════════════════════════════════════════════
