# Local Minikube Tekton

This repository contains a Tekton pipeline for running E2E Playwright tests locally using Minikube.

## Overview

The project sets up a local Tekton pipeline environment to test the learning-resources application with E2E tests. The testing environment uses:

- **git-clone task**: Clones the learning-resources repository
- **learning-resources sidecar**: Runs the application with developer changes
- **frontend-development-proxy sidecar**: Provides proxy access to resources from the stage environment
- **insights-chrome-dev sidecar**: Serves chrome UI static assets locally on port 9912
- **Playwright**: Executes E2E tests against the running application

## Architecture

The Tekton pipeline (`e2e_pipeline.yaml`) orchestrates:

1. **fetch-source**: Clones the source repository using the git-clone task
2. **e2e-test-run**: Executes the e2e-task which:
   - Runs Playwright tests from the cloned source
   - Uses sidecars:
     - `frontend-dev-proxy`: Proxies stage environment resources using custom routes configuration
     - `insights-chrome-dev`: Serves chrome UI assets on port 9912 using Caddy
     - `run-learning-resources`: Runs the application from SOURCE_ARTIFACT image

## Files

### Core Pipeline Files
- `e2e_pipeline.yaml`: Tekton Pipeline definition
- `e2e_pipeline_run.yaml`: PipelineRun instance with specific parameters
- `e2e_task.yaml`: Tekton Task definition for E2E testing

### Configuration Files
- `caddy_config.yaml`: ConfigMap for insights-chrome-dev Caddyfile configuration
- `proxy_routes_config.yaml`: ConfigMap for frontend-development-proxy routes.json configuration

### Scripts
- `start.sh`: Initializes Minikube with podman driver and installs Tekton
- `run_pipeline.sh`: Applies ConfigMaps, pipeline definitions, and displays logs

## Prerequisites

- Minikube
- Podman (used as minikube driver)
- kubectl
- tkn (Tekton CLI)

## Getting Started

1. Set required environment variables:
   ```bash
   export E2E_USER="your-test-username"
   export E2E_PASSWORD="your-test-password"
   export E2E_PROXY_URL="your-proxy-url"
   ```

2. Start Minikube and install Tekton:
   ```bash
   ./start.sh
   ```

3. Run the E2E pipeline:
   ```bash
   ./run_pipeline.sh
   ```

   This script will:
   - Clean up previous pipeline/task runs
   - Apply the Caddy configuration ConfigMap
   - Apply the proxy routes configuration ConfigMap
   - Apply the E2E task and pipeline definitions
   - Start the pipeline run
   - Follow the logs

## Configuration

### Pipeline Parameters

- `branch-name`: Git branch to clone (default: `master`)
- `repo-url`: Repository URL (default: `https://github.com/RedHatInsights/learning-resources.git`)
- `SOURCE_ARTIFACT`: Container image containing the learning-resources application (default: `quay.io/redhat-services-prod/hcc-platex-services-tenant/learning-resources:latest`)
- `E2E_USER`: Username for E2E test authentication
- `E2E_PASSWORD`: Password for E2E test authentication

### Workspaces

- `shared-code-workspace`: PersistentVolumeClaim (2Gi) that persists cloned source code between pipeline tasks
  - Mounted at `/workspace/output` in the git-clone task and e2e-task
  - Uses `volumeClaimTemplate` for automatic PVC creation

### Sidecars Configuration

The e2e-task runs three sidecars alongside the Playwright test step:

1. **frontend-dev-proxy**: Proxies requests to external resources
   - Image: `quay.io/redhat-user-workloads/hcc-platex-services-tenant/frontend-development-proxy:latest`
   - Custom routes defined in `/config/routes.json` (mounted from `proxy_routes_config.yaml`)
   - Routes `/apps/chrome*` to `http://host.docker.internal:9912` with chrome HTML fallback enabled

2. **insights-chrome-dev**: Serves chrome UI static assets
   - Image: `quay.io/redhat-services-prod/hcc-platex-services-tenant/insights-chrome-dev:latest`
   - Runs Caddy web server on port 9912
   - Configuration in `/Caddyfile` (mounted from `caddy_config.yaml`)
   - Serves files from `/opt/app-root/src/build/stable`
   - CORS enabled for cross-origin access

3. **run-learning-resources**: Runs the application under test
   - Image: Specified by `SOURCE_ARTIFACT` parameter
   - Contains the learning-resources application

### Volume Mounts

The e2e-task uses multiple volumes:

- **workdir**: EmptyDir volume (`/var/workdir`) shared between:
  - The Playwright test step
  - All three sidecars

- **chrome-dev-caddyfile**: ConfigMap mounted in insights-chrome-dev sidecar
  - Provides Caddy server configuration at `/Caddyfile`

- **frontend-proxy-routes**: ConfigMap mounted in frontend-dev-proxy sidecar
  - Provides routing configuration at `/config/routes.json`

## Important Notes

### Minikube Disk Space

Minikube's default disk size (20GB) may be insufficient. Start Minikube with increased disk space:

```bash
minikube delete
minikube start --driver=podman --disk-size=40g
```

### Playwright Configuration

The Playwright step:
- Runs as root user (UID 0)
- Uses the image: `quay.io/btweed/playwright_e2e:latest`
- Executes tests from `/workspace/output` (the cloned source)
- Has access to environment variables:
  - `HTTP_PROXY` / `HTTPS_PROXY`: Proxy configuration
  - `E2E_USER` / `E2E_PASSWORD`: Test authentication credentials
  - `NO_PROXY`: Excludes `stage.foo.redhat.com` from proxy
- Resource limits:
  - CPU: 2000m-4000m
  - Memory: 4Gi-8Gi

### Network Architecture

The test environment uses a multi-container setup with the following network flow:

```
Playwright Tests
    ↓
frontend-dev-proxy (routes.json)
    ↓
    ├─→ /apps/chrome* → insights-chrome-dev:9912 (Caddy)
    └─→ Other routes → External stage environment
```

The `host.docker.internal` hostname in the proxy routes allows the frontend-dev-proxy to communicate with the insights-chrome-dev sidecar running in the same pod.
