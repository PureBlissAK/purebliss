#!/bin/bash
set -euo pipefail
VAULT_ADDR="http://purebliss-vault:8200"
ROLE_NAME="your-approle-name" # TODO: set your AppRole name
ROLE_ID_PATH="/opt/dev-purebliss/services/vault/vault-agent/role-id"
SECRET_ID_PATH="/opt/dev-purebliss/services/vault/vault-agent/secret_id"

# Fetch RoleID
echo "Fetching RoleID for $ROLE_NAME..."
ROLE_ID=$(docker run --rm --network purebliss-net -e VAULT_ADDR=$VAULT_ADDR hashicorp/vault:1.17.3 vault read -field=role_id auth/approle/role/$ROLE_NAME/role-id)
echo "$ROLE_ID" > "$ROLE_ID_PATH"
chmod 600 "$ROLE_ID_PATH"

# Generate SecretID
echo "Generating SecretID for $ROLE_NAME..."
SECRET_ID=$(docker run --rm --network purebliss-net -e VAULT_ADDR=$VAULT_ADDR hashicorp/vault:1.17.3 vault write -f -field=secret_id auth/approle/role/$ROLE_NAME/secret-id)
echo "$SECRET_ID" > "$SECRET_ID_PATH"
chmod 600 "$SECRET_ID_PATH"
echo "AppRole credentials written to $ROLE_ID_PATH and $SECRET_ID_PATH."
