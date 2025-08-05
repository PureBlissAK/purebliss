#!/bin/bash
set -euo pipefail
LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
NON_COMPLIANT=(codeserver frontend-metro frontend-mock-api frontend-static frontend-test loki)

onboard_to_vault() {
  local cname="$1"
  echo "[$(date)] INFO: Starting Vault onboarding for $cname" | tee -a "$LOG_FILE"
  # 1. Detect secrets (example: SSL certs, passwords)
  docker exec "$cname" env | grep -iE 'SECRET|PASSWORD|TOKEN|KEY|CERT' | tee -a "$LOG_FILE" || true
  # 2. Attempt to inject Vault Agent config if not present
  if ! docker exec "$cname" env | grep -qi vault; then
    echo "[$(date)] ACTION: Injecting Vault Agent sidecar/config for $cname" | tee -a "$LOG_FILE"
    # Example: create a /vault/config/agent.hcl if not present (customize per service)
    docker exec "$cname" mkdir -p /vault/config || true
    cat <<EOF | docker exec -i "$cname" tee /vault/config/agent.hcl > /dev/null
pid_file = "/tmp/vault-agent.pid"
auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path = "/vault/role_id"
      secret_id_file_path = "/vault/secret_id"
    }
  }
  sink "file" {
    config = {
      path = "/vault/token"
    }
  }
}
EOF
    # Optionally start Vault Agent (requires agent binary in container)
    if docker exec "$cname" which vault > /dev/null 2>&1; then
      docker exec -d "$cname" vault agent -config=/vault/config/agent.hcl || true
      echo "[$(date)] INFO: Vault Agent started in $cname" | tee -a "$LOG_FILE"
    else
      echo "[$(date)] WARNING: Vault binary not found in $cname. Manual agent install required." | tee -a "$LOG_FILE"
    fi
  fi
  # 3. Validate Vault integration
  if docker exec "$cname" env | grep -qi vault; then
    echo "[$(date)] SUCCESS: $cname now using Vault for secrets." | tee -a "$LOG_FILE"
  else
    echo "[$(date)] WARNING: $cname still not using Vault for secrets. Manual intervention may be required." | tee -a "$LOG_FILE"
  fi
  echo "[$(date)] INFO: Completed Vault onboarding for $cname" | tee -a "$LOG_FILE"
}

for cname in "${NON_COMPLIANT[@]}"; do
  onboard_to_vault "$cname"
done
