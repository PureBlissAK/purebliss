#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# COMMON_FUNCTIONS_LIBRARY_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="common-functions-library.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced utilities script for general operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="utilities"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="general"
SCRIPT_DEPENDENCIES="none"
SCRIPT_DESCRIPTION="Enhanced utilities script for general with auto-commit functionality,
comprehensive error handling, logging integration, and wrapper functions"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CENTRALIZED SCRIPT REFERENCE SYSTEM
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
# Note: This IS the common-functions-library.sh - no need to source itself

# ═══════════════════════════════════════════════════════════════════════════════════
# AUTO-COMMIT WRAPPER FUNCTIONS - ENSURING CODE REUSE AND GIT AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Wrapper for standardized logging with script context
common_functions_library_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
common_functions_library_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
common_functions_library_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
common_functions_library_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    common_functions_library_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        common_functions_library_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            common_functions_library_log_success "Validation passed - proceeding with auto-commit"
        else
            common_functions_library_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        common_functions_library_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        common_functions_library_log_info "Auto-commit system not available - manual commit required"
        common_functions_library_log_info "Recommended commit message: $commit_message"
        common_functions_library_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
common_functions_library_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    common_functions_library_log_success "$final_message"
    
    # Execute auto-commit wrapper
    common_functions_library_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    common_functions_library_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════

# COMMON FUNCTIONS LIBRARY
# Comprehensive shared function library for Pure Bliss Elite Framework
# Usage: source "$SCRIPT_DIR/utilities/common-functions-library.sh"

# Prevent multiple inclusion
if [[ "${COMMON_FUNCTIONS_LOADED:-}" == "true" ]]; then
    return 0
fi
export COMMON_FUNCTIONS_LOADED="true"

# GLOBAL CONFIGURATION
COMMON_LIB_VERSION="1.0"
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
HEALTH_LOG="/opt/my-secure-ha-stack/logs/container-health-validation.log"

# ═══════════════════════════════════════════════════════════════════════════════════
# LOGGING FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════

# Enhanced logging with levels
log_with_level() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local caller_script="unknown"
    
    # Safely get caller script name
    if [[ ${#BASH_SOURCE[@]} -gt 2 ]]; then
        caller_script="${BASH_SOURCE[2]##*/}"
    fi

    echo "$timestamp - [$level] $caller_script: $message" | tee -a "$LOG_FILE"
}

# Convenience logging functions
log_info() { log_with_level "INFO" "$1"; }
log_warn() { log_with_level "WARN" "$1"; }
log_error() { log_with_level "ERROR" "$1"; }
log_debug() { log_with_level "DEBUG" "$1"; }
log_success() { log_with_level "SUCCESS" "$1"; }

# Legacy compatibility
log_action() { log_info "$1"; }

# ═══════════════════════════════════════════════════════════════════════════════════
# CONTAINER MANAGEMENT FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════

# Check if container exists
container_exists() {
    local container_name="$1"
    docker ps -aq -f name="^${container_name}$" | grep -q .
}

# Check if container is running
container_running() {
    local container_name="$1"
    docker ps -q -f name="^${container_name}$" | grep -q .
}

# Check if container is healthy
container_healthy() {
    local container_name="$1"
    local health_status

    if ! container_exists "$container_name"; then
        return 1
    fi

    health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no-healthcheck")

    case "$health_status" in
        "healthy") return 0 ;;
        "no-healthcheck")
            # If no health check, consider running as healthy
            container_running "$container_name"
            ;;
        *) return 1 ;;
    esac
}

# Get container IP address
get_container_ip() {
    local container_name="$1"
    docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name" 2>/dev/null
}

# Get container status
get_container_status() {
    local container_name="$1"

    if ! container_exists "$container_name"; then
        echo "not-found"
    elif container_running "$container_name"; then
        if container_healthy "$container_name"; then
            echo "healthy"
        else
            echo "unhealthy"
        fi
    else
        echo "stopped"
    fi
}

# Wait for container to be healthy
wait_for_container_healthy() {
    local container_name="$1"
    local timeout="${2:-300}"
    local interval="${3:-5}"

    log_info "Waiting for $container_name to be healthy (timeout: ${timeout}s)..."

    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if container_healthy "$container_name"; then
            log_success "$container_name is healthy"
            return 0
        fi

        sleep "$interval"
        elapsed=$((elapsed + interval))

        if [[ $((elapsed % 30)) -eq 0 ]]; then
            log_info "Still waiting for $container_name... (${elapsed}s elapsed)"
        fi
    done

    log_error "$container_name did not become healthy within ${timeout}s"
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════════
# SERVICE MANAGEMENT FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════

# Wait for service endpoint to be available
wait_for_service_endpoint() {
    local service_name="$1"
    local port="$2"
    local path="${3:-/health}"
    local timeout="${4:-300}"
    local interval="${5:-5}"

    log_info "Waiting for $service_name endpoint on port $port (timeout: ${timeout}s)..."

    local service_ip
    service_ip=$(get_container_ip "$service_name")

    if [[ -z "$service_ip" ]]; then
        log_error "Could not get IP for service: $service_name"
        return 1
    fi

    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if curl -sf "http://$service_ip:$port$path" >/dev/null 2>&1; then
            log_success "$service_name endpoint is available"
            return 0
        fi

        sleep "$interval"
        elapsed=$((elapsed + interval))

        if [[ $((elapsed % 30)) -eq 0 ]]; then
            log_info "Still waiting for $service_name endpoint... (${elapsed}s elapsed)"
        fi
    done

    log_error "$service_name endpoint did not become available within ${timeout}s"
    return 1
}

# Check if service is fully ready (container healthy + endpoint available)
service_ready() {
    local service_name="$1"
    local port="${2:-}"
    local path="${3:-/health}"

    # Check container health first
    if ! container_healthy "$service_name"; then
        return 1
    fi

    # If port specified, check endpoint
    if [[ -n "$port" ]]; then
        local service_ip
        service_ip=$(get_container_ip "$service_name")
        [[ -n "$service_ip" ]] && curl -sf "http://$service_ip:$port$path" >/dev/null 2>&1
    else
        return 0
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════════
# VAULT INTEGRATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════

# Check if Vault is available and initialized
vault_available() {
    if ! container_healthy "purebliss-vault"; then
        return 1
    fi

    # Check if Vault is unsealed and initialized
    vault status >/dev/null 2>&1
}

# Authenticate with Vault using AppRole
vault_auth_approle() {
    local role_id="$1"
    local secret_id="$2"

    if ! vault_available; then
        log_error "Vault is not available for authentication"
        return 1
    fi

    local auth_response
    auth_response=$(vault write -format=json auth/approle/login \
        role_id="$role_id" \
        secret_id="$secret_id" 2>/dev/null)

    if [[ $? -eq 0 ]]; then
        local vault_token
        vault_token=$(echo "$auth_response" | jq -r '.auth.client_token')
        export VAULT_TOKEN="$vault_token"
        log_success "Vault authentication successful"
        return 0
    else
        log_error "Vault authentication failed"
        return 1
    fi
}

# Get secret from Vault
vault_get_secret() {
    local secret_path="$1"
    local secret_key="${2:-}"

    if ! vault_available; then
        log_error "Vault is not available for secret retrieval"
        return 1
    fi

    local secret_data
    secret_data=$(vault kv get -format=json "$secret_path" 2>/dev/null)

    if [[ $? -eq 0 ]]; then
        if [[ -n "$secret_key" ]]; then
            echo "$secret_data" | jq -r ".data.data.$secret_key"
        else
            echo "$secret_data" | jq -r '.data.data'
        fi
    else
        log_error "Failed to retrieve secret from path: $secret_path"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════════
# DATABASE FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════

# Test database connection
test_database_connection() {
    local host="$1"
    local port="$2"
    local database="$3"
    local username="$4"
    local password="$5"

    PGPASSWORD="$password" psql -h "$host" -p "$port" -d "$database" -U "$username" -c "SELECT 1;" >/dev/null 2>&1
}

# Wait for database to be ready
wait_for_database() {
    local host="$1"
    local port="$2"
    local database="$3"
    local username="$4"
    local password="$5"
    local timeout="${6:-300}"
    local interval="${7:-5}"

    log_info "Waiting for database $database to be ready (timeout: ${timeout}s)..."

    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if test_database_connection "$host" "$port" "$database" "$username" "$password"; then
            log_success "Database $database is ready"
            return 0
        fi

        sleep "$interval"
        elapsed=$((elapsed + interval))

        if [[ $((elapsed % 30)) -eq 0 ]]; then
            log_info "Still waiting for database $database... (${elapsed}s elapsed)"
        fi
    done

    log_error "Database $database did not become ready within ${timeout}s"
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════════
# RETRY AND RESILIENCE FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════

# Retry command with exponential backoff
retry_with_backoff() {
    local max_attempts="$1"
    local base_delay="$2"
    shift 2
    local command=("$@")

    local attempt=1
    local delay="$base_delay"

    while [[ $attempt -le $max_attempts ]]; do
        log_info "Attempt $attempt/$max_attempts: ${command[*]}"

        if "${command[@]}"; then
            log_success "Command succeeded on attempt $attempt"
            return 0
        fi

        if [[ $attempt -lt $max_attempts ]]; then
            log_warn "Command failed, retrying in ${delay}s..."
            sleep "$delay"
            delay=$((delay * 2))  # Exponential backoff
        fi

        ((attempt++))
    done

    log_error "Command failed after $max_attempts attempts"
    return 1
}

# Retry command with timeout
retry_with_timeout() {
    local timeout="$1"
    local command="$2"
    local interval="${3:-5}"

    local end_time=$(($(date +%s) + timeout))

    while [[ $(date +%s) -lt $end_time ]]; do
        if eval "$command"; then
            return 0
        fi
        sleep "$interval"
    done

    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════════
# FILE AND DIRECTORY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════

# Ensure directory exists
ensure_directory() {
    local dir_path="$1"
    local permissions="${2:-755}"

    if [[ ! -d "$dir_path" ]]; then
        log_info "Creating directory: $dir_path"
        mkdir -p "$dir_path"
        chmod "$permissions" "$dir_path"
    fi
}

# Backup file with timestamp
backup_file() {
    local file_path="$1"
    local backup_dir="${2:-/opt/dev-purebliss/backups}"

    if [[ -f "$file_path" ]]; then
        ensure_directory "$backup_dir"
        local backup_name="$(basename "$file_path")-$(date +%Y%m%d-%H%M%S)"
        local backup_path="$backup_dir/$backup_name"

        cp "$file_path" "$backup_path"
        log_info "File backed up: $file_path -> $backup_path"
        echo "$backup_path"
    else
        log_warn "File not found for backup: $file_path"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════════
# HEALTH CHECK FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════

# Comprehensive health check
health_check_service() {
    local service_name="$1"
    local check_endpoint="${2:-true}"
    local port="${3:-}"
    local path="${4:-/health}"

    log_info "Performing health check for $service_name..."

    # Container existence check
    if ! container_exists "$service_name"; then
        log_error "Container does not exist: $service_name"
        return 1
    fi

    # Container running check
    if ! container_running "$service_name"; then
        log_error "Container is not running: $service_name"
        return 1
    fi

    # Container health check
    if ! container_healthy "$service_name"; then
        log_error "Container health check failed: $service_name"
        return 1
    fi

    # Endpoint check (if requested and port provided)
    if [[ "$check_endpoint" == "true" && -n "$port" ]]; then
        if ! service_ready "$service_name" "$port" "$path"; then
            log_error "Service endpoint check failed: $service_name"
            return 1
        fi
    fi

    log_success "Health check passed for $service_name"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════════
# NETWORK FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════

# Check if port is available
port_available() {
    local port="$1"
    local host="${2:-localhost}"

    ! nc -z "$host" "$port" 2>/dev/null
}

# Wait for port to be available
wait_for_port() {
    local host="$1"
    local port="$2"
    local timeout="${3:-60}"
    local interval="${4:-2}"

    log_info "Waiting for $host:$port to be available (timeout: ${timeout}s)..."

    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if nc -z "$host" "$port" 2>/dev/null; then
            log_success "Port $host:$port is available"
            return 0
        fi

        sleep "$interval"
        elapsed=$((elapsed + interval))
    done

    log_error "Port $host:$port did not become available within ${timeout}s"
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════

# Generate random string
generate_random_string() {
    local length="${1:-32}"
    local chars="${2:-a-zA-Z0-9}"

    tr -dc "$chars" < /dev/urandom | head -c "$length"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Get epoch timestamp
get_epoch() {
    date +%s
}

# Convert seconds to human readable duration
seconds_to_duration() {
    local seconds="$1"

    if [[ $seconds -lt 60 ]]; then
        echo "${seconds}s"
    elif [[ $seconds -lt 3600 ]]; then
        echo "$((seconds / 60))m $((seconds % 60))s"
    else
        echo "$((seconds / 3600))h $(((seconds % 3600) / 60))m $((seconds % 60))s"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════════
# VALIDATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════

# Validate required environment variables
validate_env_vars() {
    local required_vars=("$@")
    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        return 1
    fi

    log_success "All required environment variables are set"
    return 0
}

# Validate file exists
validate_file() {
    local file_path="$1"
    local description="${2:-file}"

    if [[ -f "$file_path" ]]; then
        log_success "$description exists: $file_path"
        return 0
    else
        log_error "$description not found: $file_path"
        return 1
    fi
}

# Validate directory exists
validate_directory() {
    local dir_path="$1"
    local description="${2:-directory}"

    if [[ -d "$dir_path" ]]; then
        log_success "$description exists: $dir_path"
        return 0
    else
        log_error "$description not found: $dir_path"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
# ═══════════════════════════════════════════════════════════════════════════════════

# Initialize common functions library
init_common_functions() {
    log_info "Common Functions Library v$COMMON_LIB_VERSION loaded"

    # Ensure log directories exist
    ensure_directory "$(dirname "$LOG_FILE")"
    ensure_directory "$(dirname "$HEALTH_LOG")"

    # Set up error handling if not already set
    if [[ "${ERROR_HANDLING_SETUP:-}" != "true" ]]; then
        set -euo pipefail
        export ERROR_HANDLING_SETUP="true"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════════
# GIT AUTOMATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════

# Auto-commit and push wrapper for successful script execution
auto_commit_push_wrapper() {
    local script_name="${1:-$(basename "$0")}"
    local commit_message="${2:-"Auto-commit: $script_name executed successfully"}"
    local branch="${3:-$(git branch --show-current 2>/dev/null || echo 'main')}"

    log_info "Starting auto-commit and push for $script_name"

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_warn "Not in a git repository - skipping auto-commit"
        return 0
    fi

    # Check for uncommitted changes
    if git diff --quiet && git diff --staged --quiet; then
        log_info "No changes to commit - auto-commit skipped"
        return 0
    fi

    # Stage changes with graceful handling of permission issues
    log_info "Staging accessible changes for commit"

    # Try to add all changes, but handle permission errors gracefully
    if git add . 2>/dev/null; then
        log_success "Changes staged successfully"
    else
        log_warn "Some files have permission issues - staging accessible files only"

        # Stage files one by one, skipping permission-denied files
        local staged_count=0
        while IFS= read -r -d '' file; do
            if git add "$file" 2>/dev/null; then
                ((staged_count++)) || true
            else
                log_warn "Skipping file with permission issues: $file"
            fi
        done < <(git diff --name-only -z 2>/dev/null)

        # Also try to stage untracked files that are accessible
        while IFS= read -r -d '' file; do
            if [[ -r "$file" ]] && git add "$file" 2>/dev/null; then
                ((staged_count++)) || true
            else
                log_warn "Skipping untracked file with permission issues: $file"
            fi
        done < <(git ls-files --others --exclude-standard -z 2>/dev/null)

        if [[ $staged_count -gt 0 ]]; then
            log_success "$staged_count files staged successfully (skipped permission-denied files)"
        else
            log_error "No files could be staged due to permission issues"
            return 1
        fi
    fi

    # Commit changes
    if git commit -m "$commit_message" -m "Script: $script_name" -m "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"; then
        log_success "Changes committed successfully"
    else
        log_error "Failed to commit changes"
        return 1
    fi

    # Push to remote (with retry logic)
    local push_attempts=0
    local max_push_attempts=3

    while [[ $push_attempts -lt $max_push_attempts ]]; do
        if git push origin "$branch"; then
            log_success "Changes pushed to origin/$branch successfully"
            return 0
        else
            ((push_attempts++))
            log_warn "Push attempt $push_attempts failed, retrying in 5 seconds..."
            sleep 5
        fi
    done

    log_error "Failed to push after $max_push_attempts attempts"
    return 1
}

# Wrapper for script success validation and auto-commit
validate_and_commit_wrapper() {
    local script_name="${1:-$(basename "$0")}"
    local validation_command="$2"
    local commit_message="${3:-"Auto-commit: $script_name validation successful"}"

    log_info "Running validation and auto-commit wrapper for $script_name"

    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            log_success "Validation passed for $script_name"
        else
            log_error "Validation failed for $script_name - skipping auto-commit"
            return 1
        fi
    fi

    # Execute auto-commit and push
    auto_commit_push_wrapper "$script_name" "$commit_message"
}

# Git status check wrapper
git_status_wrapper() {
    local script_name="${1:-$(basename "$0")}"

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_warn "$script_name: Not in a git repository"
        return 1
    fi

    log_info "$script_name: Git repository status:"
    git status --porcelain | while read -r line; do
        log_info "  $line"
    done

    # Show current branch and remote tracking
    local current_branch=$(git branch --show-current 2>/dev/null)
    local upstream=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "No upstream")
    log_info "$script_name: Current branch: $current_branch (upstream: $upstream)"
}

# Auto-initialize when sourced
init_common_functions

# Export functions for use in subshells
# ═══════════════════════════════════════════════════════════════════════════════════
# SCRIPT INDEX LIBRARY AUTO-UPDATE FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════════

# Auto-update Script Index Library with enhancement session results
auto_update_script_index() {
    local session_timestamp="${1:-$(date '+%Y-%m-%d %H:%M:%S')}"
    local enhanced_count="${2:-0}"
    local total_count="${3:-0}"
    local session_details="${4:-Enhancement session completed}"
    
    local index_file="/opt/dev-purebliss/dev_scripts/indexing/SCRIPT_INDEX_LIBRARY.md"
    
    if [[ -f "$index_file" ]]; then
        log_info "Updating Script Index Library with session results"
        
        # Create temporary update
        local temp_update="/tmp/script_index_update_$$"
        
        # Add enhancement session update
        cat << EOF >> "$temp_update"

### 🎯 Enhancement Session - $session_timestamp

**ENHANCEMENT RESULTS**: Enhanced $enhanced_count out of $total_count scripts

#### Session Details:
- **Session Date**: $session_timestamp
- **Scripts Processed**: $total_count
- **Scripts Enhanced**: $enhanced_count
- **Success Rate**: $(( enhanced_count * 100 / total_count ))%

#### Session Summary:
$session_details

EOF
        
        # Append to index file
        cat "$temp_update" >> "$index_file"
        rm -f "$temp_update"
        
        # Update statistics at top of file
        local new_timestamp=$(date '+%Y-%m-%dT%H:%M:%SZ')
        sed -i "s/\*\*Last Scan\*\*:.*/\*\*Last Scan\*\*: $new_timestamp/" "$index_file"
        sed -i "s/\*\*Enhanced Scripts\*\*:.*/\*\*Enhanced Scripts\*\*: $enhanced_count scripts enhanced/" "$index_file"
        
        log_success "Script Index Library updated successfully"
        return 0
    else
        log_error "Script Index Library not found: $index_file"
        return 1
    fi
}

# Auto-update common functions library with new functions
auto_update_functions_library() {
    local function_name="${1}"
    local function_description="${2:-New function added}"
    local function_category="${3:-utilities}"
    
    if [[ -z "$function_name" ]]; then
        log_error "Function name required for library update"
        return 1
    fi
    
    log_info "Registering new function in common library: $function_name"
    
    # Check if function exists in current file
    if grep -q "^$function_name()" "/opt/dev-purebliss/dev_scripts/utilities/common-functions-library.sh"; then
        log_info "Function $function_name already exists in library"
        
        # Update exports if not already included
        if ! grep -q "$function_name" "/opt/dev-purebliss/dev_scripts/utilities/common-functions-library.sh" | grep "export -f"; then
            # Add to appropriate export line
            local export_line=""
            case "$function_category" in
                "index"|"library")
                    export_line="export -f auto_update_script_index auto_update_functions_library register_enhanced_script"
                    ;;
                "git"|"auto-commit")
                    export_line="export -f auto_commit_push_wrapper validate_and_commit_wrapper git_status_wrapper $function_name"
                    ;;
                *)
                    export_line="export -f $function_name"
                    ;;
            esac
            
            # Add export line before AUTO-COMMIT USAGE EXAMPLES section
            sed -i "/# AUTO-COMMIT USAGE EXAMPLES/i\\$export_line" "/opt/dev-purebliss/dev_scripts/utilities/common-functions-library.sh"
        fi
        
        return 0
    else
        log_warn "Function $function_name not found in library - manual addition required"
        return 1
    fi
}

# Register an enhanced script in the index
register_enhanced_script() {
    local script_path="${1}"
    local enhancement_type="${2:-auto-commit}"
    local enhancement_timestamp="${3:-$(date '+%Y-%m-%d %H:%M:%S')}"
    
    if [[ -z "$script_path" ]]; then
        log_error "Script path required for registration"
        return 1
    fi
    
    local script_name=$(basename "$script_path")
    local script_dir=$(dirname "$script_path")
    
    log_info "Registering enhanced script: $script_name"
    
    # Update the recently enhanced scripts section
    local index_file="/opt/dev-purebliss/dev_scripts/indexing/SCRIPT_INDEX_LIBRARY.md"
    
    if [[ -f "$index_file" ]]; then
        # Add to recently enhanced table
        local table_entry="| $script_name | $script_path | $enhancement_timestamp | ✅ Enhanced |"
        
        # Insert after the table header
        sed -i "/| Script | Path | Enhancement Date | Status |/a\\$table_entry" "$index_file"
        
        log_success "Script $script_name registered in index"
        return 0
    else
        log_error "Script Index Library not found"
        return 1
    fi
}

# Validate and refresh script index completeness
validate_script_index() {
    local scan_directory="${1:-/opt/dev-purebliss/dev_scripts}"
    
    log_info "Validating Script Index Library completeness"
    
    local total_scripts=$(find "$scan_directory" -name "*.sh" -type f | wc -l)
    local index_file="/opt/dev-purebliss/dev_scripts/indexing/SCRIPT_INDEX_LIBRARY.md"
    
    if [[ -f "$index_file" ]]; then
        local indexed_scripts=$(grep -c "✅ Enhanced\|❌ Failed\|⏭️ Skipped" "$index_file" || echo "0")
        
        log_info "Index validation: $indexed_scripts/$total_scripts scripts tracked"
        
        # Update total script count
        sed -i "s/\*\*Total Scripts\*\*:.*/\*\*Total Scripts\*\*: $total_scripts scripts discovered/" "$index_file"
        
        if [[ $indexed_scripts -lt $total_scripts ]]; then
            log_warn "Index may be incomplete: $(( total_scripts - indexed_scripts )) scripts not tracked"
            log_info "Consider running full script scan: /opt/dev-purebliss/dev_scripts/indexing/scan-all-scripts.sh"
        else
            log_success "Script Index Library appears complete"
        fi
        
        return 0
    else
        log_error "Script Index Library not found"
        return 1
    fi
}

# Auto-commit changes to Script Index Library
auto_commit_index_updates() {
    local commit_message="${1:-Auto-update: Script Index Library maintenance}"
    
    log_info "Auto-committing Script Index Library updates"
    
    cd /opt/dev-purebliss || return 1
    
    # Check if there are changes to commit
    if git diff --quiet dev_scripts/indexing/SCRIPT_INDEX_LIBRARY.md; then
        log_info "No changes to Script Index Library - skipping commit"
        return 0
    fi
    
    # Stage and commit the index file
    if git add dev_scripts/indexing/SCRIPT_INDEX_LIBRARY.md 2>/dev/null; then
        if git commit -m "$commit_message" 2>/dev/null; then
            log_success "Script Index Library updates committed"
            
            # Try to push if we can
            if git push 2>/dev/null; then
                log_success "Script Index Library updates pushed to remote"
            else
                log_info "Index updates committed locally (push may require manual intervention)"
            fi
            return 0
        else
            log_error "Failed to commit Script Index Library updates"
            return 1
        fi
    else
        log_warn "Could not stage Script Index Library changes (permission issues)"
        return 1
    fi
}

export -f log_with_level log_info log_warn log_error log_debug log_success log_action
export -f container_exists container_running container_healthy get_container_ip get_container_status wait_for_container_healthy
export -f wait_for_service_endpoint service_ready vault_available vault_auth_approle vault_get_secret
export -f test_database_connection wait_for_database retry_with_backoff retry_with_timeout
export -f ensure_directory backup_file health_check_service port_available wait_for_port
export -f generate_random_string command_exists get_timestamp get_epoch seconds_to_duration
export -f validate_env_vars validate_file validate_directory
export -f auto_commit_push_wrapper validate_and_commit_wrapper git_status_wrapper
export -f auto_update_script_index auto_update_functions_library register_enhanced_script validate_script_index auto_commit_index_updates

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
