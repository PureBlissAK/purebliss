#!/bin/bash

# Enhanced Retry and Timeout Utilities
# Addresses timeout issues found in logs (30 attempts for PostgreSQL health checks)

# Function to retry a command with exponential backoff
retry_with_backoff() {
    local max_attempts=${1:-5}
    local delay=${2:-1}
    local max_delay=${3:-60}
    local command="${@:4}"
    
    local attempt=1
    local current_delay=$delay
    
    echo "Executing with retry: $command"
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt/$max_attempts..."
        
        if eval "$command"; then
            echo "Command succeeded on attempt $attempt"
            return 0
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            echo "Command failed after $max_attempts attempts"
            return 1
        fi
        
        echo "Command failed, waiting ${current_delay}s before retry..."
        sleep $current_delay
        
        # Exponential backoff with jitter
        current_delay=$(( current_delay * 2 ))
        if [ $current_delay -gt $max_delay ]; then
            current_delay=$max_delay
        fi
        
        # Add jitter (±25%)
        local jitter=$(( current_delay / 4 ))
        local random_jitter=$(( (RANDOM % (jitter * 2)) - jitter ))
        current_delay=$(( current_delay + random_jitter ))
        
        ((attempt++))
    done
}

# Function to wait for port with timeout
wait_for_port() {
    local host=$1
    local port=$2
    local timeout=${3:-60}
    local check_interval=${4:-2}
    
    echo "Waiting for $host:$port to be available (timeout: ${timeout}s)..."
    
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        if nc -z "$host" "$port" 2>/dev/null; then
            echo "$host:$port is available"
            return 0
        fi
        
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
        echo "Waiting for $host:$port... (${elapsed}s/${timeout}s)"
    done
    
    echo "Timeout waiting for $host:$port after ${timeout}s"
    return 1
}

# Function to wait for HTTP endpoint
wait_for_http_endpoint() {
    local url=$1
    local timeout=${2:-60}
    local check_interval=${3:-5}
    local expected_status=${4:-200}
    
    echo "Waiting for HTTP endpoint $url (timeout: ${timeout}s, expected: $expected_status)..."
    
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        local status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 --max-time 5 "$url" 2>/dev/null || echo "000")
        
        if [ "$status" = "$expected_status" ]; then
            echo "HTTP endpoint $url is available (status: $status)"
            return 0
        fi
        
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
        echo "Waiting for $url... (${elapsed}s/${timeout}s, status: $status)"
    done
    
    echo "Timeout waiting for HTTP endpoint $url after ${timeout}s"
    return 1
}

# Function to wait for container health
wait_for_container_health() {
    local container_name=$1
    local timeout=${2:-120}
    local check_interval=${3:-5}
    
    echo "Waiting for container $container_name to be healthy (timeout: ${timeout}s)..."
    
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no-container")
        
        case $health_status in
            "healthy")
                echo "Container $container_name is healthy"
                return 0
                ;;
            "no-container")
                echo "Container $container_name not found"
                return 1
                ;;
            "no-healthcheck")
                # For containers without health checks, check if running
                local running=$(docker inspect --format='{{.State.Running}}' "$container_name" 2>/dev/null || echo "false")
                if [ "$running" = "true" ]; then
                    echo "Container $container_name is running (no health check)"
                    return 0
                fi
                ;;
        esac
        
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
        echo "Waiting for $container_name health... (${elapsed}s/${timeout}s, status: $health_status)"
    done
    
    echo "Timeout waiting for container $container_name health after ${timeout}s"
    return 1
}

# Export functions for use in other scripts
export -f retry_with_backoff
export -f wait_for_port
export -f wait_for_http_endpoint
export -f wait_for_container_health
