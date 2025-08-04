# Simplified Vault Agent config for development
# Note: Vault server must be initialized and unsealed first

pid_file = "/tmp/agent.pid"

vault {
  address = "https://vault:8200"
  tls_skip_verify = true
}

# Simple cache configuration - no auto_auth for now
cache {
  use_auto_auth_token = false
}

listener "tcp" {
  address = "127.0.0.1:8100"
  tls_disable = true
}
