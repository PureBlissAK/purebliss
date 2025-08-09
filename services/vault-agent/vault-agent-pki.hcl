path "auth/approle/login" {
  capabilities = ["create", "read"]
}
path "pki-letsencrypt/*" {
  capabilities = ["read", "list", "create", "update"]
}
