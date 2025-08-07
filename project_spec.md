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
