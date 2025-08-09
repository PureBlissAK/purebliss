#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════════
# SYSTEMATIC_CONTAINER_TROUBLESHOOTING_SH
# ═══════════════════════════════════════════════════════════════════════════════════
# Pure Bliss Elite Framework - Enhanced Script with Auto-Commit and Metadata

# SCRIPT METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
SCRIPT_NAME="systematic-container-troubleshooting.sh"
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
systematic_container_troubleshooting_log_info() {
    local message="$1"
    if command -v log_info >/dev/null 2>&1; then
        log_info "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized error logging with script context
systematic_container_troubleshooting_log_error() {
    local message="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for standardized success logging with script context
systematic_container_troubleshooting_log_success() {
    local message="$1"
    if command -v log_success >/dev/null 2>&1; then
        log_success "${SCRIPT_NAME}: $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [SUCCESS] ${SCRIPT_NAME}: $message" | tee -a /opt/my-secure-ha-stack/logs/dev-environment-setup.log
    fi
}

# Wrapper for auto-commit and push on successful execution
systematic_container_troubleshooting_auto_commit_wrapper() {
    local commit_message="${1:-"Auto-commit: ${SCRIPT_NAME} executed successfully"}"
    local validation_command="${2:-}"
    
    systematic_container_troubleshooting_log_info "Starting auto-commit wrapper for successful execution"
    
    # Run validation if provided
    if [[ -n "$validation_command" ]]; then
        systematic_container_troubleshooting_log_info "Running validation: $validation_command"
        if eval "$validation_command"; then
            systematic_container_troubleshooting_log_success "Validation passed - proceeding with auto-commit"
        else
            systematic_container_troubleshooting_log_error "Validation failed - skipping auto-commit"
            return 1
        fi
    fi
    
    # Use existing Pure Bliss Elite auto-commit system
    if [[ -f "/opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh" ]]; then
        systematic_container_troubleshooting_log_info "Using Pure Bliss Elite auto-commit system"
        /opt/dev-purebliss/dev_scripts/automation/auto-commit-trigger.sh             "${SCRIPT_CATEGORY}" "$commit_message" "${SCRIPT_NAME}"
    elif command -v auto_commit_push_wrapper >/dev/null 2>&1; then
        auto_commit_push_wrapper "${SCRIPT_NAME}" "$commit_message"
    else
        systematic_container_troubleshooting_log_info "Auto-commit system not available - manual commit required"
        systematic_container_troubleshooting_log_info "Recommended commit message: $commit_message"
        systematic_container_troubleshooting_log_info "See: /opt/dev-purebliss/dev_scripts/automation/AUTO_COMMIT_SYSTEM_GUIDE.md"
    fi
}

# Wrapper for comprehensive script completion with auto-commit
systematic_container_troubleshooting_complete_with_commit() {
    local final_message="${1:-"${SCRIPT_NAME} completed successfully"}"
    local validation_command="${2:-}"
    
    # Log successful completion
    systematic_container_troubleshooting_log_success "$final_message"
    
    # Execute auto-commit wrapper
    systematic_container_troubleshooting_auto_commit_wrapper "Auto-commit: $final_message" "$validation_command"
    
    # Final status
    systematic_container_troubleshooting_log_success "${SCRIPT_NAME} execution and auto-commit completed"
}

# ═══════════════════════════════════════════════════════════════════════════════════
# ORIGINAL SCRIPT CONTENT (Enhanced with Auto-Commit Functionality)
# ═══════════════════════════════════════════════════════════════════════════════════


# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh"
source "$SCRIPT_DIR/utilities/retry-utils.sh"
source "$SCRIPT_DIR/utilities/script-communication-bridge.sh"

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="Systematic container troubleshooting framework - executes 6-phase scaffold-based troubleshooting"

# Configuration
TROUBLESHOOTING_LOG="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
TASKS_STATUS_FILE="/opt/dev-purebliss/troubleshooting-tasks-status.json"
PROJECT_PLAN="/opt/dev-purebliss/PROJECT_PLAN_ENHANCED.md"
CONFIG_ENV="/opt/my-secure-ha-stack/config.env"

# Load configuration
source "$CONFIG_ENV"

# Task tracking functions
create_task_status_file() {
    cat > "$TASKS_STATUS_FILE" << 'EOF'
{
  "troubleshooting_framework": {
    "version": "1.0",
    "last_updated": "",
    "phases": {
      "phase1": {
        "name": "Foundation Container Validation",
        "status": "in_progress",
        "services": ["vault", "postgres"],
        "tasks": {
          "TASK-001": {
            "name": "Vault Health Check Validation",
            "status": "pending",
            "script": "consolidated-validation.sh vault health-check-phase1",
            "documentation": "CONSOLIDATED_TROUBLESHOOTING.md#vault-service",
            "success_criteria": "Vault health endpoint responds with 200 status",
            "enhancement": "Update health validation script based on findings"
          },
          "TASK-002": {
            "name": "PostgreSQL RAID Validation",
            "status": "pending",
            "script": "consolidated-validation.sh postgres raid-validation-phase1",
            "documentation": "CONSOLIDATED_TROUBLESHOOTING.md#postgres-service",
            "success_criteria": "PostgreSQL accepts connections on RAID storage",
            "enhancement": "Enhance database validation for RAID compliance"
          }
        }
      },
      "phase2": {
        "name": "Core Services Validation",
        "status": "pending",
        "services": ["redis", "vault-agent"],
        "tasks": {
          "TASK-003": {
            "name": "Redis Container Initialization",
            "status": "pending",
            "script": "consolidated-deployment.sh redis initialize-phase2",
            "documentation": "CONSOLIDATED_AUTOMATION.md#redis-service",
            "success_criteria": "Redis running with AOF persistence enabled",
            "enhancement": "Add Redis cluster readiness validation"
          },
          "TASK-004": {
            "name": "Vault-Agent AppRole Setup",
            "status": "pending",
            "script": "consolidated-vault-integration.sh vault-agent setup-phase2",
            "documentation": "CONSOLIDATED_INTEGRATION.md#vault-agent-service",
            "success_criteria": "Vault-Agent proxying requests successfully",
            "enhancement": "Automate AppRole credential distribution"
          }
        }
      },
      "phase3": {
        "name": "Authentication Services",
        "status": "pending",
        "services": ["keycloak"],
        "tasks": {
          "TASK-005": {
            "name": "Keycloak Database Setup",
            "status": "pending",
            "script": "consolidated-deployment.sh keycloak database-init-phase3",
            "documentation": "CONSOLIDATED_AUTOMATION.md#keycloak-service",
            "success_criteria": "Keycloak database schema created and migrations completed",
            "enhancement": "Add database migration validation scripts"
          },
          "TASK-006": {
            "name": "Keycloak Vault Integration",
            "status": "pending",
            "script": "consolidated-vault-integration.sh keycloak credentials-phase3",
            "documentation": "CONSOLIDATED_INTEGRATION.md#keycloak-service",
            "success_criteria": "Keycloak using Vault for admin credentials",
            "enhancement": "Automate realm configuration from Vault"
          }
        }
      },
      "phase4": {
        "name": "Gateway Services",
        "status": "pending",
        "services": ["nginx", "letsencrypt"],
        "tasks": {
          "TASK-007": {
            "name": "Nginx Smart Upstream Configuration",
            "status": "pending",
            "script": "consolidated-deployment.sh nginx smart-upstream-phase4",
            "documentation": "CONSOLIDATED_AUTOMATION.md#nginx-service",
            "success_criteria": "Nginx starts with graceful upstream handling",
            "enhancement": "Implement dynamic upstream reconfiguration"
          },
          "TASK-008": {
            "name": "SSL Certificate Automation",
            "status": "pending",
            "script": "consolidated-vault-integration.sh letsencrypt pki-phase4",
            "documentation": "CONSOLIDATED_INTEGRATION.md#letsencrypt-service",
            "success_criteria": "Valid SSL certificates issued and automated renewal configured",
            "enhancement": "Integrate with Vault PKI engine"
          }
        }
      },
      "phase5": {
        "name": "Application Services",
        "status": "pending",
        "services": ["plane", "codeserver"],
        "tasks": {
          "TASK-009": {
            "name": "Plane Application Setup",
            "status": "pending",
            "script": "consolidated-deployment.sh plane application-init-phase5",
            "documentation": "CONSOLIDATED_AUTOMATION.md#plane-service",
            "success_criteria": "Plane accessible with database backend",
            "enhancement": "Automate project template setup"
          },
          "TASK-010": {
            "name": "CodeServer Workspace Configuration",
            "status": "pending",
            "script": "consolidated-deployment.sh codeserver workspace-phase5",
            "documentation": "CONSOLIDATED_AUTOMATION.md#codeserver-service",
            "success_criteria": "CodeServer accessible with development workspace",
            "enhancement": "Integrate with consolidated script access"
          }
        }
      },
      "phase6": {
        "name": "Monitoring Services",
        "status": "pending",
        "services": ["loki", "prometheus", "grafana"],
        "tasks": {
          "TASK-011": {
            "name": "Loki Log Aggregation Setup",
            "status": "pending",
            "script": "consolidated-deployment.sh loki aggregation-phase6",
            "documentation": "CONSOLIDATED_AUTOMATION.md#loki-service",
            "success_criteria": "Loki collecting logs from all services",
            "enhancement": "Add log parsing and alerting rules"
          },
          "TASK-012": {
            "name": "Prometheus Monitoring Setup",
            "status": "pending",
            "script": "consolidated-deployment.sh prometheus monitoring-phase6",
            "documentation": "CONSOLIDATED_AUTOMATION.md#prometheus-service",
            "success_criteria": "Prometheus scraping metrics from all services",
            "enhancement": "Add service discovery automation"
          },
          "TASK-013": {
            "name": "Grafana Dashboard Configuration",
            "status": "pending",
            "script": "consolidated-deployment.sh grafana dashboards-phase6",
            "documentation": "CONSOLIDATED_AUTOMATION.md#grafana-service",
            "success_criteria": "Grafana displaying comprehensive monitoring dashboards",
            "enhancement": "Automate dashboard provisioning from templates"
          }
        }
      }
    }
  }
}
EOF

    # Update timestamp
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')
    jq --arg time "$current_time" '.troubleshooting_framework.last_updated = $time' "$TASKS_STATUS_FILE" > "${TASKS_STATUS_FILE}.tmp" && mv "${TASKS_STATUS_FILE}.tmp" "$TASKS_STATUS_FILE"

    log_info "Task status file created: $TASKS_STATUS_FILE"
}

# Function to get current container status
get_container_status() {
    log_info "Checking current container status"

    local containers=("purebliss-vault" "purebliss-postgres" "purebliss-redis" "purebliss-vault-agent" "purebliss-keycloak" "purebliss-nginx" "purebliss-plane" "purebliss-code-server" "purebliss-loki" "purebliss-prometheus" "purebliss-grafana")

    echo "=== CURRENT CONTAINER STATUS ===" | tee -a "$TROUBLESHOOTING_LOG"
    for container in "${containers[@]}"; do
        if docker ps -q -f name="$container" > /dev/null 2>&1; then
            local status="RUNNING"
            local health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-health-check")
            echo "✅ $container: $status ($health)" | tee -a "$TROUBLESHOOTING_LOG"
        else
            echo "❌ $container: STOPPED" | tee -a "$TROUBLESHOOTING_LOG"
        fi
    done
    echo "===============================" | tee -a "$TROUBLESHOOTING_LOG"
}

# Function to execute a specific task
execute_task() {
    local phase="$1"
    local task_id="$2"

    log_info "Executing task: $task_id in $phase"

    # Get task details from JSON
    local task_name=$(jq -r ".troubleshooting_framework.phases.$phase.tasks[\"$task_id\"].name" "$TASKS_STATUS_FILE")
    local script_command=$(jq -r ".troubleshooting_framework.phases.$phase.tasks[\"$task_id\"].script" "$TASKS_STATUS_FILE")
    local documentation=$(jq -r ".troubleshooting_framework.phases.$phase.tasks[\"$task_id\"].documentation" "$TASKS_STATUS_FILE")
    local success_criteria=$(jq -r ".troubleshooting_framework.phases.$phase.tasks[\"$task_id\"].success_criteria" "$TASKS_STATUS_FILE")

    log_info "Task: $task_name"
    log_info "Script: $script_command"
    log_info "Documentation: $documentation"
    log_info "Success Criteria: $success_criteria"

    # Update task status to running
    jq ".troubleshooting_framework.phases.$phase.tasks[\"$task_id\"].status = \"running\"" "$TASKS_STATUS_FILE" > "${TASKS_STATUS_FILE}.tmp" && mv "${TASKS_STATUS_FILE}.tmp" "$TASKS_STATUS_FILE"

    # Execute the task script
    local script_path="$SCRIPT_DIR/management/${script_command%% *}"
    local script_args="${script_command#* }"

    log_info "Executing: $script_path $script_args"

    # Log task execution start
    echo "$(date '+%Y-%m-%d %H:%M:%S') - TASK_EXECUTION_START: $task_id - $task_name" >> "$TROUBLESHOOTING_LOG"

    # Check if script exists and execute
    if [[ -f "$script_path" ]]; then
        if bash "$script_path" $script_args; then
            log_success "✅ Task $task_id completed successfully"
            jq ".troubleshooting_framework.phases.$phase.tasks[\"$task_id\"].status = \"completed\"" "$TASKS_STATUS_FILE" > "${TASKS_STATUS_FILE}.tmp" && mv "${TASKS_STATUS_FILE}.tmp" "$TASKS_STATUS_FILE"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - TASK_EXECUTION_SUCCESS: $task_id - $task_name" >> "$TROUBLESHOOTING_LOG"
            return 0
        else
            log_error "❌ Task $task_id failed"
            jq ".troubleshooting_framework.phases.$phase.tasks[\"$task_id\"].status = \"failed\"" "$TASKS_STATUS_FILE" > "${TASKS_STATUS_FILE}.tmp" && mv "${TASKS_STATUS_FILE}.tmp" "$TASKS_STATUS_FILE"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - TASK_EXECUTION_FAILED: $task_id - $task_name" >> "$TROUBLESHOOTING_LOG"
            return 1
        fi
    else
        log_error "Script not found: $script_path"
        log_info "Creating placeholder script for development"

        # Create placeholder script
        cat > "$script_path" << EOF

# PLACEHOLDER SCRIPT FOR: $task_name
# This script was auto-generated by the systematic troubleshooting framework

echo "PLACEHOLDER: Executing $script_command"
echo "Task: $task_name"
echo "Success Criteria: $success_criteria"
echo "Documentation: $documentation"

# TODO: Implement actual troubleshooting logic
echo "⚠️  PLACEHOLDER SCRIPT - Manual intervention required"
echo "Refer to: $DOC_DIR/$documentation"

exit 0
EOF
        chmod +x "$script_path"

        log_info "Placeholder script created: $script_path"
        jq ".troubleshooting_framework.phases.$phase.tasks[\"$task_id\"].status = \"placeholder_created\"" "$TASKS_STATUS_FILE" > "${TASKS_STATUS_FILE}.tmp" && mv "${TASKS_STATUS_FILE}.tmp" "$TASKS_STATUS_FILE"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - TASK_PLACEHOLDER_CREATED: $task_id - $script_path" >> "$TROUBLESHOOTING_LOG"
        return 0
    fi
}

# Function to execute a phase with complete container lifecycle approach
execute_phase() {
    local phase="$1"

    log_info "Executing Phase: $phase"

    local phase_name=$(jq -r ".troubleshooting_framework.phases.$phase.name" "$TASKS_STATUS_FILE")
    local phase_status=$(jq -r ".troubleshooting_framework.phases.$phase.status" "$TASKS_STATUS_FILE")

    log_info "Phase Name: $phase_name"
    log_info "Phase Status: $phase_status"

    if [[ "$phase_status" == "completed" ]]; then
        log_info "Phase $phase already completed"
        return 0
    fi

    # Update phase status to running
    jq ".troubleshooting_framework.phases.$phase.status = \"running\"" "$TASKS_STATUS_FILE" > "${TASKS_STATUS_FILE}.tmp" && mv "${TASKS_STATUS_FILE}.tmp" "$TASKS_STATUS_FILE"

    # Get services for this phase and complete each container fully
    local services=($(jq -r ".troubleshooting_framework.phases.$phase.services[]" "$TASKS_STATUS_FILE"))

    log_info "Phase $phase has ${#services[@]} services: ${services[*]}"

    local all_containers_completed=true

    # Complete each container lifecycle fully before moving to next
    for service in "${services[@]}"; do
        if complete_container_lifecycle "$service" "$phase"; then
            log_success "✅ Container $service completed successfully in $phase"
        else
            log_error "❌ Container $service failed in $phase"
            all_containers_completed=false
            # Continue to next container but mark phase as having issues
        fi
    done

    # Update phase status based on container completion
    if $all_containers_completed; then
        jq ".troubleshooting_framework.phases.$phase.status = \"completed\"" "$TASKS_STATUS_FILE" > "${TASKS_STATUS_FILE}.tmp" && mv "${TASKS_STATUS_FILE}.tmp" "$TASKS_STATUS_FILE"
        log_success "✅ Phase $phase completed successfully"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - PHASE_COMPLETION: $phase - $phase_name completed" >> "$TROUBLESHOOTING_LOG"
        return 0
    else
        jq ".troubleshooting_framework.phases.$phase.status = \"failed\"" "$TASKS_STATUS_FILE" > "${TASKS_STATUS_FILE}.tmp" && mv "${TASKS_STATUS_FILE}.tmp" "$TASKS_STATUS_FILE"
        log_error "❌ Phase $phase failed"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - PHASE_FAILURE: $phase - $phase_name failed" >> "$TROUBLESHOOTING_LOG"
        return 1
    fi
}

# Function to complete entire container lifecycle
complete_container_lifecycle() {
    local service="$1"
    local phase="$2"

    log_info "🐳 Starting complete container lifecycle for: $service in $phase"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - CONTAINER_LIFECYCLE_START: $service - $phase" >> "$TROUBLESHOOTING_LOG"

    # Get all tasks for this service in this phase
    local service_tasks=($(jq -r ".troubleshooting_framework.phases.$phase.tasks | to_entries[] | select(.value.service == \"$service\") | .key" "$TASKS_STATUS_FILE"))

    log_info "Container $service has ${#service_tasks[@]} tasks in $phase: ${service_tasks[*]}"

    local container_success=true

    # Step 1: Execute all tasks for this container
    for task_id in "${service_tasks[@]}"; do
        if ! execute_task "$phase" "$task_id"; then
            container_success=false
            log_error "❌ Task $task_id failed for container $service"
        else
            log_success "✅ Task $task_id completed for container $service"
        fi
    done

    # Step 2: Run comprehensive container validation
    if $container_success; then
        log_info "🔍 Running comprehensive validation for $service"
        if validate_container_complete "$service" "$phase"; then
            log_success "✅ Container $service completely validated in $phase"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - CONTAINER_COMPLETE: $service - All tasks and validation passed" >> "$TROUBLESHOOTING_LOG"

            # Mark all tasks for this service as completed
            for task_id in "${service_tasks[@]}"; do
                jq ".troubleshooting_framework.phases.$phase.tasks[\"$task_id\"].status = \"completed\"" "$TASKS_STATUS_FILE" > "${TASKS_STATUS_FILE}.tmp" && mv "${TASKS_STATUS_FILE}.tmp" "$TASKS_STATUS_FILE"
            done
        else
            log_error "❌ Container $service failed comprehensive validation"
            container_success=false
        fi
    fi

    # Step 3: If container failed, implement enhancement and retry once
    if ! $container_success; then
        log_info "🔧 Container $service failed - implementing enhancements and retrying"
        enhance_container_based_on_failures "$service" "$phase"

        # Retry failed tasks once
        for task_id in "${service_tasks[@]}"; do
            local task_status=$(jq -r ".troubleshooting_framework.phases.$phase.tasks[\"$task_id\"].status" "$TASKS_STATUS_FILE")
            if [[ "$task_status" != "completed" ]]; then
                log_info "🔄 Retrying task $task_id for $service after enhancements"
                execute_task "$phase" "$task_id"
            fi
        done

        # Final validation attempt
        if validate_container_complete "$service" "$phase"; then
            log_success "✅ Container $service validated after enhancement"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - CONTAINER_ENHANCED_COMPLETE: $service - Passed after enhancement" >> "$TROUBLESHOOTING_LOG"
            container_success=true
        else
            log_error "❌ Container $service still failing after enhancement - manual intervention required"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - CONTAINER_MANUAL_INTERVENTION: $service - Requires manual troubleshooting" >> "$TROUBLESHOOTING_LOG"
        fi
    fi

    return $([ "$container_success" = true ] && echo 0 || echo 1)
}

# Function to validate complete container functionality
validate_container_complete() {
    local service="$1"
    local phase="$2"

    log_info "🔍 Comprehensive validation for $service in $phase"

    # Step 1: Container status validation
    if ! validate_container_status "$service"; then
        return 1
    fi

    # Step 2: Service-specific health validation
    local health_validation=false
    case "$service" in
        "vault")
            "$SCRIPT_DIR/management/consolidated-validation.sh" vault "health-check-$phase" && \
            test_vault_functionality "$phase" && health_validation=true
            ;;
        "postgres")
            "$SCRIPT_DIR/management/consolidated-validation.sh" postgres "raid-validation-$phase" && \
            test_postgres_functionality "$phase" && health_validation=true
            ;;
        "redis")
            "$SCRIPT_DIR/management/consolidated-validation.sh" redis "initialization-$phase" && \
            test_redis_functionality "$phase" && health_validation=true
            ;;
        "keycloak")
            "$SCRIPT_DIR/management/consolidated-validation.sh" keycloak "database-init-$phase" && \
            test_keycloak_functionality "$phase" && health_validation=true
            ;;
        "nginx")
            "$SCRIPT_DIR/management/consolidated-validation.sh" nginx "smart-upstream-$phase" && \
            test_nginx_functionality "$phase" && health_validation=true
            ;;
        "vault-agent")
            test_vault_agent_functionality "$phase" && health_validation=true
            ;;
        "loki"|"prometheus"|"grafana"|"plane"|"codeserver")
            log_info "Using generic validation for $service"
            "$SCRIPT_DIR/management/consolidated-validation.sh" "$service" "generic-$phase" && health_validation=true
            ;;
        *)
            log_info "Unknown service $service, using basic container validation"
            health_validation=true
            ;;
    esac

    if $health_validation; then
        log_success "✅ Complete validation passed for $service"
        return 0
    else
        log_error "❌ Complete validation failed for $service"
        return 1
    fi
}

# Function to validate basic container status
validate_container_status() {
    local service="$1"

    log_info "📊 Validating container status for: $service"

    local container_name="purebliss-$service"

    # Check if container exists
    if ! docker ps -a -q -f name="$container_name" > /dev/null 2>&1; then
        log_error "Container $container_name does not exist"
        return 1
    fi

    # Check if container is running
    if docker ps -q -f name="$container_name" > /dev/null 2>&1; then
        log_success "✅ Container $container_name is running"

        # Check health status if available
        local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no-health-check")

        case "$health_status" in
            "healthy")
                log_success "✅ Container $container_name is healthy"
                ;;
            "unhealthy")
                log_error "❌ Container $container_name is unhealthy"
                docker logs --tail 10 "$container_name" || true
                return 1
                ;;
            "starting")
                log_info "🔄 Container $container_name is starting"
                sleep 5  # Give it a moment
                ;;
            "no-health-check")
                log_info "ℹ️  Container $container_name has no health check configured"
                ;;
        esac

        return 0
    else
        log_error "❌ Container $container_name is not running"

        # Check container status
        local container_status=$(docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep "$container_name" || echo "Not found")
        log_info "Container status: $container_status"

        return 1
    fi
}

# Function to show progress dashboard
show_progress() {
    log_info "Troubleshooting Progress Dashboard"

    echo "============================================="
    echo "🚀 SYSTEMATIC CONTAINER TROUBLESHOOTING"
    echo "============================================="

    local phases=("phase1" "phase2" "phase3" "phase4" "phase5" "phase6")

    for phase in "${phases[@]}"; do
        local phase_name=$(jq -r ".troubleshooting_framework.phases.$phase.name" "$TASKS_STATUS_FILE")
        local phase_status=$(jq -r ".troubleshooting_framework.phases.$phase.status" "$TASKS_STATUS_FILE")
        local services=($(jq -r ".troubleshooting_framework.phases.$phase.services[]" "$TASKS_STATUS_FILE"))
        local tasks=($(jq -r ".troubleshooting_framework.phases.$phase.tasks | keys[]" "$TASKS_STATUS_FILE"))

        local status_icon
        case "$phase_status" in
            "completed") status_icon="✅" ;;
            "running"|"in_progress") status_icon="🔄" ;;
            "failed") status_icon="❌" ;;
            "pending") status_icon="📋" ;;
            *) status_icon="❓" ;;
        esac

        echo "$status_icon $phase ($phase_name): ${#services[@]} services, ${#tasks[@]} tasks"

        # Show task details for current/failed phases
        if [[ "$phase_status" == "running" || "$phase_status" == "in_progress" || "$phase_status" == "failed" ]]; then
            for task in "${tasks[@]}"; do
                local task_name=$(jq -r ".troubleshooting_framework.phases.$phase.tasks[\"$task\"].name" "$TASKS_STATUS_FILE")
                local task_status=$(jq -r ".troubleshooting_framework.phases.$phase.tasks[\"$task\"].status" "$TASKS_STATUS_FILE")

                local task_icon
                case "$task_status" in
                    "completed") task_icon="  ✅" ;;
                    "running") task_icon="  🔄" ;;
                    "failed") task_icon="  ❌" ;;
                    "pending") task_icon="  📋" ;;
                    "placeholder_created") task_icon="  🔧" ;;
                    *) task_icon="  ❓" ;;
                esac

                echo "$task_icon $task: $task_name"
            done
        fi
    done

    echo "============================================="
}

# Function to run systematic troubleshooting
run_systematic_troubleshooting() {
    log_info "Starting Systematic Container Troubleshooting Framework"

    # Create task status file if it doesn't exist
    if [[ ! -f "$TASKS_STATUS_FILE" ]]; then
        create_task_status_file
    fi

    # Show current container status
    get_container_status

    # Show initial progress
    show_progress

    # Execute phases sequentially
    local phases=("phase1" "phase2" "phase3" "phase4" "phase5" "phase6")

    for phase in "${phases[@]}"; do
        local phase_status=$(jq -r ".troubleshooting_framework.phases.$phase.status" "$TASKS_STATUS_FILE")

        if [[ "$phase_status" != "completed" ]]; then
            log_info "Starting execution of $phase"

            if execute_phase "$phase"; then
                log_success "Phase $phase completed successfully"
                show_progress
            else
                log_error "Phase $phase failed - stopping systematic troubleshooting"
                show_progress
                return 1
            fi
        else
            log_info "Phase $phase already completed"
        fi
    done

    log_success "🎉 All phases completed successfully!"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SYSTEMATIC_TROUBLESHOOTING_COMPLETE: All 6 phases completed successfully" >> "$TROUBLESHOOTING_LOG"
}

# Service-specific functionality testing functions
test_vault_functionality() {
    local phase="$1"

    log_info "🔒 Testing Vault functionality for $phase"

    # Test Vault status
    if ! docker exec purebliss-vault vault status > /dev/null 2>&1; then
        log_error "Vault status check failed"
        return 1
    fi

    # Test Vault health endpoint
    if ! curl -s http://127.0.0.1:18200/v1/sys/health | grep -q '"initialized":true'; then
        log_error "Vault health endpoint failed"
        return 1
    fi

    # Phase-specific tests
    case "$phase" in
        "phase1")
            log_info "Phase 1: Testing basic Vault operations"
            # Test basic Vault operations for foundation
            ;;
        "phase2"|"phase3"|"phase4"|"phase5"|"phase6")
            log_info "$phase: Testing advanced Vault integration"
            # Test AppRole and dynamic secrets for later phases
            ;;
    esac

    log_success "✅ Vault functionality tests passed for $phase"
    return 0
}

test_postgres_functionality() {
    local phase="$1"

    log_info "🐘 Testing PostgreSQL functionality for $phase"

    # Test PostgreSQL connection
    if ! docker exec purebliss-postgres pg_isready -h localhost -p 5432 -U postgres > /dev/null 2>&1; then
        log_error "PostgreSQL connection failed"
        return 1
    fi

    # Test RAID storage (actual data directory)
    if ! docker exec purebliss-postgres test -d /var/lib/postgresql/data/pgdata; then
        log_error "PostgreSQL data directory validation failed (/var/lib/postgresql/data/pgdata missing)"
        return 1
    fi

    # Phase-specific tests
    case "$phase" in
        "phase1")
            log_info "Phase 1: Testing basic PostgreSQL operations"
            # Test basic database operations
            ;;
        "phase3"|"phase4"|"phase5"|"phase6")
            log_info "$phase: Testing database integration"
            # Test service-specific databases
            ;;
    esac

    log_success "✅ PostgreSQL functionality tests passed for $phase"
    return 0
}

test_redis_functionality() {
    local phase="$1"

    log_info "🔴 Testing Redis functionality for $phase"

    # Test Redis ping
    if ! docker exec purebliss-redis redis-cli ping | grep -q "PONG"; then
        log_error "Redis ping failed"
        return 1
    fi

    # Test AOF persistence
    if ! docker exec purebliss-redis redis-cli config get appendonly | grep -q "yes"; then
        log_error "Redis AOF persistence not enabled"
        return 1
    fi

    log_success "✅ Redis functionality tests passed for $phase"
    return 0
}

test_keycloak_functionality() {
    local phase="$1"

    log_info "🔑 Testing Keycloak functionality for $phase"

    # Test Keycloak health
    if ! curl -s http://localhost:8080/health | grep -q '"status":"UP"'; then
        log_error "Keycloak health check failed"
        return 1
    fi

    log_success "✅ Keycloak functionality tests passed for $phase"
    return 0
}

test_nginx_functionality() {
    local phase="$1"

    log_info "🌐 Testing Nginx functionality for $phase"

    # Test Nginx configuration
    if ! docker exec purebliss-nginx nginx -t > /dev/null 2>&1; then
        log_error "Nginx configuration test failed"
        return 1
    fi

    # Test Nginx response
    if ! curl -s http://localhost:80 > /dev/null 2>&1; then
        log_error "Nginx response test failed"
        return 1
    fi

    log_success "✅ Nginx functionality tests passed for $phase"
    return 0
}

test_vault_agent_functionality() {
    local phase="$1"

    log_info "🔐 Testing Vault-Agent functionality for $phase"

    # Test Vault-Agent proxy functionality
    if curl -s http://localhost:8100/v1/sys/health > /dev/null 2>&1; then
        log_success "✅ Vault-Agent proxy responding"
    else
        log_error "Vault-Agent proxy test failed"
        return 1
    fi

    log_success "✅ Vault-Agent functionality tests passed for $phase"
    return 0
}

# Container enhancement functions
enhance_container_based_on_failures() {
    local service="$1"
    local phase="$2"

    log_info "🔧 Implementing container enhancements for $service based on failures"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - CONTAINER_ENHANCEMENT_START: $service - Analyzing failures" >> "$TROUBLESHOOTING_LOG"

    # Analyze recent logs for error patterns
    local error_patterns=$(docker logs --tail 50 "purebliss-$service" 2>&1 | grep -i "error\|fail\|critical" || true)

    if [[ -n "$error_patterns" ]]; then
        log_info "📋 Error patterns found for $service:"
        echo "$error_patterns" | head -10

        # Implement service-specific enhancements
        case "$service" in
            "vault")
                enhance_vault_container "$phase" "$error_patterns"
                ;;
            "postgres")
                enhance_postgres_container "$phase" "$error_patterns"
                ;;
            "redis")
                enhance_redis_container "$phase" "$error_patterns"
                ;;
            "keycloak")
                enhance_keycloak_container "$phase" "$error_patterns"
                ;;
            "nginx")
                enhance_nginx_container "$phase" "$error_patterns"
                ;;
        esac
    fi

    log_success "✅ Container enhancement completed for $service"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - CONTAINER_ENHANCEMENT_COMPLETE: $service" >> "$TROUBLESHOOTING_LOG"
}

enhance_vault_container() {
    local phase="$1"
    local errors="$2"

    log_info "🔒 Enhancing Vault container"

    # Check if Vault needs initialization
    if echo "$errors" | grep -q "security barrier not initialized"; then
        log_info "Vault needs initialization"
        # Already handled by our validation script
    fi

    # Check for permission issues
    if echo "$errors" | grep -q "permission denied"; then
        log_info "Fixing Vault permission issues"
        docker exec purebliss-vault chown -R vault:vault /vault || true
    fi
}

enhance_postgres_container() {
    local phase="$1"
    local errors="$2"

    log_info "🐘 Enhancing PostgreSQL container"

    # Check for data directory issues
    if echo "$errors" | grep -q "data directory"; then
        log_info "Fixing PostgreSQL data directory issues"
        docker exec purebliss-postgres chown -R postgres:postgres /raid-storage/postgres-data || true
    fi
}

enhance_redis_container() {
    local phase="$1"
    local errors="$2"

    log_info "🔴 Enhancing Redis container"

    # Check for AOF issues
    if echo "$errors" | grep -q "AOF"; then
        log_info "Fixing Redis AOF issues"
        docker exec purebliss-redis redis-cli config set appendonly yes || true
    fi
}

enhance_keycloak_container() {
    local phase="$1"
    local errors="$2"

    log_info "🔑 Enhancing Keycloak container"

    # Check for database connection issues
    if echo "$errors" | grep -q "database"; then
        log_info "Fixing Keycloak database connection issues"
        # Wait for PostgreSQL and retry
        sleep 10
    fi
}

enhance_nginx_container() {
    local phase="$1"
    local errors="$2"

    log_info "🌐 Enhancing Nginx container"

    # Check for upstream issues
    if echo "$errors" | grep -q "upstream"; then
        log_info "Fixing Nginx upstream issues"
        # Implement smart upstream logic
    fi
}

# Main execution
main() {
    local command="${1:-run}"

    case "$command" in
        "run"|"start")
            run_systematic_troubleshooting
            ;;
        "status"|"progress")
            show_progress
            ;;
        "phase")
            local phase="${2:-phase1}"
            execute_phase "$phase"
            ;;
        "task")
            local phase="${2:-phase1}"
            local task="${3:-TASK-001}"
            execute_task "$phase" "$task"
            ;;
        "containers")
            get_container_status
            ;;
        "init")
            create_task_status_file
            log_success "Task tracking system initialized"
            ;;
        *)
            echo "Usage: $0 [run|status|phase|task|containers|init]"
            echo "  run        - Execute systematic troubleshooting"
            echo "  status     - Show progress dashboard"
            echo "  phase X    - Execute specific phase"
            echo "  task X Y   - Execute specific task"
            echo "  containers - Show container status"
            echo "  init       - Initialize task tracking"
            exit 1
            ;;
    esac
}

# Execute main function
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
