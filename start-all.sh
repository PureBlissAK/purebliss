#!/bin/bash
#
# Pure Bliss Elite Social Media Technology Stack - Unified Startup Script
#
# This script orchestrates the startup of the entire Pure Bliss platform,
# including the new Infrastructure Agent responsible for managing the services.
#

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
INFRA_AGENT_SCRIPT="/opt/my-secure-ha-stack/orchestrator/agents/start-infrastructure-agent.sh"

# --- Main Execution ---

echo "[$(date)] --- Starting Pure Bliss Platform ---" | tee -a "$LOG_FILE"

# 1. Run the Infrastructure Agent to bring up all services
if [ -f "$INFRA_AGENT_SCRIPT" ]; then
    echo "[$(date)] - Executing Infrastructure Agent..." | tee -a "$LOG_FILE"
    bash "$INFRA_AGENT_SCRIPT"
else
    echo "[$(date)] - ERROR: Infrastructure Agent script not found at $INFRA_AGENT_SCRIPT" | tee -a "$LOG_FILE"
    exit 1
fi

echo "[$(date)] --- Pure Bliss Platform Startup Complete ---" | tee -a "$LOG_FILE"
