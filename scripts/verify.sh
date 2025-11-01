#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CLUSTER_NAME="${CLUSTER_NAME:-kamaji}"
ERRORS=0

check() {
    local name="$1"
    local command="$2"
    
    echo -n "Checking ${name}... "
    if eval "${command}" &>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

echo -e "${GREEN}==> Verifying Kamaji Installation${NC}"
echo ""

# Check kind cluster
echo -e "${YELLOW}Kind Cluster:${NC}"
check "Cluster exists" "kind get clusters | grep -q '^${CLUSTER_NAME}$'"
check "Cluster accessible" "kubectl cluster-info --context kind-${CLUSTER_NAME}"
echo ""

# Check cert-manager
echo -e "${YELLOW}cert-manager:${NC}"
check "Namespace exists" "kubectl get namespace certmanager-system"
check "Deployment ready" "kubectl get deployment -n certmanager-system cert-manager -o jsonpath='{.status.readyReplicas}' | grep -q '[1-9]'"
check "Pods running" "kubectl get pods -n certmanager-system --field-selector=status.phase=Running | grep -q cert-manager"
echo ""

# Check MetalLB
echo -e "${YELLOW}MetalLB:${NC}"
check "Namespace exists" "kubectl get namespace metallb-system"
check "Controller ready" "kubectl get deployment -n metallb-system controller -o jsonpath='{.status.readyReplicas}' | grep -q '[1-9]'"
check "Speaker running" "kubectl get daemonset -n metallb-system speaker -o jsonpath='{.status.numberReady}' | grep -q '[1-9]'"
check "IP pool configured" "kubectl get ipaddresspool -n metallb-system kind-ip-pool"
echo ""

# Check Kamaji
echo -e "${YELLOW}Kamaji:${NC}"
check "Namespace exists" "kubectl get namespace kamaji-system"
check "Controller ready" "kubectl get deployment -n kamaji-system kamaji-controller-manager -o jsonpath='{.status.readyReplicas}' | grep -q '[1-9]'"
check "CRDs installed" "kubectl get crd tenantcontrolplanes.kamaji.clastix.io"
echo ""

# Check Tenant Control Planes
echo -e "${YELLOW}Tenant Control Planes:${NC}"
for env in dev staging prod; do
    TCP_NAME="tcp-${env}"
    check "${TCP_NAME} exists" "kubectl get tenantcontrolplane ${TCP_NAME}"
    check "${TCP_NAME} ready" "kubectl get tenantcontrolplane ${TCP_NAME} -o jsonpath='{.status.conditions[?(@.type==\"Ready\")].status}' | grep -q True"
done
echo ""

# Summary
echo -e "${YELLOW}========================================${NC}"
if [ ${ERRORS} -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Your Kamaji environment is healthy."
    exit 0
else
    echo -e "${RED}✗ ${ERRORS} check(s) failed${NC}"
    echo ""
    echo "Please review the errors above and check:"
    echo "  • Pod logs: kubectl logs -n <namespace> <pod-name>"
    echo "  • Events: kubectl get events -A --sort-by='.lastTimestamp'"
    echo "  • Resources: kubectl get all -A"
    exit 1
fi
