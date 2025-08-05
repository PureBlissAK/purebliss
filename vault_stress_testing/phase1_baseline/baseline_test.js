import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Trend, Rate } from 'k6/metrics';

// ============================================================================
// Phase 1: Baseline Performance Test Scenario for Open-Source Vault
//
// This k6 script establishes the baseline performance of the Vault stack.
// It simulates a typical heavy workload, focusing on common operations:
// - KV secret reads/writes
// - Dynamic PostgreSQL credential generation
// - Keycloak OIDC authentication
// ============================================================================

// Custom Metrics
const kvReadLatency = new Trend('vault_kv_read_latency');
const kvWriteLatency = new Trend('vault_kv_write_latency');
const dbCredsLatency = new Trend('vault_db_creds_latency');
const oidcLoginLatency = new Trend('vault_oidc_login_latency');
const errorRate = new Rate('vault_error_rate');

// Test Configuration
const VAULT_ADDR = __ENV.VAULT_ADDR || 'http://127.0.0.1:8200';
const VAULT_TOKEN = __ENV.VAULT_TOKEN || 'dev-root-token-purebliss';

export const options = {
  stages: [
    { duration: '10s', target: 50 },   // Ramp-up to 50 users over 10s
    { duration: '40s', target: 100 },  // Ramp-up to 100 users over 40s
    { duration: '10s', target: 0 },    // Ramp-down to 0 users
  ],
  thresholds: {
    'http_req_failed': ['rate<0.01'], // http errors should be less than 1%
    'http_req_duration': ['p(95)<500'], // 95% of requests should be below 500ms
    'vault_kv_read_latency': ['p(95)<200'],
    'vault_kv_write_latency': ['p(95)<300'],
    'vault_db_creds_latency': ['p(95)<800'],
    'vault_oidc_login_latency': ['p(95)<1000'],
  },
};

const params = {
  headers: {
    'X-Vault-Token': VAULT_TOKEN,
    'Content-Type': 'application/json',
  },
};

export default function () {
  group('KV Secret Operations', function () {
    // Write a secret
    const writePath = `secret/data/k6-test/user-${__VU}`;
    const writePayload = JSON.stringify({ data: { value: `test-secret-${__ITER}` } });
    const writeRes = http.post(`${VAULT_ADDR}/v1/${writePath}`, writePayload, params);
    
    check(writeRes, { 'KV write successful': (r) => r.status === 200 });
    kvWriteLatency.add(writeRes.timings.duration);
    errorRate.add(writeRes.status >= 400);

    sleep(0.5);

    // Read the secret back
    const readRes = http.get(`${VAULT_ADDR}/v1/${writePath}`, params);
    check(readRes, { 'KV read successful': (r) => r.status === 200 });
    kvReadLatency.add(readRes.timings.duration);
    errorRate.add(readRes.status >= 400);
  });

  sleep(1);

  group('Dynamic PostgreSQL Credentials', function () {
    const dbPath = 'database/creds/postgres-role';
    const dbRes = http.get(`${VAULT_ADDR}/v1/${dbPath}`, params);

    check(dbRes, {
      'DB creds generation successful': (r) => r.status === 200,
      'DB creds response contains username': (r) => r.json('data.username') !== undefined,
    });
    dbCredsLatency.add(dbRes.timings.duration);
    errorRate.add(dbRes.status >= 400);
  });

  sleep(1);

  group('Keycloak OIDC Authentication', function () {
    const oidcLoginPath = 'auth/oidc/login';
    const oidcPayload = JSON.stringify({ role: 'keycloak-role', jwt: 'placeholder-jwt' });
    
    const oidcRes = http.post(`${VAULT_ADDR}/v1/${oidcLoginPath}`, oidcPayload, { 
      headers: { 'Content-Type': 'application/json' },
      tags: { name: 'OIDC Login Attempt' },
      // We expect a 400 response, so we tell k6 this is a valid outcome for this request.
      // This prevents it from being counted in the global `http_req_failed` metric.
      expectedStatuses: [400], 
    });

    // Check that we received the expected 400 status.
    check(oidcRes, { 'OIDC login endpoint is responsive and rejects invalid JWT': (r) => r.status === 400 });
    oidcLoginLatency.add(oidcRes.timings.duration);
    // No need to add to the custom errorRate here, as a real 5xx error would be caught by the default http_req_failed metric.
  });

  sleep(1);
}
