#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/load-config.sh"

# Start port-forwards for local access to cluster services
# Run this after setup.sh completes

echo "=== Starting Port Forwards ==="

# Kill any existing port-forwards
pkill -f "kubectl port-forward.*argocd" 2>/dev/null || true

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=120s

# Start ArgoCD port-forward in background (HTTP mode since server.insecure=true)
echo "Starting ArgoCD port-forward (${ARGOCD_PORT} -> 80)..."
kubectl port-forward svc/argocd-server -n argocd ${ARGOCD_PORT}:80 > /dev/null 2>&1 &
ARGOCD_PID=$!

# Verify port-forward started
sleep 2
if kill -0 $ARGOCD_PID 2>/dev/null; then
    echo "ArgoCD port-forward started (PID: $ARGOCD_PID)"
else
    echo "Error: Failed to start ArgoCD port-forward"
    exit 1
fi

echo ""
echo "=== Port Forwards Active ==="
echo ""
echo "ArgoCD UI:  http://localhost:${ARGOCD_PORT}"
echo "  Username: admin"
echo "  Password: (see argocd/values.yaml)"
echo ""
echo "To stop port-forwards:"
echo "  pkill -f 'kubectl port-forward'"
