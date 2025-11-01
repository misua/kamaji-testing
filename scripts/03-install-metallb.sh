#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

METALLB_VERSION="${METALLB_VERSION:-v0.13.12}"
NAMESPACE="metallb-system"

echo -e "${GREEN}==> Installing MetalLB${NC}"

# Check if already installed
if kubectl get namespace "${NAMESPACE}" &>/dev/null; then
    echo -e "${YELLOW}MetalLB namespace already exists${NC}"
    if kubectl get deployment -n "${NAMESPACE}" controller &>/dev/null; then
        echo -e "${GREEN}✓ MetalLB is already installed${NC}"
        
        # Check if IP pool is configured
        if kubectl get ipaddresspool -n "${NAMESPACE}" kind-ip-pool &>/dev/null; then
            echo -e "${GREEN}✓ IP address pool is already configured${NC}"
            exit 0
        fi
    fi
fi

# Install MetalLB
echo "Installing MetalLB ${METALLB_VERSION}..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-native.yaml

# Wait for MetalLB to be ready
echo -e "${GREEN}Waiting for MetalLB pods to be ready...${NC}"
kubectl wait --for=condition=Ready pods \
    --all \
    -n "${NAMESPACE}" \
    --timeout=180s

# Configure IP address pool
echo -e "${GREEN}Configuring IP address pool...${NC}"

# Extract kind network gateway IP
GW_IP=$(docker network inspect -f '{{range .IPAM.Config}}{{.Gateway}}{{end}}' kind)
echo "Detected kind network gateway: ${GW_IP}"

# Extract network prefix (e.g., 172.19 from 172.19.0.1)
NET_IP=$(echo "${GW_IP}" | sed -E 's|^([0-9]+\.[0-9]+)\..*$|\1|g')
echo "Using network prefix: ${NET_IP}"

# Create IPAddressPool and L2Advertisement
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: kind-ip-pool
  namespace: ${NAMESPACE}
spec:
  addresses:
  - ${NET_IP}.255.200-${NET_IP}.255.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: empty
  namespace: ${NAMESPACE}
EOF

echo -e "${GREEN}✓ MetalLB installed and configured successfully${NC}"
echo "IP address pool: ${NET_IP}.255.200-${NET_IP}.255.250"
