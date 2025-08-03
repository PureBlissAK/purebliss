# Pure Bliss Backend Service (Laravel 11)

## Overview

This service provides the production-ready Laravel 11 API backend for Pure Bliss, running in a secure, containerized environment. All development, build, and runtime actions must be performed inside the backend container.

## Key Features

- PHP 8.3 (FPM, Alpine)
- PostgreSQL 16 and Redis 7 integration
- Sanctum + Keycloak OIDC authentication
- Multi-level Redis caching
- API Gateway via Nginx
- Vault for dynamic secrets
- 90%+ PHPUnit test coverage
- Automated CI/CD pipeline

## Usage

### Build and Run (Development)

```bash
docker compose -f docker-compose.backend.yml up --build
```

### Shell Access

```bash
docker exec -it backend bash
```

### Run Tests

```bash
docker exec backend vendor/bin/phpunit
```

## Security

- All secrets are managed via Vault and never stored in the image or codebase.
- The container runs as a non-root user (appuser:1001).
- Health checks and resource limits are enforced.

## Logs

- Application logs: `/var/www/storage/logs/`
- All troubleshooting steps must be logged to `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`.

## Compliance

- Follows Pure Bliss modular microservices and security standards.
