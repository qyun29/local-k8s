#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"
source "${SCRIPT_DIR}/scripts/load-config.sh"

# Parse arguments
START_PORT_FORWARD=false
for arg in "$@"; do
    case $arg in
        --port-forward|-p)
            START_PORT_FORWARD=true
            ;;
    esac
done

echo "========================================"
echo "  Local Kubernetes Environment Setup"
echo "========================================"
echo ""

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."

    local missing=()

    command -v docker &>/dev/null || missing+=("docker")
    command -v kind &>/dev/null || missing+=("kind")
    command -v kubectl &>/dev/null || missing+=("kubectl")
    command -v helm &>/dev/null || missing+=("helm")

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing required tools: ${missing[*]}"
        echo "Please install them before running this script."
        exit 1
    fi

    # Check if Docker is running
    if ! docker info &>/dev/null; then
        echo "Error: Docker is not running. Please start Docker first."
        exit 1
    fi

    echo "All prerequisites satisfied."
    echo ""
}

# Create Kind cluster
create_cluster() {
    echo "=== Creating Kind Cluster ==="

    if kind get clusters 2>/dev/null | grep -q "^local-dev$"; then
        echo "Cluster 'local-dev' already exists. Skipping creation."
    else
        kind create cluster --config kind/cluster-config.yaml
    fi

    # Verify cluster is ready
    echo "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=120s
    echo "Cluster is ready!"
    echo ""
}

# Install Istio
install_istio() {
    echo "=== Installing Istio ==="
    chmod +x istio/install.sh
    ./istio/install.sh
    echo ""
}

# Install ArgoCD
install_argocd() {
    echo "=== Installing ArgoCD ==="
    chmod +x argocd/install.sh
    ./argocd/install.sh
    echo ""
}

# Setup application namespace
setup_apps_namespace() {
    echo "=== Setting up Apps Namespace ==="
    kubectl apply -f apps/namespace.yaml
    echo "Apps namespace created with Istio sidecar injection enabled."
    echo ""
}

# Print summary
print_summary() {
    echo "========================================"
    echo "  Setup Complete!"
    echo "========================================"
    echo ""
    echo "Cluster Status:"
    kubectl get nodes
    echo ""
    echo "Istio Status:"
    kubectl get pods -n istio-system
    echo ""
    echo "ArgoCD Status:"
    kubectl get pods -n argocd
    echo ""
    echo "----------------------------------------"
    echo "Next Steps:"
    echo ""
    echo "1. Configure Google Artifact Registry (if needed):"
    echo "   Place your GCP key at: ./secrets/gcp-key.json"
    echo "   Then run: ./scripts/configure-registry.sh [registry-host]"
    echo ""
    echo "2. Access ArgoCD UI:"
    echo "   ./scripts/start-port-forwards.sh"
    echo "   Open: http://localhost:8080"
    echo "   Username: admin"
    echo "   Password: (see argocd/values.yaml)"
    echo ""
    echo "3. Deploy your applications via ArgoCD from your GitOps repository"
    echo "----------------------------------------"
}

# Start port forwards
start_port_forwards() {
    echo ""
    chmod +x scripts/start-port-forwards.sh
    ./scripts/start-port-forwards.sh
}

# Main execution
main() {
    check_prerequisites
    create_cluster
    install_istio
    install_argocd
    setup_apps_namespace
    print_summary

    if [[ "${START_PORT_FORWARD}" == "true" ]]; then
        start_port_forwards
    fi
}

main "$@"
