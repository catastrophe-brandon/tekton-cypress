# Tekton Playwright E2E Testing

A local Tekton pipeline environment for running E2E Playwright tests against the learning-resources application using Minikube.

## Purpose

This project provides a complete local testing environment that mirrors production deployment patterns. It uses Tekton pipelines to orchestrate:

- **Source cloning** from the learning-resources repository
- **Application deployment** using containerized builds
- **E2E test execution** with Playwright in an isolated environment
- **Proxy and asset serving** to simulate production dependencies

The pipeline runs the application with developer changes alongside necessary infrastructure (chrome UI assets, proxy to stage environment) to execute comprehensive E2E tests locally before deployment.

## Quick Start

### Prerequisites

- Minikube
- Podman
- kubectl
- tkn (Tekton CLI)
- envsubst

### Getting Started

1. **Set environment variables**:
   ```bash
   export E2E_USER="your-test-username"
   export E2E_PASSWORD="your-test-password"
   export E2E_PROXY_URL="your-proxy-url"
   ```

2. **Initialize Minikube cluster**:
   ```bash
   ./cluster_setup/start.sh
   ```

3. **Install Tekton**:
   ```bash
   ./cluster_setup/install_tekton.sh
   ```

4. **(Optional) Pre-load images** to avoid Docker Hub rate limiting:
   ```bash
   ./cluster_setup/image_load.sh
   ```

5. **Run the E2E pipeline**:
   ```bash
   ./run_pipeline.sh
   ```

The pipeline will clone the source, deploy the application with sidecars, and execute Playwright tests.

## Project Structure

```
tekton-playwright/
├── cluster_setup/              # Minikube and Tekton initialization
│   ├── start.sh                # Start Minikube (40GB disk, cri-o)
│   ├── install_tekton.sh       # Install Tekton and git-clone task
│   └── image_load.sh           # Pre-load images to avoid rate limits
│
├── playwright_image/           # Custom Playwright test image
│   ├── Dockerfile              # Playwright v1.50.0 + bind9 utilities
│   └── build_and_push.sh       # Build and push to Quay.io
│
├── e2e_pipeline.yaml           # Tekton Pipeline definition
├── e2e_task.yaml               # Tekton Task with sidecars
├── e2e_pipeline_run.yaml       # PipelineRun configuration
│
├── caddy_config.yaml           # ConfigMap for chrome assets server
├── proxy_routes_config.yaml    # ConfigMap for proxy routing
│
└── run_pipeline.sh             # Execute the E2E pipeline
```

## Architecture

The E2E pipeline orchestrates a multi-container testing environment:

```
┌─────────────────────────────────────────────────────────┐
│ Tekton Pipeline Pod                                     │
│                                                         │
│  ┌──────────────────┐                                  │
│  │ Playwright Tests │                                  │
│  └────────┬─────────┘                                  │
│           │                                            │
│           ▼                                            │
│  ┌──────────────────────┐                             │
│  │ frontend-dev-proxy   │                             │
│  │ (routes.json)        │                             │
│  └──────┬───────────┬───┘                             │
│         │           │                                  │
│         │           └──────────┐                       │
│         ▼                      ▼                       │
│  ┌──────────────┐    ┌──────────────────┐            │
│  │ insights-    │    │ External Stage   │            │
│  │ chrome-dev   │    │ Environment      │            │
│  │ (Caddy:9912) │    └──────────────────┘            │
│  └──────────────┘                                     │
│                                                        │
│  ┌─────────────────────┐                              │
│  │ learning-resources  │                              │
│  │ (Application)       │                              │
│  └─────────────────────┘                              │
└────────────────────────────────────────────────────────┘
```

### Pipeline Stages

1. **fetch-source**: Clones the learning-resources repository using Tekton's git-clone task
2. **e2e-test-run**: Executes tests with three sidecars:
   - `frontend-dev-proxy`: Routes requests to chrome assets and stage environment
   - `insights-chrome-dev`: Serves chrome UI static assets via Caddy (port 9912)
   - `run-learning-resources`: Runs the application under test

## Configuration

### Pipeline Parameters

You can customize the pipeline run by modifying `e2e_pipeline_run.yaml`:

- `branch-name`: Git branch to test (default: `master`)
- `repo-url`: Repository URL
- `SOURCE_ARTIFACT`: Container image with the application build

### Environment Variables

Required for test execution:
- `E2E_USER`: Test user credentials
- `E2E_PASSWORD`: Test user password
- `E2E_PROXY_URL`: Proxy server URL

## Customization

### Building Custom Playwright Image

```bash
export QUAY_USER="your-quay-username"
cd playwright_image
./build_and_push.sh
```

Update `e2e_task.yaml` to reference your custom image.

### Modifying Proxy Routes

Edit `proxy_routes_config.yaml` to change how requests are routed between local and remote services.

### Adjusting Caddy Configuration

Edit `caddy_config.yaml` to modify how chrome assets are served.

## Troubleshooting

### Insufficient Disk Space

The `start.sh` script allocates 40GB by default. To increase:
```bash
minikube delete
minikube start --driver=podman --container-runtime=cri-o --disk-size=60g
```

### Docker Hub Rate Limiting

Run `./cluster_setup/image_load.sh` to pre-load images from Quay.io instead of Docker Hub.

### Viewing Pipeline Logs

```bash
tkn pipelinerun logs -f
```

### Checking Pod Status

```bash
kubectl get pods
kubectl describe pod <pod-name>
```

## Documentation

For detailed documentation including volume mounts, resource limits, and advanced configuration, see [.claude/CLAUDE.md](.claude/CLAUDE.md).

## License

This project is for internal testing purposes.