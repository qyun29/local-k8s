#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/wait-for-ready.sh"

echo "=== Installing Istio via Helm ==="

# Add Istio Helm repository
echo "Adding Istio Helm repository..."
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

# Create istio-system namespace
kubectl create namespace istio-system --dry-run=client -o yaml | kubectl apply -f -

# Clean up any conflicting webhooks from previous installations
echo "Cleaning up any conflicting webhooks..."
kubectl delete validatingwebhookconfiguration istio-validator-istio-system --ignore-not-found
kubectl delete validatingwebhookconfiguration istiod-default-validator --ignore-not-found

# Install Istio base (CRDs)
echo "Installing Istio base..."
helm upgrade --install istio-base istio/base \
  -n istio-system \
  --wait

# Install Istiod (control plane)
echo "Installing Istiod..."
helm upgrade --install istiod istio/istiod \
  -n istio-system \
  --set pilot.resources.requests.cpu=100m \
  --set pilot.resources.requests.memory=128Mi \
  --set pilot.resources.limits.cpu=500m \
  --set pilot.resources.limits.memory=512Mi \
  --wait

# Install Istio Ingress Gateway with NodePort for Kind
echo "Installing Istio Ingress Gateway..."
helm upgrade --install istio-ingressgateway istio/gateway \
  -n istio-system \
  --set service.type=NodePort \
  --set 'service.ports[0].name=http2' \
  --set 'service.ports[0].port=80' \
  --set 'service.ports[0].targetPort=80' \
  --set 'service.ports[0].nodePort=30080' \
  --set 'service.ports[1].name=https' \
  --set 'service.ports[1].port=443' \
  --set 'service.ports[1].targetPort=443' \
  --set 'service.ports[1].nodePort=30443' \
  --wait

# Wait for all Istio pods to be ready
echo "Waiting for Istio pods to be ready..."
wait_for_pods "istio-system" 300

# Apply default gateway
echo "Applying default gateway configuration..."
kubectl apply -f "${SCRIPT_DIR}/gateway.yaml"

echo "=== Istio installation complete ==="
