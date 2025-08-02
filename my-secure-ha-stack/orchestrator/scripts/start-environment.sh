#!/bin/bash
# Pure Bliss Development Environment - Tmux Orchestrator Startup Script
# This script initializes the tmux orchestration system for the Pure Bliss microservices environment

set -euo pipefail

# Configuration
ORCHESTRATOR_PATH="/opt/Tmux-Orchestrator"
ENVIRONMENT_PATH="/opt/my-secure-ha-stack"
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
if [[ -f "${ENVIRONMENT_PATH}/config.env" ]]; then
    log "Loading environment configuration..."
    set -a
    source "${ENVIRONMENT_PATH}/config.env"
    set +a
    success "Environment configuration loaded"
else
    error "config.env not found at ${ENVIRONMENT_PATH}/config.env"
    exit 1
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

1. **Microservices Management**: Coordinate distinct service agents (Vault, Nginx, PostgreSQL, Redis, Keycloak, Code-server)
2. **Elite Standards Enforcement**: Maintain 99.999% uptime, <30ms API latency, 90% test coverage
3. **Security Oversight**: Zero-Trust principles, Vault dynamic secrets, GDPR/CCPA compliance
4. **Pure Bliss Goals**: 107,500 customers/year, 75K Instagram followers, 50K YouTube subscribers

Current Technology Stack:
- Frontend: React Native 0.75 (TypeScript, microservices architecture)
- Backend: Laravel 11 + PHP 8.3 (TastyIgniter extensions, Sanctum auth)
- Infrastructure: GCP serverless (Cloud Functions, App Engine, Firestore)
- AI/ML: Gemini 1.5 Pro (95% content accuracy), Vertex AI
- Social: Hootsuite Enterprise (70 posts/day across 12 platforms)
- Gamification: BlissVibe engine (#PureBlissVibesChallenge)

Available Service Agents:
- Vault Agent: Dynamic secrets, TLS certificates, 30-day rotation
- Social Media Agent: 70 posts/day, ≥1.50% engagement rate
- Gamification Agent: Location-based quests, UGC challenges, loyalty
- Infrastructure Agent: Service health monitoring, zero-downtime deployments

Follow microservices principles: isolate services, troubleshoot sequentially, maintain service boundaries.
Your first task is to analyze current service status and deploy specialized agents for Pure Bliss objectives."

schedule_check_ins "pure-bliss-orchestrator" 30 "Infrastructure health check and agent coordination"

# 2. Create Vault Management Session
log "Setting up Vault Agent..."
VAULT_AGENT_SPEC="${ENVIRONMENT_PATH}/orchestrator/agents/vault-agent.md"
create_agent_session "vault-management" "/opt/dev-purebliss/services/vault" "$VAULT_AGENT_SPEC"
schedule_check_ins "vault-management" 15 "Vault health check and status monitoring"

# 3. Create Database Management Session (if database services exist)
if [[ -d "/opt/dev-purebliss/services/postgres" ]]; then
    log "Setting up Database Agent..."
    create_agent_session "database-management" "/opt/dev-purebliss/services" ""
    "${ORCHESTRATOR_PATH}/send-claude-message.sh" "database-management:0" "You are the Database Agent for Pure Bliss. Manage PostgreSQL and Redis services. Monitor health, performance, backups, and coordinate with other agents. Working directory: /opt/dev-purebliss/services"
    schedule_check_ins "database-management" 20 "Database health and performance monitoring"
fi

# 4. Create Development Session
log "Setting up Development Agent..."
create_agent_session "development" "$ENVIRONMENT_PATH" ""
"${ORCHESTRATOR_PATH}/send-claude-message.sh" "development:0" "You are the Development Agent for Pure Bliss. Manage code-server, development workflows, and coordinate development tasks. Focus on frontend and backend development coordination. Working directory: ${ENVIRONMENT_PATH}"
schedule_check_ins "development" 45 "Development progress and task coordination"

# 5. Show session overview
log "Orchestrator environment setup complete!"
success "Active tmux sessions:"
tmux list-sessions

log "To attach to the Primary Orchestrator:"
echo "tmux attach-session -t pure-bliss-orchestrator"

log "To attach to specific agents:"
echo "tmux attach-session -t vault-management"
echo "tmux attach-session -t database-management"
echo "tmux attach-session -t development"

log "To send messages to agents, use:"
echo "${ORCHESTRATOR_PATH}/send-claude-message.sh <session:window> \"message\""

success "Pure Bliss Tmux Orchestrator is now active and monitoring your environment!"

# Final status check
log "Performing initial status check..."
"${ORCHESTRATOR_PATH}/send-claude-message.sh" "pure-bliss-orchestrator:0" "Please perform an initial status check of all Pure Bliss services and report any issues that need immediate attention."
