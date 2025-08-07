import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Trend, Rate } from 'k6/metrics';

// ============================================================================
// Phase 3: Resilience and Chaos Test Scenario
//
// This script generates a constant, moderate background load against the
// Vault stack. It is intended to run for an extended period while chaos
// experiments are manually performed (e.g., killing containers,
// introducing network latency).
//
// The goal is to observe how the system behaves and recovers from failures
// while under a normal operational load.
// ============================================================================

// Custom Metrics
const kvReadLatency = new Trend('vault_kv_read_latency');
const kvWriteLatency = new Trend('vault_kv_write_latency');
const dbCredsLatency = new Trend('vault_db_creds_latency');
const errorRate = new Rate('vault_error_rate');

// Test Configuration
const VAULT_ADDR = __ENV.VAULT_ADDR || 'http://127.0.0.1:8200';
const VAULT_TOKEN = __ENV.VAULT_TOKEN || 'dev-root-token-purebliss';

export const options = {
  scenarios: {
    constant_load: {
      executor: 'constant-vus',
      vus: 50,        // A steady-state of 50 virtual users
      duration: '10m', // Run for 10 minutes, long enough for chaos experiments
    },
  },
  thresholds: {
    // During chaos tests, we expect some errors, but we want to see recovery.
    // A high failure rate for an extended period would be a problem.
    'http_req_failed': ['rate<0.1'], // http errors should be less than 10%
  },
};

const params = {
  headers: {
    'X-Vault-Token': VAULT_TOKEN,
    'Content-Type': 'application/json',
  },
  // Set a timeout to avoid requests hanging indefinitely if a service is down
  timeout: '10s',
};

export default function () {
  group('KV Secret Operations (Resilience)', function () {
    const writePath = `secret/data/k6-resilience/user-${__VU}`;
    const writePayload = JSON.stringify({ data: { value: `resilience-secret-${__ITER}` } });
    const writeRes = http.post(`${VAULT_ADDR}/v1/${writePath}`, writePayload, params);

    const writeSuccess = check(writeRes, { 'KV write successful': (r) => r.status === 200 }, { test_type: 'kv_write' });
    kvWriteLatency.add(writeRes.timings.duration);
    errorRate.add(!writeSuccess);

    sleep(1);

    const readRes = http.get(`${VAULT_ADDR}/v1/${writePath}`, params);
    const readSuccess = check(readRes, { 'KV read successful': (r) => r.status === 200 }, { test_type: 'kv_read' });
    kvReadLatency.add(readRes.timings.duration);
    errorRate.add(!readSuccess);
  });

  sleep(2);

  group('Dynamic PostgreSQL Credentials (Resilience)', function () {
    const dbPath = 'database/creds/postgres-role';
    const dbRes = http.get(`${VAULT_ADDR}/v1/${dbPath}`, params);

    const dbSuccess = check(dbRes, { 'DB creds generation successful': (r) => r.status === 200 }, { test_type: 'db_creds' });
    dbCredsLatency.add(dbRes.timings.duration);
    errorRate.add(!dbSuccess);
  });

  sleep(2);
}
