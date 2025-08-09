#!/bin/bash
set -euo pipefail

# CENTRALIZED SCRIPT REFERENCE SYSTEM
SCRIPT_DIR="/opt/dev-purebliss/dev_scripts"
DOC_DIR="/opt/dev-purebliss/Documentation"

# MANDATORY UTILITY IMPORTS (DON'T REINVENT THE WHEEL)
source "$SCRIPT_DIR/utilities/common-functions-library.sh" 2>/dev/null || true
source "$SCRIPT_DIR/utilities/retry-utils.sh" 2>/dev/null || true

# SCRIPT METADATA
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0"
SCRIPT_PURPOSE="[Enhanced with centralized structure]"

# Pure Bliss Orchestrator Quick Start
# Run this script to immediately initialize the AI agent coordination system

echo "🚀 Starting Pure Bliss Tmux Orchestrator..."
echo "🎯 Target: 107,500 customers/year | 75K Instagram | 50K YouTube | 99.999% uptime"
echo ""

# Navigate to Pure Bliss development environment
cd /opt/dev-purebliss

# Start the orchestrator
echo "🤖 Initializing AI agents for Pure Bliss..."
./orchestrator/scripts/start-environment.sh

echo ""
echo "✅ Pure Bliss Orchestrator is now active!"
echo ""
echo "🔗 Service URLs (dev.purebliss.app):"
echo "   - Code-Server: https://dev.purebliss.app/code-server"
echo "   - Keycloak: https://dev.purebliss.app/keycloak"
echo "   - Vault: https://dev.purebliss.app/vault"
echo "   - Grafana: https://dev.purebliss.app/grafana"
echo ""
echo "🤖 Active Agents:"
echo "   - Primary Orchestrator (30-min check-ins)"
echo "   - Infrastructure Agent (10-min check-ins)"
echo "   - Social Media Agent (30-min check-ins)"
echo "   - Vault Agent (15-min check-ins)"
echo "   - Frontend Agent (60-min check-ins)"
echo "   - Backend Agent (60-min check-ins)"
echo ""
echo "📱 To attach to Primary Orchestrator:"
echo "   tmux attach-session -t pure-bliss-orchestrator"
echo ""
echo "📤 To send commands to agents:"
echo '   ./orchestrator/send-claude-message.sh "social-media-management:0" "Schedule today\'s posts"'
echo ""
echo "🎉 Ready for 70 posts/day automation and elite microservices management!"
