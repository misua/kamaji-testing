#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CLUSTER_NAME="${CLUSTER_NAME:-kamaji}"

echo -e "${GREEN}==> Creating kind cluster '${CLUSTER_NAME}'${NC}"

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}Cluster '${CLUSTER_NAME}' already exists${NC}"
    echo -e "${GREEN}Validating existing cluster...${NC}"
    
    # Validate cluster is functional
    if kubectl cluster-info --context "kind-${CLUSTER_NAME}" &>/dev/null; then
        echo -e "${GREEN}✓ Cluster is functional${NC}"
        exit 0
    else
        echo -e "${RED}✗ Cluster exists but is not functional${NC}"
        echo -e "${YELLOW}Please delete the cluster and try again:${NC}"
        echo -e "  kind delete cluster --name ${CLUSTER_NAME}"
        exit 1
    fi
fi

# Create kind cluster
echo "Creating new kind cluster..."
kind create cluster --name "${CLUSTER_NAME}" --wait 2m

# Verify cluster is ready
echo -e "${GREEN}Verifying cluster readiness...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo -e "${GREEN}✓ Kind cluster '${CLUSTER_NAME}' created successfully${NC}"
echo ""
echo "Cluster info:"
kubectl cluster-info --context "kind-${CLUSTER_NAME}"
