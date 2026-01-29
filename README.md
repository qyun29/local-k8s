# Local Kubernetes Environment

Local Kubernetes development environment using Kind with Istio service mesh and ArgoCD for GitOps deployments.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kind Cluster                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Control    │  │   Worker    │  │   Worker    │         │
│  │   Plane     │  │    Node 1   │  │    Node 2   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 Istio Service Mesh                   │   │
│  │  • Ingress Gateway (port 80/443)                    │   │
│  │  • Sidecar injection for apps namespace             │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                     ArgoCD                           │   │
│  │  • Web UI (port 8080)                               │   │
│  │  • ApplicationSets for multi-app management         │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Docker Desktop (8GB+ RAM recommended)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh/docs/intro/install/)

## Quick Start

```bash
# 1. (Optional) Create local config with your settings
cp config.env config.local.env
# Edit config.local.env with your GCP project, registry host, etc.

# 2. Full setup (creates cluster, installs Istio & ArgoCD)
./setup.sh

# 3. (Optional) Start with port-forwarding
./setup.sh --port-forward

# Teardown
./teardown.sh
```

## Manual Setup

```bash
# 1. Create Kind cluster
kind create cluster --config kind/cluster-config.yaml

# 2. Install Istio
./istio/install.sh

# 3. Install ArgoCD
./argocd/install.sh

# 4. Create apps namespace
kubectl apply -f apps/namespace.yaml
```

## Configuration

Create a local config file to customize your environment:

```bash
cp config.env config.local.env
```

Edit `config.local.env`:

```bash
# Google Artifact Registry / GCR
REGISTRY_HOST="us-docker.pkg.dev"    # or gcr.io, asia-docker.pkg.dev, etc.

# GCP Project
GCP_PROJECT="my-project-id"

# Kubernetes namespace for applications
APPS_NAMESPACE="apps"

# ArgoCD local port
ARGOCD_PORT="8080"
```

The `config.local.env` file is gitignored and won't be committed.

## Google Artifact Registry Authentication

To pull images from Google Artifact Registry or GCR:

```bash
# 1. Place your GCP service account key at the default location
cp /path/to/your-key.json ./secrets/gcp-key.json

# 2. Run the script (uses default key path)
./scripts/configure-registry.sh                      # For GCR (gcr.io)
./scripts/configure-registry.sh us-docker.pkg.dev   # For Artifact Registry

# Or specify a custom key path
./scripts/configure-registry.sh /path/to/key.json us-docker.pkg.dev
```

### Service Account Requirements

The service account needs the following roles:
- `roles/artifactregistry.reader` (for Artifact Registry)
- `roles/storage.objectViewer` (for GCR)

## Accessing Services

### ArgoCD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Open http://localhost:8080
- Username: `admin`
- Password: Set in `argocd/values.yaml`

### Istio Ingress

The Istio ingress gateway is exposed on:
- HTTP: http://localhost (port 80)
- HTTPS: https://localhost (port 443)

## Directory Structure

```
local-k8s/
├── kind/
│   └── cluster-config.yaml    # Kind cluster configuration
├── istio/
│   ├── install.sh             # Istio installation script
│   └── gateway.yaml           # Default ingress gateway
├── argocd/
│   ├── install.sh             # ArgoCD installation script
│   └── values.yaml            # ArgoCD Helm values
├── apps/
│   └── namespace.yaml         # Apps namespace with Istio injection
├── scripts/
│   ├── configure-registry.sh  # GCP registry authentication
│   ├── load-config.sh         # Config loader helper
│   ├── start-port-forwards.sh # Start port-forwards for UI access
│   └── wait-for-ready.sh      # Helper functions
├── secrets/
│   └── gcp-key.json           # GCP service account key (gitignored)
├── config.env                 # Default configuration
├── config.local.env           # Local overrides (gitignored)
├── setup.sh                   # Full environment setup
├── teardown.sh                # Environment teardown
└── README.md
```

## Deploying Applications

Application manifests should be managed in a separate GitOps repository. Configure ArgoCD to watch that repository:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-spring-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-gitops-repo
    targetRevision: HEAD
    path: apps/my-spring-app
  destination:
    server: https://kubernetes.default.svc
    namespace: apps
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Troubleshooting

### Cluster creation fails

```bash
# Check Docker resources (needs 8GB+ RAM)
docker info --format '{{.MemTotal}}'

# Try with fewer workers
# Edit kind/cluster-config.yaml and remove worker nodes
```

### Pods stuck in ImagePullBackOff

```bash
# Check if registry secret exists
kubectl get secrets -n apps

# Reconfigure registry authentication
./scripts/configure-registry.sh <registry-host>
```

### Istio sidecar not injecting

```bash
# Verify namespace label
kubectl get namespace apps --show-labels

# Should show: istio-injection=enabled
```

## Resource Requirements

- Docker: 8GB RAM recommended
- Disk: ~10GB for container images
- CPU: 4+ cores recommended
