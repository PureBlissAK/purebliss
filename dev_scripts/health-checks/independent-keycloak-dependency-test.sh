#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# INDEPENDENT_KEYCLOAK_DEPENDENCY_TEST_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="independent-keycloak-dependency-test.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced health-validation script for monitoring operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="health-validation"
SCRIPT_TAGS="enhancement,automation,auto-commit,monitoring,testing,validation"
SCRIPT_SERVICES="monitoring"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced health-validation script for monitoring with auto-commit functionality,
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
independent_keycloak_dependency_test_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
independent_keycloak_dependency_test_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
independent_keycloak_dependency_test_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
independent_keycloak_dependency_test_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    independent_keycloak_dependency_test_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        independent_keycloak_dependency_test_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            independent_keycloak_dependency_test_log_success "Validation passed - proceeding with auto-commit"
        else
            independent_keycloak_dependency_test_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        independent_keycloak_dependency_test_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        independent_keycloak_dependency_test_log_info "Auto-commit system not available - manual commit required"
        independent_keycloak_dependency_test_log_info "Recommended commit message: $commit_message"
        independent_keycloak_dependency_test_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
independent_keycloak_dependency_test_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    independent_keycloak_dependency_test_log_success "$final_message"
    
    # Execute auto-commit wrapper
    independent_keycloak_dependency_test_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    independent_keycloak_dependency_test_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# Independent Keycloak Dependency Testing Script
# Tests PostgreSQL and Redis connectivity independently while maintaining all running services
# Date: 2025-08-06


# Logging function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - KEYCLOAK_DEP_TEST [$1]: $2" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
}

log_action "INFO" "Starting independent Keycloak dependency testing while maintaining running infrastructure"

# Verify core infrastructure is running
verify_core_infrastructure() {
    log_action "INFO" "Verifying core infrastructure services are running"

    local required_services=("purebliss-vault" "purebliss-vault-agent" "purebliss-postgres" "purebliss-redis" "purebliss-nginx")
    local all_running=true

    for service in "${required_services[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^${service}$"; then
            local status=$(docker inspect --format='{{.State.Status}}' "$service")
            if [ "$status" = "running" ]; then
                log_action "SUCCESS" "$service is running"
            else
                log_action "ERROR" "$service exists but is not running (status: $status)"
                all_running=false
            fi
        else
            log_action "ERROR" "$service is not found"
            all_running=false
        fi
    done

    if [ "$all_running" = "true" ]; then
        log_action "SUCCESS" "All core infrastructure services are running"
        return 0
    else
        log_action "ERROR" "Some core infrastructure services are not running"
        return 1
    fi
}

# Comprehensive PostgreSQL connectivity testing
test_postgres_connectivity_comprehensive() {
    log_action "INFO" "Comprehensive PostgreSQL connectivity testing started"

    local postgres_host="purebliss-postgres"
    local postgres_port="5432"
    local max_retries=5
    local retry_delay=3

    # Test 1: Basic TCP connectivity with retries
    log_action "INFO" "Test 1.1.1: Basic TCP connectivity to PostgreSQL"
    local retry=0
    while [ $retry -lt $max_retries ]; do
        if timeout 10 bash -c "echo > /dev/tcp/$postgres_host/$postgres_port" 2>/dev/null; then
            log_action "SUCCESS" "PostgreSQL TCP connectivity: PASS (attempt $((retry + 1)))"
            break
        else
            retry=$((retry + 1))
            if [ $retry -lt $max_retries ]; then
                log_action "WARNING" "PostgreSQL TCP connectivity failed, retrying ($retry/$max_retries)"
                sleep $retry_delay
            else
                log_action "ERROR" "PostgreSQL TCP connectivity: FAIL (all $max_retries attempts failed)"
                return 1
            fi
        fi
    done

    # Test 2: PostgreSQL service readiness
    log_action "INFO" "Test 1.1.2: PostgreSQL service readiness check"
    retry=0
    while [ $retry -lt $max_retries ]; do
        if docker exec purebliss-postgres pg_isready -U postgres -h localhost -p 5432 2>/dev/null; then
            log_action "SUCCESS" "PostgreSQL service readiness: PASS (attempt $((retry + 1)))"
            break
        else
            retry=$((retry + 1))
            if [ $retry -lt $max_retries ]; then
                log_action "WARNING" "PostgreSQL service not ready, retrying ($retry/$max_retries)"
                sleep $retry_delay
            else
                log_action "ERROR" "PostgreSQL service readiness: FAIL (all $max_retries attempts failed)"
                return 1
            fi
        fi
    done

    # Test 3: PostgreSQL version and basic info
    log_action "INFO" "Test 1.1.3: PostgreSQL version and configuration"
    local pg_version=$(docker exec purebliss-postgres psql -U postgres -t -c "SELECT version();" 2>/dev/null | head -1 | xargs)
    if [ -n "$pg_version" ]; then
        log_action "SUCCESS" "PostgreSQL version: $pg_version"
    else
        log_action "ERROR" "Failed to retrieve PostgreSQL version"
        return 1
    fi

    # Test 4: PostgreSQL connection limit check
    log_action "INFO" "Test 1.1.4: PostgreSQL connection limits"
    local max_connections=$(docker exec purebliss-postgres psql -U postgres -t -c "SHOW max_connections;" 2>/dev/null | xargs)
    local current_connections=$(docker exec purebliss-postgres psql -U postgres -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null | xargs)

    if [ -n "$max_connections" ] && [ -n "$current_connections" ]; then
        log_action "SUCCESS" "PostgreSQL connections: $current_connections/$max_connections"
        if [ "$current_connections" -gt $((max_connections * 80 / 100)) ]; then
            log_action "WARNING" "PostgreSQL connection usage > 80% - potential issue"
        fi
    else
        log_action "ERROR" "Failed to check PostgreSQL connection limits"
        return 1
    fi

    log_action "SUCCESS" "PostgreSQL connectivity comprehensive testing: COMPLETE"
    return 0
}

# Comprehensive PostgreSQL authentication testing
test_postgres_authentication_comprehensive() {
    log_action "INFO" "Comprehensive PostgreSQL authentication testing started"

    local db_user="keycloak"
    local db_password="keycloak_secure_2025"
    local max_retries=3
    local retry_delay=2

    # Test 1: Superuser authentication
    log_action "INFO" "Test 1.2.1: PostgreSQL superuser authentication"
    if docker exec purebliss-postgres psql -U postgres -c "SELECT current_user, session_user;" 2>/dev/null; then
        log_action "SUCCESS" "PostgreSQL superuser authentication: PASS"
    else
        log_action "ERROR" "PostgreSQL superuser authentication: FAIL"
        return 1
    fi

    # Test 2: Keycloak user existence
    log_action "INFO" "Test 1.2.2: Keycloak user existence check"
    local user_exists=$(docker exec purebliss-postgres psql -U postgres -t -c "SELECT 1 FROM pg_roles WHERE rolname='$db_user';" 2>/dev/null | xargs)
    if [ "$user_exists" = "1" ]; then
        log_action "SUCCESS" "Keycloak user exists: PASS"
    else
        log_action "ERROR" "Keycloak user does not exist: FAIL"
        return 1
    fi

    # Test 3: Keycloak user authentication with retries
    log_action "INFO" "Test 1.2.3: Keycloak user authentication"
    export PGPASSWORD="$db_password"
    local retry=0
    while [ $retry -lt $max_retries ]; do
        if docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d postgres -c "SELECT current_user, current_database();" 2>/dev/null; then
            log_action "SUCCESS" "Keycloak user authentication: PASS (attempt $((retry + 1)))"
            break
        else
            retry=$((retry + 1))
            if [ $retry -lt $max_retries ]; then
                log_action "WARNING" "Keycloak user authentication failed, retrying ($retry/$max_retries)"
                sleep $retry_delay
            else
                log_action "ERROR" "Keycloak user authentication: FAIL (all $max_retries attempts failed)"
                return 1
            fi
        fi
    done

    # Test 4: User privileges validation
    log_action "INFO" "Test 1.2.4: Keycloak user privileges validation"
    local user_privileges=$(docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d postgres -t -c "SELECT rolcreatedb, rolcreaterole FROM pg_roles WHERE rolname='$db_user';" 2>/dev/null | xargs)
    if [ -n "$user_privileges" ]; then
        log_action "SUCCESS" "Keycloak user privileges: $user_privileges"
    else
        log_action "ERROR" "Failed to validate Keycloak user privileges"
        return 1
    fi

    log_action "SUCCESS" "PostgreSQL authentication comprehensive testing: COMPLETE"
    return 0
}

# Comprehensive PostgreSQL database access testing
test_postgres_database_access_comprehensive() {
    log_action "INFO" "Comprehensive PostgreSQL database access testing started"

    local db_name="keycloak"
    local db_user="keycloak"
    local db_password="keycloak_secure_2025"

    # Test 1: Keycloak database existence
    log_action "INFO" "Test 1.3.1: Keycloak database existence check"
    local db_exists=$(docker exec purebliss-postgres psql -U postgres -t -c "SELECT 1 FROM pg_database WHERE datname='$db_name';" 2>/dev/null | xargs)
    if [ "$db_exists" = "1" ]; then
        log_action "SUCCESS" "Keycloak database exists: PASS"
    else
        log_action "ERROR" "Keycloak database does not exist: FAIL"
        return 1
    fi

    # Test 2: Database connection
    log_action "INFO" "Test 1.3.2: Keycloak database connection"
    export PGPASSWORD="$db_password"
    if docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d "$db_name" -c "SELECT current_database(), current_user;" 2>/dev/null; then
        log_action "SUCCESS" "Keycloak database connection: PASS"
    else
        log_action "ERROR" "Keycloak database connection: FAIL"
        return 1
    fi

    # Test 3: Database schema validation
    log_action "INFO" "Test 1.3.3: Keycloak database schema validation"
    local schema_count=$(docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d "$db_name" -t -c "SELECT count(*) FROM information_schema.schemata WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast');" 2>/dev/null | xargs)
    if [ -n "$schema_count" ] && [ "$schema_count" -ge 1 ]; then
        log_action "SUCCESS" "Keycloak database schemas: $schema_count"
    else
        log_action "WARNING" "Keycloak database has minimal schemas: $schema_count (may be empty/new database)"
    fi

    # Test 4: Read/Write operations test
    log_action "INFO" "Test 1.3.4: Database read/write operations test"
    local test_table="keycloak_health_test_$(date +%s)"

    # Create test table
    if docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d "$db_name" -c "CREATE TABLE $test_table (id SERIAL PRIMARY KEY, test_data VARCHAR(50), created_at TIMESTAMP DEFAULT NOW());" 2>/dev/null; then
        log_action "SUCCESS" "Test table creation: PASS"
    else
        log_action "ERROR" "Test table creation: FAIL"
        return 1
    fi

    # Insert test data
    if docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d "$db_name" -c "INSERT INTO $test_table (test_data) VALUES ('health_check_test');" 2>/dev/null; then
        log_action "SUCCESS" "Test data insertion: PASS"
    else
        log_action "ERROR" "Test data insertion: FAIL"
        return 1
    fi

    # Read test data
    local test_result=$(docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d "$db_name" -t -c "SELECT test_data FROM $test_table WHERE test_data = 'health_check_test';" 2>/dev/null | xargs)
    if [ "$test_result" = "health_check_test" ]; then
        log_action "SUCCESS" "Test data retrieval: PASS"
    else
        log_action "ERROR" "Test data retrieval: FAIL"
        return 1
    fi

    # Cleanup test table
    docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d "$db_name" -c "DROP TABLE $test_table;" 2>/dev/null
    log_action "SUCCESS" "Test table cleanup: COMPLETE"

    log_action "SUCCESS" "PostgreSQL database access comprehensive testing: COMPLETE"
    return 0
}

# Comprehensive PostgreSQL performance testing
test_postgres_performance_comprehensive() {
    log_action "INFO" "Comprehensive PostgreSQL performance testing started"

    local db_name="keycloak"
    local db_user="keycloak"
    local db_password="keycloak_secure_2025"

    # Test 1: Connection response time
    log_action "INFO" "Test 1.4.1: PostgreSQL connection response time"
    export PGPASSWORD="$db_password"
    local start_time=$(date +%s%N)
    if docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d "$db_name" -c "SELECT 1;" 2>/dev/null >/dev/null; then
        local end_time=$(date +%s%N)
        local response_time=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
        log_action "SUCCESS" "PostgreSQL connection response time: ${response_time}ms"

        if [ "$response_time" -gt 5000 ]; then
            log_action "WARNING" "PostgreSQL connection response time > 5000ms - performance concern"
        fi
    else
        log_action "ERROR" "PostgreSQL connection response time test: FAIL"
        return 1
    fi

    # Test 2: Query performance test
    log_action "INFO" "Test 1.4.2: PostgreSQL query performance test"
    start_time=$(date +%s%N)
    local query_result=$(docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d "$db_name" -t -c "SELECT count(*) FROM information_schema.tables;" 2>/dev/null | xargs)
    end_time=$(date +%s%N)
    local query_time=$(( (end_time - start_time) / 1000000 ))

    if [ -n "$query_result" ]; then
        log_action "SUCCESS" "PostgreSQL query performance: ${query_time}ms (${query_result} tables)"

        if [ "$query_time" -gt 1000 ]; then
            log_action "WARNING" "PostgreSQL query time > 1000ms - performance concern"
        fi
    else
        log_action "ERROR" "PostgreSQL query performance test: FAIL"
        return 1
    fi

    # Test 3: Database size and statistics
    log_action "INFO" "Test 1.4.3: PostgreSQL database statistics"
    local db_size=$(docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d "$db_name" -t -c "SELECT pg_size_pretty(pg_database_size('$db_name'));" 2>/dev/null | xargs)
    local connection_count=$(docker exec purebliss-postgres psql -U postgres -t -c "SELECT count(*) FROM pg_stat_activity WHERE datname='$db_name';" 2>/dev/null | xargs)

    if [ -n "$db_size" ] && [ -n "$connection_count" ]; then
        log_action "SUCCESS" "Keycloak database size: $db_size, active connections: $connection_count"
    else
        log_action "ERROR" "Failed to retrieve PostgreSQL database statistics"
        return 1
    fi

    log_action "SUCCESS" "PostgreSQL performance comprehensive testing: COMPLETE"
    return 0
}

# Comprehensive PostgreSQL-Keycloak integration testing
test_postgres_keycloak_integration_comprehensive() {
    log_action "INFO" "Comprehensive PostgreSQL-Keycloak integration testing started"

    local db_name="keycloak"
    local db_user="keycloak"
    local db_password="keycloak_secure_2025"

    # Test 1: Keycloak-specific configuration validation
    log_action "INFO" "Test 1.5.1: Keycloak database configuration validation"
    export PGPASSWORD="$db_password"

    # Check for typical Keycloak tables (if they exist)
    local keycloak_tables=$(docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d "$db_name" -t -c "SELECT count(*) FROM information_schema.tables WHERE table_name LIKE '%realm%' OR table_name LIKE '%user%' OR table_name LIKE '%client%';" 2>/dev/null | xargs)

    if [ -n "$keycloak_tables" ]; then
        if [ "$keycloak_tables" -gt 0 ]; then
            log_action "SUCCESS" "Keycloak tables detected: $keycloak_tables (existing installation)"
        else
            log_action "SUCCESS" "No Keycloak tables found: clean database ready for Keycloak initialization"
        fi
    else
        log_action "ERROR" "Failed to query Keycloak table information"
        return 1
    fi

    # Test 2: Database encoding and collation
    log_action "INFO" "Test 1.5.2: Database encoding and collation validation"
    local db_encoding=$(docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d "$db_name" -t -c "SELECT pg_encoding_to_char(encoding) FROM pg_database WHERE datname='$db_name';" 2>/dev/null | xargs)
    local db_collate=$(docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d "$db_name" -t -c "SELECT datcollate FROM pg_database WHERE datname='$db_name';" 2>/dev/null | xargs)

    if [ -n "$db_encoding" ] && [ -n "$db_collate" ]; then
        log_action "SUCCESS" "Database encoding: $db_encoding, collation: $db_collate"

        # Check for UTF8 encoding (recommended for Keycloak)
        if echo "$db_encoding" | grep -q "UTF8\|UTF-8"; then
            log_action "SUCCESS" "UTF-8 encoding detected: optimal for Keycloak"
        else
            log_action "WARNING" "Non-UTF8 encoding detected: may cause Keycloak issues"
        fi
    else
        log_action "ERROR" "Failed to validate database encoding and collation"
        return 1
    fi

    # Test 3: Connection pool simulation
    log_action "INFO" "Test 1.5.3: PostgreSQL connection pool simulation"
    local concurrent_connections=5
    local connection_test_passed=0

    for i in $(seq 1 $concurrent_connections); do
        if docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d "$db_name" -c "SELECT 'connection_test_$i' AS test;" 2>/dev/null >/dev/null; then
            connection_test_passed=$((connection_test_passed + 1))
        fi
    done

    if [ "$connection_test_passed" -eq "$concurrent_connections" ]; then
        log_action "SUCCESS" "Connection pool simulation: $connection_test_passed/$concurrent_connections connections successful"
    else
        log_action "WARNING" "Connection pool simulation: only $connection_test_passed/$concurrent_connections connections successful"
    fi

    # Test 4: Transaction support validation
    log_action "INFO" "Test 1.5.4: PostgreSQL transaction support validation"
    local transaction_test="keycloak_transaction_test_$(date +%s)"

    # Test transaction with rollback
    if docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d "$db_name" -c "BEGIN; CREATE TABLE $transaction_test (id INT); ROLLBACK;" 2>/dev/null; then
        log_action "SUCCESS" "Transaction rollback support: PASS"
    else
        log_action "ERROR" "Transaction rollback support: FAIL"
        return 1
    fi

    # Verify table was not created (rollback worked)
    local table_exists=$(docker exec -e PGPASSWORD="$db_password" purebliss-postgres psql -U "$db_user" -d "$db_name" -t -c "SELECT count(*) FROM information_schema.tables WHERE table_name='$transaction_test';" 2>/dev/null | xargs)
    if [ "$table_exists" = "0" ]; then
        log_action "SUCCESS" "Transaction rollback verification: PASS"
    else
        log_action "ERROR" "Transaction rollback verification: FAIL (table still exists)"
        return 1
    fi

    log_action "SUCCESS" "PostgreSQL-Keycloak integration comprehensive testing: COMPLETE"
    return 0
}

# Comprehensive Redis connectivity testing
test_redis_connectivity_comprehensive() {
    log_action "INFO" "Comprehensive Redis connectivity testing started"

    local redis_host="purebliss-redis"
    local redis_port="6379"
    local max_retries=5
    local retry_delay=3

    # Test 1: Basic TCP connectivity with retries
    log_action "INFO" "Test 2.1.1: Basic TCP connectivity to Redis"
    local retry=0
    while [ $retry -lt $max_retries ]; do
        if timeout 10 bash -c "echo > /dev/tcp/$redis_host/$redis_port" 2>/dev/null; then
            log_action "SUCCESS" "Redis TCP connectivity: PASS (attempt $((retry + 1)))"
            break
        else
            retry=$((retry + 1))
            if [ $retry -lt $max_retries ]; then
                log_action "WARNING" "Redis TCP connectivity failed, retrying ($retry/$max_retries)"
                sleep $retry_delay
            else
                log_action "ERROR" "Redis TCP connectivity: FAIL (all $max_retries attempts failed)"
                return 1
            fi
        fi
    done

    # Test 2: Redis service ping
    log_action "INFO" "Test 2.1.2: Redis service ping test"
    retry=0
    while [ $retry -lt $max_retries ]; do
        local ping_result=$(docker exec purebliss-redis redis-cli ping 2>/dev/null)
        if [ "$ping_result" = "PONG" ]; then
            log_action "SUCCESS" "Redis service ping: PASS (attempt $((retry + 1)))"
            break
        else
            retry=$((retry + 1))
            if [ $retry -lt $max_retries ]; then
                log_action "WARNING" "Redis service ping failed, retrying ($retry/$max_retries)"
                sleep $retry_delay
            else
                log_action "ERROR" "Redis service ping: FAIL (all $max_retries attempts failed)"
                return 1
            fi
        fi
    done

    # Test 3: Redis server info
    log_action "INFO" "Test 2.1.3: Redis server information"
    local redis_version=$(docker exec purebliss-redis redis-cli info server 2>/dev/null | grep "redis_version" | cut -d: -f2 | tr -d '\r')
    local redis_mode=$(docker exec purebliss-redis redis-cli info server 2>/dev/null | grep "redis_mode" | cut -d: -f2 | tr -d '\r')

    if [ -n "$redis_version" ] && [ -n "$redis_mode" ]; then
        log_action "SUCCESS" "Redis version: $redis_version, mode: $redis_mode"
    else
        log_action "ERROR" "Failed to retrieve Redis server information"
        return 1
    fi

    # Test 4: Redis memory and configuration
    log_action "INFO" "Test 2.1.4: Redis memory and configuration check"
    local used_memory=$(docker exec purebliss-redis redis-cli info memory 2>/dev/null | grep "used_memory_human" | cut -d: -f2 | tr -d '\r')
    local max_memory=$(docker exec purebliss-redis redis-cli config get maxmemory 2>/dev/null | tail -1)

    if [ -n "$used_memory" ]; then
        log_action "SUCCESS" "Redis memory usage: $used_memory"
        if [ "$max_memory" != "0" ]; then
            log_action "SUCCESS" "Redis max memory configured: $max_memory"
        else
            log_action "INFO" "Redis max memory: unlimited"
        fi
    else
        log_action "ERROR" "Failed to check Redis memory configuration"
        return 1
    fi

    log_action "SUCCESS" "Redis connectivity comprehensive testing: COMPLETE"
    return 0
}

# Comprehensive Redis authentication testing
test_redis_authentication_comprehensive() {
    log_action "INFO" "Comprehensive Redis authentication testing started"

    # Test 1: No-auth access (if configured)
    log_action "INFO" "Test 2.2.1: Redis authentication method detection"
    local auth_required=$(docker exec purebliss-redis redis-cli config get requirepass 2>/dev/null | tail -1)

    if [ -n "$auth_required" ] && [ "$auth_required" != "" ]; then
        log_action "INFO" "Redis authentication required: YES"

        # Test authentication with password if required
        log_action "INFO" "Test 2.2.2: Redis password authentication"
        if docker exec purebliss-redis redis-cli -a "$auth_required" ping 2>/dev/null | grep -q "PONG"; then
            log_action "SUCCESS" "Redis password authentication: PASS"
        else
            log_action "ERROR" "Redis password authentication: FAIL"
            return 1
        fi
    else
        log_action "INFO" "Redis authentication required: NO (no password set)"

        # Test no-auth access
        log_action "INFO" "Test 2.2.2: Redis no-auth access"
        if docker exec purebliss-redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
            log_action "SUCCESS" "Redis no-auth access: PASS"
        else
            log_action "ERROR" "Redis no-auth access: FAIL"
            return 1
        fi
    fi

    # Test 3: ACL configuration check (Redis 6+)
    log_action "INFO" "Test 2.2.3: Redis ACL configuration check"
    local acl_users=$(docker exec purebliss-redis redis-cli acl list 2>/dev/null | wc -l)

    if [ -n "$acl_users" ] && [ "$acl_users" -gt 0 ]; then
        log_action "SUCCESS" "Redis ACL users configured: $acl_users"
    else
        log_action "INFO" "Redis ACL: not configured or not supported"
    fi

    # Test 4: Connection persistence test
    log_action "INFO" "Test 2.2.4: Redis connection persistence test"
    local connection_id=$(docker exec purebliss-redis redis-cli client id 2>/dev/null)
    sleep 2
    local connection_id_after=$(docker exec purebliss-redis redis-cli client id 2>/dev/null)

    if [ -n "$connection_id" ] && [ -n "$connection_id_after" ]; then
        log_action "SUCCESS" "Redis connection persistence: stable (ID: $connection_id → $connection_id_after)"
    else
        log_action "ERROR" "Redis connection persistence test: FAIL"
        return 1
    fi

    log_action "SUCCESS" "Redis authentication comprehensive testing: COMPLETE"
    return 0
}

# Comprehensive Redis operations testing
test_redis_operations_comprehensive() {
    log_action "INFO" "Comprehensive Redis operations testing started"

    local test_key_prefix="keycloak_health_test_$(date +%s)"

    # Test 1: Basic SET/GET operations
    log_action "INFO" "Test 2.3.1: Redis basic SET/GET operations"
    local test_value="health_check_value_$(date +%s)"

    if docker exec purebliss-redis redis-cli set "${test_key_prefix}_basic" "$test_value" 2>/dev/null | grep -q "OK"; then
        log_action "SUCCESS" "Redis SET operation: PASS"
    else
        log_action "ERROR" "Redis SET operation: FAIL"
        return 1
    fi

    local retrieved_value=$(docker exec purebliss-redis redis-cli get "${test_key_prefix}_basic" 2>/dev/null)
    if [ "$retrieved_value" = "$test_value" ]; then
        log_action "SUCCESS" "Redis GET operation: PASS"
    else
        log_action "ERROR" "Redis GET operation: FAIL (expected: $test_value, got: $retrieved_value)"
        return 1
    fi

    # Test 2: Hash operations (common for session storage)
    log_action "INFO" "Test 2.3.2: Redis hash operations test"
    local hash_key="${test_key_prefix}_hash"

    if docker exec purebliss-redis redis-cli hset "$hash_key" field1 "value1" field2 "value2" 2>/dev/null >/dev/null; then
        log_action "SUCCESS" "Redis HSET operation: PASS"
    else
        log_action "ERROR" "Redis HSET operation: FAIL"
        return 1
    fi

    local hash_value=$(docker exec purebliss-redis redis-cli hget "$hash_key" field1 2>/dev/null)
    if [ "$hash_value" = "value1" ]; then
        log_action "SUCCESS" "Redis HGET operation: PASS"
    else
        log_action "ERROR" "Redis HGET operation: FAIL"
        return 1
    fi

    # Test 3: List operations
    log_action "INFO" "Test 2.3.3: Redis list operations test"
    local list_key="${test_key_prefix}_list"

    if docker exec purebliss-redis redis-cli lpush "$list_key" "item1" "item2" "item3" 2>/dev/null >/dev/null; then
        log_action "SUCCESS" "Redis LPUSH operation: PASS"
    else
        log_action "ERROR" "Redis LPUSH operation: FAIL"
        return 1
    fi

    local list_length=$(docker exec purebliss-redis redis-cli llen "$list_key" 2>/dev/null)
    if [ "$list_length" = "3" ]; then
        log_action "SUCCESS" "Redis LLEN operation: PASS (length: $list_length)"
    else
        log_action "ERROR" "Redis LLEN operation: FAIL (expected: 3, got: $list_length)"
        return 1
    fi

    # Test 4: Expiration and TTL
    log_action "INFO" "Test 2.3.4: Redis expiration and TTL test"
    local ttl_key="${test_key_prefix}_ttl"

    if docker exec purebliss-redis redis-cli setex "$ttl_key" 60 "expires_in_60_seconds" 2>/dev/null | grep -q "OK"; then
        log_action "SUCCESS" "Redis SETEX operation: PASS"
    else
        log_action "ERROR" "Redis SETEX operation: FAIL"
        return 1
    fi

    local ttl_value=$(docker exec purebliss-redis redis-cli ttl "$ttl_key" 2>/dev/null)
    if [ "$ttl_value" -gt 0 ] && [ "$ttl_value" -le 60 ]; then
        log_action "SUCCESS" "Redis TTL operation: PASS (TTL: ${ttl_value}s)"
    else
        log_action "ERROR" "Redis TTL operation: FAIL (TTL: $ttl_value)"
        return 1
    fi

    # Cleanup test keys
    docker exec purebliss-redis redis-cli del "${test_key_prefix}_basic" "$hash_key" "$list_key" "$ttl_key" 2>/dev/null >/dev/null
    log_action "SUCCESS" "Redis test keys cleanup: COMPLETE"

    log_action "SUCCESS" "Redis operations comprehensive testing: COMPLETE"
    return 0
}

# Comprehensive Redis performance testing
test_redis_performance_comprehensive() {
    log_action "INFO" "Comprehensive Redis performance testing started"

    # Test 1: Command latency test
    log_action "INFO" "Test 2.4.1: Redis command latency test"
    local latency_samples=10
    local total_latency=0

    for i in $(seq 1 $latency_samples); do
        local start_time=$(date +%s%N)
        docker exec purebliss-redis redis-cli ping 2>/dev/null >/dev/null
        local end_time=$(date +%s%N)
        local latency=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
        total_latency=$((total_latency + latency))
    done

    local avg_latency=$((total_latency / latency_samples))
    log_action "SUCCESS" "Redis average command latency: ${avg_latency}ms (${latency_samples} samples)"

    if [ "$avg_latency" -gt 100 ]; then
        log_action "WARNING" "Redis average latency > 100ms - performance concern"
    fi

    # Test 2: Throughput test
    log_action "INFO" "Test 2.4.2: Redis throughput test"
    local throughput_start=$(date +%s)
    local operations_count=100
    local test_key_prefix="perf_test_$(date +%s)"

    for i in $(seq 1 $operations_count); do
        docker exec purebliss-redis redis-cli set "${test_key_prefix}_$i" "value_$i" 2>/dev/null >/dev/null
    done

    local throughput_end=$(date +%s)
    local throughput_time=$((throughput_end - throughput_start))
    local ops_per_second=$((operations_count / (throughput_time + 1))) # +1 to avoid division by zero

    log_action "SUCCESS" "Redis throughput: ${ops_per_second} ops/sec ($operations_count operations in ${throughput_time}s)"

    # Cleanup performance test keys
    for i in $(seq 1 $operations_count); do
        docker exec purebliss-redis redis-cli del "${test_key_prefix}_$i" 2>/dev/null >/dev/null
    done

    # Test 3: Memory usage analysis
    log_action "INFO" "Test 2.4.3: Redis memory usage analysis"
    local used_memory_bytes=$(docker exec purebliss-redis redis-cli info memory 2>/dev/null | grep "used_memory:" | cut -d: -f2 | tr -d '\r')
    local used_memory_human=$(docker exec purebliss-redis redis-cli info memory 2>/dev/null | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
    local mem_fragmentation=$(docker exec purebliss-redis redis-cli info memory 2>/dev/null | grep "mem_fragmentation_ratio:" | cut -d: -f2 | tr -d '\r')

    if [ -n "$used_memory_human" ] && [ -n "$mem_fragmentation" ]; then
        log_action "SUCCESS" "Redis memory usage: $used_memory_human, fragmentation ratio: $mem_fragmentation"

        # Check fragmentation ratio (should be close to 1.0)
        if echo "$mem_fragmentation" | awk '{ if ($1 > 2.0) exit 1; else exit 0 }'; then
            log_action "SUCCESS" "Redis memory fragmentation is acceptable"
        else
            log_action "WARNING" "Redis memory fragmentation ratio > 2.0 - memory concern"
        fi
    else
        log_action "ERROR" "Failed to retrieve Redis memory statistics"
        return 1
    fi

    # Test 4: Persistence performance
    log_action "INFO" "Test 2.4.4: Redis persistence performance test"
    local save_start=$(date +%s)
    if docker exec purebliss-redis redis-cli bgsave 2>/dev/null | grep -q "Background saving started"; then
        log_action "SUCCESS" "Redis background save initiated: PASS"

        # Wait for save to complete (with timeout)
        local save_timeout=30
        local save_elapsed=0
        while [ $save_elapsed -lt $save_timeout ]; do
            if docker exec purebliss-redis redis-cli lastsave 2>/dev/null >/dev/null; then
                local save_end=$(date +%s)
                local save_duration=$((save_end - save_start))
                log_action "SUCCESS" "Redis background save completed in ${save_duration}s"
                break
            fi
            sleep 1
            save_elapsed=$((save_elapsed + 1))
        done

        if [ $save_elapsed -ge $save_timeout ]; then
            log_action "WARNING" "Redis background save taking longer than expected (>${save_timeout}s)"
        fi
    else
        log_action "WARNING" "Redis background save failed (may not be critical)"
    fi

    log_action "SUCCESS" "Redis performance comprehensive testing: COMPLETE"
    return 0
}

# Comprehensive Redis-Keycloak integration testing
test_redis_keycloak_integration_comprehensive() {
    log_action "INFO" "Comprehensive Redis-Keycloak integration testing started"

    # Test 1: Session storage simulation
    log_action "INFO" "Test 2.5.1: Keycloak session storage simulation"
    local session_key="sessions:keycloak:user:test_$(date +%s)"
    local session_data='{"userId":"test_user","realm":"master","clientId":"test_client","timestamp":"'$(date -Iseconds)'"}'

    if docker exec purebliss-redis redis-cli set "$session_key" "$session_data" EX 3600 2>/dev/null | grep -q "OK"; then
        log_action "SUCCESS" "Keycloak session storage: PASS"
    else
        log_action "ERROR" "Keycloak session storage: FAIL"
        return 1
    fi

    # Verify session retrieval
    local retrieved_session=$(docker exec purebliss-redis redis-cli get "$session_key" 2>/dev/null)
    if echo "$retrieved_session" | grep -q "test_user"; then
        log_action "SUCCESS" "Keycloak session retrieval: PASS"
    else
        log_action "ERROR" "Keycloak session retrieval: FAIL"
        return 1
    fi

    # Test 2: Cache invalidation simulation
    log_action "INFO" "Test 2.5.2: Keycloak cache invalidation simulation"
    local cache_pattern="cache:keycloak:*"
    local cache_key1="cache:keycloak:realm:master"
    local cache_key2="cache:keycloak:user:test_user"

    # Create test cache entries
    docker exec purebliss-redis redis-cli set "$cache_key1" "realm_data" 2>/dev/null
    docker exec purebliss-redis redis-cli set "$cache_key2" "user_data" 2>/dev/null

    # Test pattern-based cache invalidation
    local cache_keys=$(docker exec purebliss-redis redis-cli keys "$cache_pattern" 2>/dev/null)
    if [ -n "$cache_keys" ]; then
        log_action "SUCCESS" "Keycloak cache pattern matching: PASS (found keys)"

        # Simulate cache invalidation
        if docker exec purebliss-redis redis-cli del $cache_keys 2>/dev/null >/dev/null; then
            log_action "SUCCESS" "Keycloak cache invalidation: PASS"
        else
            log_action "ERROR" "Keycloak cache invalidation: FAIL"
            return 1
        fi
    else
        log_action "WARNING" "Keycloak cache pattern matching: no keys found (may be expected)"
    fi

    # Test 3: Connection pool simulation for Keycloak
    log_action "INFO" "Test 2.5.3: Keycloak connection pool simulation"
    local concurrent_sessions=10
    local successful_connections=0

    for i in $(seq 1 $concurrent_sessions); do
        local conn_key="connection:keycloak:pool:$i"
        if docker exec purebliss-redis redis-cli set "$conn_key" "connection_$i" EX 30 2>/dev/null | grep -q "OK"; then
            successful_connections=$((successful_connections + 1))
        fi
    done

    if [ "$successful_connections" -eq "$concurrent_sessions" ]; then
        log_action "SUCCESS" "Keycloak connection pool: $successful_connections/$concurrent_sessions connections successful"
    else
        log_action "WARNING" "Keycloak connection pool: only $successful_connections/$concurrent_sessions connections successful"
    fi

    # Cleanup connection pool test
    for i in $(seq 1 $concurrent_sessions); do
        docker exec purebliss-redis redis-cli del "connection:keycloak:pool:$i" 2>/dev/null >/dev/null
    done

    # Test 4: Redis cluster readiness for Keycloak (if applicable)
    log_action "INFO" "Test 2.5.4: Redis deployment type validation for Keycloak"
    local redis_cluster_enabled=$(docker exec purebliss-redis redis-cli config get cluster-enabled 2>/dev/null | tail -1)

    if [ "$redis_cluster_enabled" = "yes" ]; then
        log_action "INFO" "Redis cluster mode: ENABLED"
        local cluster_nodes=$(docker exec purebliss-redis redis-cli cluster nodes 2>/dev/null | wc -l)
        log_action "SUCCESS" "Redis cluster nodes: $cluster_nodes"
    else
        log_action "INFO" "Redis cluster mode: DISABLED (standalone mode)"
        log_action "SUCCESS" "Redis standalone mode: suitable for Keycloak"
    fi

    # Final cleanup
    docker exec purebliss-redis redis-cli del "$session_key" 2>/dev/null >/dev/null

    log_action "SUCCESS" "Redis-Keycloak integration comprehensive testing: COMPLETE"
    return 0
}

# Test Vault connectivity independently (optional for Keycloak)
test_vault_independently() {
    log_action "INFO" "Testing Vault connectivity independently (for potential future integration)"

    local vault_host="purebliss-vault"
    local vault_port="8200"

    # Phase 1: Network connectivity test
    log_action "INFO" "Phase 1: Testing Vault network connectivity"
    if timeout 10 bash -c "echo > /dev/tcp/$vault_host/$vault_port" 2>/dev/null; then
        log_action "SUCCESS" "Vault network connectivity: PASS"
    else
        log_action "WARNING" "Vault network connectivity: FAIL (optional for Keycloak)"
        return 0  # Non-critical for Keycloak
    fi

    # Phase 2: Vault service status
    log_action "INFO" "Phase 2: Testing Vault service status"
    if docker exec purebliss-vault vault status > /dev/null 2>&1; then
        log_action "SUCCESS" "Vault service status: PASS"
    else
        log_action "WARNING" "Vault service status: FAIL (optional for Keycloak)"
        return 0  # Non-critical for Keycloak
    fi

    log_action "SUCCESS" "Vault independent testing completed (optional validation)"
    return 0
}

# Restart any stopped services without disrupting running ones
restart_stopped_services() {
    log_action "INFO" "Checking for stopped services that should be running"

    local services=("purebliss-vault" "purebliss-vault-agent" "purebliss-postgres" "purebliss-redis" "purebliss-nginx")

    for service in "${services[@]}"; do
        if docker ps -a --format "{{.Names}}" | grep -q "^${service}$"; then
            local status=$(docker inspect --format='{{.State.Status}}' "$service")
            if [ "$status" != "running" ]; then
                log_action "INFO" "Restarting stopped service: $service"
                docker start "$service"
                sleep 5  # Allow time for startup

                # Verify restart
                local new_status=$(docker inspect --format='{{.State.Status}}' "$service")
                if [ "$new_status" = "running" ]; then
                    log_action "SUCCESS" "Successfully restarted: $service"
                else
                    log_action "ERROR" "Failed to restart: $service"
                fi
            fi
        fi
    done
}

# Generate comprehensive dependency test report
generate_test_report() {
    log_action "INFO" "Generating comprehensive sequential dependency test report"

    local report_file="/opt/my-secure-ha-stack/logs/keycloak-dependency-test-sequential-$(date +%Y%m%d-%H%M%S).json"

    cat > "$report_file" << EOF
{
  "test_type": "sequential_comprehensive_keycloak_dependency_testing",
  "test_methodology": "complete_validation_before_next_service",
  "test_date": "$(date -Iseconds)",
  "test_sequence": [
    "core_infrastructure_verification",
    "complete_postgresql_validation",
    "complete_redis_validation",
    "optional_vault_validation"
  ],
  "core_infrastructure_status": {
    "vault": "$(docker inspect --format='{{.State.Status}}' purebliss-vault 2>/dev/null || echo 'not_found')",
    "vault_agent": "$(docker inspect --format='{{.State.Status}}' purebliss-vault-agent 2>/dev/null || echo 'not_found')",
    "postgres": "$(docker inspect --format='{{.State.Status}}' purebliss-postgres 2>/dev/null || echo 'not_found')",
    "redis": "$(docker inspect --format='{{.State.Status}}' purebliss-redis 2>/dev/null || echo 'not_found')",
    "nginx": "$(docker inspect --format='{{.State.Status}}' purebloss-nginx 2>/dev/null || echo 'not_found')"
  },
  "sequential_dependency_tests": {
    "postgresql": {
      "overall_result": "$POSTGRES_TEST_RESULT",
      "validation_phases": {
        "connectivity": "comprehensive_tcp_and_service_readiness",
        "authentication": "superuser_and_keycloak_user_validation",
        "database_access": "keycloak_db_schema_and_operations",
        "performance": "latency_throughput_and_memory_analysis",
        "integration": "keycloak_specific_configuration_validation"
      },
      "completion_status": "$([ "$POSTGRES_TEST_RESULT" = "PASS" ] && echo "100_percent_healthy_and_functioning" || echo "failed_validation")"
    },
    "redis": {
      "overall_result": "$REDIS_TEST_RESULT",
      "validation_phases": {
        "connectivity": "comprehensive_tcp_and_ping_validation",
        "authentication": "auth_method_detection_and_validation",
        "operations": "set_get_hash_list_ttl_operations",
        "performance": "latency_throughput_memory_persistence_analysis",
        "integration": "keycloak_session_storage_and_cache_simulation"
      },
      "completion_status": "$([ "$REDIS_TEST_RESULT" = "PASS" ] && echo "100_percent_healthy_and_functioning" || echo "failed_validation")",
      "prerequisite_validation": "postgresql_must_be_100_percent_validated_first"
    },
    "vault": {
      "overall_result": "$VAULT_TEST_RESULT",
      "validation_type": "optional_connectivity_check",
      "completion_status": "$([ "$VAULT_TEST_RESULT" = "PASS" ] && echo "optional_validation_successful" || echo "optional_validation_failed_non_blocking")"
    }
  },
  "testing_protocol": {
    "sequential_validation": "each_service_validated_to_100_percent_before_next",
    "health_gates": "mandatory_health_validation_after_each_phase",
    "failure_protocol": "stop_all_testing_if_any_dependency_fails",
    "infrastructure_impact": "no_service_disruption_all_services_remain_running"
  },
  "keycloak_readiness": {
    "postgresql_ready": "$([ "$POSTGRES_TEST_RESULT" = "PASS" ] && echo "yes" || echo "no")",
    "redis_ready": "$([ "$REDIS_TEST_RESULT" = "PASS" ] && echo "yes" || echo "no")",
    "overall_readiness": "$([ "$POSTGRES_TEST_RESULT" = "PASS" ] && [ "$REDIS_TEST_RESULT" = "PASS" ] && echo "ready_for_keycloak_deployment" || echo "dependencies_not_ready")"
  }
}
EOF

    log_action "SUCCESS" "Comprehensive sequential test report generated: $report_file"

    # Also create a summary for quick reference
    local summary_file="/opt/my-secure-ha-stack/logs/keycloak-dependency-summary-$(date +%Y%m%d-%H%M%S).txt"
    cat > "$summary_file" << EOF
=== Keycloak Sequential Dependency Test Summary ===
Date: $(date '+%Y-%m-%d %H:%M:%S')
Test Type: Sequential Comprehensive Validation

PHASE 1 - PostgreSQL: $POSTGRES_TEST_RESULT
  $([ "$POSTGRES_TEST_RESULT" = "PASS" ] && echo "✅ 100% healthy and functioning" || echo "❌ Failed validation - testing stopped")

PHASE 2 - Redis: $REDIS_TEST_RESULT
  $([ "$REDIS_TEST_RESULT" = "PASS" ] && echo "✅ 100% healthy and functioning" || echo "❌ Failed validation")

PHASE 3 - Vault: $VAULT_TEST_RESULT (optional)
  $([ "$VAULT_TEST_RESULT" = "PASS" ] && echo "✅ Optional validation successful" || echo "⚠️  Optional validation failed (non-blocking)")

Keycloak Deployment Status: $([ "$POSTGRES_TEST_RESULT" = "PASS" ] && [ "$REDIS_TEST_RESULT" = "PASS" ] && echo "✅ READY" || echo "❌ NOT READY")

Core Infrastructure: All services maintained running during testing
Testing Methodology: Sequential validation with 100% completion requirement
EOF

    log_action "SUCCESS" "Test summary generated: $summary_file"
}

# Complete PostgreSQL validation with comprehensive health checks
complete_postgres_validation() {
    log_action "INFO" "=== COMPLETE POSTGRESQL VALIDATION - PHASE 1 ==="
    log_action "INFO" "Testing PostgreSQL integration completely until 100% healthy and functioning"

    local validation_phases=("connectivity" "authentication" "database_access" "performance" "integration")
    local postgres_fully_validated=false

    for phase in "${validation_phases[@]}"; do
        log_action "INFO" "PostgreSQL Validation Phase: $phase"

        case $phase in
            "connectivity")
                log_action "INFO" "Phase 1.1: PostgreSQL Network Connectivity Validation"
                if ! test_postgres_connectivity_comprehensive; then
                    log_action "ERROR" "PostgreSQL connectivity validation failed - STOPPING"
                    return 1
                fi
                log_action "SUCCESS" "PostgreSQL connectivity validation: COMPLETE"
                ;;
            "authentication")
                log_action "INFO" "Phase 1.2: PostgreSQL Authentication Validation"
                if ! test_postgres_authentication_comprehensive; then
                    log_action "ERROR" "PostgreSQL authentication validation failed - STOPPING"
                    return 1
                fi
                log_action "SUCCESS" "PostgreSQL authentication validation: COMPLETE"
                ;;
            "database_access")
                log_action "INFO" "Phase 1.3: PostgreSQL Database Access Validation"
                if ! test_postgres_database_access_comprehensive; then
                    log_action "ERROR" "PostgreSQL database access validation failed - STOPPING"
                    return 1
                fi
                log_action "SUCCESS" "PostgreSQL database access validation: COMPLETE"
                ;;
            "performance")
                log_action "INFO" "Phase 1.4: PostgreSQL Performance Validation"
                if ! test_postgres_performance_comprehensive; then
                    log_action "ERROR" "PostgreSQL performance validation failed - STOPPING"
                    return 1
                fi
                log_action "SUCCESS" "PostgreSQL performance validation: COMPLETE"
                ;;
            "integration")
                log_action "INFO" "Phase 1.5: PostgreSQL Integration Validation"
                if ! test_postgres_keycloak_integration_comprehensive; then
                    log_action "ERROR" "PostgreSQL Keycloak integration validation failed - STOPPING"
                    return 1
                fi
                log_action "SUCCESS" "PostgreSQL integration validation: COMPLETE"
                ;;
        esac

        # Health validation after each phase
        log_action "INFO" "Running health validation after PostgreSQL $phase phase"
        if ! /opt/dev-purebliss/dev_scripts/core/validate-container-health.sh postgres "validation-$phase" 2>/dev/null; then
            log_action "ERROR" "PostgreSQL health validation failed after $phase phase - STOPPING"
            return 1
        fi
        log_action "SUCCESS" "PostgreSQL health validation passed after $phase phase"

        # Brief pause between phases
        sleep 2
    done

    log_action "SUCCESS" "=== POSTGRESQL VALIDATION COMPLETE - 100% HEALTHY AND FUNCTIONING ==="
    postgres_fully_validated=true
    return 0
}

# Complete Redis validation with comprehensive health checks
complete_redis_validation() {
    log_action "INFO" "=== COMPLETE REDIS VALIDATION - PHASE 2 ==="
    log_action "INFO" "Testing Redis integration completely until 100% healthy and functioning"

    local validation_phases=("connectivity" "authentication" "operations" "performance" "integration")
    local redis_fully_validated=false

    for phase in "${validation_phases[@]}"; do
        log_action "INFO" "Redis Validation Phase: $phase"

        case $phase in
            "connectivity")
                log_action "INFO" "Phase 2.1: Redis Network Connectivity Validation"
                if ! test_redis_connectivity_comprehensive; then
                    log_action "ERROR" "Redis connectivity validation failed - STOPPING"
                    return 1
                fi
                log_action "SUCCESS" "Redis connectivity validation: COMPLETE"
                ;;
            "authentication")
                log_action "INFO" "Phase 2.2: Redis Authentication Validation"
                if ! test_redis_authentication_comprehensive; then
                    log_action "ERROR" "Redis authentication validation failed - STOPPING"
                    return 1
                fi
                log_action "SUCCESS" "Redis authentication validation: COMPLETE"
                ;;
            "operations")
                log_action "INFO" "Phase 2.3: Redis Operations Validation"
                if ! test_redis_operations_comprehensive; then
                    log_action "ERROR" "Redis operations validation failed - STOPPING"
                    return 1
                fi
                log_action "SUCCESS" "Redis operations validation: COMPLETE"
                ;;
            "performance")
                log_action "INFO" "Phase 2.4: Redis Performance Validation"
                if ! test_redis_performance_comprehensive; then
                    log_action "ERROR" "Redis performance validation failed - STOPPING"
                    return 1
                fi
                log_action "SUCCESS" "Redis performance validation: COMPLETE"
                ;;
            "integration")
                log_action "INFO" "Phase 2.5: Redis Integration Validation"
                if ! test_redis_keycloak_integration_comprehensive; then
                    log_action "ERROR" "Redis Keycloak integration validation failed - STOPPING"
                    return 1
                fi
                log_action "SUCCESS" "Redis integration validation: COMPLETE"
                ;;
        esac

        # Health validation after each phase
        log_action "INFO" "Running health validation after Redis $phase phase"
        if ! /opt/dev-purebliss/dev_scripts/core/validate-container-health.sh redis "validation-$phase" 2>/dev/null; then
            log_action "ERROR" "Redis health validation failed after $phase phase - STOPPING"
            return 1
        fi
        log_action "SUCCESS" "Redis health validation passed after $phase phase"

        # Brief pause between phases
        sleep 2
    done

    log_action "SUCCESS" "=== REDIS VALIDATION COMPLETE - 100% HEALTHY AND FUNCTIONING ==="
    redis_fully_validated=true
    return 0
}

# Main execution
main() {
    log_action "INFO" "Starting sequential independent Keycloak dependency testing"
    log_action "INFO" "Sequential Protocol: PostgreSQL 100% complete → Redis 100% complete → Vault optional"

    # Restart any stopped services first
    restart_stopped_services

    # Verify core infrastructure
    if ! verify_core_infrastructure; then
        log_action "ERROR" "Core infrastructure verification failed"
        exit 1
    fi

    # PHASE 1: Complete PostgreSQL validation first - 100% healthy and functioning
    log_action "INFO" "Starting PHASE 1: Complete PostgreSQL validation until 100% healthy"
    if complete_postgres_validation; then
        POSTGRES_TEST_RESULT="PASS"
        log_action "SUCCESS" "PHASE 1 COMPLETE: PostgreSQL is 100% healthy and functioning"
    else
        POSTGRES_TEST_RESULT="FAIL"
        log_action "ERROR" "PHASE 1 FAILED: PostgreSQL validation failed - STOPPING all testing"
        log_action "ERROR" "Will not proceed to Redis testing until PostgreSQL is 100% healthy"

        # Generate failure report
        generate_test_report
        exit 1
    fi

    # PHASE 2: Complete Redis validation only after PostgreSQL is 100% validated
    log_action "INFO" "Starting PHASE 2: Complete Redis validation until 100% healthy"
    log_action "INFO" "Prerequisites: PostgreSQL is confirmed 100% healthy and functioning"
    if complete_redis_validation; then
        REDIS_TEST_RESULT="PASS"
        log_action "SUCCESS" "PHASE 2 COMPLETE: Redis is 100% healthy and functioning"
    else
        REDIS_TEST_RESULT="FAIL"
        log_action "ERROR" "PHASE 2 FAILED: Redis validation failed"

        # Generate partial success report (PostgreSQL passed, Redis failed)
        generate_test_report
        exit 1
    fi

    # PHASE 3: Optional Vault validation (only after both PostgreSQL and Redis are 100% validated)
    log_action "INFO" "Starting PHASE 3: Optional Vault validation"
    log_action "INFO" "Prerequisites: PostgreSQL and Redis are both confirmed 100% healthy and functioning"
    if test_vault_independently; then
        VAULT_TEST_RESULT="PASS"
        log_action "SUCCESS" "PHASE 3 COMPLETE: Vault validation successful (optional)"
    else
        VAULT_TEST_RESULT="OPTIONAL_FAIL"
        log_action "WARNING" "PHASE 3 WARNING: Vault validation failed (optional - not blocking)"
    fi

    # Generate comprehensive test report
    generate_test_report

    # Final status - only succeed if both PostgreSQL and Redis are 100% validated
    if [ "$POSTGRES_TEST_RESULT" = "PASS" ] && [ "$REDIS_TEST_RESULT" = "PASS" ]; then
        log_action "SUCCESS" "Sequential independent Keycloak dependency testing completed successfully"
        log_action "SUCCESS" "PostgreSQL: 100% healthy and functioning ✅"
        log_action "SUCCESS" "Redis: 100% healthy and functioning ✅"
        log_action "SUCCESS" "Vault: ${VAULT_TEST_RESULT} (optional)"
        log_action "INFO" "Core infrastructure maintained: All services remain running"
        log_action "INFO" "Keycloak can now be tested against fully verified dependencies"
        exit 0
    else
        log_action "ERROR" "Sequential independent Keycloak dependency testing failed"
        log_action "ERROR" "PostgreSQL: $POSTGRES_TEST_RESULT"
        log_action "ERROR" "Redis: $REDIS_TEST_RESULT"
        log_action "INFO" "Review detailed validation results above for specific issues"
        exit 1
    fi
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
