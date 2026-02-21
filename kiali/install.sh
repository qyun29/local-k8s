#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Kiali..."

# Add Kiali Helm repo
helm repo add kiali https://kiali.org/helm-charts 2>/dev/null || true
helm repo update kiali

# Install Kiali Server
helm upgrade --install kiali-server kiali/kiali-server \
  --namespace istio-system \
  --set auth.strategy="anonymous" \
  --set external_services.prometheus.url="http://prometheus-kube-prometheus-prometheus.monitoring:9090" \
  --set external_services.grafana.enabled=true \
  --set external_services.grafana.in_cluster_url="http://prometheus-grafana.monitoring:80" \
  --set external_services.grafana.url="http://localhost:3000" \
  --set external_services.tracing.enabled=false \
  --wait

echo "Kiali installed successfully!"
echo ""
echo "To access Kiali dashboard:"
echo "  kubectl port-forward svc/kiali -n istio-system 20001:20001"
echo "  Then open: http://localhost:20001"
