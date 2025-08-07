#!/bin/bash

# Enhanced Keycloak Health Check Script
# Addresses issues found in logs: health endpoint timeouts, dependency validation failures

set -euo pipefail

KEYCLOAK_HOST="${1:-localhost}"
KEYCLOAK_PORT="${2:-8080}"
MAX_RETRIES="${3:-30}"
RETRY_INTERVAL="${4:-10}"

# Function to check Keycloak readiness
check_keycloak_readiness() {
    local attempt=1
    
    while [ $attempt -le $MAX_RETRIES ]; do
        echo "Attempt $attempt/$MAX_RETRIES: Checking Keycloak health..."
        
        # Check if Keycloak process is running
        if ! pgrep -f "keycloak" > /dev/null; then
            echo "Keycloak process not found, waiting..."
            sleep $RETRY_INTERVAL
            ((attempt++))
            continue
        fi
        
        # Check basic HTTP response
        if curl -f -s --connect-timeout 5 --max-time 10 "http://${KEYCLOAK_HOST}:${KEYCLOAK_PORT}" > /dev/null 2>&1; then
            echo "Keycloak HTTP endpoint responding"
            
            # Check admin console availability
            if curl -f -s --connect-timeout 5 --max-time 10 "http://${KEYCLOAK_HOST}:${KEYCLOAK_PORT}/admin" > /dev/null 2>&1; then
                echo "Keycloak admin console accessible"
                
                # Check health endpoint
                if curl -f -s --connect-timeout 5 --max-time 10 "http://${KEYCLOAK_HOST}:${KEYCLOAK_PORT}/health" > /dev/null 2>&1; then
                    echo "Keycloak health endpoint responding"
                    return 0
                fi
            fi
        fi
        
        echo "Keycloak not ready, waiting ${RETRY_INTERVAL}s..."
        sleep $RETRY_INTERVAL
        ((attempt++))
    done
    
    echo "Keycloak failed to become ready after $MAX_RETRIES attempts"
    return 1
}

# Function to validate dependencies before starting health checks
validate_dependencies() {
    echo "Validating Keycloak dependencies..."
    
    # Check PostgreSQL connectivity
    if ! nc -z purebliss-postgres 5432; then
        echo "ERROR: PostgreSQL not reachable on purebliss-postgres:5432"
        return 1
    fi
    
    # Check PostgreSQL readiness
    if ! docker exec purebliss-postgres pg_isready -U "${POSTGRES_USER:-keycloak}" > /dev/null 2>&1; then
        echo "ERROR: PostgreSQL not ready"
        return 1
    fi
    
    echo "Dependencies validated successfully"
    return 0
}

# Main execution
main() {
    echo "Starting enhanced Keycloak health check..."
    
    # First validate dependencies
    if ! validate_dependencies; then
        echo "Dependency validation failed"
        exit 1
    fi
    
    # Then check Keycloak readiness
    if check_keycloak_readiness; then
        echo "Keycloak is healthy and ready"
        exit 0
    else
        echo "Keycloak health check failed"
        exit 1
    fi
}

main "$@"
