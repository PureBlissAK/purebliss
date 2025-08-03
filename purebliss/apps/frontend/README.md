
# Pure Bliss Frontend

This is the React Native 0.75 + TypeScript frontend for the Pure Bliss Elite Social Media Technology Stack.

## 🚀 Run in Docker (Recommended)

All frontend development should be done inside the provided Docker container for consistency and isolation.

### 1. Build and Start the Container
```bash
docker compose up --build
```

- Metro bundler will be available on port 8081.
- Code changes on the host are reflected in the container via volume mounts.

### 2. Install Dependencies (if needed)
```bash
docker compose exec frontend npm install
```

### 3. Run Metro Bundler
Metro starts automatically. To restart:
```bash
docker compose restart frontend
```

### 4. Run on Device/Emulator
- For Android: Connect your device/emulator to the container network and run:
  ```bash
  npx react-native run-android
  ```
- For iOS: Use a Mac-based runner or CI for iOS builds.

## Local Development (Not Recommended)
If you must run locally (not recommended):
```bash
npm install
npm start
```

## Directory Structure
...existing code...

## Security & Compliance
- OIDC auth via Keycloak
- Secure storage for tokens
- Input validation everywhere
- 99.999% uptime, GDPR/CCPA ready

## Contact
For architecture or security questions, see `/opt/dev-purebliss/orchestrator/projects/frontend-specification.md`.
