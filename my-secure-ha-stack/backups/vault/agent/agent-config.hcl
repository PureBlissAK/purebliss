auto_auth {
  method "token_file" {
    config = {
      token_file_path = "/opt/my-secure-ha-stack/secrets/vault_token"
    }
  }
  sink "file" {
    config = {
      path = "/vault/unseal/vault_token"
    }
  }
}

listener "tcp" {
  address     = "0.0.0.0:8201"
  tls_disable = "true"
}

unseal {
  method "file" {
    config {
      path = "/vault/unseal/unseal_key.json"
    }
  }
}
