# Phase 2: Bottleneck Identification

This directory contains the k6 test script and runner for Phase 2: Bottleneck Identification.

The objective of this phase is to find the weakest link in the stack by overwhelming individual components with targeted, high-concurrency tests.

- `bottleneck_test.js`: The k6 script containing scenarios to overload KV secrets, dynamic credentials, and OIDC authentication.
- `run_phase2_tests.sh`: The runner script to execute the bottleneck tests.
