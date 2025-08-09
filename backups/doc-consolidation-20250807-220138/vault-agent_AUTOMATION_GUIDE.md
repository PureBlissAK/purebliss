# Vault Agent Automation Guide

## Overview

The Vault Agent service provides API proxy functionality and template rendering capabilities for the PureBliss development environment. It acts as an intermediary between other services and the main Vault server, enabling secure credential management and automatic secret injection.

## Architecture

### Container Details
- **Container Name:** `purebliss-vault-agent`
- **Base Image:** `hashicorp/vault:1.17.3`
- **Exposed Ports:** `8100` (API proxy)
- **Dependencies:** `purebliss-vault` (Vault server)

### Key Features
1. **API Proxy:** Forwards requests to Vault server
2. **Template Rendering:** Generates configuration files with secrets
3. **Health Monitoring:** Built-in health checks
4. **Development Mode:** Simplified configuration for development

## Configuration

### Main Configuration File
Location: `/opt/dev-purebliss/services/vault-agent/config.hcl`

Key configuration sections:
- **Cache:** Performance optimization
- **Listener:** API proxy configuration (port 8100)
- **Vault:** Connection to main Vault server
- **Templates:** Secret injection into configuration files

### Environment Variables
- `VAULT_ADDR`: Vault server address (default: `http://purebliss-vault:8200`)
- `VAULT_SKIP_VERIFY`: Skip TLS verification (development mode)

## Directory Structure

```
/opt/dev-purebliss/services/vault-agent/
├── config.hcl                    # Main configuration
├── entrypoint.sh                 # Container startup script
├── vault-agent-docker-compose.yml # Docker Compose configuration
├── vault-agent-dockerfile        # Container build configuration
├── templates/                    # Template files for secret injection
│   ├── database-config.tpl      # Database credential template
│   ├── keycloak-env.tpl         # Keycloak environment template
│   └── nginx-config.tpl         # Nginx configuration template
├── output/                      # Generated configuration files
└── logs/                       # Agent logs
```

## Operations

### Starting the Service
```bash
cd /opt/dev-purebliss/services/vault-agent
docker compose -f vault-agent-docker-compose.yml up -d
```

### Stopping the Service
```bash
cd /opt/dev-purebliss/services/vault-agent
docker compose -f vault-agent-docker-compose.yml down
```

### Health Check
```bash
# Check container status
docker ps --filter "name=purebliss-vault-agent"

# Test API proxy functionality
curl -s http://localhost:8100/v1/sys/health | jq .

# Check agent logs
docker logs purebliss-vault-agent
```

### Template Testing
```bash
# Check if templates are being rendered
ls -la /opt/dev-purebliss/services/vault-agent/output/

# View specific rendered template
cat /opt/dev-purebliss/services/vault-agent/output/database-config.json
```

## Integration Points

### Service Dependencies
1. **Vault Server:** Must be running and healthy before starting agent
2. **Network:** Uses `purebliss-net` Docker network

### Services Using Agent
- **Database Services:** PostgreSQL credential management
- **Authentication:** Keycloak configuration
- **Gateway:** Nginx SSL certificate management

## Monitoring

### Health Endpoint
- **URL:** `http://localhost:8100/v1/sys/health`
- **Method:** GET
- **Expected Status:** 200 OK with Vault health information

### Log Monitoring
```bash
# Follow agent logs
docker logs -f purebliss-vault-agent

# Check specific log file
tail -f /opt/dev-purebliss/services/vault-agent/logs/vault-agent.log
```

## Security Considerations

### Development Mode
- Uses HTTP connection to Vault (TLS disabled)
- No authentication required for API proxy
- Template rendering without AppRole authentication

### Production Recommendations
- Enable TLS for all communications
- Implement AppRole authentication
- Secure template output permissions
- Enable audit logging

## Troubleshooting

### Common Issues

1. **Agent Won't Start**
   - Verify Vault server is running: `docker ps | grep purebliss-vault`
   - Check network connectivity: `docker network ls | grep purebliss-net`
   - Review configuration: `docker logs purebliss-vault-agent`

2. **API Proxy Not Working**
   - Test Vault connectivity: `curl http://localhost:8200/v1/sys/health`
   - Verify agent port: `netstat -tlnp | grep 8100`
   - Check firewall rules

3. **Templates Not Rendering**
   - Verify template syntax in `/vault/templates/`
   - Check Vault authentication and permissions
   - Review agent logs for template errors

### Log Analysis
```bash
# Check for specific errors
docker logs purebliss-vault-agent 2>&1 | grep -i error

# Monitor template rendering
docker logs purebliss-vault-agent 2>&1 | grep -i template
```

## Maintenance

### Backup Considerations
- Configuration files: `config.hcl`, templates
- Generated outputs should be ephemeral
- No persistent data to backup

### Updates
1. Update base image version in Dockerfile
2. Rebuild container: `docker compose build`
3. Restart service: `docker compose up -d`

## Development Notes

### Current Status
- ✅ API proxy functionality working
- ✅ Health checks passing
- ✅ Container independence achieved
- ⚠️ Template rendering requires authentication setup
- ✅ Proper logging and monitoring

### Future Enhancements
- Implement AppRole authentication for production
- Add more sophisticated template examples
- Integrate with other service entrypoints
- Add automated testing for template rendering
