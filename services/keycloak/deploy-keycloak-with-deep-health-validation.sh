#!/bin/bash
# Enhanced Keycloak Deployment Script with Deep Health Validation
# DIRECTIVE: ALWAYS FURTHER TROUBLESHOOT HEALTH - Never proceed with ANY unresolved health issues

set -euo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

log_msg() {
    local msg="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $msg"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] KEYCLOAK_DEPLOY: $msg" >> "$LOG_FILE"
}

# CRITICAL: Health validation function that STOPS on ANY issue
validate_health_or_stop() {
    local task_name="$1"
    local description="$2"

    log_msg "MANDATORY HEALTH VALIDATION: $description"

    if /opt/dev-purebliss/validate-container-health.sh keycloak "$task_name"; then
        log_msg "✅ HEALTH VALIDATION PASSED: $description"
        log_msg "PROCEEDING: Health is confirmed, continuing to next step"
    else
        log_msg "❌ HEALTH VALIDATION FAILED: $description"
        log_msg "CRITICAL: STOPPING ALL WORK - Health issues detected"
        log_msg "DIRECTIVE: ALL health issues must be resolved before proceeding"
        log_msg "REQUIRED ACTION: Review health validation output above and fix all issues"

        echo ""
        echo "═══════════════════════════════════════════════════════════════════════════════════════"
        echo "❌ DEPLOYMENT STOPPED - HEALTH VALIDATION FAILED"
        echo "═══════════════════════════════════════════════════════════════════════════════════════"
        echo "Task: $task_name"
        echo "Description: $description"
        echo "Directive: ALWAYS FURTHER TROUBLESHOOT HEALTH"
        echo ""
        echo "REQUIRED ACTIONS:"
        echo "1. Review the comprehensive health analysis above"
        echo "2. Fix ALL identified health issues"
        echo "3. Ensure container is 100% healthy"
        echo "4. Re-run this deployment script"
        echo ""
        echo "NO SHORTCUTS: Health issues cannot be bypassed or ignored"
        echo "═══════════════════════════════════════════════════════════════════════════════════════"
        echo ""

        exit 1
    fi
}

# Enhanced phase execution with mandatory health validation
execute_phase_with_health_validation() {
    local phase_name="$1"
    local phase_description="$2"
    local phase_command="$3"

    log_msg "STARTING PHASE: $phase_name - $phase_description"

    # Execute the phase command
    if eval "$phase_command"; then
        log_msg "✅ PHASE COMPLETED: $phase_name"

        # MANDATORY: Validate health after EVERY phase
        validate_health_or_stop "$phase_name" "$phase_description"

        log_msg "✅ PHASE VALIDATED: $phase_name - Health confirmed, proceeding"
    else
        log_msg "❌ PHASE FAILED: $phase_name - $phase_description"
        log_msg "CRITICAL: Phase execution failed before health validation"

        echo ""
        echo "═══════════════════════════════════════════════════════════════════════════════════════"
        echo "❌ PHASE EXECUTION FAILED: $phase_name"
        echo "═══════════════════════════════════════════════════════════════════════════════════════"
        echo "Command: $phase_command"
        echo "Description: $phase_description"
        echo ""
        echo "REQUIRED ACTIONS:"
        echo "1. Review the command output above"
        echo "2. Fix the phase execution issue"
        echo "3. Ensure the command runs successfully"
        echo "4. Re-run this deployment script"
        echo "═══════════════════════════════════════════════════════════════════════════════════════"
        echo ""

        exit 1
    fi
}

main() {
    log_msg "STARTING: Enhanced Keycloak Deployment with Deep Health Validation"
    log_msg "DIRECTIVE: ALWAYS FURTHER TROUBLESHOOT HEALTH - NO health issues will be bypassed"

    # Pre-deployment validation
    log_msg "PRE-DEPLOYMENT: Checking existing Keycloak state"
    if docker ps --format "{{.Names}}" | grep -q "purebliss-keycloak"; then
        log_msg "INFO: Existing Keycloak container found, performing pre-enhancement health check"
        validate_health_or_stop "pre-deployment-existing" "Pre-deployment health check of existing Keycloak"
    else
        log_msg "INFO: No existing Keycloak container found, proceeding with fresh deployment"
    fi

    # Phase 1: Container Build/Enhancement
    execute_phase_with_health_validation \
        "container-build" \
        "Build enhanced Keycloak container with Elite Container Scaffolding" \
        "/opt/dev-purebliss/container-scaffold.sh build keycloak 6"

    # Phase 2: Container Validation
    execute_phase_with_health_validation \
        "container-validation" \
        "Validate enhanced Keycloak container functionality" \
        "/opt/dev-purebliss/container-scaffold.sh validate keycloak 6"

    # Phase 3: Service Integration
    execute_phase_with_health_validation \
        "service-integration" \
        "Integrate Keycloak with Pure Bliss infrastructure" \
        "/opt/dev-purebliss/container-scaffold.sh integrate keycloak"

    # Phase 4: Dependency Integration Test
    execute_phase_with_health_validation \
        "dependency-integration" \
        "Test Keycloak integration with PostgreSQL and Redis dependencies" \
        "docker exec purebliss-keycloak bash -c 'timeout 10 bash -c \"until echo > /dev/tcp/purebliss-postgres/5432; do sleep 1; done\" && timeout 10 bash -c \"until echo > /dev/tcp/purebliss-redis/6379; do sleep 1; done\"'"

    # Phase 5: Vault Integration Test (if available)
    if docker ps --format "{{.Names}}" | grep -q "purebliss-vault"; then
        execute_phase_with_health_validation \
            "vault-integration" \
            "Test Keycloak integration with Vault secrets management" \
            "docker exec purebliss-keycloak bash -c 'timeout 10 bash -c \"until echo > /dev/tcp/purebliss-vault/8200; do sleep 1; done\"'"
    else
        log_msg "INFO: Vault not available, skipping Vault integration test"
    fi

    # Phase 6: Final Comprehensive Health Validation
    log_msg "FINAL VALIDATION: Comprehensive Keycloak health assessment"
    validate_health_or_stop "final-comprehensive" "Final comprehensive Keycloak deployment validation"

    # Success notification
    log_msg "🎉 SUCCESS: Enhanced Keycloak deployment completed with full health validation"
    log_msg "STATUS: Keycloak is healthy, integrated, and ready for production use"
    log_msg "COMPLIANCE: All health validation requirements met - no issues bypassed"

    echo ""
    echo "══════════════════════════════════════════════════════════════════════════════════════"
    echo "🎉 KEYCLOAK DEPLOYMENT SUCCESSFUL"
    echo "══════════════════════════════════════════════════════════════════════════════════════"
    echo "✅ Container build and validation: PASSED"
    echo "✅ Service integration: PASSED"
    echo "✅ Dependency integration: PASSED"
    echo "✅ Health validation: PASSED"
    echo "✅ Compliance: ALWAYS FURTHER TROUBLESHOOT HEALTH directive followed"
    echo ""
    echo "Keycloak is now ready for use at: https://dev.purebliss.app/keycloak"
    echo "══════════════════════════════════════════════════════════════════════════════════════"
    echo ""
}

# Execute main function
main "$@"
