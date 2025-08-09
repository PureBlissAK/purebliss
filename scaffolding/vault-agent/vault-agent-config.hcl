# Vault Agent configuration for LetsEncrypt PKI integration (AppRole auth)
auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path   = "/vault/approle/role_id"
      secret_id_file_path = "/vault/approle/secret_id"
      remove_secret_id_file_after_reading = false
    }
  }
  sink "file" {
    config = {
      path = "/vault/token-output/vault-agent-token"
    }
  }
}

vault {
  address = "http://purebliss-vault:8200"
}

cache {
  use_auto_auth_token = true
}

listener "tcp" {
  address     = "0.0.0.0:8201"
  tls_disable = true
}

pid_file = "/tmp/vault-agent.pid"
