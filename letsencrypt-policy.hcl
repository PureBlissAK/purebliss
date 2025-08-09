# PKI engine access for certificate operations
path "pki/issue/letsencrypt-role" {
  capabilities = ["create", "update"]
}

path "pki/cert/ca" {
  capabilities = ["read"]
}

path "pki/certs" {
  capabilities = ["list"]
}

# Token self-management
path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
