#!/bin/bash
# Script Communication Bridge v1.0
# Facilitates inter-script communication and coordination

# Global communication variables
BRIDGE_ACTIVE=true
BRIDGE_LOG="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
BRIDGE_TEMP_DIR="/tmp/purebliss-bridge"

# Initialize bridge
init_bridge() {
    mkdir -p "$BRIDGE_TEMP_DIR"
    log_info "Script communication bridge initialized"
}

# Send message to other scripts
send_message() {
    local target_script="$1"
    local message="$2"
    local priority="${3:-info}"

    local message_file="$BRIDGE_TEMP_DIR/${target_script}.msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$priority] $message" >> "$message_file"
    log_info "Message sent to $target_script: $message"
}

# Check for messages from other scripts
check_messages() {
    local script_name="$(basename "$0" .sh)"
    local message_file="$BRIDGE_TEMP_DIR/${script_name}.msg"

    if [[ -f "$message_file" ]]; then
        log_info "Messages for $script_name:"
        cat "$message_file"
        rm -f "$message_file"
    fi
}

# Signal script completion
signal_completion() {
    local script_name="$(basename "$0" .sh)"
    local status="$1"
    local message="${2:-Completed}"

    local completion_file="$BRIDGE_TEMP_DIR/${script_name}.complete"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$status] $message" > "$completion_file"

    echo "$(date '+%Y-%m-%d %H:%M:%S') - SCRIPT_COMPLETION: $script_name - $status - $message" >> "$BRIDGE_LOG"
}

# Wait for script completion
wait_for_completion() {
    local target_script="$1"
    local timeout="${2:-300}"  # 5 minute default timeout
    local completion_file="$BRIDGE_TEMP_DIR/${target_script}.complete"

    log_info "Waiting for $target_script completion (timeout: ${timeout}s)"

    local count=0
    while [[ ! -f "$completion_file" && $count -lt $timeout ]]; do
        sleep 1
        ((count++))
    done

    if [[ -f "$completion_file" ]]; then
        local result="$(cat "$completion_file")"
        log_success "Script completed: $target_script - $result"
        return 0
    else
        log_error "Timeout waiting for $target_script completion"
        return 1
    fi
}

# Coordinate parallel execution
coordinate_parallel() {
    local -a scripts=("$@")
    local coordination_id="parallel-$(date +%s)"

    log_info "Coordinating parallel execution: ${scripts[*]}"

    # Signal start of parallel coordination
    echo "$(date '+%Y-%m-%d %H:%M:%S') - PARALLEL_START: [$coordination_id] ${scripts[*]}" >> "$BRIDGE_LOG"

    # Wait for all scripts to complete
    local all_success=true
    for script in "${scripts[@]}"; do
        if ! wait_for_completion "$script"; then
            all_success=false
        fi
    done

    if $all_success; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - PARALLEL_SUCCESS: [$coordination_id] All scripts completed successfully" >> "$BRIDGE_LOG"
        return 0
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - PARALLEL_FAILURE: [$coordination_id] Some scripts failed" >> "$BRIDGE_LOG"
        return 1
    fi
}

# Cleanup bridge resources
cleanup_bridge() {
    if [[ -d "$BRIDGE_TEMP_DIR" ]]; then
        rm -rf "$BRIDGE_TEMP_DIR"
        log_info "Script communication bridge cleaned up"
    fi
}

# Initialize bridge when sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    init_bridge
fi
