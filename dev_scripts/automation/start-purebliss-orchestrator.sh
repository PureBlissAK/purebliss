#!/bin/bash
set -euo pipefail

SESSION="purebliss-orchestrator"
SPEC="/opt/dev-purebliss/project_spec.md"
PLAN="/opt/dev-purebliss/PROJECT_PLAN.md"
LOG="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"

# Create project spec if missing
if [ ! -f "$SPEC" ]; then
    cat > "$SPEC" << 'EOF'
PROJECT: Pure Bliss Service Independence & Vault Integration
GOAL: Refactor all services for container independence, Vault onboarding, and health-validated orchestration.
CONSTRAINTS:
- One service at a time, strict health validation
- Log all actions to /opt/my-secure-ha-stack/logs/dev-environment-setup.log
- Update /opt/dev-purebliss/PROJECT_PLAN.md in real time
- Use entrypoint.sh for all service startup logic
- Follow /opt/dev-purebliss/.github/copilot-instructions.md
DELIVERABLES:
1. Vault: entrypoint.sh, Dockerfile, Compose, health check, backup, docs
2. Repeat for postgres, redis, keycloak, nginx, etc.
3. Final orchestrator: pure orchestration, health checks, git workflow
SUCCESS CRITERIA:
- Each service starts independently and passes health checks
- All logs and docs updated per spec
- Git workflow and backup steps completed
EOF
    echo "[$(date)] [Orchestrator] Created project_spec.md" >> "$LOG"
fi

# Start tmux session and windows
tmux new-session -d -s "$SESSION" -n orchestrator
tmux new-window -t "$SESSION" -n project-manager
tmux new-window -t "$SESSION" -n engineer
tmux new-window -t "$SESSION" -n qa-logger

# Orchestrator agent prompt
tmux send-keys -t "$SESSION:0" "
You are the Orchestrator. Read $SPEC and $PLAN.
Set up a Project Manager agent in window 1 to manage the Vault refactor phase.
Schedule check-ins every 30 minutes. Log all actions to $LOG.
" C-m

# Project Manager agent prompt
tmux send-keys -t "$SESSION:1" "
You are the Project Manager for Pure Bliss Vault refactor.
Assign the Vault entrypoint.sh, Dockerfile, and Compose update tasks to an Engineer agent in window 2.
Update $PLAN after each step.
Schedule check-ins every 15 minutes.
" C-m

# Engineer agent prompt
tmux send-keys -t "$SESSION:2" "
You are the Engineer. Implement the Vault entrypoint.sh, update Dockerfile and Compose, and test container startup.
Log all actions and errors to $LOG.
Mark tasks complete in $PLAN.
Notify the Project Manager when Vault passes health checks.
" C-m

# QA/Logger agent prompt
tmux send-keys -t "$SESSION:3" "
You are the QA/Logger agent. Monitor $LOG for errors and health check results.
Validate Vault container health and backup steps.
Log all validation actions and update $PLAN.
" C-m

# Attach to orchestrator session
tmux attach-session -t "$SESSION"
