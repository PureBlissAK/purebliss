pid_file = "/tmp/vault-agent-nginx.pid"
auto_auth {
  method "token_file" {
    config = {
      token_file_path = "/opt/my-secure-ha-stack/secrets/vault_token"
    }
  }
  sink "file" {
    config = {
      path = "/opt/my-secure-ha-stack/vault/agent/nginx-agent-token"
    }
  }
}
template {
  source      = "/opt/my-secure-ha-stack/vault/agent/nginx-creds.ctmpl"
  destination = "/opt/my-secure-ha-stack/vault/agent/nginx-creds.env"
}
