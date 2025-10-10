# Local Minikube Tekton

This repository contains a Tekton pipeline for running E2E Cypress tests locally using Minikube.

## Overview

The project sets up a local Tekton pipeline environment to test the learning-resources application with E2E tests. The testing environment uses:

- **git-clone task**: Clones the learning-resources repository
- **learning-resources sidecar**: Runs the application with developer changes
- **frontend-proxy sidecar**: Provides proxy access to resources from the stage environment
- **Cypress**: Executes E2E tests against the running application

## Architecture

The Tekton pipeline (`e2e_pipeline.yaml`) orchestrates:

1. **fetch-source**: Clones the source repository using the git-clone task
2. **e2e-test-run**: Executes the e2e-task which:
   - Runs Cypress tests from the cloned source
   - Uses sidecars:
     - `frontend-dev-proxy`: Proxies stage environment resources
     - `run-learning-resources`: Runs the application from SOURCE_ARTIFACT image

## Files

- `e2e_pipeline.yaml`: Tekton Pipeline definition
- `e2e_pipeline_run.yaml`: PipelineRun instance with specific parameters
- `e2e_task.yaml`: Tekton Task definition for E2E testing
- `start.sh`: Initializes Minikube with podman driver and installs Tekton
- `run.sh`: Applies the pipeline/pipelinerun and displays logs

## Prerequisites

- Minikube
- Podman (used as minikube driver)
- kubectl
- tkn (Tekton CLI)

## Getting Started

1. Start Minikube and install Tekton:
   ```bash
   ./start.sh
   ```

2. Run the E2E task:
   ```bash
   ./run.sh
   ```

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

### Volume Mounts

The e2e-task uses `/var/workdir` as an emptyDir volume shared between:
- The Cypress test step
- The frontend-dev-proxy sidecar
- The run-learning-resources sidecar

## Important Notes

### Minikube Disk Space

Minikube's default disk size (20GB) may be insufficient. Start Minikube with increased disk space:

```bash
minikube delete
minikube start --driver=podman --disk-size=40g
```

### Cypress Configuration

The Cypress step runs as non-root user (1001) and reinstalls Cypress on each run to ensure proper permissions. The test script:
- Installs Cypress binary
- Runs tests from `/workspace/output` (the cloned source)
- Uses the `cypress.config.ts` from the repository
