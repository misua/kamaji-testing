#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CERT_MANAGER_VERSION="${CERT_MANAGER_VERSION:-v1.13.2}"
NAMESPACE="certmanager-system"

echo -e "${GREEN}==> Installing cert-manager${NC}"

# Add Bitnami Helm repository
echo "Adding Bitnami Helm repository..."
helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
helm repo update

# Check if already installed
if kubectl get namespace "${NAMESPACE}" &>/dev/null; then
    echo -e "${YELLOW}cert-manager namespace already exists${NC}"
    if kubectl get deployment -n "${NAMESPACE}" cert-manager &>/dev/null; then
        echo -e "${GREEN}✓ cert-manager is already installed${NC}"
        exit 0
    fi
fi

# Install cert-manager
echo "Installing cert-manager via Helm..."
helm upgrade --install cert-manager bitnami/cert-manager \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    --set "installCRDs=true" \
    --wait \
    --timeout 5m

# Wait for cert-manager to be ready
echo -e "${GREEN}Waiting for cert-manager pods to be ready...${NC}"
kubectl wait --for=condition=Ready pods \
    --all \
    -n "${NAMESPACE}" \
    --timeout=180s

# Verify webhook is functional
echo -e "${GREEN}Verifying cert-manager webhook...${NC}"
kubectl get validatingwebhookconfigurations -o name | grep cert-manager

echo -e "${GREEN}✓ cert-manager installed successfully${NC}"
