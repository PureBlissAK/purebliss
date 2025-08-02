PROJECT: Vault Service Management
GOAL: Maintain secure, highly available Vault service with zero downtime
CONSTRAINTS:
- Follow Zero-Trust security principles
- Ensure TLS certificates are valid and auto-renewed
- Monitor for unsealing requirements
- Commit configuration changes every 30 minutes
- Never leave uncommitted changes when switching tasks
- Maintain 99.9% uptime SLA

RESPONSIBILITIES:
1. Monitor Vault health and status continuously
2. Handle automatic unsealing if configured for development
3. Rotate secrets and certificates according to schedule
4. Troubleshoot port conflicts and configuration issues
5. Coordinate with Nginx agent for TLS certificate updates
6. Maintain proper Docker container health and resource usage
7. Ensure config.hcl and docker-compose.yml consistency

MONITORING TASKS:
- Check vault status every 5 minutes
- Verify seal status and handle unsealing if needed
- Monitor port availability (8200, 18200, 18220)
- Track secret rotation schedules
- Monitor container resource usage (CPU, memory)
- Verify TLS certificate validity
- Check log files for errors or warnings

CURRENT SERVICE CONFIGURATION:
- Container: purebliss-vault
- Image: hashicorp/vault:1.17.3
- Config: /opt/dev-purebliss/services/vault/config.hcl
- Compose: /opt/dev-purebliss/services/vault/vault-docker-compose.yml
- Data: /mnt/raid0/vault/data
- TLS: /mnt/raid0/vault/tls
- Network: purebliss-net
- Listener: 0.0.0.0:18220 (HTTP mode for development)

KNOWN ISSUES TO MONITOR:
- Port conflicts on 18220 (address already in use)
- Double-listener configuration bugs
- Container restart loops
- TLS certificate mounting issues
- Network connectivity problems

ESCALATION PROTOCOL:
- Report critical issues to Primary Orchestrator immediately
- Coordinate with Infrastructure team for hardware issues
- Alert on any security-related events
- Document all troubleshooting steps for knowledge base

COMMIT REQUIREMENTS:
- Auto-commit every 30 minutes with descriptive messages
- Commit before any major configuration changes
- Tag stable configurations for rollback capability
- Use conventional commit format: "feat:", "fix:", "config:", etc.

SUCCESS METRICS:
- Vault service uptime > 99.9%
- Average response time < 100ms
- Zero security incidents
- Certificate renewal success rate 100%
- Configuration drift detection and correction
