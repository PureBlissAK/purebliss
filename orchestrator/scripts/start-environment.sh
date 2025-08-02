#!/bin/bash
# Pure Bliss Development Environment - Tmux Orchestrator Startup Script
# This script initializes the tmux orchestration system for the Pure Bliss microservices environment

set -euo pipefail

# Configuration
ORCHESTRATOR_PATH="/opt/dev-purebliss/orchestrator"
ENVIRONMENT_PATH="/opt/dev-purebliss"
SERVICES_PATH="/opt/dev-purebliss/services"
LOG_FILE="${ENVIRONMENT_PATH}/logs/orchestrator-startup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR $(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS $(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING $(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

log "Starting Pure Bliss Tmux Orchestrator Environment..."

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    error "Tmux is not installed. Please install tmux first."
    exit 1
fi

# Check if claude command is available
if ! command -v claude &> /dev/null; then
    warn "Claude CLI not found. Make sure Claude is properly configured."
fi

# Source environment variables
if [[ -f "${ENVIRONMENT_PATH}/.env" ]]; then
    log "Loading environment configuration..."
    set -a
    source "${ENVIRONMENT_PATH}/.env"
    set +a
    success "Environment configuration loaded"
else
    warn ".env not found at ${ENVIRONMENT_PATH}/.env - using defaults"
    export LOCAL_HOSTNAME="dev.purebliss.app"
fi

# Function to check if session exists
session_exists() {
    tmux has-session -t "$1" 2>/dev/null
}

# Function to create tmux session with claude agent
create_agent_session() {
    local session_name="$1"
    local working_dir="$2"
    local agent_spec="$3"

    log "Creating session: $session_name"

    if session_exists "$session_name"; then
        warn "Session $session_name already exists. Skipping creation."
        return
    fi

    # Create tmux session
    tmux new-session -d -s "$session_name" -c "$working_dir"

    # Create additional windows
    tmux new-window -t "$session_name" -n "Logs" -c "$working_dir"
    tmux new-window -t "$session_name" -n "Monitoring" -c "$working_dir"
    tmux new-window -t "$session_name" -n "Shell" -c "$working_dir"

    # Switch back to main window
    tmux select-window -t "$session_name":0

    success "Session $session_name created successfully"

    # Start Claude in the main window
    log "Initializing Claude agent in $session_name..."
    tmux send-keys -t "$session_name":0 "claude" Enter

    # Wait for Claude to initialize
    sleep 5

    # Send agent specification if provided
    if [[ -n "$agent_spec" && -f "$agent_spec" ]]; then
        log "Briefing agent with specification: $agent_spec"
        local briefing_message
        briefing_message="You are a specialized agent for Pure Bliss Development Environment. Please read and follow this specification:

$(cat "$agent_spec")

Current working directory: $working_dir
Environment: $(basename "$ENVIRONMENT_PATH")

First, analyze your current environment and report your status."

        "${ORCHESTRATOR_PATH}/send-claude-message.sh" "$session_name:0" "$briefing_message"
        success "Agent briefed successfully"
    fi
}

# Function to schedule regular check-ins
schedule_check_ins() {
    local session_name="$1"
    local interval="$2"
    local note="$3"

    log "Scheduling check-ins for $session_name every $interval minutes"
    cd "$ORCHESTRATOR_PATH"
    ./schedule_with_note.sh "$interval" "$note" "$session_name:0"
    success "Check-ins scheduled for $session_name"
}

# 1. Create Primary Orchestrator Session
log "Setting up Primary Orchestrator..."
create_agent_session "pure-bliss-orchestrator" "$ENVIRONMENT_PATH" ""

# Brief the Primary Orchestrator manually (no spec file for this one)
log "Briefing Primary Orchestrator..."
"${ORCHESTRATOR_PATH}/send-claude-message.sh" "pure-bliss-orchestrator:0" "You are the Primary Orchestrator for Pure Bliss Elite Social Media Technology Stack. Your responsibilities:

1. **Microservices Management**: Coordinate distinct service agents running on dev.purebliss.app
2. **Elite Standards Enforcement**: Maintain 99.999% uptime, <30ms API latency, 90% test coverage
3. **Security Oversight**: Zero-Trust principles, Vault dynamic secrets, GDPR/CCPA compliance
4. **Pure Bliss Goals**: 107,500 customers/year, 75K Instagram followers, 50K YouTube subscribers

Current Technology Stack:
- Frontend: React Native 0.75 (TypeScript, microservices architecture)
- Backend: Laravel 11 + PHP 8.3 (TastyIgniter extensions, Sanctum auth)
- Infrastructure: Docker Compose with Nginx proxy on dev.purebliss.app
- Database: PostgreSQL 16 + Redis 7 caching
- AI/ML: Gemini 1.5 Pro (95% content accuracy), Vertex AI
- Social: Hootsuite Enterprise (70 posts/day across 12 platforms)
- Gamification: BlissVibe engine (#PureBlissVibesChallenge)

Services Directory: ${SERVICES_PATH}
Main Domain: dev.purebliss.app
Service Endpoints:
- Code-Server: https://dev.purebliss.app/code-server
- Keycloak: https://dev.purebliss.app/keycloak
- Vault: https://dev.purebliss.app/vault
- Plane: https://dev.purebliss.app/plane
- Grafana: https://dev.purebliss.app/grafana
- Prometheus: https://dev.purebliss.app/prometheus

Available Service Agents:
- Infrastructure Agent: Service health monitoring, zero-downtime deployments
- Vault Agent: Dynamic secrets, TLS certificates, 30-day rotation
- Social Media Agent: 70 posts/day, ≥1.50% engagement rate
- Frontend Agent: React Native 0.75 development
- Backend Agent: Laravel 11 API development
- Gamification Agent: Location-based quests, UGC challenges, loyalty

Follow microservices principles: isolate services, troubleshoot sequentially, maintain service boundaries.
Your first task is to analyze current service status and deploy specialized agents for Pure Bliss objectives."

schedule_check_ins "pure-bliss-orchestrator" 30 "Infrastructure health check and agent coordination"

# 2. Create Vault Management Session
log "Setting up Vault Agent..."
VAULT_AGENT_SPEC="${ENVIRONMENT_PATH}/orchestrator/agents/vault-agent.md"
create_agent_session "vault-management" "${SERVICES_PATH}/vault" "$VAULT_AGENT_SPEC"
schedule_check_ins "vault-management" 15 "Vault health check and status monitoring"

# 3. Create Social Media Management Session
log "Setting up Social Media Agent..."
SOCIAL_AGENT_SPEC="${ENVIRONMENT_PATH}/orchestrator/agents/social-media-agent.md"
create_agent_session "social-media-management" "${ENVIRONMENT_PATH}" "$SOCIAL_AGENT_SPEC"
schedule_check_ins "social-media-management" 30 "Social media automation and engagement monitoring"

# 4. Create Infrastructure Management Session
log "Setting up Infrastructure Agent..."
INFRA_AGENT_SPEC="${ENVIRONMENT_PATH}/orchestrator/agents/infrastructure-agent.md"
create_agent_session "infrastructure-management" "${SERVICES_PATH}" "$INFRA_AGENT_SPEC"
schedule_check_ins "infrastructure-management" 10 "Service health and performance monitoring"

# 5. Create Frontend Development Session
log "Setting up Frontend Agent..."
FRONTEND_AGENT_SPEC="${ENVIRONMENT_PATH}/orchestrator/agents/frontend-agent.md"
create_agent_session "frontend-development" "${ENVIRONMENT_PATH}" "$FRONTEND_AGENT_SPEC"
schedule_check_ins "frontend-development" 60 "React Native development and testing"

# 6. Create Backend Development Session
log "Setting up Backend Agent..."
BACKEND_AGENT_SPEC="${ENVIRONMENT_PATH}/orchestrator/agents/backend-agent.md"
create_agent_session "backend-development" "${ENVIRONMENT_PATH}" "$BACKEND_AGENT_SPEC"
schedule_check_ins "backend-development" 60 "Laravel API development and optimization"

# 5. Show session overview
log "Orchestrator environment setup complete!"
success "Active tmux sessions:"
tmux list-sessions

log "To attach to the Primary Orchestrator:"
echo "tmux attach-session -t pure-bliss-orchestrator"

log "To attach to specific agents:"
echo "tmux attach-session -t vault-management"
echo "tmux attach-session -t social-media-management"
echo "tmux attach-session -t infrastructure-management"
echo "tmux attach-session -t frontend-development"
echo "tmux attach-session -t backend-development"

log "To send messages to agents, use:"
echo "${ORCHESTRATOR_PATH}/send-claude-message.sh <session:window> \"message\""

log "Service endpoints available at:"
echo "https://dev.purebliss.app"

success "Pure Bliss Tmux Orchestrator is now active and monitoring your environment!"

# Final status check
log "Performing initial status check..."
"${ORCHESTRATOR_PATH}/send-claude-message.sh" "pure-bliss-orchestrator:0" "Please perform an initial status check of all Pure Bliss services and report any issues that need immediate attention."
