# Vault config for development mode with TLS
# This configuration runs Vault in dev mode for easier testing
storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/vault/certs/selfsigned/fullchain.pem"
  tls_key_file  = "/vault/certs/selfsigned/privkey.pem"
  tls_disable   = 0
}

api_addr = "https://dev.purebliss.app:8200"
ui = true

# Dev mode settings for easier testing
disable_mlock = true
