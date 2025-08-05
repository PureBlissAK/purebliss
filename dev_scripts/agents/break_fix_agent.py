"""
break_fix_agent.py - Vault Secrets Holistic Check & Remediation Agent

This agent audits all Pure Bliss microservices for proper Vault dynamic secret usage, logs findings to the break-fix log, and attempts minimal, non-disruptive remediation if issues are found.

- Scans for hardcoded secrets in config/env files and code.
- Verifies Vault Agent sidecar/config per service.
- Checks Vault token/lease status for each service.
- Logs all actions to /opt/my-secure-ha-stack/logs/reports/break_fix_report.md.
- Suggests or applies minimal fixes (e.g., restart vault-agent, rotate lease, alert on hardcoded secret).

Usage: python break_fix_agent.py
"""
import os
import re
import logging
from datetime import datetime

LOG_PATH = "/opt/my-secure-ha-stack/logs/reports/break_fix_report.md"
SERVICES = [
    "codeserver", "keycloak", "nginx", "plane", "postgres", "redis", "vault", "loki", "prometheus", "grafana"
]
VAULT_AGENT_PATH = "/opt/dev-purebliss/dev_scripts/services/vault-agent/"
VAULT_TOKEN_PATH = "/opt/my-secure-ha-stack/secrets/vault_token"

logging.basicConfig(filename=LOG_PATH, level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')

def log(msg):
    print(msg)
    logging.info(msg)

def scan_for_hardcoded_secrets():
    """Scan for hardcoded secrets in env/config/code files."""
    findings = []
    secret_patterns = [r'password\s*=\s*.+', r'secret(_key)?\s*=\s*.+', r'VAULT_TOKEN\s*=\s*.+', r'api_key\s*=\s*.+']
    for root, dirs, files in os.walk("/opt/my-secure-ha-stack/repo"):
        for file in files:
            if file.endswith(('.env', '.json', '.js', '.ts', '.py', '.php', '.yml', '.yaml', '.conf')):
                path = os.path.join(root, file)
                try:
                    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                        for i, line in enumerate(f, 1):
                            for pat in secret_patterns:
                                if re.search(pat, line, re.IGNORECASE):
                                    findings.append(f"[HARD-CODED SECRET] {path}:{i}: {line.strip()}")
                except Exception as e:
                    log(f"[ERROR] Could not scan {path}: {e}")
    return findings

def check_vault_agent_running(service):
    """Check if vault-agent is running for a service."""
    result = os.system(f"docker ps -q -f name={service}-vault-agent > /dev/null")
    return result == 0

def check_vault_token():
    """Check if Vault token exists and is valid."""
    if not os.path.exists(VAULT_TOKEN_PATH):
        return False, "Vault token file missing."
    try:
        with open(VAULT_TOKEN_PATH) as f:
            token = f.read().strip()
        if not token or len(token) < 10:
            return False, "Vault token appears invalid or empty."
        # Optionally, check token validity with vault CLI
        status = os.system(f"vault token lookup {token} > /dev/null 2>&1")
        if status != 0:
            return False, "Vault token is invalid or expired."
        return True, "Vault token is valid."
    except Exception as e:
        return False, f"Error reading Vault token: {e}"

def check_vault_lease(service):
    """Check if Vault lease is valid for a service."""
    # This is a placeholder; real check would use vault CLI or API
    lease_path = f"/opt/my-secure-ha-stack/repo/{service}/vault_lease.info"
    if os.path.exists(lease_path):
        with open(lease_path) as f:
            lease = f.read().strip()
        if lease:
            return True, f"Lease found for {service}."
        else:
            return False, f"Lease file for {service} is empty."
    else:
        return False, f"Lease file for {service} not found."


def unseal_vault_with_tmux_orchestrator():
    """
    Use tmux-orchestrator integration to automate Vault unseal via tmux pane.
    Logs all actions and errors to the break-fix log.
    """
    log("[tmux-orchestrator] Starting Vault unseal automation...")
    unseal_keys_path = "/opt/my-secure-ha-stack/vault-unseal-keys.env"
    if not os.path.exists(unseal_keys_path):
        log(f"[ERROR] Unseal keys file not found: {unseal_keys_path}")
        return False
    with open(unseal_keys_path) as f:
        keys = [line.strip() for line in f if line.strip() and not line.startswith('#')]
    if not keys:
        log("[ERROR] No unseal keys found in file.")
        return False
    # Compose tmux command sequence
    for idx, key in enumerate(keys[:3]):
        cmd = f"curl --request PUT --data '{{\"key\": \"{key}\"}}' http://dev.purebliss.app:18200/v1/sys/unseal"
        tmux_cmd = f"tmux send-keys -t orchestrator '{cmd}' C-m"
        result = os.system(tmux_cmd)
        if result != 0:
            log(f"[ERROR] Failed to send unseal command {idx+1} to tmux orchestrator.")
            return False
        log(f"[tmux-orchestrator] Sent unseal key {idx+1} to Vault via tmux.")
    log("[tmux-orchestrator] All unseal keys sent. Verifying Vault status...")
    # Check sealed status
    status_cmd = "curl -s http://dev.purebliss.app:18200/v1/sys/health | grep 'sealed'"
    tmux_status_cmd = f"tmux send-keys -t orchestrator '{status_cmd}' C-m"
    os.system(tmux_status_cmd)
    log("[tmux-orchestrator] Vault unseal automation complete. Check orchestrator pane for output.")
    return True


def process_service(service):
    log(f"\n[PROCESSING] Service: {service}")
    agent_ok = check_vault_agent_running(service)
    log(f"Vault Agent for {service}: {'RUNNING' if agent_ok else 'NOT RUNNING'}")
    lease_ok, lease_msg = check_vault_lease(service)
    log(f"Vault Lease for {service}: {lease_msg}")
    if not agent_ok:
        log(f"[FIX] Suggest restarting vault-agent for {service}.")
        return False
    if not lease_ok:
        log(f"[FIX] Suggest renewing Vault lease for {service}.")
        return False
    # Optionally, add more per-service health checks here
    log(f"[SUCCESS] {service} passed Vault agent and lease checks.")
    return True

def main():
    log(f"\n# Vault Secrets Holistic Check - {datetime.now().isoformat()}\n")
    # 1. Scan for hardcoded secrets
    findings = scan_for_hardcoded_secrets()
    if findings:
        log("## Hardcoded Secrets Detected:")
        for f in findings:
            log(f)
    else:
        log("No hardcoded secrets found in code/configs.")
    # 2. Vault unseal via tmux orchestrator if sealed
    try:
        import requests
        resp = requests.get("http://dev.purebliss.app:18200/v1/sys/health", timeout=3)
        if resp.ok and resp.json().get("sealed"):
            log("[INFO] Vault is sealed. Attempting unseal via tmux orchestrator...")
            unseal_vault_with_tmux_orchestrator()
        else:
            log("[INFO] Vault is already unsealed.")
    except Exception as e:
        log(f"[ERROR] Could not check Vault sealed status: {e}")
    # 3. Check Vault token
    token_ok, token_msg = check_vault_token()
    log(f"Vault Token: {token_msg}")
    if not token_ok:
        log("[FIX] Vault token needs to be replaced or renewed.")
    # 4. Process each service one at a time, stopping if a service fails
    for svc in SERVICES:
        ok = process_service(svc)
        if not ok:
            log(f"[STOP] Halting further checks until {svc} is fixed.")
            break
    if findings:
        log("[ACTION REQUIRED] Remove hardcoded secrets and use Vault dynamic secrets.")
    log("\n--- End of Vault Secrets Holistic Check ---\n")

if __name__ == "__main__":
    main()
