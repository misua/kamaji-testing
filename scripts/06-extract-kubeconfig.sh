#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Usage function
usage() {
    echo "Usage: $0 <tenant-name>"
    echo ""
    echo "Extract kubeconfig for a tenant control plane"
    echo ""
    echo "Examples:"
    echo "  $0 tcp-dev"
    echo "  $0 tcp-staging"
    echo "  $0 tcp-prod"
    exit 1
}

# Check arguments
if [ $# -ne 1 ]; then
    usage
fi

TCP_NAME="$1"
OUTPUT_DIR="${OUTPUT_DIR:-./kubeconfigs}"
OUTPUT_FILE="${OUTPUT_DIR}/${TCP_NAME}.kubeconfig"

echo -e "${GREEN}==> Extracting kubeconfig for ${TCP_NAME}${NC}"

# Check if TCP exists
if ! kubectl get tenantcontrolplane "${TCP_NAME}" &>/dev/null; then
    echo -e "${RED}✗ TenantControlPlane '${TCP_NAME}' not found${NC}"
    exit 1
fi

# Get the secret name from the TCP
SECRET_NAME=$(kubectl get tenantcontrolplane "${TCP_NAME}" -o jsonpath='{.status.kubeconfig.admin.secretName}')

if [ -z "${SECRET_NAME}" ]; then
    echo -e "${RED}✗ Secret name not found. Is the TCP ready?${NC}"
    echo "Check status: kubectl get tenantcontrolplane ${TCP_NAME}"
    exit 1
fi

echo "Secret name: ${SECRET_NAME}"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Extract kubeconfig
echo "Extracting kubeconfig..."
kubectl get secret "${SECRET_NAME}" -o jsonpath='{.data.admin\.conf}' | base64 -d > "${OUTPUT_FILE}"

echo -e "${GREEN}✓ Kubeconfig saved to: ${OUTPUT_FILE}${NC}"
echo ""
echo "To use this kubeconfig:"
echo "  export KUBECONFIG=${OUTPUT_FILE}"
echo "  kubectl get nodes"
echo ""
echo "Or use directly:"
echo "  kubectl --kubeconfig=${OUTPUT_FILE} get nodes"
