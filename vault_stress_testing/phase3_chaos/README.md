# Phase 3: Chaos and Resilience Testing

This directory contains the k6 test script and runbook for Phase 3: Chaos and Resilience Testing.

The objective of this phase is to validate the high-availability and self-healing capabilities of the stack under chaotic conditions. We will simulate real-world failures while the system is under a steady load.

- `resilience_test.js`: A `k6` script that generates a constant, moderate load against the stack. This runs *during* the chaos experiments.
- `chaos_runbook.md`: A step-by-step guide for executing chaos experiments, such as killing containers or introducing network latency. This is a manual guide for the operator.
- `run_resilience_test.sh`: The runner script to start the background load generation.
