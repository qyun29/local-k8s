#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/wait-for-ready.sh"

echo "=== Installing ArgoCD via Helm ==="

# Add ArgoCD Helm repository
echo "Adding ArgoCD Helm repository..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Create argocd namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
echo "Installing ArgoCD..."
helm upgrade --install argocd argo/argo-cd \
  -n argocd \
  -f "${SCRIPT_DIR}/values.yaml" \
  --wait

# Wait for all ArgoCD pods to be ready
echo "Waiting for ArgoCD pods to be ready..."
wait_for_pods "argocd" 300

echo "=== ArgoCD installation complete ==="
echo ""
echo "Access ArgoCD UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo "  Open: http://localhost:8080"
echo "  Username: admin"
echo "  Password: (see argocd/values.yaml)"
