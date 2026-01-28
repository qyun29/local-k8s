#!/bin/bash
# Helper functions for waiting on Kubernetes resources

# Wait for all pods in a namespace to be ready
# Usage: wait_for_pods <namespace> [timeout_seconds]
wait_for_pods() {
    local namespace="${1}"
    local timeout="${2:-300}"
    local interval=5
    local elapsed=0

    echo "Waiting for pods in namespace '${namespace}' to be ready (timeout: ${timeout}s)..."

    while [[ ${elapsed} -lt ${timeout} ]]; do
        # Get pod status
        local not_ready=$(kubectl get pods -n "${namespace}" --no-headers 2>/dev/null | grep -v "Running\|Completed" | wc -l | tr -d ' ')
        local total=$(kubectl get pods -n "${namespace}" --no-headers 2>/dev/null | wc -l | tr -d ' ')

        if [[ "${total}" -gt 0 ]] && [[ "${not_ready}" -eq 0 ]]; then
            echo "All ${total} pods in '${namespace}' are ready!"
            return 0
        fi

        echo "  Waiting... (${not_ready}/${total} pods not ready, ${elapsed}s elapsed)"
        sleep ${interval}
        elapsed=$((elapsed + interval))
    done

    echo "Error: Timeout waiting for pods in '${namespace}'"
    kubectl get pods -n "${namespace}"
    return 1
}

# Wait for a specific deployment to be ready
# Usage: wait_for_deployment <namespace> <deployment_name> [timeout_seconds]
wait_for_deployment() {
    local namespace="${1}"
    local deployment="${2}"
    local timeout="${3:-300}"

    echo "Waiting for deployment '${deployment}' in namespace '${namespace}'..."
    kubectl rollout status deployment/"${deployment}" -n "${namespace}" --timeout="${timeout}s"
}

# Wait for CRDs to be established
# Usage: wait_for_crd <crd_name> [timeout_seconds]
wait_for_crd() {
    local crd="${1}"
    local timeout="${2:-60}"
    local interval=2
    local elapsed=0

    echo "Waiting for CRD '${crd}' to be established..."

    while [[ ${elapsed} -lt ${timeout} ]]; do
        if kubectl get crd "${crd}" &>/dev/null; then
            local established=$(kubectl get crd "${crd}" -o jsonpath='{.status.conditions[?(@.type=="Established")].status}')
            if [[ "${established}" == "True" ]]; then
                echo "CRD '${crd}' is established!"
                return 0
            fi
        fi

        sleep ${interval}
        elapsed=$((elapsed + interval))
    done

    echo "Error: Timeout waiting for CRD '${crd}'"
    return 1
}
