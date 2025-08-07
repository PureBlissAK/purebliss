# Break-Fix Report: Redis Container Logging and Independence

## Issue Description

The Redis container failed to start independently due to issues with creating and writing to the centralized log file at `/opt/my-secure-ha-stack/logs/dev-environment-setup.log`. The container's user (`redis`) lacked permissions to create the directory or the file, causing the entrypoint script to fail.

## Troubleshooting Steps

1. **Initial Startup Failure:** `docker run purebliss-redis-image` failed.
2. **Log Inspection:** `docker logs` showed `tee: /opt/my-secure-ha-stack/logs/dev-environment-setup.log: No such file or directory`.
3. **Interactive Debugging:** Ran `docker run --entrypoint bash ...` to inspect the container's environment. Confirmed that the `/opt/my-secure-ha-stack/logs` directory did not exist from within the container's context.
4. **Permissions Check:** `id` command inside the container showed `uid=999(redis) gid=1000(redis)`. The host directory `/opt/my-secure-ha-stack/logs` had different ownership.
5. **Volume Mount Test:** Attempted to run the container with `-v /opt/my-secure-ha-stack/logs:/opt/my-secure-ha-stack/logs`, which would have solved the problem but would violate the container independence principle.

## Resolution

The `entrypoint.sh` script was refactored to be more resilient and adhere to container independence principles.

1. **Fallback Logging:** Implemented a `log_msg` function that attempts to write to the primary log file. If it fails (due to permissions or non-existence), it falls back to a local log file at `/tmp/redis-entrypoint.log`. This ensures the container can always log its startup sequence.
2. **Error-Tolerant Directory Creation:** Modified the log directory creation logic to be error-tolerant (`mkdir -p "$LOG_DIR" 2>/dev/null || ...`). If directory creation fails, it logs the warning to the fallback log and continues.
3. **Simplified Logging Calls:** Replaced all `echo ... | tee -a "$LOG_FILE"` calls with the new `log_msg` function.

## Impact on Build Process

- The `Dockerfile` was not changed.
- The `entrypoint.sh` script is now more robust and guarantees the container can start even if the external log directory is not available, which is critical for independent testing and operation.

## Validation

1. **Rebuilt Image:** `docker build -t purebliss-redis-image .`
2. **Standalone Run:** `docker run -d --name purebliss-redis purebliss-redis-image` started successfully.
3. **Log Verification:** `docker logs purebliss-redis` showed the container started successfully, with warnings about the log file being unwritable, and then the Redis server startup messages.
4. **Health Check:** `docker exec purebliss-redis redis-cli ping` returned `PONG`.

## References

- Commit: `fix(redis): implement fallback logging for container independence`
- Plane Issue: N/A
