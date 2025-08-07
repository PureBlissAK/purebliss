# Vault Service Best Practices

## Configuration Guidelines

### Environment Variable Standards
- `VAULT_ADDR`: Must use HTTPS in production, HTTP only for development mode
- `VAULT_DEV_MODE`: Set to `true` only for development, `false` for production
- `VAULT_DATA_PATH`: Must point to RAID storage (`/raid-storage/vault/data`)
- `VAULT_LOG_PATH`: Must point to RAID storage (`/raid-storage/logs/vault.log`)

### RAID Storage Requirements
- Data persistence: `/raid-storage/vault/data`
- Log files: `/raid-storage/logs/vault.log`
- TLS certificates: `/raid-storage/vault/tls`
- Backup location: `/raid-storage/backups/vault`

### Security Configuration
- TLS always enabled except in development mode
- Auto-unseal disabled in development (manual unseal required)
- Root token stored securely and rotated regularly
- Audit logging enabled for all production deployments

## Performance Optimization

### Resource Limits and Requests
```yaml
resources:
  limits:
    memory: "512Mi"
    cpu: "500m"
  requests:
    memory: "256Mi"
    cpu: "250m"
```

### Storage Backend
- File storage backend for development
- High-performance storage required for RAID array
- Regular backup and recovery testing

### Caching Strategies
- In-memory secret caching with appropriate TTL
- PKI certificate caching for SSL/TLS operations

## Security Considerations

### Vault Integration Requirements
- AppRole authentication for service-to-service communication
- Dynamic database credentials for PostgreSQL
- PKI engine for certificate management
- Secret engines properly configured with appropriate policies

### TLS/SSL Configuration
- TLS 1.3 minimum for all communications
- Valid certificates from internal PKI or Let's Encrypt
- Certificate rotation automation implemented

### Access Control Standards
- Least privilege principle for all policies
- Service-specific AppRoles with minimal required permissions
- Regular policy auditing and cleanup

## Common Issues & Solutions

### Issue: Vault Sealed State
**Symptoms:** Vault returns 503 errors, services cannot authenticate
**Solution:**
```bash
# Check seal status
vault status
# Unseal if needed (development mode)
vault operator unseal ${VAULT_UNSEAL_KEY_1}
vault operator unseal ${VAULT_UNSEAL_KEY_2}
vault operator unseal ${VAULT_UNSEAL_KEY_3}
```

### Issue: AppRole Authentication Failures
**Symptoms:** Services report 403 errors from Vault
**Solution:**
1. Verify AppRole exists and is enabled
2. Check policy assignments
3. Validate role_id and secret_id

### Issue: PKI Certificate Issues
**Symptoms:** SSL/TLS errors in services
**Solution:**
1. Check PKI engine health
2. Verify certificate validity
3. Regenerate certificates if expired

## Emergency Procedures

### Vault Recovery
1. Stop all dependent services
2. Restore Vault data from RAID backup
3. Initialize and unseal Vault
4. Verify all secrets and engines
5. Restart dependent services

### Security Incident Response
1. Immediately seal Vault if compromise suspected
2. Rotate all AppRole credentials
3. Audit all access logs
4. Generate new root token if needed

## Monitoring & Alerting

### Key Metrics to Monitor
- Vault seal status (should always be unsealed)
- Authentication success/failure rates
- Secret engine health
- Storage backend performance
- Memory and CPU utilization

### Alert Thresholds
- Vault sealed state: Immediate critical alert
- Authentication failure rate > 5%: Warning alert
- Storage usage > 80%: Warning alert
- Memory usage > 90%: Critical alert

### Dashboard Configuration
- Vault health overview
- Authentication metrics
- Secret engine utilization
- Performance metrics
- Error rates and response times

## Development vs Production

### Development Mode
- Single node deployment
- HTTP listener for local access
- File storage backend
- Manual unsealing acceptable
- Simplified logging

### Production Mode
- High availability cluster
- HTTPS only with valid certificates
- Auto-unseal with cloud KMS
- Comprehensive audit logging
- Monitoring and alerting required

## Integration Points

### Services Dependent on Vault
- PostgreSQL (dynamic database credentials)
- Redis (authentication tokens)
- Keycloak (configuration secrets)
- Nginx (TLS certificates)
- All application services (API keys, passwords)

### Backup Dependencies
- RAID storage availability
- Automated backup scripts
- Recovery testing procedures

## Troubleshooting Quick Reference

```bash
# Check Vault status
docker exec purebliss-vault vault status

# View Vault logs
docker logs purebliss-vault

# Test AppRole authentication
vault write auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID"

# List enabled engines
vault secrets list

# Check policy assignments
vault policy list
vault policy read <policy-name>
```
