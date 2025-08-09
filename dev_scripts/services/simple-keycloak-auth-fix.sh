#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# SIMPLE_KEYCLOAK_AUTH_FIX_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="simple-keycloak-auth-fix.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced utilities script for general operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="utilities"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="general"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced utilities script for general with auto-commit functionality,
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
simple_keycloak_auth_fix_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
simple_keycloak_auth_fix_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
simple_keycloak_auth_fix_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
simple_keycloak_auth_fix_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    simple_keycloak_auth_fix_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        simple_keycloak_auth_fix_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            simple_keycloak_auth_fix_log_success "Validation passed - proceeding with auto-commit"
        else
            simple_keycloak_auth_fix_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        simple_keycloak_auth_fix_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        simple_keycloak_auth_fix_log_info "Auto-commit system not available - manual commit required"
        simple_keycloak_auth_fix_log_info "Recommended commit message: $commit_message"
        simple_keycloak_auth_fix_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
simple_keycloak_auth_fix_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    simple_keycloak_auth_fix_log_success "$final_message"
    
    # Execute auto-commit wrapper
    simple_keycloak_auth_fix_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    simple_keycloak_auth_fix_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# Simple Keycloak Database Authentication Fix
# Updates password and tests connection
# Date: 2025-08-06


# Logging function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - DB_AUTH_SIMPLE [$1]: $2" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
}

log_action "INFO" "Starting simple database authentication fix for Keycloak"

# Set the password we'll use
KEYCLOAK_PASSWORD="keycloak_secure_2025"

# Update keycloak user password
update_keycloak_password() {
    log_action "INFO" "Updating Keycloak user password"

    docker exec purebliss-postgres psql -U postgres -c "ALTER ROLE keycloak PASSWORD '$KEYCLOAK_PASSWORD';" || {
        log_action "ERROR" "Failed to update keycloak password"
        return 1
    }

    log_action "SUCCESS" "Keycloak password updated"
}

# Test database connection
test_connection() {
    log_action "INFO" "Testing Keycloak database connection"

    # Test connection with new password
    export PGPASSWORD="$KEYCLOAK_PASSWORD"
    if docker exec -e PGPASSWORD="$KEYCLOAK_PASSWORD" purebliss-postgres psql -U keycloak -d keycloak -c "SELECT current_user, current_database(), version();" 2>/dev/null; then
        log_action "SUCCESS" "Database connection test passed"
        return 0
    else
        log_action "ERROR" "Database connection test failed"
        return 1
    fi
}

# Create simple Keycloak docker-compose
create_simple_keycloak_compose() {
    log_action "INFO" "Creating simple Keycloak docker-compose"

    cat > /opt/dev-purebliss/services/keycloak/docker-compose.simple.yml << EOF
version: '3.8'

services:
  purebliss-keycloak:
    image: quay.io/keycloak/keycloak:24.0.5
    container_name: purebliss-keycloak
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin_secure_2025
      KC_DB: postgres
      KC_DB_URL_HOST: purebliss-postgres
      KC_DB_URL_PORT: 5432
      KC_DB_URL_DATABASE: keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: $KEYCLOAK_PASSWORD
      KC_HOSTNAME: dev.purebliss.app
      KC_HOSTNAME_STRICT: false
      KC_PROXY: edge
      KC_HTTP_ENABLED: true
    command: |
      bash -c '
        echo "[$(date)] Waiting for PostgreSQL..."
        until nc -z purebliss-postgres 5432; do
          echo "[$(date)] PostgreSQL not ready, waiting..."
          sleep 5
        done

        echo "[$(date)] Testing database connection..."
        export PGPASSWORD=$KEYCLOAK_PASSWORD
        until docker exec purebliss-postgres psql -U keycloak -d keycloak -c "SELECT 1;" > /dev/null 2>&1; do
          echo "[$(date)] Database connection failed, waiting..."
          sleep 10
        done

        echo "[$(date)] Database connection successful, starting Keycloak..."
        exec /opt/keycloak/bin/kc.sh start-dev
      '
    depends_on:
      - purebliss-postgres
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s
    networks:
      - purebliss-net

networks:
  purebliss-net:
    external: true
EOF

    log_action "SUCCESS" "Simple Keycloak docker-compose created"
}

# Grant database permissions
grant_permissions() {
    log_action "INFO" "Granting database permissions to keycloak user"

    docker exec purebliss-postgres psql -U postgres -c "
        GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
        ALTER DATABASE keycloak OWNER TO keycloak;
    " || {
        log_action "WARNING" "Failed to grant some permissions (may already exist)"
    }

    log_action "SUCCESS" "Database permissions updated"
}

# Main execution
main() {
    log_action "INFO" "Starting simple database authentication fix"

    # Update password
    if update_keycloak_password; then
        log_action "SUCCESS" "Password update completed"
    else
        log_action "ERROR" "Password update failed"
        exit 1
    fi

    # Grant permissions
    grant_permissions

    # Test connection
    if test_connection; then
        log_action "SUCCESS" "Connection test passed"
    else
        log_action "ERROR" "Connection test failed"
        exit 1
    fi

    # Create compose file
    create_simple_keycloak_compose

    log_action "SUCCESS" "Database authentication fix completed successfully"
    log_action "INFO" "Next steps:"
    log_action "INFO" "1. Stop current Keycloak: docker stop purebliss-keycloak && docker rm purebliss-keycloak"
    log_action "INFO" "2. Start with new config: docker-compose -f /opt/dev-purebliss/services/keycloak/docker-compose.simple.yml up -d"
    log_action "INFO" "3. Check logs: docker logs purebliss-keycloak -f"
}

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
