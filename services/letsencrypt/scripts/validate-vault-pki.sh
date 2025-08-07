#!/bin/bash
# ============================================================================
# Let's Encrypt Vault PKI Integration Validation Script
#
# This script validates the Vault PKI setup for Let's Encrypt certificate generation
# and tests certificate generation functionality.
# ============================================================================

set -euo pipefail

LOG_FILE="/opt/my-secure-ha-stack/logs/dev-environment-setup.log"
PKI_PATH="pki-letsencrypt"
PKI_ROLE="letsencrypt-role"
DOMAIN="dev.purebliss.app"

echo "[$(date)] INFO: Starting Let's Encrypt Vault PKI validation" | tee -a "$LOG_FILE"

# Auto-detect Vault mode and configure
detect_vault_mode() {
  if curl -s "http://127.0.0.1:8200/v1/sys/health" >/dev/null 2>&1; then
    export VAULT_ADDR="http://127.0.0.1:8200"
    export VAULT_TOKEN="dev-root-token-purebliss"
    VAULT_MODE="dev"
    echo "[$(date)] INFO: Detected Vault in development mode" | tee -a "$LOG_FILE"
  elif curl -sk "https://127.0.0.1:8200/v1/sys/health" >/dev/null 2>&1; then
    export VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_SKIP_VERIFY=1
    if [[ -f "/opt/my-secure-ha-stack/secrets/vault_token" ]]; then
      export VAULT_TOKEN=$(cat /opt/my-secure-ha-stack/secrets/vault_token)
    else
      echo "[$(date)] ERROR: Vault token file not found for production mode" | tee -a "$LOG_FILE"
      return 1
    fi
    VAULT_MODE="production"
    echo "[$(date)] INFO: Detected Vault in production mode" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Cannot connect to Vault on HTTP or HTTPS" | tee -a "$LOG_FILE"
    return 1
  fi
  return 0
}

# Test 1: Vault connectivity
test_vault_connectivity() {
  echo "[$(date)] INFO: Testing Vault connectivity..." | tee -a "$LOG_FILE"

  if vault status >/dev/null 2>&1; then
    echo "[$(date)] SUCCESS: Vault is accessible and responding" | tee -a "$LOG_FILE"
    return 0
  else
    echo "[$(date)] ERROR: Cannot connect to Vault" | tee -a "$LOG_FILE"
    return 1
  fi
}

# Test 2: PKI secrets engine validation
test_pki_engine() {
  echo "[$(date)] INFO: Testing PKI secrets engine..." | tee -a "$LOG_FILE"

  if vault secrets list | grep -q "$PKI_PATH"; then
    echo "[$(date)] SUCCESS: PKI engine $PKI_PATH is enabled" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: PKI engine $PKI_PATH is not enabled" | tee -a "$LOG_FILE"
    return 1
  fi

  # Check if root CA exists
  if vault read "$PKI_PATH/cert/ca" >/dev/null 2>&1; then
    echo "[$(date)] SUCCESS: Root CA is configured for $PKI_PATH" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Root CA is not configured for $PKI_PATH" | tee -a "$LOG_FILE"
    return 1
  fi

  return 0
}

# Test 3: PKI role validation
test_pki_role() {
  echo "[$(date)] INFO: Testing PKI role configuration..." | tee -a "$LOG_FILE"

  if vault read "$PKI_PATH/roles/$PKI_ROLE" >/dev/null 2>&1; then
    echo "[$(date)] SUCCESS: PKI role $PKI_ROLE is configured" | tee -a "$LOG_FILE"

    # Display role configuration
    echo "[$(date)] INFO: PKI role configuration:" | tee -a "$LOG_FILE"
    vault read "$PKI_PATH/roles/$PKI_ROLE" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: PKI role $PKI_ROLE is not configured" | tee -a "$LOG_FILE"
    return 1
  fi

  return 0
}

# Test 4: Certificate generation test
test_certificate_generation() {
  echo "[$(date)] INFO: Testing certificate generation..." | tee -a "$LOG_FILE"

  local test_response
  test_response=$(vault write -format=json "$PKI_PATH/issue/$PKI_ROLE" \
    common_name="$DOMAIN" \
    alt_names="*.$DOMAIN" \
    ttl="1h" 2>/dev/null)

  if [[ $? -eq 0 ]] && [[ -n "$test_response" ]]; then
    echo "[$(date)] SUCCESS: Certificate generation test passed" | tee -a "$LOG_FILE"

    # Extract and validate certificate components
    local cert_data=$(echo "$test_response" | jq -r '.data.certificate')
    local private_key=$(echo "$test_response" | jq -r '.data.private_key')
    local ca_chain=$(echo "$test_response" | jq -r '.data.ca_chain[0]')

    if [[ -n "$cert_data" ]] && [[ "$cert_data" != "null" ]]; then
      echo "[$(date)] SUCCESS: Certificate data extracted successfully" | tee -a "$LOG_FILE"

      # Validate certificate using openssl
      if echo "$cert_data" | openssl x509 -noout -text >/dev/null 2>&1; then
        echo "[$(date)] SUCCESS: Generated certificate is valid" | tee -a "$LOG_FILE"

        # Display certificate details
        echo "[$(date)] INFO: Certificate details:" | tee -a "$LOG_FILE"
        echo "$cert_data" | openssl x509 -noout -subject -issuer -dates | tee -a "$LOG_FILE"
      else
        echo "[$(date)] ERROR: Generated certificate is invalid" | tee -a "$LOG_FILE"
        return 1
      fi
    else
      echo "[$(date)] ERROR: Certificate data extraction failed" | tee -a "$LOG_FILE"
      return 1
    fi

    if [[ -n "$private_key" ]] && [[ "$private_key" != "null" ]]; then
      echo "[$(date)] SUCCESS: Private key extracted successfully" | tee -a "$LOG_FILE"
    else
      echo "[$(date)] ERROR: Private key extraction failed" | tee -a "$LOG_FILE"
      return 1
    fi

    if [[ -n "$ca_chain" ]] && [[ "$ca_chain" != "null" ]]; then
      echo "[$(date)] SUCCESS: CA chain extracted successfully" | tee -a "$LOG_FILE"
    else
      echo "[$(date)] ERROR: CA chain extraction failed" | tee -a "$LOG_FILE"
      return 1
    fi

  else
    echo "[$(date)] ERROR: Certificate generation test failed" | tee -a "$LOG_FILE"
    return 1
  fi

  return 0
}

# Test 5: Let's Encrypt container validation
test_letsencrypt_container() {
  echo "[$(date)] INFO: Testing Let's Encrypt container..." | tee -a "$LOG_FILE"

  if docker ps | grep -q "purebliss-letsencrypt"; then
    echo "[$(date)] SUCCESS: Let's Encrypt container is running" | tee -a "$LOG_FILE"

    # Check container health
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' purebliss-letsencrypt 2>/dev/null || echo "no_healthcheck")
    echo "[$(date)] INFO: Container health status: $health_status" | tee -a "$LOG_FILE"

    # Check container logs for Vault PKI activity
    if docker logs purebliss-letsencrypt --tail 20 | grep -q "Vault PKI"; then
      echo "[$(date)] SUCCESS: Container is using Vault PKI for certificate generation" | tee -a "$LOG_FILE"
    else
      echo "[$(date)] WARNING: Container may not be using Vault PKI (check logs)" | tee -a "$LOG_FILE"
    fi

  else
    echo "[$(date)] WARNING: Let's Encrypt container is not running" | tee -a "$LOG_FILE"
    return 1
  fi

  return 0
}

# Test 6: Certificate file validation
test_certificate_files() {
  echo "[$(date)] INFO: Testing generated certificate files..." | tee -a "$LOG_FILE"

  local cert_dir="/mnt/raid0/nginx/certs/live/$DOMAIN"

  # Check if certificate directory exists
  if [[ -d "$cert_dir" ]]; then
    echo "[$(date)] SUCCESS: Certificate directory exists: $cert_dir" | tee -a "$LOG_FILE"

    # Check for required certificate files
    local required_files=("cert.pem" "privkey.pem" "fullchain.pem" "chain.pem")
    local all_files_present=true

    for file in "${required_files[@]}"; do
      if [[ -f "$cert_dir/$file" ]]; then
        echo "[$(date)] SUCCESS: Certificate file exists: $file" | tee -a "$LOG_FILE"

        # Validate certificate file content
        if [[ "$file" == "cert.pem" ]] || [[ "$file" == "fullchain.pem" ]]; then
          if openssl x509 -in "$cert_dir/$file" -noout -text >/dev/null 2>&1; then
            echo "[$(date)] SUCCESS: Certificate file $file is valid" | tee -a "$LOG_FILE"
          else
            echo "[$(date)] ERROR: Certificate file $file is invalid" | tee -a "$LOG_FILE"
            all_files_present=false
          fi
        fi
      else
        echo "[$(date)] ERROR: Certificate file missing: $file" | tee -a "$LOG_FILE"
        all_files_present=false
      fi
    done

    if [[ "$all_files_present" == "true" ]]; then
      echo "[$(date)] SUCCESS: All required certificate files are present and valid" | tee -a "$LOG_FILE"
      return 0
    else
      echo "[$(date)] ERROR: Some certificate files are missing or invalid" | tee -a "$LOG_FILE"
      return 1
    fi

  else
    echo "[$(date)] WARNING: Certificate directory does not exist: $cert_dir" | tee -a "$LOG_FILE"
    return 1
  fi
}

# Main validation function
main() {
  echo "[$(date)] INFO: ============================================" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Let's Encrypt Vault PKI Validation Report" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: ============================================" | tee -a "$LOG_FILE"

  local tests_passed=0
  local tests_total=6

  # Initialize Vault connection
  if detect_vault_mode; then
    echo "[$(date)] SUCCESS: Vault mode detected and configured" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] ERROR: Failed to detect or configure Vault mode" | tee -a "$LOG_FILE"
    exit 1
  fi

  # Run validation tests
  if test_vault_connectivity; then ((tests_passed++)) || true; fi
  if test_pki_engine; then ((tests_passed++)) || true; fi
  if test_pki_role; then ((tests_passed++)) || true; fi
  if test_certificate_generation; then ((tests_passed++)) || true; fi
  if test_letsencrypt_container; then ((tests_passed++)) || true; fi
  if test_certificate_files; then ((tests_passed++)) || true; fi

  # Summary
  echo "[$(date)] INFO: ============================================" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: Validation Summary: $tests_passed/$tests_total tests passed" | tee -a "$LOG_FILE"
  echo "[$(date)] INFO: ============================================" | tee -a "$LOG_FILE"

  if [[ $tests_passed -eq $tests_total ]]; then
    echo "[$(date)] SUCCESS: All validation tests passed! Let's Encrypt Vault PKI integration is working correctly." | tee -a "$LOG_FILE"
    echo ""
    echo "🎉 Let's Encrypt Vault PKI Integration Validation Complete!"
    echo ""
    echo "✅ All tests passed ($tests_passed/$tests_total)"
    echo "✅ Vault PKI engine is properly configured"
    echo "✅ Certificate generation is working"
    echo "✅ Let's Encrypt container is operational"
    echo "✅ Certificate files are valid and accessible"
    echo ""
    echo "The system is ready to generate and manage SSL certificates using Vault PKI!"
    return 0
  else
    echo "[$(date)] ERROR: Some validation tests failed ($tests_passed/$tests_total passed)" | tee -a "$LOG_FILE"
    echo ""
    echo "⚠️  Let's Encrypt Vault PKI Integration Validation Failed"
    echo ""
    echo "❌ $((tests_total - tests_passed)) out of $tests_total tests failed"
    echo "📋 Check the logs for detailed error information:"
    echo "   tail -f $LOG_FILE"
    echo ""
    echo "🔧 Troubleshooting steps:"
    echo "   1. Ensure Vault is running and unsealed"
    echo "   2. Check Vault token permissions"
    echo "   3. Verify PKI engine and role configuration"
    echo "   4. Restart the Let's Encrypt container if needed"
    return 1
  fi
}

# Execute main function
main "$@"
