#!/bin/bash
# Load configuration from config files
# Usage: source scripts/load-config.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."

# Load default config
if [[ -f "${ROOT_DIR}/config.env" ]]; then
    source "${ROOT_DIR}/config.env"
fi

# Override with local config if exists
if [[ -f "${ROOT_DIR}/config.local.env" ]]; then
    source "${ROOT_DIR}/config.local.env"
fi

# Set defaults if not configured
REGISTRY_HOST="${REGISTRY_HOST:-gcr.io}"
APPS_NAMESPACE="${APPS_NAMESPACE:-apps}"
CLUSTER_NAME="${CLUSTER_NAME:-local-dev}"
ARGOCD_PORT="${ARGOCD_PORT:-8080}"
GCP_KEY_PATH="${GCP_KEY_PATH:-${ROOT_DIR}/secrets/gcp-key.json}"
