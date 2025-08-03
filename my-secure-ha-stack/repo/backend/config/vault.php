<?php
// config/vault.php

return [
    'url' => env('VAULT_URL', 'https://vault.purebliss.app:8200'),
    'token' => env('VAULT_TOKEN'),
    'database_creds_path' => env('VAULT_DB_CREDS_PATH', 'database/creds/backend'),
    'keycloak_creds_path' => env('VAULT_KEYCLOAK_CREDS_PATH', 'keycloak/creds/backend'),
];
