# Vault Server Configuration
# Development mode with file storage

storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = 1
}

# API address for client connections
api_addr = "http://0.0.0.0:8200"

# Enable UI
ui = true

# Disable mlock for development
disable_mlock = true

# Log level
log_level = "debug"
