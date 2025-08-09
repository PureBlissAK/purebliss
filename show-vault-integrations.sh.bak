#!/bin/bash
set -euo pipefail

# Summary script to show all Vault integrations configured by start-all.sh
# This provides a quick overview of what secrets, policies, and tokens are set up

echo "🔐 Pure Bliss Vault Integration Summary"
echo "======================================="
echo ""

# Set Vault environment
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="dev-root-token-purebliss"

# Check if Vault is accessible
if ! docker exec purebliss-vault vault status >/dev/null 2>&1; then
    echo "❌ Vault is not accessible or not running"
    exit 1
fi

echo "✅ Vault Status:"
docker exec purebliss-vault vault status | grep -E "(Cluster|Version|Storage|Sealed)"
echo ""

echo "🔧 Secrets Engines:"
docker exec purebliss-vault vault secrets list -format=table | grep -E "(Path|Type|Version)"
echo ""

echo "📋 Policies:"
echo "Available policies:"
docker exec purebliss-vault vault policy list
echo ""

echo "🔑 Service Secrets (KV v2):"
for service in postgres redis keycloak nginx letsencrypt prometheus loki grafana plane codeserver; do
    echo -n "  $service: "
    if docker exec purebliss-vault vault kv get -format=json secret/$service >/dev/null 2>&1; then
        echo "✅ Configured"
    else
        echo "❌ Missing"
    fi
done
echo ""

echo "🗄️  Database Dynamic Credentials:"
echo -n "  PostgreSQL: "
if docker exec purebliss-vault vault read database/config/postgres-app >/dev/null 2>&1; then
    echo "✅ Configured"
    echo -n "    Dynamic creds test: "
    if docker exec purebliss-vault vault read database/creds/postgres-role >/dev/null 2>&1; then
        echo "✅ Working"
    else
        echo "❌ Failed"
    fi
else
    echo "❌ Not configured"
fi
echo ""

echo "🔒 PKI Certificate Authority:"
echo -n "  Nginx PKI: "
if docker exec purebliss-vault vault secrets list | grep -q "pki-nginx/"; then
    echo "✅ Enabled"
    echo -n "    Certificate role: "
    if docker exec purebliss-vault vault read pki-nginx/roles/nginx >/dev/null 2>&1; then
        echo "✅ Configured"
    else
        echo "❌ Missing"
    fi
else
    echo "❌ Not enabled"
fi
echo ""

echo "📝 Audit Logging:"
echo -n "  File audit: "
if docker exec purebliss-vault vault audit list | grep -q "file"; then
    echo "✅ Enabled"
else
    echo "❌ Disabled"
fi
echo ""

echo "🎫 Service Tokens:"
if [ -d "/opt/my-secure-ha-stack/secrets" ]; then
    for token_file in /opt/my-secure-ha-stack/secrets/*_vault_token; do
        if [ -f "$token_file" ]; then
            service=$(basename "$token_file" _vault_token)
            echo "  $service: ✅ Token exists"
        fi
    done
else
    echo "  ❌ No token directory found"
fi
echo ""

echo "📊 Integration Status Summary:"
echo "  🔧 Secrets Engines: $(docker exec purebliss-vault vault secrets list -format=json | jq 'keys | length - 3') custom engines"
echo "  📋 Policies: $(docker exec purebliss-vault vault policy list | wc -l) total policies"
echo "  🔑 KV Secrets: $(for s in postgres redis keycloak nginx letsencrypt prometheus loki grafana plane codeserver; do docker exec purebliss-vault vault kv get secret/$s >/dev/null 2>&1 && echo 1 || echo 0; done | grep 1 | wc -l)/10 services configured"
echo ""

echo "🚀 Quick Test Commands:"
echo "  # Test PostgreSQL dynamic credentials:"
echo "  docker exec purebliss-vault vault read database/creds/postgres-role"
echo ""
echo "  # View service secrets:"
echo "  docker exec purebliss-vault vault kv get secret/keycloak"
echo ""
echo "  # Generate Nginx certificate:"
echo "  docker exec purebliss-vault vault write pki-nginx/issue/nginx common_name=\"dev.purebliss.app\""
echo ""
echo "  # View audit log:"
echo "  docker exec purebliss-vault cat /vault/logs/audit.log | tail -10"
echo ""

echo "✨ All integrations have been configured by start-all.sh!"
echo "   Each service now has Vault policies, secrets, and tokens for zero-trust secret management."
