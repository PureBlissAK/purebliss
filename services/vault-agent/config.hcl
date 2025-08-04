# Vault Agent Configuration with AppRole Auto-Authentication
# This configuration enables automatic authentication with Vault using AppRole
# and provides API proxy functionality for other services

# Exit after authentication - set to false to keep agent running
exit_after_auth = false

# PID file for process management
pid_file = "/tmp/vault-agent.pid"

# Auto-authentication configuration using AppRole
auto_auth {
    method "approle" {
        mount_path = "auth/approle"
        config = {
            role_id_file_path   = "/vault/secrets/role_id"
            secret_id_file_path = "/vault/secrets/secret_id"
            remove_secret_id_file_after_reading = false
        }
    }

    sink "file" {
        config = {
            path = "/vault/agent/output/vault-token"
            mode = 0600
        }
    }
}

# Cache configuration for improved performance
cache {
    use_auto_auth_token = true
}

# API proxy configuration for other services to access Vault
listener "tcp" {
    address = "0.0.0.0:8100"
    tls_disable = true
}

# Vault server configuration
vault {
    address = "https://purebliss-vault:8200"
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
