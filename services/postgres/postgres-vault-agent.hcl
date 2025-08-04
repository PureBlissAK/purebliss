# Vault Agent config for Postgres dynamic secrets
pid_file = "/tmp/postgres-vault-agent.pid"

vault {
  address = "https://vault:8200"
  tls_skip_verify = true
}

auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path = "/vault/approle/role_id"
      secret_id_file_path = "/vault/approle/secret_id"
    }
  }
  sink "file" {
    config = {
      path = "/vault/approle/postgres_token"
    }
  }
}

template {
  source      = "/vault/approle/postgres-creds.tpl"
  destination = "/vault/approle/postgres-creds.env"
}
