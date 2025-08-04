# Vault config for self-signed TLS
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
