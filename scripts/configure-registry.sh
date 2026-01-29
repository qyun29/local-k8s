#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/load-config.sh"

# Configure Google Artifact Registry / GCR authentication for Kind cluster
# Usage: ./configure-registry.sh [service-account-key.json] [registry-host] [namespace]
#
# Arguments:
#   service-account-key.json - Path to GCP service account JSON key file (default: from config or ./secrets/gcp-key.json)
#   registry-host - Registry host (default: from config.env or gcr.io)
#   namespace - Kubernetes namespace (default: from config.env or apps)
#
# Examples:
#   ./configure-registry.sh                                    # Uses config.env settings
#   ./configure-registry.sh ~/keys/sa-key.json                 # Custom key path
#   ./configure-registry.sh ~/keys/sa-key.json us-docker.pkg.dev

SERVICE_ACCOUNT_KEY="${1:-${GCP_KEY_PATH}}"
REGISTRY_HOST="${2:-${REGISTRY_HOST}}"
NAMESPACE="${3:-${APPS_NAMESPACE}}"

print_usage() {
    echo "Usage: $0 [service-account-key.json] [registry-host] [namespace]"
    echo ""
    echo "Arguments:"
    echo "  service-account-key.json  Path to GCP service account JSON key file"
    echo "                            (default: ./secrets/gcp-key.json)"
    echo "  registry-host             Registry host (default: gcr.io)"
    echo "                            For Artifact Registry: REGION-docker.pkg.dev"
    echo "  namespace                 Kubernetes namespace (default: apps)"
    echo ""
    echo "Examples:"
    echo "  $0                                         # Uses default key path"
    echo "  $0 ~/keys/sa-key.json"
    echo "  $0 ~/keys/sa-key.json us-docker.pkg.dev"
    echo "  $0 ~/keys/sa-key.json asia-docker.pkg.dev apps"
}

if [[ ! -f "${SERVICE_ACCOUNT_KEY}" ]]; then
    echo "Error: Service account key file not found: ${SERVICE_ACCOUNT_KEY}"
    exit 1
fi

echo "=== Configuring Google Container Registry Access ==="
echo "Registry: ${REGISTRY_HOST}"
echo "Namespace: ${NAMESPACE}"

# Ensure namespace exists
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# Delete existing secret if it exists
kubectl delete secret gcr-secret -n "${NAMESPACE}" --ignore-not-found

# Create docker-registry secret
echo "Creating registry secret..."
kubectl create secret docker-registry gcr-secret \
    --docker-server="${REGISTRY_HOST}" \
    --docker-username=_json_key \
    --docker-password="$(cat "${SERVICE_ACCOUNT_KEY}")" \
    --docker-email=sa@example.com \
    -n "${NAMESPACE}"

# Patch default service account to use the secret
echo "Patching default service account..."
kubectl patch serviceaccount default -n "${NAMESPACE}" \
    -p '{"imagePullSecrets": [{"name": "gcr-secret"}]}'

echo ""
echo "=== Registry configuration complete ==="
echo ""
echo "Your pods in the '${NAMESPACE}' namespace can now pull images from:"
echo "  ${REGISTRY_HOST}/<project-id>/<image>:<tag>"
echo ""
echo "To configure additional namespaces, run:"
echo "  $0 ${SERVICE_ACCOUNT_KEY} ${REGISTRY_HOST} <namespace>"
