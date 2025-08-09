# Vault Agent configuration for PureBliss development environment
# This configuration sets up Vault Agent as an API proxy with AppRole authentication

pid_file = "/opt/vault-agent/vault-agent.pid"

vault {
  address = "http://purebliss-vault:8200"
}

auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path = "/opt/dev-purebliss/secrets/vault-agent-role-id"
      secret_id_file_path = "/opt/dev-purebliss/secrets/vault-agent-secret-id"
    }
  }

  sink "file" {
    config = {
      path = "/opt/vault-agent/vault-token"
    }
  }
}

cache {
  
}

api_proxy {
  use_auto_auth_token = true
}

listener "tcp" {
  address = "0.0.0.0:8100"
  tls_disable = true
}

template {
  source      = "/opt/vault-agent/templates/nginx-cert.tpl"
  destination = "/opt/vault-agent/certs/nginx.crt"
  command     = "echo 'Certificate updated'"
}

template {
  source      = "/opt/vault-agent/templates/nginx-key.tpl"
  destination = "/opt/vault-agent/certs/nginx.key"
  command     = "echo 'Private key updated'"
}
