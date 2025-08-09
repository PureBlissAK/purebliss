# Auto-auth configuration
auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path = "/vault/agent/role-id"
      secret_id_file_path = "/vault/agent/secret_id"
    }
  }
}

# Cache configuration
cache {
  use_auto_auth_token = true
}

# Listener configuration
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true
}
# Template configuration for certificates and keys
template {
  source      = "/vault-agent/nginx-cert.tpl"
  destination = "/vault-agent/nginx.crt"
}

template {
  source      = "/vault-agent/nginx-key.tpl"
  destination = "/vault-agent/nginx.key"
}

template {
  source      = "/vault-agent/letsencrypt-cert.tpl"
  destination = "/vault-agent/letsencrypt.crt"
}

template {
  source      = "/vault-agent/letsencrypt-key.tpl"
  destination = "/vault-agent/letsencrypt.key"
}

# Vault server configuration
vault {
  address = "http://purebliss-vault:8200"
  tls_skip_verify = true
}
