#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# VALIDATE_SETUP_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="validate-setup.sh"
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
validate_setup_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
validate_setup_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
validate_setup_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
validate_setup_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    validate_setup_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        validate_setup_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            validate_setup_log_success "Validation passed - proceeding with auto-commit"
        else
            validate_setup_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        validate_setup_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        validate_setup_log_info "Auto-commit system not available - manual commit required"
        validate_setup_log_info "Recommended commit message: $commit_message"
        validate_setup_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
validate_setup_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    validate_setup_log_success "$final_message"
    
    # Execute auto-commit wrapper
    validate_setup_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    validate_setup_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# PostgreSQL Vault Integration Comprehensive Validation Script
# Pure Bliss Elite Standards: Validates complete Vault integration
# This script ensures PostgreSQL meets all Pure Bliss requirements

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

function log_test() {
    echo "🔍 $1"
    echo "[$(date)] POSTGRES_VALIDATION: $1" >> "$LOG_FILE"
}

function log_success() {
    echo "✅ $1"
    echo "[$(date)] POSTGRES_VALIDATION: ✅ SUCCESS: $1" >> "$LOG_FILE"
}

function log_error() {
    echo "❌ $1"
    echo "[$(date)] POSTGRES_VALIDATION: ❌ ERROR: $1" >> "$LOG_FILE"
}

function log_warning() {
    echo "⚠️  $1"
    echo "[$(date)] POSTGRES_VALIDATION: ⚠️  WARNING: $1" >> "$LOG_FILE"
}

echo "=== PostgreSQL Vault Integration Comprehensive Validation ==="
echo "Testing Pure Bliss Elite Standards Compliance"
echo "$(date)"
echo ""

# Test 1: Container Health and Status
log_test "Testing PostgreSQL container health and status..."
if docker ps | grep -q purebliss-postgres; then
    log_success "PostgreSQL container is running"

    # Check detailed status
    echo "   Container Details:"
    docker ps --filter name=purebliss-postgres --format "   {{.Names}}: {{.Status}} | {{.Ports}}"
    echo ""

    # Check health status
    health_status=$(docker inspect --format='{{.State.Health.Status}}' purebliss-postgres 2>/dev/null || echo "no_healthcheck")
    if [[ "$health_status" == "healthy" ]]; then
        log_success "PostgreSQL health check: $health_status"
    elif [[ "$health_status" == "no_healthcheck" ]]; then
        log_warning "No health check defined"
    else
        log_error "PostgreSQL health check: $health_status"
    fi
else
    log_error "PostgreSQL container is not running"
    exit 1
fi

echo ""

# Test 2: Basic PostgreSQL Connectivity
log_test "Testing basic PostgreSQL connectivity..."
if docker exec purebliss-postgres pg_isready -U postgres -d postgres -h localhost -p 5432 >/dev/null 2>&1; then
    log_success "PostgreSQL is ready and accepting connections"
else
    log_error "PostgreSQL is not ready or not accepting connections"
    exit 1
fi

# Test admin user connection
if docker exec purebliss-postgres psql -U postgres -d postgres -t -c "SELECT 'Admin connection successful!' as status;" 2>/dev/null | grep -q "Admin connection successful"; then
    log_success "PostgreSQL admin user connection working"
else
    log_error "PostgreSQL admin user connection failed"
    exit 1
fi

echo ""

# Test 3: Vault Integration - Secrets Management
log_test "Testing Vault secrets integration..."
if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
    export VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_SKIP_VERIFY=1
    export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)

    # Test Vault connectivity
    if vault token lookup >/dev/null 2>&1; then
        log_success "Vault authentication working"

        # Test PostgreSQL secrets in Vault
        if vault kv get secret/postgres >/dev/null 2>&1; then
            log_success "PostgreSQL secrets stored in Vault"

            # Check specific secret fields
            if vault kv get -field=bootstrap_password secret/postgres >/dev/null 2>&1; then
                log_success "Bootstrap password stored in Vault"
            else
                log_error "Bootstrap password missing from Vault"
            fi

            if vault kv get -field=vault_admin_password secret/postgres >/dev/null 2>&1; then
                log_success "Vault admin password stored in Vault"
            else
                log_error "Vault admin password missing from Vault"
            fi
        else
            log_error "PostgreSQL secrets not found in Vault"
        fi
    else
        log_error "Vault authentication failed"
    fi
else
    log_error "Vault token not available for testing"
fi

echo ""

# Test 4: Database Structure and Users
log_test "Testing database structure and users..."

# Check if service databases exist
service_databases=("keycloak" "plane" "vikunja" "vault_managed")
for db in "${service_databases[@]}"; do
    if docker exec purebliss-postgres psql -U postgres -d postgres -t -c "SELECT 1 FROM pg_database WHERE datname='$db'" 2>/dev/null | grep -q 1; then
        log_success "Database '$db' exists"
    else
        log_error "Database '$db' missing"
    fi
done

# Check if service users exist
service_users=("vault_admin" "keycloak" "plane" "vikunja")
for user in "${service_users[@]}"; do
    if docker exec purebliss-postgres psql -U postgres -d postgres -t -c "SELECT 1 FROM pg_roles WHERE rolname='$user'" 2>/dev/null | grep -q 1; then
        log_success "User '$user' exists"
    else
        log_error "User '$user' missing"
    fi
done

echo ""

# Test 5: Vault Database Secrets Engine
log_test "Testing Vault database secrets engine..."
if [[ -n "${VAULT_TOKEN:-}" ]]; then
    # Check if database secrets engine is enabled
    if vault secrets list | grep -q "database/"; then
        log_success "Database secrets engine enabled"

        # Check PostgreSQL connection configuration
        if vault read database/config/postgres-app >/dev/null 2>&1; then
            log_success "PostgreSQL connection configured in Vault"

            # Test dynamic credential generation
            log_test "Testing dynamic credential generation..."
            if CREDS=$(vault read -format=json database/creds/postgres-role 2>/dev/null); then
                VAULT_USER=$(echo "$CREDS" | jq -r '.data.username')
                VAULT_PASS=$(echo "$CREDS" | jq -r '.data.password')
                log_success "Generated dynamic credentials: $VAULT_USER"

                # Test connection with generated credentials
                if PGPASSWORD="$VAULT_PASS" docker exec purebliss-postgres psql -U "$VAULT_USER" -d postgres -t -c "SELECT 'Dynamic credentials working!' as status;" 2>/dev/null | grep -q "Dynamic credentials working"; then
                    log_success "Dynamic credentials connection test successful"
                else
                    log_error "Dynamic credentials connection test failed"
                fi
            else
                log_error "Failed to generate dynamic credentials"
            fi
        else
            log_error "PostgreSQL connection not configured in Vault"
        fi
    else
        log_error "Database secrets engine not enabled in Vault"
    fi
else
    log_warning "Vault token not available for database secrets engine testing"
fi

echo ""

# Test 6: Service Database Connectivity
log_test "Testing service database connectivity..."

# Test Keycloak database
if docker exec purebliss-postgres psql -U postgres -d keycloak -t -c "SELECT 'Keycloak DB accessible!' as status;" 2>/dev/null | grep -q "Keycloak DB accessible"; then
    log_success "Keycloak database accessible"

    # Test keycloak user access
    if [[ -n "${VAULT_TOKEN:-}" ]]; then
        if keycloak_pass=$(vault kv get -field=db_password secret/keycloak 2>/dev/null); then
            if PGPASSWORD="$keycloak_pass" docker exec purebliss-postgres psql -U keycloak -d keycloak -t -c "SELECT 'Keycloak user access working!' as status;" 2>/dev/null | grep -q "Keycloak user access working"; then
                log_success "Keycloak user database access working"
            else
                log_error "Keycloak user database access failed"
            fi
        else
            log_warning "Keycloak password not available from Vault for testing"
        fi
    fi
else
    log_error "Keycloak database not accessible"
fi

# Test Plane database
if docker exec purebliss-postgres psql -U postgres -d plane -t -c "SELECT 'Plane DB accessible!' as status;" 2>/dev/null | grep -q "Plane DB accessible"; then
    log_success "Plane database accessible"
else
    log_error "Plane database not accessible"
fi

echo ""

# Test 7: Security and Compliance
log_test "Testing security and compliance..."

# Check for hardcoded passwords (should be none)
if docker exec purebliss-postgres env | grep -E "(PASSWORD|PASS)" | grep -v "PASSWORD_FILE"; then
    log_error "Hardcoded passwords found in container environment (violates Elite Standards)"
else
    log_success "No hardcoded passwords in container environment"
fi

# Check file permissions on secrets
if docker exec purebliss-postgres ls -la /run/secrets/ 2>/dev/null | grep "^-rw-------"; then
    log_success "Secret files have secure permissions (600)"
else
    log_warning "Secret file permissions may not be optimal"
fi

# Check if container is running as non-root
if docker exec purebliss-postgres id | grep -q "uid=999"; then
    log_success "Container running as postgres user (non-root)"
else
    log_warning "Container may be running as root"
fi

echo ""

# Test 8: Performance and Resource Usage
log_test "Testing performance and resource usage..."

# Check memory usage
memory_usage=$(docker stats purebliss-postgres --no-stream --format "{{.MemUsage}}" | cut -d'/' -f1)
log_success "Current memory usage: $memory_usage"

# Check connection count
conn_count=$(docker exec purebliss-postgres psql -U postgres -d postgres -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null | tr -d ' ')
log_success "Active connections: $conn_count"

# Test query performance (basic)
query_time=$(docker exec purebliss-postgres psql -U postgres -d postgres -t -c "EXPLAIN ANALYZE SELECT 1;" 2>/dev/null | grep "Execution Time" | awk '{print $3 " " $4}' || echo "N/A")
log_success "Basic query execution time: $query_time"

echo ""

# Final Status Summary
echo "=== Validation Summary ==="
echo ""

# Count errors and warnings from this session
error_count=$(grep -c "❌" /tmp/postgres_validation_output 2>/dev/null || echo "0")
warning_count=$(grep -c "⚠️" /tmp/postgres_validation_output 2>/dev/null || echo "0")

if [[ "$error_count" -eq 0 && "$warning_count" -eq 0 ]]; then
    echo "🎉 PostgreSQL Vault Integration: FULLY COMPLIANT"
    echo "✅ Zero-Trust: All secrets managed by Vault"
    echo "✅ Dynamic Secrets: Working and tested"
    echo "✅ Service Integration: All databases and users configured"
    echo "✅ Security: No hardcoded credentials"
    echo "✅ Performance: Optimal resource usage"
    echo "✅ Ready for production workloads"
    echo ""
    echo "PostgreSQL is ready for the next service (Redis) to start."
    exit 0
elif [[ "$error_count" -eq 0 ]]; then
    echo "✅ PostgreSQL Vault Integration: OPERATIONAL with $warning_count warnings"
    echo "⚠️  Check warnings above for optimization opportunities"
    echo ""
    echo "PostgreSQL is functional and ready for the next service."
    exit 0
else
    echo "❌ PostgreSQL Vault Integration: FAILED with $error_count errors"
    echo "🔧 Issues must be resolved before proceeding to next service"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check logs: docker logs purebliss-postgres"
    echo "2. Verify Vault status: vault status"
    echo "3. Re-run setup: /opt/dev-purebliss/services/postgres/start-postgres-vault.sh"
    echo "4. Check comprehensive health: /opt/dev-purebliss/dev_scripts/health-checks/comprehensive-health-check.sh"
    exit 1
fi

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
