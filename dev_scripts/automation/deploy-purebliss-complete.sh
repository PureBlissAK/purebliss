#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# DEPLOY_PUREBLISS_COMPLETE_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="deploy-purebliss-complete.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_PURPOSE="Enhanced automation script for development operations with auto-commit"
SCRIPT_AUTHOR="Pure Bliss Elite Framework"
SCRIPT_CREATED="2025-08-09"
SCRIPT_MODIFIED="2025-08-09"
SCRIPT_CATEGORY="automation"
SCRIPT_TAGS="enhancement,automation,auto-commit"
SCRIPT_SERVICES="development"
SCRIPT_DEPENDENCIES="common-functions-library.sh"
SCRIPT_DESCRIPTION="Enhanced automation script for development with auto-commit functionality,
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
deploy_purebliss_complete_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
deploy_purebliss_complete_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
deploy_purebliss_complete_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
deploy_purebliss_complete_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    deploy_purebliss_complete_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        deploy_purebliss_complete_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            deploy_purebliss_complete_log_success "Validation passed - proceeding with auto-commit"
        else
            deploy_purebliss_complete_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        deploy_purebliss_complete_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        deploy_purebliss_complete_log_info "Auto-commit system not available - manual commit required"
        deploy_purebliss_complete_log_info "Recommended commit message: $commit_message"
        deploy_purebliss_complete_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
deploy_purebliss_complete_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    deploy_purebliss_complete_log_success "$final_message"
    
    # Execute auto-commit wrapper
    deploy_purebliss_complete_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    deploy_purebliss_complete_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════

# PURE BLISS ELITE MASTER DEPLOYMENT SCRIPT
# Single-command deployment for complete Pure Bliss stack
# Usage: ./deploy-purebliss-complete.sh [--environment=dev|staging|production]


# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

# SCRIPT METADATA
SCRIPT_NAME="deploy-purebliss-complete.sh"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Master single-command deployment for complete Pure Bliss stack"

# CONFIGURATION
ENVIRONMENT="${1:-dev}"
DEPLOYMENT_LOG="/opt/my-secure-ha-stack/logs/master-deployment.log"
DEPLOYMENT_START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# DEPLOYMENT SEQUENCE (DEPENDENCY ORDER)
DEPLOYMENT_SEQUENCE=(
    "vault"
    "vault-agent"
    "postgres"
    "redis"
    "letsencrypt"
    "nginx"
    "keycloak"
    "prometheus"
    "grafana"
    "loki"
    "plane"
    "codeserver"
)

# MASTER DEPLOYMENT ORCHESTRATION
main() {
    log_action "🚀 STARTING COMPLETE PURE BLISS DEPLOYMENT"
    log_action "Environment: $ENVIRONMENT"
    log_action "Start Time: $DEPLOYMENT_START_TIME"

    # 1. Pre-deployment validation
    pre_deployment_validation

    # 2. Infrastructure preparation
    prepare_infrastructure

    # 3. Service deployment orchestration
    deploy_all_services

    # 4. Post-deployment validation
    post_deployment_validation

    # 5. Documentation generation
    generate_deployment_documentation

    # 6. Success notification and auto-commit
    deployment_success_workflow

    log_action "✅ PURE BLISS DEPLOYMENT COMPLETE - ALL SERVICES HEALTHY"
    display_deployment_summary
}

# PRE-DEPLOYMENT VALIDATION
pre_deployment_validation() {
    log_action "🔍 Starting pre-deployment validation..."

    # Check system requirements
    "$SCRIPT_DIR/deployment/system-requirements-check.sh"

    # Validate Docker environment
    "$SCRIPT_DIR/deployment/docker-environment-validation.sh"

    # Check RAID storage availability
    "$SCRIPT_DIR/deployment/raid-storage-validation.sh"

    # Validate git repository state
    "$SCRIPT_DIR/deployment/git-repository-validation.sh"

    log_action "✅ Pre-deployment validation complete"
}

# INFRASTRUCTURE PREPARATION
prepare_infrastructure() {
    log_action "🏗️ Preparing infrastructure..."

    # Setup networking
    "$SCRIPT_DIR/deployment/network-setup.sh" "$ENVIRONMENT"

    # Initialize storage
    "$SCRIPT_DIR/deployment/storage-initialization.sh"

    # Setup monitoring infrastructure
    "$SCRIPT_DIR/deployment/monitoring-infrastructure.sh"

    log_action "✅ Infrastructure preparation complete"
}

# SERVICE DEPLOYMENT ORCHESTRATION
deploy_all_services() {
    log_action "🎼 Starting service deployment orchestration..."

    for service in "${DEPLOYMENT_SEQUENCE[@]}"; do
        deploy_service_with_integration "$service"
    done

    log_action "✅ All services deployed successfully"
}

# INDIVIDUAL SERVICE DEPLOYMENT WITH FULL INTEGRATION
deploy_service_with_integration() {
    local service="$1"

    log_action "🚀 Deploying $service with full integration..."

    # Check if service deployment script exists
    local service_script="$SCRIPT_DIR/services/$service/${service}-automation-suite.sh"
    if [[ ! -f "$service_script" ]]; then
        log_action "⚠️ Service script not found: $service_script"
        log_action "📝 Using fallback deployment method for $service"
        service_script="$SCRIPT_DIR/deployment/fallback-service-deployment.sh"
    fi

    # Deploy service with master deployment mode
    if "$service_script" deploy --master-deployment --environment="$ENVIRONMENT"; then
        log_action "✅ $service deployment successful"

        # Validate service health
        if "$SCRIPT_DIR/core/validate-container-health.sh" "$service" "master-deployment"; then
            log_action "✅ $service health validation passed"

            # Notify dependent services
            "$SCRIPT_DIR/utilities/script-communication-bridge.sh" \
                notify_service_ready "$service"

            # Update service documentation
            "$SCRIPT_DIR/automation/documentation-automation.sh" \
                update "$service" "master-deployment-complete"
        else
            log_action "❌ $service health validation failed"
            handle_deployment_failure "$service" "health_validation_failed"
        fi
    else
        log_action "❌ $service deployment failed"
        handle_deployment_failure "$service" "deployment_failed"
    fi
}

# DEPLOYMENT FAILURE HANDLING
handle_deployment_failure() {
    local service="$1"
    local failure_type="$2"

    log_action "🚨 Handling deployment failure for $service: $failure_type"

    # Attempt automatic remediation
    "$SCRIPT_DIR/automation/self-healing-engine.sh" "$service" "$failure_type"

    # If remediation fails, provide manual intervention guidance
    if ! "$SCRIPT_DIR/core/validate-container-health.sh" "$service" "remediation-check"; then
        log_action "🛠️ Automatic remediation failed for $service"
        log_action "📋 Manual intervention required - see break-fix guide:"
        log_action "📖 $DOC_DIR/services/$service/BREAK_FIX_REPORT.md"

        # Optionally pause deployment for manual intervention
        if [[ "$ENVIRONMENT" != "production" ]]; then
            read -p "Press Enter to continue deployment or Ctrl+C to abort..."
        else
            log_action "🚨 Production deployment failure - aborting for safety"
            exit 1
        fi
    fi
}

# POST-DEPLOYMENT VALIDATION
post_deployment_validation() {
    log_action "🔍 Starting post-deployment validation..."

    # Comprehensive health check of all services
    "$SCRIPT_DIR/core/comprehensive-health-check.sh" all

    # End-to-end integration testing
    "$SCRIPT_DIR/health-checks/integration-testing-suite.sh"

    # Performance baseline validation
    "$SCRIPT_DIR/health-checks/performance-validation.sh"

    # Security validation
    "$SCRIPT_DIR/health-checks/security-validation.sh"

    log_action "✅ Post-deployment validation complete"
}

# DEPLOYMENT DOCUMENTATION GENERATION
generate_deployment_documentation() {
    log_action "📚 Generating deployment documentation..."

    # Generate deployment report
    "$SCRIPT_DIR/automation/deployment-report-generator.sh" \
        "$ENVIRONMENT" "$DEPLOYMENT_START_TIME"

    # Update architecture documentation
    "$SCRIPT_DIR/automation/architecture-documentation-generator.sh"

    # Generate service dependency map
    "$SCRIPT_DIR/automation/dependency-map-generator.sh"

    log_action "✅ Deployment documentation generated"
}

# SUCCESS WORKFLOW AND AUTO-COMMIT
deployment_success_workflow() {
    log_action "🎉 Executing deployment success workflow..."

    # Generate success metrics
    local deployment_duration=$(( $(date +%s) - $(date -d "$DEPLOYMENT_START_TIME" +%s) ))
    log_action "⏱️ Total deployment time: ${deployment_duration}s"

    # Auto-commit deployment success
    "$SCRIPT_DIR/automation/auto-commit-trigger.sh" \
        "deployment" \
        "Complete Pure Bliss stack deployment successful ($ENVIRONMENT)" \
        "infrastructure"

    # Send notifications if configured
    "$SCRIPT_DIR/automation/notification-sender.sh" \
        "deployment_success" "$ENVIRONMENT" "$deployment_duration"

    log_action "✅ Success workflow complete"
}

# DEPLOYMENT SUMMARY DISPLAY
display_deployment_summary() {
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    local deployment_duration=$(( $(date +%s) - $(date -d "$DEPLOYMENT_START_TIME" +%s) ))

    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 PURE BLISS ELITE DEPLOYMENT COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 DEPLOYMENT SUMMARY:
   Environment: $ENVIRONMENT
   Start Time:  $DEPLOYMENT_START_TIME
   End Time:    $end_time
   Duration:    ${deployment_duration}s ($(date -d@$deployment_duration -u +%H:%M:%S))

🎯 SERVICES DEPLOYED:
EOF

    for service in "${DEPLOYMENT_SEQUENCE[@]}"; do
        if "$SCRIPT_DIR/core/validate-container-health.sh" "$service" "final-status-check" >/dev/null 2>&1; then
            printf "   ✅ %-15s - Healthy and operational\n" "$service"
        else
            printf "   ❌ %-15s - Health check failed\n" "$service"
        fi
    done

    cat <<EOF

🔗 ACCESS POINTS:
   🌐 Main Gateway:      https://dev.purebliss.app
   🔐 Keycloak Admin:    https://dev.purebliss.app/keycloak
   📋 Plane Dashboard:   https://dev.purebliss.app/plane
   💻 Code Server:       https://dev.purebliss.app/code-server
   📊 Grafana:           https://dev.purebliss.app/grafana
   🔍 Prometheus:        https://dev.purebliss.app/prometheus
   🔐 Vault:             https://vault.purebliss.app:8200

📚 DOCUMENTATION:
   📖 Complete Guides:   /opt/dev-purebliss/Documentation/
   🔧 Troubleshooting:   /opt/dev-purebliss/Documentation/procedures/TROUBLESHOOTING_PROCEDURES.md
   📋 Break-Fix Reports: /opt/dev-purebliss/Documentation/services/*/BREAK_FIX_REPORT.md

💾 LOGS AND MONITORING:
   📝 Deployment Log:    $DEPLOYMENT_LOG
   🏥 Health Validation: /opt/my-secure-ha-stack/logs/container-health-validation.log
   📊 System Metrics:    Available in Grafana dashboard

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 PURE BLISS STACK IS READY FOR USE!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
}

# LOGGING HELPER
log_action() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp - MASTER_DEPLOYMENT: $message" | tee -a "$DEPLOYMENT_LOG"
}

# ERROR HANDLING
handle_error() {
    local error_message="$1"
    log_action "ERROR: $error_message"

    # Attempt cleanup on error
    "$SCRIPT_DIR/utilities/emergency-cleanup.sh"

    # Generate error report
    "$SCRIPT_DIR/automation/error-report-generator.sh" \
        "$error_message" "$DEPLOYMENT_START_TIME"

    exit 1
}

# Setup error handling
trap 'handle_error "Unexpected error during deployment"' ERR

# EXECUTION
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@" 2>&1 | tee -a "$DEPLOYMENT_LOG"
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
