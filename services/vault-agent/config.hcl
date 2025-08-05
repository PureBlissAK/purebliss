# Vault Agent Configuration for Development Mode
# This configuration provides API proxy functionality for other services
# Without AppRole authentication (using dev root token)

# Exit after authentication - set to false to keep agent running
exit_after_auth = false

# PID file for process management
pid_file = "/tmp/vault-agent.pid"

# Cache configuration for improved performance
cache {
    # Don't use auto auth token in dev mode
    use_auto_auth_token = false
}

# API proxy configuration for other services to access Vault
listener "tcp" {
    address = "0.0.0.0:8100"
    tls_disable = true
}

# Vault server configuration - HTTP for dev mode
vault {
    address = "http://purebliss-vault:8200"
    tls_skip_verify = true
}

# Template for database credentials (example)
template {
    source      = "/vault/templates/database-config.tpl"
    destination = "/vault/agent/output/database-config.json"
    perms       = 0600
    command     = "echo 'Database credentials updated'"
}

# Logging configuration
log_level = "info"
