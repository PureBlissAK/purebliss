vault {
  address = "http://vault-dev-letsencrypt:8200"
  retry {
    num_retries = 3
  }
}

auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path = "/vault/config/role_id"
      secret_id_file_path = "/vault/config/secret_id"
    }
  }

  sink "file" {
    config = {
      path = "/vault/token/vault-token"
    }
  }
}

listener "tcp" {
  address = "127.0.0.1:8100"
  tls_disable = true
}

template {
  source = "/vault/templates/cert.tpl"
  destination = "/vault/certs/cert.pem"
  command = "echo 'Certificate updated at $(date)' >> /vault/logs/cert-updates.log"
}

template {
  source = "/vault/templates/key.tpl"
  destination = "/vault/certs/key.pem"
  perms = 0600
  command = "echo 'Private key updated at $(date)' >> /vault/logs/cert-updates.log"
}
