#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

MANIFESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../manifests/tenant-control-planes" && pwd)"

echo -e "${GREEN}==> Deploying Tenant Control Planes${NC}"
echo ""

# Deploy each tenant control plane
for env in dev staging prod; do
    TCP_NAME="tcp-${env}"
    MANIFEST="${MANIFESTS_DIR}/${TCP_NAME}.yaml"
    
    echo -e "${GREEN}Deploying ${TCP_NAME}...${NC}"
    
    # Check if already exists
    if kubectl get tenantcontrolplane "${TCP_NAME}" &>/dev/null; then
        echo -e "${YELLOW}${TCP_NAME} already exists${NC}"
        continue
    fi
    
    # Apply manifest
    kubectl apply -f "${MANIFEST}"
    echo -e "${GREEN}✓ ${TCP_NAME} manifest applied${NC}"
done

echo ""
echo -e "${GREEN}Waiting for tenant control planes to be ready...${NC}"
echo "This may take 3-5 minutes per control plane..."
echo ""

# Wait for each TCP to be ready
for env in dev staging prod; do
    TCP_NAME="tcp-${env}"
    echo -e "${YELLOW}Waiting for ${TCP_NAME}...${NC}"
    
    # Wait up to 10 minutes for Ready condition
    kubectl wait --for=condition=Ready tenantcontrolplane "${TCP_NAME}" --timeout=600s || {
        echo -e "${RED}✗ ${TCP_NAME} failed to become ready${NC}"
        echo "Check status with: kubectl describe tenantcontrolplane ${TCP_NAME}"
        continue
    }
    
    echo -e "${GREEN}✓ ${TCP_NAME} is ready${NC}"
done

echo ""
echo -e "${GREEN}✓ All tenant control planes deployed${NC}"
echo ""
echo "View status:"
echo "  kubectl get tenantcontrolplanes"
echo ""
echo "View services:"
echo "  kubectl get svc -l 'kamaji.clastix.io/name'"
