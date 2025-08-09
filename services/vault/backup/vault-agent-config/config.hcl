# Vault Agent config for development mode (HTTP)
# Compatible with Vault dev mode running on HTTP

pid_file = "/tmp/agent.pid"

vault {
  address = "http://purebliss-vault:8200"
  tls_skip_verify = true
}

# Simple cache configuration - no auto_auth for development mode
cache {
  # use_auto_auth_token should only be specified in api_proxy when both are enabled
}

listener "tcp" {
  address = "127.0.0.1:8100"
  tls_disable = true
}

# API proxy for simplified development access
api_proxy {
  use_auto_auth_token = false
}
