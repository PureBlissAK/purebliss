#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=myroot
export VAULT_SKIP_VERIFY=true

# Create policies for each service
vault policy write keycloak-policy - << 'EOL'
path "secret/data/keycloak/*" {
  capabilities = ["read"]
}
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOL

vault policy write nginx-policy - << 'EOL'
path "secret/data/nginx/*" {
  capabilities = ["read"]
}
path "pki/*" {
  capabilities = ["read"]
}
EOL

vault policy write postgres-policy - << 'EOL'
path "secret/data/postgres/*" {
  capabilities = ["read"]
}
EOL

vault policy write redis-policy - << 'EOL'
path "secret/data/redis/*" {
  capabilities = ["read"]
}
EOL

vault policy write grafana-policy - << 'EOL'
path "secret/data/grafana/*" {
  capabilities = ["read"]
}
EOL

vault policy write loki-policy - << 'EOL'
path "secret/data/loki/*" {
  capabilities = ["read"]
}
EOL

vault policy write prometheus-policy - << 'EOL'
path "secret/data/prometheus/*" {
  capabilities = ["read"]
}
EOL

vault policy write plane-policy - << 'EOL'
path "secret/data/plane/*" {
  capabilities = ["read"]
}
EOL

vault policy write codeserver-policy - << 'EOL'
path "secret/data/codeserver/*" {
  capabilities = ["read"]
}
EOL

# Create AppRoles for each service
for service in keycloak nginx postgres redis grafana loki prometheus plane codeserver; do
    echo "Creating AppRole for $service..."
    vault write auth/approle/role/$service \
        token_policies="$service-policy" \
        token_ttl=1h \
        token_max_ttl=4h \
        bind_secret_id=true
    
    # Get role-id and secret-id
    ROLE_ID=$(vault read -field=role_id auth/approle/role/$service/role-id)
    SECRET_ID=$(vault write -field=secret_id auth/approle/role/$service/secret-id)
    
    echo "Service: $service"
    echo "Role ID: $ROLE_ID"
    echo "Secret ID: $SECRET_ID"
    echo "---"
    
    # Store in KV store for the service to retrieve
    vault kv put secret/$service/approle role_id="$ROLE_ID" secret_id="$SECRET_ID"
done

echo "AppRole setup complete!"
vault auth list
vault policy list
