#!/bin/bash
set -e

echo "========================================"
echo "  Local Kubernetes Environment Teardown"
echo "========================================"
echo ""

# Confirm teardown
if [[ "${1}" != "-y" ]] && [[ "${1}" != "--yes" ]]; then
    read -p "This will delete the Kind cluster 'local-dev' and all its data. Continue? [y/N] " confirm
    if [[ "${confirm}" != "y" ]] && [[ "${confirm}" != "Y" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Delete Kind cluster
echo "Deleting Kind cluster 'local-dev'..."
if kind get clusters 2>/dev/null | grep -q "^local-dev$"; then
    kind delete cluster --name local-dev
    echo "Cluster deleted."
else
    echo "Cluster 'local-dev' does not exist. Nothing to delete."
fi

echo ""
echo "========================================"
echo "  Teardown Complete!"
echo "========================================"
echo ""
echo "To recreate the environment, run:"
echo "  ./setup.sh"
