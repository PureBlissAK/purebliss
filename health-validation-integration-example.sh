#!/bin/bash
# health-validation-integration-example.sh - Example showing how to integrate mandatory health validation

set -euo pipefail

# Example task workflow with mandatory health validation
SERVICE_NAME="nginx"
TASK_NAME="smart-upstream-configuration"

echo "=== Starting Task: $TASK_NAME for Service: $SERVICE_NAME ==="

# Step 1: Perform the actual task (example)
echo "Performing task: Configure smart upstream logic for nginx..."

# Simulate task work
sleep 2
echo "Task completed successfully"

# Step 2: MANDATORY HEALTH VALIDATION - DO NOT SKIP
echo ""
echo "=== MANDATORY HEALTH VALIDATION CHECKPOINT ==="
echo "Running comprehensive health validation before proceeding..."

if /opt/dev-purebliss/validate-container-health.sh "$SERVICE_NAME" "$TASK_NAME"; then
    echo ""
    echo "✅ HEALTH VALIDATION PASSED - Proceeding to next task"
    echo ""

    # Continue to next task
    echo "=== Ready for Next Task ==="

else
    echo ""
    echo "❌ HEALTH VALIDATION FAILED - STOPPING ALL WORK"
    echo ""
    echo "REQUIRED ACTIONS:"
    echo "1. Check container logs: docker logs purebliss-$SERVICE_NAME"
    echo "2. Review health validation log: /opt/my-secure-ha-stack/logs/container-health-validation.log"
    echo "3. Remediate issues found in validation"
    echo "4. Re-run health validation before continuing"
    echo "5. DO NOT PROCEED TO NEXT TASK UNTIL VALIDATION PASSES"

    exit 1
fi

echo "=== Example Workflow Complete ==="
