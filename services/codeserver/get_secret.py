import hvac
import os

vault_addr = os.environ.get("VAULT_ADDR", "http://purebliss-vault:8200")
vault_token = os.environ.get("VAULT_TOKEN")

client = hvac.Client(url=vault_addr, token=vault_token)

try:
    response = client.secrets.kv.v2.read_secret_version(path='codeserver')
    password = response['data']['data']['password']
    os.environ['PASSWORD'] = password
    print("Successfully fetched secret from Vault and set PASSWORD environment variable.")
except Exception as e:
    print(f"Error fetching secret from Vault: {e}")
    exit(1)
