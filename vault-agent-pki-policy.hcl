# Vault Agent PKI policy for LetsEncrypt integration
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/revoke-self" {
  capabilities = ["update"]
}

path "pki-letsencrypt/issue/letsencrypt-role" {
  capabilities = ["create", "update"]
}

path "pki-letsencrypt/sign/letsencrypt-role" {
  capabilities = ["create", "update"]
}
