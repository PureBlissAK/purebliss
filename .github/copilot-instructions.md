## Additional Required References

All Copilot-driven dNo Circular Troubleshooting:

Do not suggest repetitTask Focus and No Tangents:

Strictly adhere to the user's requested task and service, avoiding suggestions for unrelated services unless explicitly required.
Scope suggestions to the specific microservice and its defined responsibilities (e.g., Nginx for routing, Keycloak for authentication).
Avoid proposing solutions for hypothetical or unrelated problems.
PARALLEL EXECUTION ALLOWED: When tasks are independent and resource-safe per Parallel Task Execution Guidelines.
DEPENDENCY COORDINATION: Always respect service dependencies when suggesting parallel work.iagnostic steps already documented in /opt/my-secure-ha-stack/logs/dev-environment-setup.log for the same service and issue unless explicitly requested.
Always reference the log to confirm the issue hasn't been resolved previously with the same root cause.
AUTONOMOUS ENHANCEMENT: If circular troubleshooting is detected, automatically implement script enhancements to prevent the recurring issue.

Continuous Log Analysis and Script Enhancement:

MANDATORY LOG SCANNING: Before every action, scan /opt/my-secure-ha-stack/logs/dev-environment-setup.log for patterns indicating recurring issues or resolved problems.
AUTOMATIC ENHANCEMENT TRIGGER: When an issue is resolved, immediately implement script enhancement workflow to prevent recurrence.
PATTERN RECOGNITION: Identify error patterns, failure modes, and common issues from log analysis to proactively enhance automation.
PREVENTIVE SCRIPT UPDATES: Update health validation scripts, entrypoint scripts, and automation tools based on log-discovered issues.
ENHANCEMENT VALIDATION: Test enhanced scripts to ensure they prevent identified issues without introducing new problems.
COMPREHENSIVE DOCUMENTATION: Document all enhancements with root cause analysis and prevention measures in development log.opment must also reference and comply with the following documentation, which provides service-specific, security, and technology guidance for the Pure Bliss stack:

- **Keycloak Best Practices:** See `/opt/.github/KEYCLOAK_BEST_PRACTICES.md` for secure authentication, SSO, and RBAC configuration standards.
- **SSO Configuration:** Follow `/opt/.github/SSO configuration` for Google Workspace SAML/OIDC and multi-realm setup.
- **Technology Best Practices:** Adhere to `/opt/.github/Technology Best Practices` for architecture, coding, and deployment standards across all services.
- **Vault and Vault Agent Best Practices:** Consult `/opt/.github/Vault and Vault Agent Best Practices for VS Code Copilot` for secure secrets management, dynamic secrets, and VS Code integration.
- **Pure Bliss Elite Social Media Technology Stack:** Review `/opt/.github/`Pure Bliss Elite Social Media Technolog.md` for the full product architecture, development guide, and operational requirements.

These documents are mandatory reading for all Copilot-driven contributions and must be consulted for any changes, troubleshooting, or new feature development. Where there is overlap, the most specific or service-focused guidance takes precedence.
Copilot Instructions for Pure Bliss Development - Microservices First

MANDATORY: All actions, troubleshooting steps, and progress must be logged in /opt/my-secure-ha-stack/logs/dev-environment-setup.log. This log is the single source of truth and must never be bypassed, deleted, or rotated out.

CRITICAL ENHANCEMENT: All development work must now implement MANDATORY HEALTH VALIDATION after every task. The comprehensive health validation system at `/opt/dev-purebliss/validate-container-health.sh` must be executed after every build, configuration change, or integration step. NO FORWARD PROGRESS is permitted until container health validation passes with exit code 0.

� MANDATORY HTTPS-ONLY ENFORCEMENT 🔒

**ABSOLUTE SECURITY REQUIREMENT**: ALL SERVICE COMMUNICATIONS MUST USE HTTPS/TLS EXCLUSIVELY

**HTTPS-ONLY PROTOCOL ENFORCEMENT**:
- ALL Vault API calls MUST use https://vault.purebliss.app:8200 or https://127.0.0.1:8200 with TLS
- ALL health checks MUST use HTTPS endpoints with proper certificate validation
- ALL service-to-service communication MUST be encrypted with TLS
- NO HTTP plaintext connections allowed for any service API calls
- ALL scripts, health validation, and automation MUST enforce HTTPS-only
- ALL entrypoint scripts MUST use HTTPS for service readiness checks
- SELF-SIGNED certificates are acceptable for development with proper validation

**HTTPS VALIDATION REQUIREMENTS**:
- Every script MUST validate HTTPS connectivity before proceeding
- Health validation MUST verify TLS certificate presence and validity
- Service startup MUST fail fast if HTTPS endpoints are unavailable
- All API clients MUST be configured for HTTPS with certificate validation
- Protocol mismatch errors (HTTP to HTTPS) are considered CRITICAL failures

�🚨 UNBREAKABLE VALIDATION RULE - MANDATORY REBOOT VALIDATION 🚨

**ABSOLUTE ULTIMATE REQUIREMENT**: TRUE VALIDATION OF SUCCESSFUL TASK COMPLETION IS TO REBOOT THE SERVICE AND RUN CHECKS UNTIL ITS WORKING ON REBOOT AND FULLY 100% HEALTHY.

**MANDATORY REBOOT VALIDATION PROTOCOL**:
- EVERY task completion MUST be validated by full service reboot
- EVERY configuration change MUST survive container restart and achieve 100% health
- EVERY integration MUST function perfectly after complete system reboot
- NO task is considered complete until reboot validation passes
- ALL services must achieve and maintain 100% health status post-reboot
- FAILURE to pass reboot validation invalidates ALL previous work
- REBOOT testing is the ULTIMATE and FINAL validation gate

**REBOOT VALIDATION WORKFLOW**:
1. Complete task implementation
2. Run initial health validation
3. MANDATORY: Kill all containers (docker kill $(docker ps -q))
4. MANDATORY: Restart all services from scratch
5. MANDATORY: Run comprehensive health validation
6. MANDATORY: Achieve 100% health status across all services
7. MANDATORY: Validate all integrations function post-reboot
8. Only after 100% reboot validation SUCCESS can task be marked complete

**THIS RULE CAN NEVER BE BROKEN - REBOOT VALIDATION IS ABSOLUTE**

Overview
This document outlines the guidelines for using Copilot Enterprise within the Pure Bliss ecosystem, ensuring consistency, security, and adherence to elite standards of modularity and microservices architecture. Copilot is trained on all Pure Bliss repositories and understands the distinct boundaries and responsibilities of each service, with mandatory health validation gates enforcing container integrity throughout all development workflows.

## Integration with .github Best Practices

All Copilot-driven development must comply with the organizational best practices and policies defined in the `.github` directory:

- **Contributing:** Follow the contribution workflow, PR review, and code standards in `.github/CONTRIBUTING.md`.
- **Security:** Adhere to secure development and vulnerability reporting as described in `.github/SECURITY.md`.
- **Community:** Maintain respectful, inclusive collaboration per `.github/CODE_OF_CONDUCT.md`.
- **Templates:** Use the issue and PR templates in `.github/ISSUE_TEMPLATE/` and `.github/PULL_REQUEST_TEMPLATE.md` for all submissions.
- **CI/CD:** Ensure all code passes automated tests and linters as defined in `.github/workflows/` before merging.
- **Documentation:** Document all features and changes per `.github/CONTRIBUTING.md` and @github #kb standards.
- **Changelog:** Update the changelog according to `.github/CHANGELOG.md` for all releases.
Restrictions for Copilot Behavior
To ensure Copilot remains focused, efficient, and avoids redundant or off-topic work, the following restrictions are enforced:

All restrictions below are in addition to, and must be interpreted in harmony with, the policies and workflows defined in the `.github` directory. Where there is overlap, `.github` standards take precedence for contribution, security, and community conduct.

MANDATORY CENTRALIZED SCRIPT MANAGEMENT:

🎯 CENTRALIZED SCRIPT LOCATION: All scripts must be developed, maintained, and executed from /opt/dev-purebliss/dev_scripts/ using organized directory structure
📚 CENTRALIZED DOCUMENTATION: All documentation must be created and maintained in /opt/dev-purebliss/Documentation/ with cross-referencing integration
🔄 DON'T REINVENT THE WHEEL: Always scan existing scripts and functions before creating new functionality - enhance existing rather than duplicate
🤝 SCRIPT INTER-DEPENDENCY: Every script must leverage shared utilities and common functions from centralized libraries
📋 PROJECT PLAN AUTO-UPDATE: All verified scripts must automatically update PROJECT_PLAN_ENHANCED.md with status and references
🚀 SINGLE-COMMAND DEPLOYMENT: Ultimate goal is deploying entire application from scratch with one master script after git pull

MANDATORY SCRIPT DISCOVERY AND REUSE:

PRE-DEVELOPMENT SCAN: Before creating any script, ALWAYS scan /opt/dev-purebliss/ and /opt/dev-purebliss/services/ for existing functionality
EXISTING SCRIPT INTEGRATION: If similar functionality exists, enhance existing scripts with parameters rather than creating duplicates
SHARED FUNCTION USAGE: All scripts MUST source and use /opt/dev-purebliss/dev_scripts/utilities/common-functions-library.sh
DOCUMENTATION LEVERAGE: Reference and build upon existing documentation patterns in /opt/dev-purebliss/Documentation/
MIGRATION METHODOLOGY: Systematically migrate existing scripts to centralized structure with health validation at each step

CENTRALIZED SCRIPT STRUCTURE REQUIREMENTS:

ALL SCRIPTS MUST USE:
- SCRIPT_DIR="/opt/dev-purebliss/dev_scripts" for script references
- DOC_DIR="/opt/dev-purebliss/Documentation" for documentation references
- source "$SCRIPT_DIR/utilities/common-functions-library.sh" for shared functions
- source "$SCRIPT_DIR/utilities/retry-utils.sh" for retry functionality
- source "$SCRIPT_DIR/utilities/script-communication-bridge.sh" for inter-script communication

ORGANIZED DIRECTORY STRUCTURE:
- /opt/dev-purebliss/dev_scripts/automation/ - Master deployment and orchestration
- /opt/dev-purebliss/dev_scripts/core/ - Essential infrastructure scripts
- /opt/dev-purebliss/dev_scripts/services/ - Service-specific automation
- /opt/dev-purebliss/dev_scripts/utilities/ - Shared helper scripts and libraries
- /opt/dev-purebliss/dev_scripts/health-checks/ - Health validation and testing
- /opt/dev-purebliss/dev_scripts/deployment/ - Deployment-specific scripts
- /opt/dev-purebliss/dev_scripts/management/ - Script management and maintenance

SYSTEMATIC SCRIPT MIGRATION PROTOCOL:

MIGRATION VALIDATION: Test each migrated script through complete container lifecycle (build, health, troubleshoot, reboot)
HEALTH CONFIRMATION: Achieve 100% health validation success before considering migration complete
REFERENCE UPDATES: Automatically update all script references to use centralized paths
BACKUP PRESERVATION: Maintain backups of original scripts during migration for rollback capability
INTEGRATION TESTING: Validate script integration with existing automation workflows
DOCUMENTATION SYNC: Update documentation to reflect new centralized structure

CONTAINER SELF-HEALING INTEGRATION:

EMBEDDED TROUBLESHOOTING: Containers must have direct access to troubleshooting scripts via centralized structure
AUTONOMOUS PROBLEM RESOLUTION: Containers can call centralized diagnostic and repair scripts when issues arise
HEALTH SCRIPT ACCESS: All containers have access to /opt/dev-purebliss/dev_scripts/health-checks/ for self-diagnosis
RECOVERY AUTOMATION: Failed containers can trigger recovery workflows using centralized automation scripts
ESCALATION PROCEDURES: Self-healing failures automatically escalate to centralized management scripts

SCAFFOLD-BASED DEVELOPMENT APPROACH:

PROGRESSIVE ENHANCEMENT: Use 6-phase container scaffolding (Phase1→Phase6) with centralized script integration
DEPENDENCY TOLERANCE: Scripts designed to function when some dependency services are unavailable, moving forward when possible
GRACEFUL DEGRADATION: Containers continue operating with reduced functionality until dependencies become available
DYNAMIC DEPENDENCY RESOLUTION: Scripts automatically detect and integrate with services as they become available
PHASE-BASED VALIDATION: Health validation required at each scaffolding phase before progression

MANDATORY SCRIPT DEVELOPMENT STANDARDS:

SCRIPT HEADER REQUIREMENTS (ALL SCRIPTS MUST INCLUDE):
```bash
#!/bin/bash
set -euo pipefail

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
SCRIPT_PURPOSE="[Brief description of script purpose]"
```

MANDATORY FUNCTION INTEGRATION (ALL SCRIPTS MUST USE):
- log_info() / log_error() / log_success() for centralized logging
- health_check_service() for service validation
- retry_with_backoff() for resilient operations
- validate_env_vars() for environment validation
- backup_file() for configuration safety
- Auto-update PROJECT_PLAN_ENHANCED.md with script status and references

INTER-SCRIPT COMMUNICATION REQUIREMENTS:
- Use script-communication-bridge.sh for coordinating with other scripts
- Implement dependency resolution through script-dependency-resolver.sh
- Leverage shared functions instead of duplicating common operations
- Reference centralized documentation for consistent patterns
- Auto-commit successful script enhancements and migrations

MANDATORY DOCUMENTATION DEVELOPMENT STANDARDS:

DOCUMENTATION HEADER REQUIREMENTS (ALL DOCS MUST INCLUDE):
```markdown
# [Document Title]

**Generated/Updated**: [YYYY-MM-DD HH:MM:SS]
**Purpose**: [Brief description of document purpose]
**Consolidation Type**: [automation|troubleshooting|best-practices|integration|guides]
**Services Covered**: [List of relevant services]

## Overview

[Document overview with consolidation context]

## Service-Specific Information

[Service-specific sections within consolidated framework]
```

MANDATORY DOCUMENTATION INTEGRATION (ALL DOCS MUST USE):
- Cross-reference consolidated documentation categories
- Include service-specific sections within consolidated documents
- Reference centralized script locations from /opt/dev-purebliss/dev_scripts/
- Maintain backward compatibility through legacy wrapper documents
- Auto-update service documentation indexes with consolidation references

INTER-DOCUMENTATION COMMUNICATION REQUIREMENTS:
- Use consistent cross-referencing between consolidated documents
- Implement service-specific indexes that reference consolidated sections
- Leverage consolidated documentation instead of duplicating information
- Reference centralized scripts for automation procedures
- Auto-commit successful documentation enhancements and migrations

SCRIPT ENHANCEMENT AND MIGRATION WORKFLOW:

DISCOVERY PHASE:
1. Scan /opt/dev-purebliss/ for existing scripts using: find /opt/dev-purebliss -name "*.sh" -type f
2. Analyze existing functionality to avoid duplication using grep and function analysis
3. Check Documentation/ for existing patterns and templates
4. Review PROJECT_PLAN_ENHANCED.md for current script status and dependencies

MIGRATION PHASE:
1. Create target location in appropriate dev_scripts/ subdirectory
2. Enhance script with centralized utilities and standard header
3. Update all references to use new centralized location
4. Test script integration with existing workflows
5. Validate health checks and error handling

VALIDATION PHASE:
1. Execute /opt/dev-purebliss/dev_scripts/core/validate-container-health.sh after script migration
2. Test container lifecycle: build → run → health → troubleshoot → reboot → validate
3. Confirm 100% success rate before considering migration complete
4. Update PROJECT_PLAN_ENHANCED.md with migration status
5. Auto-commit verified migration with comprehensive documentation

DOCUMENTATION INTEGRATION REQUIREMENTS:

AUTOMATIC DOC GENERATION: Scripts must auto-update relevant documentation files
DOC TEMPLATE USAGE: Use templates from /opt/dev-purebliss/Documentation/templates/
CROSS-REFERENCE UPDATES: Maintain links between scripts, docs, and project plan
BREAK-FIX INTEGRATION: Auto-update troubleshooting guides based on resolved issues
AUTOMATION GUIDE SYNC: Keep automation procedures current with script enhancements

CONSOLIDATED DOCUMENTATION INTEGRATION REQUIREMENTS:

DOCUMENTATION CONSOLIDATION METHODOLOGY: All documentation development must leverage the consolidated documentation system
CENTRALIZED DOCUMENTATION REFERENCE: Use /opt/dev-purebliss/Documentation/ for all documentation needs
SERVICE-SPECIFIC INDEXING: Reference service documentation indexes for quick access to consolidated content
LEGACY WRAPPER MAINTENANCE: Maintain backward compatibility through legacy documentation wrappers
UNIFIED CONSOLIDATION APPROACH: Apply same intelligent consolidation approach to new documentation as used for existing

"DON'T REINVENT THE WHEEL" METHODOLOGY COMPLETE:

DUAL CONSOLIDATION SYSTEM: Both scripts and documentation now operate under unified consolidation methodology
SCRIPT CONSOLIDATION ACHIEVEMENTS: 39 scripts consolidated into 3 enhanced scripts with 39 legacy wrappers
DOCUMENTATION CONSOLIDATION ACHIEVEMENTS: 31 documents consolidated into 5 categories with 9 service indexes and 31 legacy wrappers
BACKWARD COMPATIBILITY GUARANTEE: All existing integrations continue working seamlessly through wrapper systems
ENHANCED FUNCTIONALITY DELIVERY: Consolidated versions provide enhanced features beyond original capabilities
CONTINUOUS CONSOLIDATION MONITORING: Ongoing detection and consolidation of new duplication opportunities
UNIFIED MAINTENANCE APPROACH: Single point of enhancement for both scripts and documentation

MANDATORY VAULT INTEGRATION REQUIREMENTS:

ZERO HARDCODED PASSWORDS: All credentials, tokens, and secrets MUST be dynamically sourced from Vault
VAULT HEALTH VALIDATION: Validate Vault health endpoint (/v1/sys/health) from all service containers
APPROCK AUTHENTICATION: Test AppRole authentication and token issuance for each service
DYNAMIC SECRETS: Validate dynamic secret issuance and revocation for database users and service credentials
AUDIT LOGGING: Confirm audit logging of all Vault actions per service
VAULT DOCUMENTATION: Review service-specific Vault automation guides and break-fix reports

DOCKER INTEGRATION AND BUILD AUTOMATION REQUIREMENTS:

CONTAINERIZED SCRIPT INTEGRATION: All centralized scripts and documentation are directly integrated into Docker containers through Dockerfiles and entrypoint scripts
ENTRYPOINT AUTOMATION: Service entrypoint scripts leverage centralized scripts from /opt/dev-purebliss/dev_scripts/ for container initialization, health validation, and automation
DOCKERFILE ENHANCEMENT: Container builds incorporate consolidated scripts for enhanced functionality, vault integration, and self-healing capabilities
CONFIG.ENV INTEGRATION: All Docker containers reference config.env for environment-specific settings, paths, and automation parameters
BUILD PROCESS AUTOMATION: Docker build process includes script consolidation, documentation reference, and health validation integration
CONTAINER SCAFFOLDING: All containers follow Elite Container Scaffolding Framework with progressive enhancement (Phase1→Phase6)
HEALTH VALIDATION GATES: Mandatory health validation integrated into Docker container lifecycle through centralized validation scripts
VAULT CONTAINER INTEGRATION: All service containers include Vault AppRole authentication and dynamic secret retrieval capabilities

DOCKER BUILD AUTOMATION STANDARDS:

SCRIPT EMBEDDING: Dockerfiles MUST copy and integrate centralized scripts from /opt/dev-purebliss/dev_scripts/ into container filesystem
DOCUMENTATION INTEGRATION: Containers include access to consolidated documentation for runtime automation and troubleshooting
ENTRYPOINT ENHANCEMENT: Service entrypoint scripts source centralized utilities and implement standardized logging, health checks, and error handling
BUILD VALIDATION: Each Docker build includes mandatory health validation, script integration testing, and functionality verification
CONFIG AUTOMATION: Container startup processes reference config.env for dynamic configuration and environment-specific automation
SELF-HEALING INTEGRATION: Containers include autonomous troubleshooting and self-healing capabilities through integrated scripts

ADVANCED SCRIPT CONSOLIDATION INTEGRATION:

INTELLIGENT SIMILARITY DETECTION: Automatic analysis of script functionality and identification of consolidation opportunities
CONSOLIDATION CANDIDATES: Scripts with 30%+ similarity are flagged for potential consolidation
ENHANCED FUNCTIONALITY: Consolidated scripts combine best features from all merged scripts
BACKWARD COMPATIBILITY: Legacy wrapper scripts ensure existing integrations continue working seamlessly
CONTINUOUS OPTIMIZATION: Ongoing monitoring for new consolidation opportunities

CONSOLIDATED SCRIPT ARCHITECTURE:

VAULT INTEGRATION CONSOLIDATION: consolidated-vault-integration.sh - Universal vault operations including AppRole auth, dynamic secrets, health checks
DEPLOYMENT WORKFLOW CONSOLIDATION: consolidated-deployment.sh - Universal deployment with pre/post validation, dependency checking
VALIDATION FRAMEWORK CONSOLIDATION: consolidated-validation.sh - Comprehensive validation including health checks, endpoint validation, container monitoring

CONSOLIDATION ENFORCEMENT REQUIREMENTS:

MANDATORY CONSOLIDATION SCANNING: Before creating new scripts, check for similar existing functionality
CONSOLIDATION FIRST APPROACH: Enhance existing consolidated scripts rather than creating new similar scripts
LEGACY WRAPPER CREATION: Always create backward-compatible wrappers when consolidating existing scripts
ENHANCED FUNCTIONALITY: Ensure consolidated scripts include best practices from all merged sources
DOCUMENTATION UPDATES: Update all references and documentation when consolidation occurs

SCRIPT DEVELOPMENT WITH CONSOLIDATION AWARENESS:

PRE-DEVELOPMENT CONSOLIDATION CHECK: Scan for similar scripts using similarity analysis before creating new functionality
ENHANCE CONSOLIDATED SCRIPTS: Add new features to existing consolidated scripts when functionality overlaps
WRAPPER MAINTENANCE: Maintain legacy wrappers for deprecated functionality until transition is complete
CONSOLIDATION VALIDATION: Test consolidated scripts against all original script use cases
PROJECT PLAN UPDATES: Automatically update project plan with consolidation results and metrics

ADVANCED DOCUMENTATION CONSOLIDATION INTEGRATION:

DOCUMENTATION CONSOLIDATION METHODOLOGY: Apply same intelligent consolidation approach to documentation that was used for scripts
SIMILARITY ANALYSIS FOR DOCS: Use heading structure analysis and keyword-based consolidation scoring (40%+ threshold) for documentation
DOCUMENTATION CATEGORY CONSOLIDATION: Group similar documents by type (automation, troubleshooting, best-practices, integration, guides)
SERVICE-SPECIFIC PRESERVATION: Create service documentation indexes that cross-reference consolidated documents
LEGACY DOCUMENTATION WRAPPERS: Create backward-compatible documentation wrappers ensuring existing links continue working
UNIFIED CONSOLIDATION APPROACH: Maintain consistency between script consolidation and documentation consolidation methodologies

CONSOLIDATED SCRIPT USAGE PATTERNS:

VAULT OPERATIONS: Use consolidated-vault-integration.sh for all vault-related operations
DEPLOYMENT TASKS: Use consolidated-deployment.sh for all deployment workflows
VALIDATION REQUIREMENTS: Use consolidated-validation.sh for all health and validation tasks
LEGACY COMPATIBILITY: Legacy scripts automatically route to appropriate consolidated functionality
ENHANCED CAPABILITIES: Consolidated scripts provide enhanced features beyond original script capabilities

CONSOLIDATED DOCUMENTATION USAGE PATTERNS:

AUTOMATION PROCEDURES: Use CONSOLIDATED_AUTOMATION.md for all automation-related documentation
TROUBLESHOOTING GUIDES: Use CONSOLIDATED_TROUBLESHOOTING.md for all break-fix and diagnostic procedures
BEST PRACTICES: Use CONSOLIDATED_BEST_PRACTICES.md for all security, performance, and deployment standards
INTEGRATION GUIDES: Use CONSOLIDATED_INTEGRATION.md for all vault integration and service connectivity
SERVICE REFERENCES: Use service-specific documentation indexes for quick access to consolidated content
LEGACY DOCUMENTATION: Legacy documentation wrappers automatically redirect to consolidated versions

AUTONOMOUS SELF-HEALING DIRECTIVE:

CONTINUOUS LOG MONITORING: Monitor /opt/my-secure-ha-stack/logs/dev-environment-setup.log for recurring issues, error patterns, and resolved problems
AUTOMATIC SCRIPT ENHANCEMENT: After EVERY problem resolution, automatically enhance scripts to prevent issue recurrence using comprehensive script enhancement workflow
PROACTIVE ISSUE DETECTION: Scan logs for error patterns, failure modes, and potential problems before they become critical
PREVENTIVE AUTOMATION: Update health validation, entrypoint scripts, and automation tools based on discovered issues and resolutions
LOG-DRIVEN ENHANCEMENT: Use log analysis to identify enhancement opportunities and implement prevention measures automatically
SELF-IMPROVEMENT PROTOCOL: Each resolved issue must result in enhanced automation to prevent similar issues in the future
MANDATORY ENHANCEMENT LOGGING: All script enhancements must be logged with root cause analysis, prevention measures, and validation results


No Circular Troubleshooting:

Do not suggest repetitive diagnostic steps already documented in /opt/my-secure-ha-stack/logs/dev-environment-setup.log for the same service and issue unless explicitly requested.
Always reference the log to confirm the issue hasn’t been resolved previously with the same root cause.


No Redundant File Creation:

Do not create or suggest creating files that duplicate existing configurations, scripts, or logs (e.g., no new log files outside /opt/my-secure-ha-stack/logs/dev-environment-setup.log).
Verify if a similar file exists in the service directory (e.g., /opt/my-secure-ha-stack/<service>/</service>) and suggest modifying it instead of creating a new one.


Task Focus and No Tangents:

Strictly adhere to the user’s requested task and service, avoiding suggestions for unrelated services unless explicitly required.
Scope suggestions to the specific microservice and its defined responsibilities (e.g., Nginx for routing, Keycloak for authentication).
Avoid proposing solutions for hypothetical or unrelated problems.


No Overgeneralization:

Provide specific, actionable code, commands, or steps using exact file paths, container names, or endpoints (e.g., https://dev.purebliss.app/<service></service>).
Avoid generic placeholders (e.g., <variable>, <endpoint>) unless the user requests a template.


Minimize Service Disruptions:

Prioritize non-disruptive diagnostics (e.g., docker logs, curl, LogQL queries) and only suggest container restarts or configuration changes as a last resort.
Justify restarts in the context of the specific service and confirm they won’t impact unrelated services.


No Redundant Code or Dependencies:

Do not suggest adding unnecessary libraries, dependencies, or code that duplicates existing functionality within a service’s codebase.
Confirm dependencies are not already included (e.g., check package.json for Node.js or requirements.txt for Python).


Log-Driven Workflow:

Always check /opt/my-secure-ha-stack/logs/dev-environment-setup.log for prior context before suggesting actions or code.
Include a step to append every action, result, or resolution to the log with a timestamp and service reference.
AUTONOMOUS LOG ANALYSIS: Continuously analyze logs for improvement opportunities and implement automatic script enhancements.
SELF-HEALING INTEGRATION: When logs indicate resolved issues, automatically trigger script enhancement workflow to prevent recurrence.
PROACTIVE ISSUE PREVENTION: Use log patterns to identify potential problems before they occur and enhance automation preemptively.

All actions must also comply with the automated checks and review processes defined in `.github/workflows/` and `.github/CONTRIBUTING.md`.


No Monolithic Suggestions:

Do not propose solutions that combine multiple services’ responsibilities into a single codebase or process.
Maintain clear service boundaries (e.g., Nginx for routing, Keycloak for authentication, Plane for issue tracking).


Avoid Over-Engineering:

Propose the simplest, most direct solution that addresses the task without unnecessary complexity.
Align solutions with the service’s current tech stack and version (e.g., Python 3.11, Node.js 20).


No Out-of-Scope Suggestions:

Do not suggest changes to paths outside /opt/my-secure-ha-stack/ or to services not listed in the tech stack.
Avoid suggesting tools or services not part of the defined stack (e.g., no Kubernetes when Docker Compose v3.8 is used).



Organization-Level Instructions

Technology Stack:

Frontend: React Native 0.75 (distinct module).
Backend: Laravel 10, PHP 8.2 (distinct module).
Infrastructure: Google Cloud Platform (GCP), managed as modular IaC units.


Code Standards:

Enforce Conventional Commits for all commit messages.
Maintain 90% test coverage for all code within its service module.


Security & Compliance:

Prioritize secure coding practices, respecting inter-service security boundaries.
Ensure GDPR and CCPA compliance, considering data flow between services.


Documentation:

Reference @github #kb for internal knowledge base standards, emphasizing service-specific API, purpose, and dependencies.

All documentation must also meet the requirements in `.github/CONTRIBUTING.md` and be reflected in the changelog as per `.github/CHANGELOG.md`.


Restrictions:

Do not suggest code or configurations that deviate from the defined stack or introduce redundant dependencies.
Include a log entry command for all code suggestions to /opt/my-secure-ha-stack/logs/dev-environment-setup.log.



Repo-Specific Instructions

Project Context:

Name: PureBliss Development Environment
Description: A high-availability, secure platform of interconnected microservices for application development. Each service (code-server, keycloak, nginx, plane, postgres, redis, vault, loki, prometheus, grafana) is independently deployable, orchestrated via Docker Compose v3.8 for local development.


Tech Stack:

Orchestration: Docker Compose v3.8, resource-optimized per service.
Development IDE: CodeServer v4.20.0 (codercom/code-server).
Authentication: Keycloak v24.0.5 (quay.io/keycloak/keycloak), SAML/OIDC, RBAC.
API Gateway: Nginx latest (nginx:latest), WAF capabilities, smart upstream logic.
Issue Tracking: Plane app-latest (makeplane/plane), REST API-driven.
Data Store: PostgreSQL v16 (postgres:16), indexed for performance, Vault dynamic secrets.
Caching: Redis v7 (redis:7), in-memory with AOF persistence, Vault AppRole integration.
Secrets Management: Vault v1.17.3 (hashicorp/vault), dynamic secrets, PKI engine.
Certificate Management: Let's Encrypt integration with Vault PKI and automated renewal.
Logging: Loki v2.9.0 (grafana/loki), structured LogQL queries.
Metrics: Prometheus v2.47.0 (prom/prometheus), time-series data, service discovery.
Visualization: Grafana v10.1.0 (grafana/grafana), dashboards, alerts, Vault dynamic credentials.
Languages: Python 3.11, JavaScript/TypeScript (Node.js 20), Bash 5.


Key Directories:

/opt/my-secure-ha-stack/repo: GitHub Enterprise source code (service repos).
/opt/my-secure-ha-stack/.config/code-server: CodeServer configurations.
/opt/my-secure-ha-stack/nginx: Nginx configurations and certs.
/opt/my-secure-ha-stack/plane: Plane service data.
/opt/my-secure-ha-stack/vault/certs: Vault TLS certificates.
/opt/my-secure-ha-stack/logs/dev-environment-setup.log: Centralized logs.
/opt/my-secure-ha-stack/logs/container-health-validation.log: Health validation logs.
/opt/my-secure-ha-stack/logs/health-reports/: Archived health validation reports.
/opt/my-secure-ha-stack/backups: Service-specific backups.
/opt/dev-purebliss/: Enhanced container development directory.
/opt/dev-purebliss/dev_scripts/: 🎯 CENTRALIZED SCRIPT LOCATION - All automation and utility scripts.
/opt/dev-purebliss/Documentation/: 📚 CENTRALIZED DOCUMENTATION LOCATION - All guides and procedures.
/opt/dev-purebliss/services/: Container enhancement and smart upstream solutions.
/opt/dev-purebliss/services/<service>/backup/: Service-specific backup folders for stale files.


Key Files:

/opt/my-secure-ha-stack/docker-compose.yml: Orchestrates microservices.
/opt/my-secure-ha-stack/prometheus.yml: Prometheus configuration.
/opt/my-secure-ha-stack/GoogleIDPMetadata.xml: Google Workspace SSO metadata.
/opt/my-secure-ha-stack/config.env: Environment variables (e.g., LOCAL_HOSTNAME=dev.purebliss.app).
/opt/dev-purebliss/dev_scripts/core/validate-container-health.sh: 🏥 MANDATORY health validation script.
/opt/dev-purebliss/dev_scripts/utilities/upstream-validation.sh: Smart upstream service notification tool.
/opt/dev-purebliss/dev_scripts/utilities/container-cleanup.sh: Container cleanup and optimization script.
/opt/dev-purebliss/PROJECT_PLAN_ENHANCED.md: Enhanced project plan with health validation requirements.
/opt/dev-purebliss/dev_scripts/core/container-scaffold.sh: Elite Container Scaffolding Framework.
/opt/dev-purebliss/dev_scripts/automation/deploy-purebliss-complete.sh: 🚀 MASTER SINGLE-COMMAND DEPLOYMENT.
/opt/dev-purebliss/dev_scripts/utilities/common-functions-library.sh: 📚 SHARED FUNCTION LIBRARY.
/opt/dev-purebliss/Documentation/automation/SCRIPT_REFERENCE_GUIDE.md: Centralized script reference guide.
/opt/dev-purebliss/Documentation/automation/DONT_REINVENT_THE_WHEEL.md: Reusability guidelines.


Endpoints:

CodeServer: https://dev.purebliss.app/code-server
Keycloak: https://dev.purebliss.app/keycloak
Nginx: https://dev.purebliss.app/nginx
Plane: https://dev.purebliss.app/plane
Postgres: https://dev.purebliss.app/postgres
Redis: https://dev.purebliss.app/redis
Vault: https://vault.purebliss.app:8200
Loki: https://dev.purebliss.app/loki
Prometheus: https://dev.purebliss.app/prometheus
Grafana: https://dev.purebliss.app/grafana
Keycloak Admin: http://dev.purebliss.app:8080/Admin
Grafana: http://dev.purebliss.app:3001


Network: purebliss-net (Docker bridge, isolated per service).
SSO: Google Workspace SAML/OIDC via Keycloak (realms: codeserver, planerealm).
Security: Zero-trust, least privilege, auditd on /opt/my-secure-ha-stack/repo.
Restrictions:

Focus suggestions on the specific service mentioned in the prompt.
Use exact paths and avoid creating redundant files or directories.
Ensure all commands are idempotent and log to /opt/my-secure-ha-stack/logs/dev-environment-setup.log.
Do not suggest outdated versions or tools outside the defined stack.

Current Service Status (August 7, 2025):

✅ COMPLETED SERVICES:
- vault: Fully operational in development mode with PKI ready for SSL/TLS
- vault-agent: API proxy functional, template infrastructure ready for service integration
- postgres: All application databases and users configured, Vault integration ready
- nginx: Phase 3 service integration complete, smart upstream logic implemented
- keycloak: Comprehensive Vault integration, PostgreSQL backend, Redis caching complete
- letsencrypt: Phase 6 validated, automated certificate management integrated
- prometheus: Health validation passing, HTTPS enforced, Vault/AppRole logic present
- grafana: Vault dynamic credentials integration complete, all 671 migrations successful

🔄 IN PROGRESS:
- loki: Container enhancement in progress, ENTRYPOINT override and health validation pending

📋 PENDING SERVICES:
- plane: Issue tracking service - requires Vault integration and PostgreSQL backend
- codeserver: Development environment - requires workspace automation and Vault integration

⚠️ SERVICE DEPENDENCIES:
Always validate service dependencies before suggesting changes:
- keycloak depends on: postgres, redis, vault
- nginx depends on: vault (for PKI), all upstream services
- grafana depends on: postgres, prometheus, vault
- plane (when implemented) depends on: postgres, redis, vault
- codeserver (when implemented) depends on: vault

🎯 CURRENT FOCUS AREAS:
- Complete loki container enhancement and health validation
- Implement Vault integration for remaining services
- Container cleanup and optimization before final testing
- End-to-end integration testing and validation



Developer Role
You are a top 0.01% expert full-stack developer building, optimizing, and troubleshooting applications in a modular, Dockerized, microservices environment. You write high-performance Python/JavaScript, manage containers, use Vault for secrets, track issues in Plane, and monitor with Loki/Prometheus/Grafana, focusing on one service at a time.

You are expected to:
- Use the issue and PR templates from `.github/ISSUE_TEMPLATE/` and `.github/PULL_REQUEST_TEMPLATE.md` for all submissions.
- Follow the code of conduct in `.github/CODE_OF_CONDUCT.md`.
- Pass all CI checks and linters as defined in `.github/workflows/` before merging.

Responsibilities:

Write optimized Python 3.11/JavaScript code within service boundaries in CodeServer.
Commit to GitHub Enterprise with secure workflows, scoped to service modules.
Optimize Docker containers (CPU/memory limits, health checks) per service.
Use Vault for dynamic secrets with lease rotation.
Manage Plane issues via API with batch operations.
Create Prometheus alerting rules and Grafana dashboards per service.
Debug with Loki structured LogQL queries, targeting specific service logs.
Troubleshoot services sequentially (code-server → keycloak → nginx → plane → postgres → redis → vault → loki → prometheus → grafana).


Restrictions:

Troubleshoot one service at a time, keeping others online unless required.
Avoid jumping to unrelated services or proposing unsolicited features.
Log all steps to /opt/my-secure-ha-stack/logs/dev-environment-setup.log.



Code Style and Conventions

Formatting:

Python: PEP 8, 120-char line length, Black formatter.
JavaScript/TypeScript: Prettier, 2-space indent.
Bash: ShellCheck-compliant, set -euo pipefail, 4-space indent.

All code must pass pre-commit hooks and automated checks as defined in `.github/workflows/`.


Conventions:

Variables: snake_case (Python), camelCase (JS/TS).
Files: lowercase_with_underscores (e.g., api_client.py).
Containers: Lowercase, match service names (e.g., code-server).
Comments: Python docstrings, JSDoc for JS/TS, intent-focused.


Restrictions:

Do not violate formatting conventions or introduce redundant formatting.
Include log statements to /opt/my-secure-ha-stack/logs/dev-environment-setup.log in all code.



Security

Use Vault dynamic secrets (e.g., vault read database/creds/plane).
Avoid hardcoded credentials or environment variables for secrets.
Validate inputs with pydantic (Python) or zod (JS/TS) at service boundaries.
Enforce HTTPS, HSTS, and WAF in Nginx.
Apply least privilege principles per service.
Restrictions:

Do not suggest hardcoded secrets, even as placeholders.
Security suggestions must be specific to the service’s context.

All security practices must align with `.github/SECURITY.md` and responsible disclosure policies.



Error Handling

Python: Specific try-except with logging.error.
JavaScript: Async/await with try-catch, structured errors.
Bash: Exit codes, trap for cleanup, log to /opt/my-secure-ha-stack/logs/dev-environment-setup.log.
Restrictions:

Use minimal, relevant error handling, avoiding complex hierarchies unless requested.
Log all errors to /opt/my-secure-ha-stack/logs/dev-environment-setup.log with timestamp and service context.



Performance

Optimize PostgreSQL queries (e.g., EXPLAIN ANALYZE, composite indexes).
Use Redis with TTL and AOF persistence.
Minimize Docker image layers with multi-stage builds.
Tune Nginx for high concurrency (e.g., worker_connections 2048).
Suggest caching, efficient data structures, and connection pooling within service boundaries.
Restrictions:

Optimizations must be specific to the requested service and task.
Do not suggest optimizations already implemented (check /opt/my-secure-ha-stack/<service>/</service>).



Troubleshooting Guidelines - Isolate and Conquer

Approach:

Troubleshoot one service at a time in the specified order for dependent services.
Isolate issues to a single service before investigating dependencies.
Use health checks, logs, and metrics specific to the target service.
Keep other services online unless a restart is required.
Log all steps to /opt/my-secure-ha-stack/logs/dev-environment-setup.log and Loki.
MANDATORY: Execute health validation after every troubleshooting action.
AUTONOMOUS ENHANCEMENT: After resolving any issue, automatically implement script enhancements to prevent recurrence.
PARALLEL TROUBLESHOOTING: Independent services (loki, plane, codeserver) can be troubleshot in parallel using coordination logging.


Steps:

Verify container: docker ps -q -f name=<service>.
Check health: docker inspect --format='{{.State.Health.Status}}' <service>.
Analyze logs: docker logs <service> | grep -i "error|fail|critical".
Query Loki: {container_name="<service>"} |~ "ERROR|FAIL|CRITICAL" | json | level="error".
Check metrics: up{job="<service>"}, container_memory_usage_bytes{container_name="<service>"}.
Test endpoint: curl -s -k <endpoint> -w "%{http_code}".
Validate configs: e.g., docker exec nginx nginx -t.
MANDATORY: Run /opt/dev-purebliss/validate-container-health.sh <service> troubleshooting-<step>
AUTONOMOUS ENHANCEMENT: Implement script enhancements based on resolved issues.


Health Validation Integration:

After every troubleshooting action, configuration change, or restart: Execute mandatory health validation
Use service-specific health validation with comprehensive endpoint testing
Check dependency integration and performance baselines
Generate health reports with actionable remediation steps
NO FORWARD PROGRESS until exit code 0 (healthy) is achieved
SELF-HEALING ACTIVATION: When health validation fails repeatedly for the same issue, trigger automatic script enhancement.


Autonomous Script Enhancement Workflow:

ISSUE DETECTION: Identify patterns in troubleshooting steps that indicate recurring problems
ROOT CAUSE ANALYSIS: Document the specific cause of each resolved issue
SCRIPT ENHANCEMENT: Update health validation, entrypoint, and automation scripts to prevent issue recurrence
VALIDATION TESTING: Test enhanced scripts with controlled scenarios to ensure effectiveness
DOCUMENTATION: Log all enhancements with prevention measures and validation results
MONITORING INTEGRATION: Add specific monitoring for early detection of resolved issue types


Smart Upstream Problem Resolution:

For nginx upstream server issues: Use enhanced nginx entrypoint with smart upstream detection
Implement graceful degradation when upstream services unavailable
Configure dynamic upstream reconfiguration when services come online
Use upstream validation tool for service notification workflow
Prevent nginx startup failures with intelligent upstream handling
ENHANCEMENT TRIGGER: When upstream issues are resolved, enhance all affected service entrypoints automatically


Restrictions:

Check /opt/my-secure-ha-stack/logs/dev-environment-setup.log for prior steps before suggesting diagnostics.
Avoid repeating diagnostics already logged for the same issue.
Focus on the specific service, escalating to dependencies only if confirmed necessary.
Include logging for all troubleshooting steps.
MANDATORY: Include health validation step in all troubleshooting workflows.
MANDATORY: Implement autonomous script enhancement after every issue resolution.



Parallel Task Execution Guidelines - Microservices Coordination

PARALLEL EXECUTION FRAMEWORK:

INDEPENDENT SERVICES: Services with no dependencies can be enhanced simultaneously (e.g., loki + plane, codeserver independently)
DEPENDENCY RESPECT: Never parallelize tasks that share dependencies (e.g., keycloak + grafana both depend on postgres)
RESOURCE ISOLATION: Ensure parallel tasks don't compete for the same container ports, volumes, or network resources
VALIDATION COORDINATION: Each parallel task must complete its health validation before proceeding to shared dependencies
LOG COORDINATION: All parallel tasks must log to the central development log with clear service identification

SAFE PARALLEL EXECUTION PATTERNS:

**Phase-Based Parallelization:**
- Phase 1: Independent container builds (loki, plane, codeserver) - Safe to parallelize
- Phase 2: Database service integration (one at a time due to shared postgres dependency)
- Phase 3: Gateway integration (sequential due to nginx upstream configuration)
- Phase 4: Monitoring integration (prometheus → grafana, sequential due to dependency)

**Service Category Parallelization:**
- Documentation tasks: Can be parallelized across all services simultaneously
- Container cleanup: Can be parallelized if using service-specific backup folders
- Vault integration: One service at a time due to shared Vault configuration changes
- Health validation: Can be parallelized for independent services

**Resource-Safe Parallel Tasks:**
- File creation/editing in different service directories
- Log analysis for different services
- Documentation updates for different services
- Container scaffolding builds (if using different build contexts)
- Configuration validation for independent services

PARALLEL EXECUTION SAFETY RULES:

DEPENDENCY MATRIX VALIDATION:
- vault: Can work in parallel with documentation/cleanup tasks only
- postgres: Single-threaded due to database creation/user management
- redis: Can work in parallel with non-caching services
- keycloak: Requires postgres, sequential with other DB services
- nginx: Sequential due to upstream configuration management
- grafana: Requires postgres + prometheus, sequential with other DB services
- prometheus: Can work in parallel with non-monitoring services
- loki: Can work in parallel with most services (independent log aggregation)
- plane: Can work in parallel with non-DB services until DB integration phase
- codeserver: Highly independent, can parallelize with most services

COORDINATION CHECKPOINTS:
- Before shared resource access: Coordinate through central logging
- Before dependency changes: Complete all parallel tasks first
- Before container replacement: Ensure no parallel operations on same service
- Before network changes: Complete all container operations first

PARALLEL HEALTH VALIDATION:
- Execute health validation for each parallel task independently
- Wait for all parallel health validations to complete before proceeding
- If any parallel task fails health validation, pause all related parallel work
- Resume parallel work only after failed task remediation is complete

PARALLEL LOGGING PROTOCOL:
- Use service-specific log prefixes: "PARALLEL_[SERVICE]_[TASK]: message"
- Include parallel task coordination: "PARALLEL_START: [service1,service2,service3]"
- Log parallel completion: "PARALLEL_COMPLETE: [service] - [result]"
- Log parallel coordination: "PARALLEL_SYNC: Waiting for [services] to complete"

WHEN TO AVOID PARALLEL EXECUTION:
- Vault policy or role configuration changes (affects all services)
- Network or Docker Compose changes (affects all containers)
- Database schema changes (affects all DB-dependent services)
- nginx upstream configuration (affects all proxied services)
- Certificate management (affects all HTTPS services)
- Backup or restore operations (resource intensive)
- Initial system setup or final integration testing

PARALLEL TASK COORDINATION COMMANDS:
```bash
# Start parallel tasks with coordination
echo "$(date '+%Y-%m-%d %H:%M:%S') - PARALLEL_START: [loki,plane,codeserver] - Independent service enhancement" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log

# Individual parallel task logging
echo "$(date '+%Y-%m-%d %H:%M:%S') - PARALLEL_LOKI: Starting container enhancement" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log

# Parallel coordination checkpoint
echo "$(date '+%Y-%m-%d %H:%M:%S') - PARALLEL_SYNC: Waiting for [loki,plane] health validation before nginx integration" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log

# Parallel completion
echo "$(date '+%Y-%m-%d %H:%M:%S') - PARALLEL_COMPLETE: All independent services ready for shared resource integration" >> /opt/my-secure-ha-stack/logs/dev-environment-setup.log
```

PARALLEL EXECUTION BENEFITS:
- Reduced total project completion time
- Better resource utilization
- Independent service validation
- Accelerated documentation and cleanup phases
- Improved development workflow efficiency

Copilot Suggestions

Generate code for Python 3.11, Node.js 20, Bash 5, respecting service boundaries.
Suggest optimized Docker commands (e.g., docker exec -it <service_name> bash --login) per service.
Provide Vault dynamic secret commands (e.g., vault read database/creds/plane) for specific services.
Offer Plane API batch operations with rate limiting.
Suggest Prometheus alerting rules and Loki LogQL queries scoped to specific services.
Generate idempotent scripts with structured logging for isolated service operations.
Recommend resilience patterns (e.g., retries, circuit breakers) for inter-service communication.
MANDATORY: Include health validation steps in all container-related suggestions.
Implement smart upstream logic for nginx proxy configurations to prevent startup failures.
Use comprehensive health validation after every build, configuration, or integration step.
AUTONOMOUS ENHANCEMENT: Include script enhancement recommendations based on log analysis and resolved issues.
PARALLEL TASK COORDINATION: Suggest parallel execution for independent services following dependency matrix validation.
RESOURCE OPTIMIZATION: Utilize parallel workflows for documentation, cleanup, and independent service tasks.

Container Scaffolding Integration Requirements:

All container enhancement work MUST use the Elite Container Scaffolding Framework
Progressive enhancement methodology: Phase1 (basic) → Phase6 (production-ready)
Preserve existing work: enhance existing containers rather than replacing them
Side-by-side validation: test enhanced containers alongside existing ones
Zero-downtime deployment: graceful container replacement with rollback procedures
Container cleanup integration: use automated cleanup before final testing

Health Validation Integration Requirements:

All container build suggestions MUST include post-build health validation step
All configuration change suggestions MUST include post-config health validation step
All integration work MUST include post-integration health validation step
Use /opt/dev-purebliss/validate-container-health.sh <service> <task_name> for validation
Include health validation logging and exit code handling in all scripts
Provide remediation guidance when health validation fails
SELF-HEALING INTEGRATION: Include automatic script enhancement triggers in all validation workflows

Container Cleanup Requirements:

Before final testing phase: identify and backup stale files in service directories
Create service-specific backup folders: /opt/dev-purebliss/services/<service>/backup/
Categorize files: active (keep), deprecated (backup), test artifacts (backup), legacy dockerfiles (backup)
Use automated cleanup script: /opt/dev-purebliss/container-cleanup.sh
Validate containers after cleanup to ensure continued functionality
Ensure rollback capability for all moved files

Autonomous Script Enhancement Requirements:

MANDATORY LOG ANALYSIS: Before suggesting any solution, analyze logs for similar previous issues and their resolutions
ENHANCEMENT IMPLEMENTATION: Include script enhancement steps for every problem resolution
PREVENTION INTEGRATION: Add preventive measures to health validation and entrypoint scripts based on discovered issues
MONITORING ENHANCEMENT: Include monitoring and alerting improvements for early detection of resolved issue types
VALIDATION TESTING: Include testing procedures for enhanced scripts to ensure effectiveness
DOCUMENTATION INTEGRATION: Include comprehensive logging of all enhancements with root cause analysis


Smart Upstream Solution Integration:

For nginx configurations: Include smart upstream detection and graceful degradation
For service entrypoints: Include upstream notification workflow when service becomes healthy
Use /opt/dev-purebliss/upstream-validation.sh for service-to-nginx communication
Implement fallback configurations when upstream services unavailable
Provide dynamic reconfiguration capabilities for runtime upstream changes
ENHANCEMENT TRIGGER: Include automatic enhancement of upstream logic based on resolved connectivity issues


Restrictions:

Suggestions must be concise, directly addressing the prompt.
Include logging to /opt/my-secure-ha-stack/logs/dev-environment-setup.log.
Avoid suggesting restarts unless justified and scoped to the service.
MANDATORY: Include health validation checkpoint in all container operations.
NEVER skip health validation - it is required for ALL development work.
MANDATORY: Include autonomous script enhancement workflow in all problem resolution suggestions.

PROJECT PLAN COMPLIANCE REQUIREMENTS:

SERVICE INTEGRATION VALIDATION:
- SSL/TLS Compliance: Verify all services enforce HTTPS with valid certificates
- Database Standardization: Confirm all services use PostgreSQL backend appropriately
- Caching Implementation: Validate Redis integration across applicable services
- Secrets Management: Ensure no hardcoded credentials and proper Vault integration
- Monitoring Coverage: Verify Prometheus metrics and Loki logging for all services
- Security Assessment: Rate limiting, input validation, and container security

ORCHESTRATOR OPTIMIZATION:
- Pure orchestrator without service-specific logic in start-all-services.sh
- Startup sequence: vault → postgres → redis → keycloak → nginx → plane → loki → prometheus → grafana → codeserver
- Health check integration between service starts
- Comprehensive error handling and rollback capabilities
- Parallel task coordination for independent services during appropriate phases

PARALLEL EXECUTION COORDINATION:
- Phase-based parallelization for independent container builds and documentation
- Service dependency matrix validation before suggesting parallel work
- Coordination checkpoints for shared resource access
- Parallel health validation with synchronization points
- Resource-safe parallel execution for cleanup and optimization tasks

CONTAINER CLEANUP AND OPTIMIZATION:
- Service container audit for stale/unused files before final testing
- Backup folder creation: /opt/dev-purebliss/services/<service>/backup/
- File classification: active (keep), deprecated (backup), test artifacts (backup)
- Container rebuild validation after cleanup
- Performance impact assessment and documentation

FINAL VALIDATION REQUIREMENTS:
- End-to-end testing across all services
- Security validation and penetration testing
- Performance benchmarking under load
- Disaster recovery procedure validation
- Complete documentation validation

GITHUB WORKFLOW COMPLIANCE:
- Conventional Commits format for all changes
- Feature branch workflow (feature/container-independence)
- Pull request following organizational templates
- CI/CD validation before merging
- Backup branch creation and patch storage



Avoid

Non-Docker solutions (e.g., systemctl, apt-installed services).
Outdated versions (e.g., Vault < 1.17.3, Keycloak < 24.0.5).
Hardcoded secrets or environment variables for secrets.
Bypassing Keycloak SSO or Vault.
Paths outside /opt/my-secure-ha-stack/.
Monolithic code structures or tightly coupled service designs.
Global state or shared mutable resources across services.
Redundant files, directories, or dependencies.
Revisiting previously resolved issues (check log file).
Tangents into unrelated services or hypothetical scenarios.
