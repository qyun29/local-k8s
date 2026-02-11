#!/bin/bash
set -e

MONITORING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${MONITORING_DIR}/../scripts/load-config.sh"
source "${MONITORING_DIR}/../scripts/wait-for-ready.sh"

echo "=== Installing Monitoring Stack (Prometheus + Grafana) ==="

# Add Helm repository
echo "Adding prometheus-community Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install kube-prometheus-stack
echo "Installing kube-prometheus-stack..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f "${MONITORING_DIR}/values.yaml" \
  --wait --timeout 10m

# Wait for pods to be ready
echo "Waiting for monitoring pods to be ready..."
wait_for_pods "monitoring" 300

echo ""
echo "=== Monitoring Stack Installation Complete ==="
echo ""
echo "Access Grafana:"
echo "  kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80"
echo "  Open: http://localhost:3000"
echo "  Username: admin"
echo "  Password: admin"
echo ""
echo "Access Prometheus:"
echo "  kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090"
echo "  Open: http://localhost:9090"
