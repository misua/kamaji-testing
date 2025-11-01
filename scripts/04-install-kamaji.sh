#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

KAMAJI_VERSION="${KAMAJI_VERSION:-0.0.0+latest}"
NAMESPACE="kamaji-system"

echo -e "${GREEN}==> Installing Kamaji${NC}"

# Add Clastix Helm repository
echo "Adding Clastix Helm repository..."
helm repo add clastix https://clastix.github.io/charts 2>/dev/null || true
helm repo update

# Check if already installed
if kubectl get namespace "${NAMESPACE}" &>/dev/null; then
    echo -e "${YELLOW}Kamaji namespace already exists${NC}"
    if kubectl get deployment -n "${NAMESPACE}" kamaji-controller-manager &>/dev/null; then
        echo -e "${GREEN}✓ Kamaji is already installed${NC}"
        exit 0
    fi
fi

# Install Kamaji
echo "Installing Kamaji ${KAMAJI_VERSION} via Helm..."
helm upgrade --install kamaji clastix/kamaji \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    --set 'resources=null' \
    --version "${KAMAJI_VERSION}" \
    --wait \
    --timeout 5m

# Wait for Kamaji controller to be ready
echo -e "${GREEN}Waiting for Kamaji controller to be ready...${NC}"
kubectl wait --for=condition=Ready pods \
    --all \
    -n "${NAMESPACE}" \
    --timeout=180s

# Verify Kamaji CRDs
echo -e "${GREEN}Verifying Kamaji CRDs...${NC}"
kubectl get crds | grep -i kamaji

echo -e "${GREEN}✓ Kamaji installed successfully${NC}"
echo ""
echo "Available CRDs:"
kubectl get crds | grep kamaji.clastix.io
