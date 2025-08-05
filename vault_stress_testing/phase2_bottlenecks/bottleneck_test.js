import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Trend, Rate } from 'k6/metrics';

// ============================================================================
// Phase 2: Bottleneck Identification Test Scenario
//
// This script is designed to find the weakest link in the Vault stack by
// running targeted, high-concurrency stress tests against individual components.
// Each scenario can be run independently.
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
  scenarios: {
    // Scenario 1: Overwhelm the KV secrets engine
    kv_stress: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '10s', target: 200 }, // Ramp up to 200 VUs
        { duration: '40s', target: 200 }, // Hold at 200 VUs
        { duration: '10s', target: 0 },   // Ramp down
      ],
      exec: 'kv_test',
      tags: { test_type: 'bottleneck_kv' },
      env: { VAULT_ADDR: VAULT_ADDR, VAULT_TOKEN: VAULT_TOKEN },
    },
    // Scenario 2: Overwhelm the Database secrets engine
    db_creds_stress: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '10s', target: 150 }, // Ramp up to 150 VUs
        { duration: '40s', target: 150 }, // Hold at 150 VUs
        { duration: '10s', target: 0 },   // Ramp down
      ],
      exec: 'db_creds_test',
      tags: { test_type: 'bottleneck_db' },
      env: { VAULT_ADDR: VAULT_ADDR, VAULT_TOKEN: VAULT_TOKEN },
    },
    // Scenario 3: Overwhelm the OIDC auth method
    oidc_stress: {
        executor: 'ramping-vus',
        startVUs: 0,
        stages: [
          { duration: '10s', target: 100 }, // Ramp up to 100 VUs
          { duration: '40s', target: 100 }, // Hold at 100 VUs
          { duration: '10s', target: 0 },   // Ramp down
        ],
        exec: 'oidc_test',
        tags: { test_type: 'bottleneck_oidc' },
        env: { VAULT_ADDR: VAULT_ADDR, VAULT_TOKEN: VAULT_TOKEN },
      },
  },
  thresholds: {
    'http_req_failed': ['rate<0.02'], // Allow slightly higher error rate for stress tests
    'http_req_duration': ['p(95)<1500'],
  },
};

const params = {
  headers: {
    'X-Vault-Token': VAULT_TOKEN,
    'Content-Type': 'application/json',
  },
};

// Function for KV Stress Test
export function kv_test() {
  const writePath = `secret/data/k6-stress/user-${__VU}`;
  const writePayload = JSON.stringify({ data: { value: `stress-secret-${__ITER}` } });
  const writeRes = http.post(`${VAULT_ADDR}/v1/${writePath}`, writePayload, params);
  
  check(writeRes, { 'KV write successful': (r) => r.status === 200 });
  kvWriteLatency.add(writeRes.timings.duration);
  errorRate.add(writeRes.status >= 400);
  sleep(0.2);

  const readRes = http.get(`${VAULT_ADDR}/v1/${writePath}`, params);
  check(readRes, { 'KV read successful': (r) => r.status === 200 });
  kvReadLatency.add(readRes.timings.duration);
  errorRate.add(readRes.status >= 400);
}

// Function for DB Credentials Stress Test
export function db_creds_test() {
  const dbPath = 'database/creds/postgres-role';
  const dbRes = http.get(`${VAULT_ADDR}/v1/${dbPath}`, params);

  check(dbRes, { 'DB creds generation successful': (r) => r.status === 200 });
  dbCredsLatency.add(dbRes.timings.duration);
  errorRate.add(dbRes.status >= 400);
  sleep(0.5);
}

// Function for OIDC Login Stress Test
export function oidc_test() {
  const oidcLoginPath = 'auth/oidc/login';
  const oidcPayload = JSON.stringify({ role: 'keycloak-role', jwt: 'placeholder-jwt' });
  const oidcRes = http.post(`${VAULT_ADDR}/v1/${oidcLoginPath}`, oidcPayload, { headers: { 'Content-Type': 'application/json' } });

  check(oidcRes, { 'OIDC login endpoint is responsive': (r) => r.status === 400 });
  oidcLoginLatency.add(oidcRes.timings.duration);
  errorRate.add(oidcRes.status >= 500);
  sleep(0.5);
}
