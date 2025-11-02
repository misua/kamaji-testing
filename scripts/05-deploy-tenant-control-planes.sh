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
    
    # Wait for TCP to show Ready status (max 5 minutes)
    TIMEOUT=300
    ELAPSED=0
    while [ $ELAPSED -lt $TIMEOUT ]; do
        STATUS=$(kubectl get tenantcontrolplane "${TCP_NAME}" -o jsonpath='{.status.kubeconfig.lastUpdate}' 2>/dev/null)
        if [ -n "$STATUS" ]; then
            # Check if LoadBalancer has external IP
            EXTERNAL_IP=$(kubectl get svc -l "kamaji.clastix.io/name=${TCP_NAME}" -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null)
            if [ -n "$EXTERNAL_IP" ]; then
                echo -e "${GREEN}✓ ${TCP_NAME} is ready (${EXTERNAL_IP})${NC}"
                break
            fi
        fi
        sleep 5
        ELAPSED=$((ELAPSED + 5))
        if [ $((ELAPSED % 30)) -eq 0 ]; then
            echo -n " ${ELAPSED}s"
        fi
    done
    echo ""
    
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo -e "${YELLOW}⚠ ${TCP_NAME} took longer than expected${NC}"
        echo "Check status: kubectl get tenantcontrolplane ${TCP_NAME}"
    fi
done

# Patch services to use specific NodePorts
echo ""
echo -e "${GREEN}Configuring NodePorts for external access...${NC}"
kubectl patch svc tcp-dev -p '{"spec":{"ports":[{"port":6443,"protocol":"TCP","targetPort":6443,"nodePort":30001}]}}' 2>/dev/null || echo "tcp-dev service not ready yet"
kubectl patch svc tcp-staging -p '{"spec":{"ports":[{"port":6443,"protocol":"TCP","targetPort":6443,"nodePort":30002}]}}' 2>/dev/null || echo "tcp-staging service not ready yet"
kubectl patch svc tcp-prod -p '{"spec":{"ports":[{"port":6443,"protocol":"TCP","targetPort":6443,"nodePort":30003}]}}' 2>/dev/null || echo "tcp-prod service not ready yet"

echo ""
echo -e "${GREEN}✓ All tenant control planes deployed${NC}"
echo ""
echo "View status:"
echo "  kubectl get tenantcontrolplanes"
echo ""
echo "View services:"
echo "  kubectl get svc -l 'kamaji.clastix.io/name'"
