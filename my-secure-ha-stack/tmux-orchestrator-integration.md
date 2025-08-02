# Tmux-Orchestrator Integration for Pure Bliss Development Environment

## Overview
This document outlines the integration of the Tmux-Orchestrator with our Pure Bliss microservices development environment to automate container management, service orchestration, and development workflows.

## Integration Plan

### 1. Clone and Setup Tmux-Orchestrator
```bash
cd /opt
git clone https://github.com/Jedward23/Tmux-Orchestrator.git
cd Tmux-Orchestrator
chmod +x send-claude-message.sh
chmod +x schedule_with_note.sh
```

### 2. Adapt for Pure Bliss Environment

#### Service Management Scripts
Create orchestrator-aware scripts for each microservice:

- **Vault Service**: Automated startup, health checks, and TLS configuration
- **Nginx Service**: SSL certificate management and reverse proxy configuration
- **Database Services**: PostgreSQL and Redis monitoring
- **Development Services**: Code-server, Keycloak, monitoring stack

#### Project Structure Integration
```
/opt/my-secure-ha-stack/
├── orchestrator/
│   ├── agents/
│   │   ├── vault-agent.md
│   │   ├── nginx-agent.md
│   │   ├── database-agent.md
│   │   └── monitoring-agent.md
│   ├── projects/
│   │   ├── pure-bliss-backend.md
│   │   ├── pure-bliss-frontend.md
│   │   └── infrastructure.md
│   └── scripts/
│       ├── start-environment.sh
│       ├── health-check.sh
│       └── deploy-agents.sh
```

### 3. Service-Specific Agent Configurations

#### Vault Agent Specification
```markdown
PROJECT: Vault Service Management
GOAL: Maintain secure, highly available Vault service
CONSTRAINTS:
- Follow Zero-Trust security principles
- Ensure TLS certificates are valid
- Monitor for unsealing requirements
- Commit configuration changes every 30 minutes

RESPONSIBILITIES:
1. Monitor Vault health and status
2. Handle automatic unsealing if configured
3. Rotate secrets and certificates
4. Troubleshoot port conflicts and configuration issues
5. Coordinate with Nginx agent for TLS certificate updates

MONITORING:
- Check vault status every 5 minutes
- Verify seal status
- Monitor port availability (8200, 18200, 18220)
- Track secret rotation schedules
```

#### Infrastructure Orchestrator Specification
```markdown
PROJECT: Pure Bliss Infrastructure
GOAL: Maintain 99.9% uptime across all microservices
CONSTRAINTS:
- Microservices-first architecture
- All services must be containerized
- Follow Pure Bliss Elite Manifesto principles
- Zero-downtime deployments

DELIVERABLES:
1. Automated service health monitoring
2. Container orchestration and scaling
3. Network troubleshooting and optimization
4. Backup and disaster recovery automation
5. Performance monitoring and alerting

TEAM COORDINATION:
- Vault Agent: Security and secrets management
- Database Agent: PostgreSQL and Redis operations
- Monitoring Agent: Loki, Prometheus, Grafana
- Development Agent: Code-server and development tools
```

### 4. Tmux Session Architecture

#### Primary Orchestrator Session
```bash
tmux new-session -s pure-bliss-orchestrator
# Window 0: Main Orchestrator (Claude)
# Window 1: Infrastructure Overview
# Window 2: Service Health Dashboard
# Window 3: Logs Aggregation
```

#### Service-Specific Sessions
```bash
# Vault Management
tmux new-session -s vault-management
# Window 0: Vault Agent (Claude)
# Window 1: Vault Server Logs
# Window 2: Configuration Management

# Database Management  
tmux new-session -s database-management
# Window 0: Database Agent (Claude)
# Window 1: PostgreSQL Logs
# Window 2: Redis Monitoring

# Development Environment
tmux new-session -s development
# Window 0: Development Agent (Claude)
# Window 1: Code-server
# Window 2: Frontend Development
# Window 3: Backend Development
```

### 5. Automated Startup Sequence

#### Master Startup Script
```bash
#!/bin/bash
# /opt/my-secure-ha-stack/orchestrator/scripts/start-environment.sh

# 1. Start Primary Orchestrator
tmux new-session -d -s pure-bliss-orchestrator -c "/opt/my-secure-ha-stack"
tmux send-keys -t pure-bliss-orchestrator:0 "claude" Enter
sleep 5

# Brief the Primary Orchestrator
/opt/Tmux-Orchestrator/send-claude-message.sh pure-bliss-orchestrator:0 "You are the Primary Orchestrator for Pure Bliss Development Environment. Your responsibilities:

1. **Infrastructure Management**: Coordinate with service agents to maintain 99.9% uptime
2. **Security Oversight**: Ensure all services follow Zero-Trust principles
3. **Development Coordination**: Manage development workflow and task assignment
4. **Quality Assurance**: Enforce Elite Manifesto standards across all services

Current Environment Status:
- Services: Vault, Nginx, PostgreSQL, Redis, Keycloak, Code-server, Monitoring Stack
- Location: /opt/my-secure-ha-stack
- Configuration: config.env centralized environment variables

First, analyze the current service status and create specialized agents for critical services."

# 2. Schedule regular check-ins
cd /opt/Tmux-Orchestrator
./schedule_with_note.sh 30 "Infrastructure health check and agent coordination" "pure-bliss-orchestrator:0"

echo "Primary Orchestrator started and briefed"
```

### 6. Service Agent Deployment

#### Vault Agent Deployment
```bash
# Create Vault management session
tmux new-session -d -s vault-management -c "/opt/dev-purebliss/services/vault"

# Start Vault Agent
tmux send-keys -t vault-management:0 "claude" Enter
sleep 5

# Brief Vault Agent
/opt/Tmux-Orchestrator/send-claude-message.sh vault-management:0 "You are the Vault Service Agent. Specializing in:

1. **Service Health**: Monitor Vault container status and performance
2. **Security Management**: Handle unsealing, secret rotation, TLS certificates
3. **Configuration**: Maintain config.hcl and docker-compose configurations
4. **Troubleshooting**: Resolve port conflicts, configuration issues, startup failures

Current Service Status:
- Container: purebliss-vault
- Config: /opt/dev-purebliss/services/vault/config.hcl
- Compose: /opt/dev-purebliss/services/vault/vault-docker-compose.yml

Immediate Tasks:
1. Check current Vault service status
2. Verify configuration correctness
3. Resolve any startup issues
4. Report back to Primary Orchestrator

Use the vault-docker-compose.yml file and ensure port 18220:18220 mapping matches config.hcl listener."
```

### 7. Communication Protocols

#### Agent-to-Orchestrator Reporting
```bash
# Vault Agent reports to Primary Orchestrator
/opt/Tmux-Orchestrator/send-claude-message.sh pure-bliss-orchestrator:0 "VAULT AGENT REPORT: Service status healthy, config validated, no port conflicts detected. Ready for production workload."

# Primary Orchestrator responds
/opt/Tmux-Orchestrator/send-claude-message.sh vault-management:0 "Acknowledged. Proceed with TLS configuration and coordinate with Nginx agent for certificate deployment."
```

#### Cross-Agent Coordination
```bash
# Vault Agent coordinates with Nginx Agent
/opt/Tmux-Orchestrator/send-claude-message.sh nginx-management:0 "Vault TLS certificates updated at /mnt/raid0/vault/tls. Please update Nginx configuration to use new certificates."
```

### 8. Monitoring and Health Checks

#### Automated Health Monitoring
```bash
# Schedule health checks for all critical services
./schedule_with_note.sh 15 "Check Vault service health and seal status" "vault-management:0"
./schedule_with_note.sh 20 "Monitor database connections and performance" "database-management:0"
./schedule_with_note.sh 25 "Verify Nginx proxy and SSL certificate status" "nginx-management:0"
```

### 9. Development Workflow Integration

#### Code Development Coordination
```bash
# Development Agent manages code-server and project work
/opt/Tmux-Orchestrator/send-claude-message.sh development:0 "New feature request: Implement OAuth integration with Keycloak. Coordinate with Infrastructure Orchestrator for service dependencies."
```

### 10. Implementation Steps

1. **Phase 1**: Setup Tmux-Orchestrator and basic session structure
2. **Phase 2**: Deploy Primary Orchestrator and Vault Agent
3. **Phase 3**: Add Database and Nginx agents
4. **Phase 4**: Integrate development workflow agents
5. **Phase 5**: Implement automated monitoring and alerting

## Benefits

1. **24/7 Autonomous Operation**: Agents work continuously to maintain service health
2. **Intelligent Problem Resolution**: AI agents can diagnose and fix common issues
3. **Coordinated Development**: Multiple agents can work on different aspects simultaneously
4. **Quality Assurance**: Automated testing and validation at every level
5. **Documentation**: All actions and decisions are logged and tracked

## Next Steps

1. Clone the Tmux-Orchestrator repository
2. Create the orchestrator directory structure
3. Implement the startup scripts
4. Deploy the Primary Orchestrator
5. Begin with Vault Agent deployment and testing
