#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh" 2>/dev/null || {
    # Fallback logging if library unavailable
    log_info() { echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $*" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }
    log_error() { echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $*" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }
    log_success() { echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: $*" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log; }
}

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Advanced Docker system recovery and cleanup with orphan removal"

log_info "Starting $SCRIPT_NAME v$SCRIPT_VERSION - $SCRIPT_PURPOSE"

# Advanced Docker System Recovery Function
docker_system_recovery() {
    local recovery_phase="$1"

    log_info "Phase $recovery_phase: Docker System Recovery initiated"

    case "$recovery_phase" in
        "1-graceful-stop")
            log_info "Phase 1: Graceful container shutdown"
            if docker ps -q >/dev/null 2>&1; then
                docker stop $(docker ps -q) 2>/dev/null || log_info "No running containers to stop gracefully"
            else
                log_info "Docker ps command failed - daemon may be unresponsive"
            fi
            ;;

        "2-force-kill")
            log_info "Phase 2: Force kill all containers"
            if docker ps -aq >/dev/null 2>&1; then
                docker kill $(docker ps -aq) 2>/dev/null || log_info "No containers to force kill"
            else
                log_info "Docker ps command failed - proceeding with system cleanup"
            fi
            ;;

        "3-remove-containers")
            log_info "Phase 3: Remove all containers (including stopped)"
            if docker ps -aq >/dev/null 2>&1; then
                docker rm -f $(docker ps -aq) 2>/dev/null || log_info "No containers to remove"
            else
                log_info "Docker ps command failed - containers may already be cleaned"
            fi
            ;;

        "4-remove-images")
            log_info "Phase 4: Remove unused images"
            docker image prune -a -f 2>/dev/null || log_info "Image cleanup failed or no images to remove"
            ;;

        "5-remove-volumes")
            log_info "Phase 5: Remove unused volumes"
            docker volume prune -f 2>/dev/null || log_info "Volume cleanup failed or no volumes to remove"
            ;;

        "6-remove-networks")
            log_info "Phase 6: Remove unused networks"
            docker network prune -f 2>/dev/null || log_info "Network cleanup failed or no networks to remove"
            ;;

        "7-system-prune")
            log_info "Phase 7: Complete system prune"
            docker system prune -a -f --volumes 2>/dev/null || log_info "System prune failed - may indicate daemon issues"
            ;;

        "8-restart-daemon")
            log_info "Phase 8: Restart Docker daemon"
            sudo systemctl stop docker 2>/dev/null || log_info "Docker stop failed"
            sleep 5
            sudo systemctl start docker 2>/dev/null || log_error "Docker start failed - may need manual intervention"
            sleep 10
            ;;

        "9-validate-recovery")
            log_info "Phase 9: Validate Docker recovery"
            if docker run --rm busybox echo 'Docker recovery successful!' 2>/dev/null; then
                log_success "Docker system recovery completed successfully"
                return 0
            else
                log_error "Docker recovery validation failed"
                return 1
            fi
            ;;
    esac
}

# Kill Docker Orphan Processes
kill_docker_orphans() {
    log_info "Killing Docker orphan processes"

    # Kill containerd-shim processes
    sudo pkill -f containerd-shim 2>/dev/null || log_info "No containerd-shim processes to kill"

    # Kill docker-proxy processes
    sudo pkill -f docker-proxy 2>/dev/null || log_info "No docker-proxy processes to kill"

    # Kill runC processes
    sudo pkill -f runc 2>/dev/null || log_info "No runc processes to kill"

    # Clean up /var/run/docker
    sudo rm -rf /var/run/docker/netns/* 2>/dev/null || log_info "No docker netns to clean"
    sudo rm -rf /var/run/docker/runtime-runc/* 2>/dev/null || log_info "No runtime-runc to clean"

    log_success "Docker orphan cleanup completed"
}

# Clean Docker Storage Areas
clean_docker_storage() {
    log_info "Cleaning Docker storage areas"

    # Stop docker first
    sudo systemctl stop docker 2>/dev/null || log_info "Docker already stopped or stop failed"

    # Clean overlay2 storage driver data
    sudo rm -rf /var/lib/docker/overlay2/* 2>/dev/null || log_info "No overlay2 data to clean"

    # Clean container runtime data
    sudo rm -rf /var/lib/docker/containers/* 2>/dev/null || log_info "No container data to clean"

    # Clean image data
    sudo rm -rf /var/lib/docker/image/* 2>/dev/null || log_info "No image data to clean"

    # Clean network data
    sudo rm -rf /var/lib/docker/network/* 2>/dev/null || log_info "No network data to clean"

    # Clean volume data (be careful with this)
    if [[ "${CLEAN_VOLUMES:-false}" == "true" ]]; then
        sudo rm -rf /var/lib/docker/volumes/* 2>/dev/null || log_info "No volume data to clean"
        log_info "Volume data cleaned (CLEAN_VOLUMES=true)"
    else
        log_info "Volume data preserved (set CLEAN_VOLUMES=true to clean)"
    fi

    log_success "Docker storage cleanup completed"
}

# Main Recovery Workflow
main() {
    local action="${1:-full-recovery}"

    log_info "Docker System Recovery starting with action: $action"

    case "$action" in
        "full-recovery")
            log_info "Starting full Docker system recovery"

            # Run all recovery phases
            for phase in {1..9}; do
                case $phase in
                    1) docker_system_recovery "1-graceful-stop" ;;
                    2) docker_system_recovery "2-force-kill" ;;
                    3) docker_system_recovery "3-remove-containers" ;;
                    4) docker_system_recovery "4-remove-images" ;;
                    5) docker_system_recovery "5-remove-volumes" ;;
                    6) docker_system_recovery "6-remove-networks" ;;
                    7) docker_system_recovery "7-system-prune" ;;
                    8)
                        kill_docker_orphans
                        clean_docker_storage
                        docker_system_recovery "8-restart-daemon"
                        ;;
                    9)
                        if docker_system_recovery "9-validate-recovery"; then
                            log_success "Full Docker recovery completed successfully"
                            return 0
                        else
                            log_error "Full Docker recovery failed - manual intervention may be required"
                            return 1
                        fi
                        ;;
                esac
                sleep 2
            done
            ;;

        "orphan-cleanup")
            kill_docker_orphans
            ;;

        "storage-cleanup")
            clean_docker_storage
            ;;

        "daemon-restart")
            docker_system_recovery "8-restart-daemon"
            docker_system_recovery "9-validate-recovery"
            ;;

        "validate")
            docker_system_recovery "9-validate-recovery"
            ;;

        *)
            log_error "Unknown action: $action"
            log_info "Available actions: full-recovery, orphan-cleanup, storage-cleanup, daemon-restart, validate"
            return 1
            ;;
    esac
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

log_success "$SCRIPT_NAME completed"
