# Script Integration Guide

## 🤝 Inter-Script Communication and Integration Patterns

This guide provides comprehensive patterns for script-to-script integration, enabling powerful automation workflows where scripts can call upon each other for enhanced functionality.

## 🔗 Core Integration Architecture

### Script Communication Bridge

**All scripts must use the centralized communication bridge:**

```bash
# Source the communication bridge in all scripts
source "/opt/dev-purebliss/dev_scripts/utilities/script-communication-bridge.sh"

# Standard communication pattern
communicate_with_script() {
    local target_script="$1"
    local action="$2"
    local parameters="$3"

    # Log communication attempt
    log_script_communication "$SCRIPT_NAME" "$target_script" "$action" "attempting"

    # Execute target script with parameters
    if "$SCRIPT_DIR/$target_script" "$action" $parameters; then
        log_script_communication "$SCRIPT_NAME" "$target_script" "$action" "success"
        return 0
    else
        log_script_communication "$SCRIPT_NAME" "$target_script" "$action" "failed"
        return 1
    fi
}
```

### Dependency Resolution System

**Scripts can declare and resolve dependencies automatically:**

```bash
# Declare script dependencies
declare_dependencies() {
    cat > "/tmp/$SCRIPT_NAME.deps" <<EOF
{
    "required_scripts": [
        "core/validate-container-health.sh",
        "utilities/retry-utils.sh"
    ],
    "optional_scripts": [
        "automation/auto-commit-trigger.sh"
    ],
    "required_services": [
        "vault",
        "postgres"
    ]
}
EOF
}

# Resolve dependencies before execution
resolve_dependencies() {
    "$SCRIPT_DIR/utilities/script-dependency-resolver.sh" resolve "$SCRIPT_NAME"
}
```

## 🏗️ Service Deployment Integration Patterns

### Master Service Deployment Framework

**All service deployments follow this integration pattern:**

```bash
# Example: nginx service deployment with full integration
deploy_nginx_integrated() {
    local deployment_mode="${1:-standard}"

    echo "🚀 Starting integrated Nginx deployment..."

    # 1. Resolve dependencies
    resolve_dependencies

    # 2. Coordinate with infrastructure scripts
    "$SCRIPT_DIR/core/container-scaffold.sh" analyze nginx
    "$SCRIPT_DIR/core/container-scaffold.sh" build nginx phase-6

    # 3. Coordinate with Vault for secrets
    "$SCRIPT_DIR/services/vault/vault-integration-automation.sh" setup_service nginx

    # 4. Setup SSL certificates via Let's Encrypt integration
    "$SCRIPT_DIR/services/letsencrypt/certificate-automation.sh" nginx

    # 5. Configure upstream services notification
    "$SCRIPT_DIR/utilities/upstream-validation.sh" register nginx

    # 6. Validate health at each step
    "$SCRIPT_DIR/core/validate-container-health.sh" nginx "deployment-phase-1"

    # 7. Notify dependent services
    notify_dependent_services "nginx" "deployed"

    # 8. Update documentation automatically
    "$SCRIPT_DIR/automation/documentation-automation.sh" update nginx "deployment-complete"

    # 9. Auto-commit if configured
    "$SCRIPT_DIR/automation/auto-commit-trigger.sh" \
        "deployment" "Nginx integrated deployment complete" "nginx"

    echo "✅ Nginx integrated deployment complete"
}
```

### Cross-Service Coordination

**Services can coordinate with each other through the integration framework:**

```bash
# Example: Keycloak coordinating with PostgreSQL and Redis
deploy_keycloak_with_coordination() {
    echo "🔐 Starting coordinated Keycloak deployment..."

    # Coordinate with database service
    coordinate_with_service() {
        local target_service="$1"
        local action="$2"

        echo "🤝 Coordinating with $target_service for $action..."

        # Check if target service is available
        if ! "$SCRIPT_DIR/core/validate-container-health.sh" "$target_service" "availability-check"; then
            echo "⚠️ $target_service not available, attempting to deploy..."
            "$SCRIPT_DIR/services/$target_service/${target_service}-automation-suite.sh" deploy
        fi

        # Perform coordinated action
        "$SCRIPT_DIR/services/$target_service/${target_service}-automation-suite.sh" "$action" keycloak
    }

    # Coordinate database setup
    coordinate_with_service "postgres" "create_database"

    # Coordinate cache setup
    coordinate_with_service "redis" "setup_caching"

    # Deploy Keycloak with coordination complete
    "$SCRIPT_DIR/services/keycloak/keycloak-automation-suite.sh" deploy_with_dependencies

    echo "✅ Coordinated Keycloak deployment complete"
}
```

## 🔧 Utility Integration Patterns

### Health Check Integration

**All scripts must integrate with the centralized health validation system:**

```bash
# Health check integration pattern
integrated_health_validation() {
    local service="$1"
    local task="$2"
    local validation_level="${3:-standard}"

    case "$validation_level" in
        "basic")
            "$SCRIPT_DIR/core/validate-container-health.sh" "$service" "$task"
            ;;
        "comprehensive")
            "$SCRIPT_DIR/core/comprehensive-health-check.sh" "$service"
            ;;
        "deep")
            "$SCRIPT_DIR/health-checks/deep-troubleshooting-engine.sh" "$service"
            ;;
    esac

    local health_status=$?

    # Auto-remediation if health check fails
    if [[ $health_status -ne 0 ]]; then
        echo "🏥 Health check failed, attempting auto-remediation..."
        "$SCRIPT_DIR/automation/self-healing-engine.sh" "$service" "$task"
    fi

    return $health_status
}
```

### Vault Integration Helper

**Standardized Vault integration across all services:**

```bash
# Vault integration helper
integrate_with_vault() {
    local service="$1"
    local vault_actions="$2"  # comma-separated list

    IFS=',' read -ra ACTIONS <<< "$vault_actions"

    for action in "${ACTIONS[@]}"; do
        case "$action" in
            "auth")
                "$SCRIPT_DIR/services/vault/vault-integration-automation.sh" setup_auth "$service"
                ;;
            "secrets")
                "$SCRIPT_DIR/services/vault/vault-integration-automation.sh" create_secrets "$service"
                ;;
            "policies")
                "$SCRIPT_DIR/services/vault/vault-integration-automation.sh" create_policies "$service"
                ;;
            "dynamic_db")
                "$SCRIPT_DIR/services/vault/vault-integration-automation.sh" setup_dynamic_db "$service"
                ;;
        esac
    done

    # Validate Vault integration
    "$SCRIPT_DIR/services/vault/vault-integration-automation.sh" validate "$service"
}
```

## 📊 Monitoring Integration Patterns

### Automated Monitoring Setup

**All services automatically integrate with monitoring stack:**

```bash
# Monitoring integration helper
integrate_monitoring() {
    local service="$1"
    local monitoring_components="${2:-prometheus,grafana,loki}"

    IFS=',' read -ra COMPONENTS <<< "$monitoring_components"

    for component in "${COMPONENTS[@]}"; do
        echo "📊 Integrating $service with $component..."

        case "$component" in
            "prometheus")
                "$SCRIPT_DIR/services/monitoring/prometheus-automation.sh" add_target "$service"
                ;;
            "grafana")
                "$SCRIPT_DIR/services/monitoring/grafana-automation.sh" create_dashboard "$service"
                ;;
            "loki")
                "$SCRIPT_DIR/services/monitoring/loki-automation.sh" configure_logging "$service"
                ;;
        esac
    done

    # Validate monitoring integration
    "$SCRIPT_DIR/services/monitoring/monitoring-automation-suite.sh" validate "$service"
}
```

### Alert Integration

**Automated alert rule creation for all services:**

```bash
# Alert integration helper
setup_alerts() {
    local service="$1"
    local alert_types="${2:-health,performance,security}"

    IFS=',' read -ra TYPES <<< "$alert_types"

    for alert_type in "${TYPES[@]}"; do
        echo "🚨 Setting up $alert_type alerts for $service..."

        "$SCRIPT_DIR/services/monitoring/alert-automation.sh" \
            create_rule "$service" "$alert_type"
    done

    # Test alert rules
    "$SCRIPT_DIR/services/monitoring/alert-automation.sh" test_rules "$service"
}
```

## 🗄️ Database Integration Patterns

### Database Service Coordination

**Standardized database integration for all services requiring database access:**

```bash
# Database integration helper
integrate_database() {
    local service="$1"
    local db_requirements="$2"  # JSON string

    echo "🗄️ Setting up database integration for $service..."

    # Parse requirements
    local db_name=$(echo "$db_requirements" | jq -r '.database_name')
    local user_type=$(echo "$db_requirements" | jq -r '.user_type')
    local permissions=$(echo "$db_requirements" | jq -r '.permissions[]' | tr '\n' ',')

    # Coordinate with PostgreSQL service
    "$SCRIPT_DIR/services/postgres/postgres-automation-suite.sh" \
        create_database "$db_name"

    # Setup Vault dynamic secrets
    "$SCRIPT_DIR/services/vault/vault-integration-automation.sh" \
        setup_dynamic_db "$service" "$db_name" "$user_type" "$permissions"

    # Validate database connection
    "$SCRIPT_DIR/services/postgres/postgres-automation-suite.sh" \
        test_connection "$service" "$db_name"

    echo "✅ Database integration complete for $service"
}
```

## 🔄 Cleanup Integration Patterns

### Coordinated Cleanup Operations

**All services participate in coordinated cleanup operations:**

```bash
# Cleanup integration helper
coordinate_cleanup() {
    local service="$1"
    local cleanup_scope="${2:-standard}"

    echo "🧹 Starting coordinated cleanup for $service..."

    # Service-specific cleanup
    "$SCRIPT_DIR/services/$service/${service}-automation-suite.sh" cleanup

    # Vault cleanup (revoke secrets, clean policies)
    "$SCRIPT_DIR/services/vault/vault-integration-automation.sh" cleanup "$service"

    # Database cleanup (remove users, drop databases if needed)
    if [[ "$cleanup_scope" == "full" ]]; then
        "$SCRIPT_DIR/services/postgres/postgres-automation-suite.sh" cleanup "$service"
    fi

    # Container cleanup
    "$SCRIPT_DIR/utilities/automated-cleanup-manager.sh" "$service"

    # Documentation cleanup
    "$SCRIPT_DIR/automation/documentation-automation.sh" cleanup "$service"

    echo "✅ Coordinated cleanup complete for $service"
}
```

## 🚀 Master Deployment Integration

### Single-Command Deployment Coordination

**How individual services integrate with master deployment:**

```bash
# Master deployment integration
integrate_with_master_deployment() {
    local service="$1"

    # Register service with master deployment
    cat >> "$SCRIPT_DIR/automation/deployment-registry.json" <<EOF
{
    "service": "$service",
    "deployment_script": "$SCRIPT_DIR/services/$service/${service}-automation-suite.sh",
    "health_check": "$SCRIPT_DIR/core/validate-container-health.sh",
    "dependencies": [$(get_service_dependencies "$service")],
    "deployment_timeout": 300,
    "health_timeout": 60
}
EOF

    echo "✅ $service registered with master deployment system"
}

# Service dependency declaration
get_service_dependencies() {
    local service="$1"

    case "$service" in
        "keycloak")
            echo '"vault", "postgres", "redis"'
            ;;
        "grafana")
            echo '"vault", "postgres", "prometheus"'
            ;;
        "nginx")
            echo '"vault", "letsencrypt"'
            ;;
        *)
            echo '"vault"'
            ;;
    esac
}
```

## 📚 Documentation Integration

### Auto-Documentation Updates

**All scripts automatically update relevant documentation:**

```bash
# Documentation integration helper
update_integration_docs() {
    local source_script="$1"
    local target_script="$2"
    local integration_type="$3"
    local result="$4"

    # Update integration log
    cat >> "$DOC_DIR/automation/INTEGRATION_LOG.md" <<EOF

## $(date): $source_script → $target_script Integration

**Type**: $integration_type
**Result**: $result
**Scripts Involved**:
- Source: $source_script
- Target: $target_script

**Integration Details**:
- Communication method: Script execution with parameters
- Error handling: Centralized error handling with rollback
- Health validation: ✅ Performed
- Documentation: ✅ Auto-updated

EOF
}
```

## 🔧 Error Handling and Recovery

### Integrated Error Handling

**Standardized error handling across all script integrations:**

```bash
# Integrated error handling
handle_integration_error() {
    local source_script="$1"
    local target_script="$2"
    local error_message="$3"
    local recovery_action="${4:-rollback}"

    # Log error
    log_script_error "$source_script" "$target_script" "$error_message"

    # Attempt recovery
    case "$recovery_action" in
        "rollback")
            "$SCRIPT_DIR/utilities/rollback-manager.sh" "$source_script" "$target_script"
            ;;
        "retry")
            retry_with_backoff "$target_script" "$@"
            ;;
        "skip")
            log_action "Skipping $target_script integration due to error"
            ;;
    esac

    # Update documentation with error and recovery
    update_integration_docs "$source_script" "$target_script" "error_recovery" "$recovery_action"
}
```

---

**Document Version**: 1.0
**Integration Philosophy**: Scripts Working Together for Maximum Automation
**Maintained By**: Pure Bliss Elite Automation Team
**Last Updated**: August 7, 2025
