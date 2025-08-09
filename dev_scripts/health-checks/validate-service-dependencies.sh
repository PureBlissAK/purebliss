#!/bin/bash

# Enhanced Service Dependency Validation
# Addresses dependency connection failures found in logs

set -euo pipefail

# Service dependency validation functions
validate_postgres_connection() {
    local host=${1:-purebliss-postgres}
    local port=${2:-5432}
    local user=${3:-$POSTGRES_USER}
    local db=${4:-$POSTGRES_DB}

    echo "Validating PostgreSQL connection to $host:$port..."

    # Network connectivity check
    if ! nc -z "$host" "$port"; then
        echo "ERROR: Cannot connect to PostgreSQL at $host:$port"
        return 1
    fi

    # PostgreSQL specific readiness check
    if ! docker exec purebliss-postgres pg_isready -U "$user" -d "$db" > /dev/null 2>&1; then
        echo "ERROR: PostgreSQL not ready for connections"
        return 1
    fi

    # Connection test
    if ! docker exec purebliss-postgres psql -U "$user" -d "$db" -c "SELECT 1;" > /dev/null 2>&1; then
        echo "ERROR: PostgreSQL connection test failed"
        return 1
    fi

    echo "PostgreSQL connection validated successfully"
    return 0
}

validate_redis_connection() {
    local host=${1:-purebliss-redis}
    local port=${2:-6379}

    echo "Validating Redis connection to $host:$port..."

    # Network connectivity check
    if ! nc -z "$host" "$port"; then
        echo "ERROR: Cannot connect to Redis at $host:$port"
        return 1
    fi

    # Redis ping test
    if ! docker exec purebliss-redis redis-cli ping > /dev/null 2>&1; then
        echo "ERROR: Redis ping failed"
        return 1
    fi

    echo "Redis connection validated successfully"
    return 0
}

validate_vault_connection() {
    local host=${1:-purebliss-vault}
    local port=${2:-8200}

    echo "Validating Vault connection to $host:$port..."

    # Network connectivity check
    if ! nc -z "$host" "$port"; then
        echo "ERROR: Cannot connect to Vault at $host:$port"
        return 1
    fi

    # Vault status check
    local vault_status=$(docker exec purebliss-vault vault status -format=json 2>/dev/null | jq -r '.initialized // false' 2>/dev/null || echo "false")

    if [ "$vault_status" != "true" ]; then
        echo "ERROR: Vault not initialized"
        return 1
    fi

    echo "Vault connection validated successfully"
    return 0
}

# Main validation function
validate_service_dependencies() {
    local service=$1

    echo "Validating dependencies for $service..."

    case $service in
        "keycloak")
            validate_postgres_connection && validate_redis_connection
            ;;
        "plane")
            validate_postgres_connection && validate_redis_connection
            ;;
        "nginx")
            validate_vault_connection
            ;;
        "vault-agent")
            validate_vault_connection
            ;;
        *)
            echo "No specific dependency validation for $service"
            return 0
            ;;
    esac
}

# Main execution
main() {
    local service=${1:-"all"}

    if [ "$service" = "all" ]; then
        echo "Validating all service dependencies..."
        for svc in keycloak plane nginx vault-agent; do
            echo "=== Validating $svc dependencies ==="
            validate_service_dependencies "$svc"
            echo
        done
    else
        validate_service_dependencies "$service"
    fi
}

main "$@"
