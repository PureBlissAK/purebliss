# Vault & Pure Bliss Stack: Comprehensive Stress Testing Framework

This repository contains a professional, multi-phase stress testing framework designed to validate the performance, resilience, and operational limits of an open-source Vault deployment and its integrated services (PostgreSQL, Redis, Keycloak, Nginx, etc.).

This framework replaces the previous monolithic bash script with a structured approach using `k6`, a modern, high-performance load testing tool.

## Framework Structure

The framework is organized into three distinct phases, each with a specific objective:

- **/phase1_baseline**: Scripts and scenarios for establishing baseline performance under typical heavy load. This helps define the "green zone" of your system's operational capacity.
- **/phase2_bottlenecks**: Focused tests designed to intentionally push individual components (e.g., Vault's Raft storage, PostgreSQL, Nginx) to their breaking point, allowing for targeted tuning and optimization.
- **/phase3_chaos**: Advanced scenarios for simulating real-world failures (e.g., active node failure, network partitions, backend service outages) to test the HA cluster's resilience and recovery mechanisms.

## Tooling

- **Primary Load Generation Tool**: [k6](https://k6.io/) is used for its high performance, clear reporting, and scriptability in JavaScript.
- **Orchestration**: Each phase includes runner scripts (`.sh`) to configure and execute the `k6` tests.
- **Monitoring**: It is critical to use the existing monitoring stack (Prometheus, Grafana, Loki) to observe the system's behavior during these tests.

## Getting Started

1.  **Install k6**: Run the installation script to prepare the environment for testing.
    ```bash
    bash /opt/vault_stress_testing/install_k6.sh
    ```
2.  **Run a Test**: Navigate to the framework directory and execute a phase's runner script. For example, to run the baseline performance test:
    ```bash
    bash /opt/vault_stress_testing/run_phase1_test.sh
    ```
