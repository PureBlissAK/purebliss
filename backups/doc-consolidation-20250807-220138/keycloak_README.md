# Keycloak Vault PostgreSQL Integration

Comprehensive Keycloak service with Vault secrets management and PostgreSQL database integration for the PureBliss development environment.

## Overview

This enhanced Keycloak service provides:
- **Vault Integration**: Automatic secrets retrieval from HashiCorp Vault
- **PostgreSQL Integration**: Dedicated database with automatic setup
- **Production-Ready**: Health checks, monitoring, and management scripts
- **Security**: Least-privilege access with Vault policies and AppRoles

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Keycloak      │    │     Vault       │    │   PostgreSQL    │
│   Container     │◄──►│   Secrets       │    │   Database      │
│                 │    │   Management    │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Docker        │
                    │   Network       │
                    │   purebliss-net │
                    └─────────────────┘
```

## Files Structure

```
/opt/dev-purebliss/services/keycloak/
├── .env                                    # Environment configuration
├── keycloak-vault-entrypoint.sh          # Enhanced entrypoint with Vault integration
├── keycloak-vault-docker-compose.yml     # Docker Compose with Vault support
├── setup-keycloak-vault.sh               # Complete setup script
├── validate-keycloak-vault.sh            # Comprehensive validation tests
├── README.md                              # This documentation
├── start-keycloak.sh                      # Start service (created by setup)
├── stop-keycloak.sh                       # Stop service (created by setup)
├── status-keycloak.sh                     # Status check (created by setup)
├── logs-keycloak.sh                       # View logs (created by setup)
└── vault/                                 # Vault-specific configurations
    └── approle-credentials                # AppRole credentials (created by setup)
```

## Quick Start

### 1. Setup (One-time)

```bash
# Navigate to Keycloak directory
cd /opt/dev-purebliss/services/keycloak

# Run comprehensive setup
./setup-keycloak-vault.sh
```

### 2. Start Keycloak

```bash
# Start the service
./start-keycloak.sh

# Check status
./status-keycloak.sh

# View logs
./logs-keycloak.sh
```

### 3. Access Keycloak

- **User Portal**: http://dev.purebliss.app:8080/auth
- **Admin Console**: http://dev.purebliss.app:8080/auth/admin
- **Health Check**: http://dev.purebliss.app:8080/auth/health

## Configuration

### Environment Variables

The `.env` file contains all configuration options:

```bash
# Vault Configuration
VAULT_ADDR=http://purebliss-vault:8200      # Vault server address
VAULT_TOKEN=                                # Vault authentication token

# PostgreSQL Configuration
POSTGRES_HOST=purebliss-postgres            # Database host
POSTGRES_PORT=5432                          # Database port
KEYCLOAK_DB_NAME=keycloak                   # Keycloak database name
KEYCLOAK_DB_USER=keycloak                   # Keycloak database user

# Keycloak Server Configuration
KC_HOSTNAME=dev.purebliss.app               # Public hostname
KC_PROXY=edge                               # Proxy mode
KC_HTTP_RELATIVE_PATH=/auth                 # Base path
KC_START_MODE=start-dev                     # Start mode (start-dev or start)
```

### Vault Secrets

The service automatically manages these secrets in Vault:

#### Database Credentials (`secret/keycloak/database`)
```json
{
  "username": "keycloak",
  "password": "generated_secure_password",
  "database": "keycloak",
  "host": "purebliss-postgres",
  "port": "5432"
}
```

#### Admin Credentials (`secret/keycloak/admin`)
```json
{
  "username": "admin",
  "password": "generated_secure_password",
  "realm": "master"
}
```

## Vault Integration Details

### Authentication Flow

1. **Token Detection**: Entrypoint tries multiple token sources:
   - `VAULT_TOKEN` environment variable
   - `/opt/my-secure-ha-stack/secrets/vault_token` file
   - Root token from vault initialization

2. **Vault Health Check**: Verifies Vault accessibility and unsealed status

3. **Secret Retrieval**: Fetches Keycloak credentials from Vault KV store

4. **Fallback**: Uses environment defaults if Vault unavailable

### Vault Policies

The setup creates a dedicated policy for Keycloak:

```hcl
# Keycloak secrets access
path "secret/data/keycloak/*" {
    capabilities = ["read"]
}

# Database credentials access
path "database/creds/keycloak" {
    capabilities = ["read"]
}
```

### AppRole Authentication

For production use, AppRole credentials are generated:
- **Role ID**: Stored in `vault/approle-credentials`
- **Secret ID**: Automatically rotated
- **Policies**: Limited to Keycloak-specific secrets

## PostgreSQL Integration

### Database Setup

The service automatically:
1. **Creates Database**: `keycloak` database if it doesn't exist
2. **Creates User**: Dedicated `keycloak` user with appropriate permissions
3. **Configures Access**: Grants all privileges on the Keycloak database
4. **Tests Connection**: Validates connectivity before starting Keycloak

### Connection Configuration

Database connection is configured via JDBC URL:
```
jdbc:postgresql://purebliss-postgres:5432/keycloak
```

## Health Checks & Monitoring

### Health Endpoints

- **General Health**: `/auth/health`
- **Readiness**: `/auth/health/ready`
- **Liveness**: `/auth/health/live`

### Docker Health Check

```yaml
healthcheck:
  test: ["CMD-SHELL", "curl -f http://localhost:8080/auth/health/ready || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 10
  start_period: 120s
```

### Monitoring Integration

The service includes labels for monitoring integration:
- Traefik routing configuration
- Prometheus metrics exposure
- Service discovery labels

## Management Scripts

### start-keycloak.sh
Starts the Keycloak service using Docker Compose.

### stop-keycloak.sh
Gracefully stops the Keycloak service.

### status-keycloak.sh
Comprehensive status check including:
- Container status
- Health endpoint validation
- Database connectivity
- Recent log analysis

### logs-keycloak.sh
Real-time log viewing with `docker logs -f`.

### validate-keycloak-vault.sh
Comprehensive validation suite with 10 test categories:
1. Container Status
2. Health Endpoints
3. Admin Console Access
4. Database Connectivity
5. Vault Connectivity
6. Vault Secrets Access
7. Container Logs Analysis
8. Admin Authentication
9. Performance Metrics
10. Configuration Validation

## Security Features

### Network Security
- Isolated Docker network (`purebliss-net`)
- No host network access
- Controlled port exposure

### Vault Security
- Least-privilege access policies
- AppRole-based authentication
- Automatic secret rotation support
- Secure token handling

### Database Security
- Dedicated database user
- Limited database permissions
- Encrypted connections (when configured)
- Password complexity enforcement

## Troubleshooting

### Common Issues

#### 1. Vault Connection Failed
```bash
# Check Vault status
curl http://purebliss-vault:8200/v1/sys/health

# Verify token
echo $VAULT_TOKEN

# Check network connectivity
docker network inspect purebliss-net
```

#### 2. Database Connection Failed
```bash
# Test PostgreSQL connectivity
docker exec -it purebliss-postgres psql -U postgres -l

# Check Keycloak database
docker exec -it purebliss-postgres psql -U keycloak -d keycloak -c "SELECT 1;"
```

#### 3. Admin Login Failed
```bash
# Get admin credentials from Vault
curl -H "X-Vault-Token: $VAULT_TOKEN" \
     http://purebliss-vault:8200/v1/secret/data/keycloak/admin

# Check Keycloak logs
./logs-keycloak.sh
```

### Log Analysis

```bash
# View recent logs
docker logs purebliss-keycloak --tail 50

# Search for specific issues
docker logs purebliss-keycloak 2>&1 | grep -i "error\|exception\|failed"

# Monitor real-time logs
./logs-keycloak.sh
```

### Validation

Run the comprehensive validation suite:

```bash
./validate-keycloak-vault.sh
```

This will test all aspects of the integration and provide a detailed report.

## Integration with Other Services

### Nginx Reverse Proxy
Keycloak is configured to work behind Nginx with:
- Path-based routing (`/auth`)
- SSL termination support
- Proxy headers forwarding

### Vault PKI Integration
For production deployment:
- SSL certificates from Vault PKI
- Automatic certificate renewal
- Secure internal communication

### Monitoring Stack
Integration with:
- **Prometheus**: Metrics collection
- **Grafana**: Dashboard visualization
- **Loki**: Centralized logging

## Production Considerations

### SSL/TLS Configuration
```bash
# Enable HTTPS mode
KC_START_MODE=start
KC_HOSTNAME_STRICT=true
KC_HOSTNAME_STRICT_HTTPS=true
```

### Performance Tuning
```bash
# Clustering configuration
KC_CACHE=ispn
KC_CACHE_STACK=tcp

# JVM tuning
JAVA_OPTS="-Xms512m -Xmx2g"
```

### High Availability
- Multiple Keycloak instances
- Shared database
- Load balancer configuration
- Session replication

## Support

### Logs Location
- Container logs: `docker logs purebliss-keycloak`
- Application logs: `/opt/logs/dev-environment-setup.log`
- Keycloak data: `/mnt/raid0/keycloak/data`

### Configuration Files
- Main config: `.env`
- Docker Compose: `keycloak-vault-docker-compose.yml`
- Entrypoint: `keycloak-vault-entrypoint.sh`

### Vault Secrets Paths
- Database: `secret/keycloak/database`
- Admin: `secret/keycloak/admin`
- AppRole: `auth/approle/role/keycloak`

For additional support, check the main troubleshooting guide at `/opt/.github/copilot-instructions.md`.
