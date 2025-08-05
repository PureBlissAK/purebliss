pid_file = "/tmp/vault-agent-loki.pid"
auto_auth {
  method "token_file" {
    config = {
      token_file_path = "/opt/my-secure-ha-stack/secrets/vault_token"
    }
  }
  sink "file" {
    config = {
      path = "/opt/my-secure-ha-stack/vault/agent/loki-agent-token"
    }
  }
}
template {
  source      = "/opt/my-secure-ha-stack/vault/agent/loki-creds.ctmpl"
  destination = "/opt/my-secure-ha-stack/vault/agent/loki-creds.env"
}
