#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Installing Istio Grafana Dashboards ==="

# Create ConfigMaps from dashboard JSON files
# The grafana sidecar watches for ConfigMaps with label grafana_dashboard=1

for dashboard in istio-mesh istio-service istio-workload; do
    if [ -f "${SCRIPT_DIR}/dashboards/${dashboard}.json" ]; then
        echo "Installing ${dashboard} dashboard..."
        kubectl create configmap "grafana-dashboard-${dashboard}" \
            --from-file="${dashboard}.json=${SCRIPT_DIR}/dashboards/${dashboard}.json" \
            -n monitoring \
            --dry-run=client -o yaml | \
            kubectl label --local -f - grafana_dashboard=1 -o yaml | \
            kubectl apply -f -
    fi
done

echo ""
echo "=== Istio Dashboards Installed ==="
echo ""
echo "Dashboards will appear in Grafana within ~30 seconds"
echo "Access Grafana: http://localhost:3000"
echo ""
echo "Available dashboards:"
echo "  - Istio Mesh Dashboard: Overall mesh traffic"
echo "  - Istio Service Dashboard: Per-service metrics"
echo "  - Istio Workload Dashboard: Per-workload metrics"
