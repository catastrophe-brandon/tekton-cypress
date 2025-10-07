# Local Minikube Tekton

This repository contains Tekton tasks for running E2E Cypress tests locally using Minikube.

## Overview

The project sets up a local Tekton pipeline environment to test the learning-resources application with E2E tests. The testing environment uses:

- **learning-resources container**: Contains the application code with developer changes
- **frontend-proxy sidecar**: Provides proxy access to resources from the stage environment
- **Cypress**: Executes E2E tests against the running application

## Architecture

The Tekton task (`e2e_task.yaml`) orchestrates:

1. **Copy source files**: Extracts application source code from the learning-resources image to a shared volume
2. **Run E2E tests**: Executes Cypress tests from the shared volume against the running application
3. **Sidecars**:
   - `frontend-dev-proxy`: Proxies stage environment resources
   - `run-learning-resources`: Runs the application with developer changes

## Files

- `e2e_task.yaml`: Tekton Task definition for E2E testing
- `e2e_task_run.yaml`: TaskRun instance with specific parameters
- `start.sh`: Initializes Minikube with podman driver and installs Tekton
- `run.sh`: Applies the task/taskrun and displays logs

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

### Task Parameters

- `SOURCE_ARTIFACT`: Container image containing the learning-resources application (default: `quay.io/redhat-services-prod/hcc-platex-services-tenant/learning-resources:latest`)
- `e2e-tests-script`: Shell script that configures and runs Cypress tests

### Volume Mounts

All components share a `/var/workdir` volume where:
- Source files are copied from the learning-resources image
- Cypress configuration is generated
- Tests are executed

## Customization

If your learning-resources image stores files in a non-standard location, update the `copy-source-files` step in `e2e_task.yaml` (line 45) to specify the correct source path.
