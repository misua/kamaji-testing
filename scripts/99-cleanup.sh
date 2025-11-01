#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CLUSTER_NAME="${CLUSTER_NAME:-kamaji}"

echo -e "${YELLOW}==> Cleaning up Kamaji environment${NC}"
echo ""
echo "This will delete:"
echo "  - kind cluster '${CLUSTER_NAME}'"
echo "  - All tenant control planes"
echo "  - Worker VMs (if any)"
echo "  - All associated resources"
echo ""

read -p "Are you sure you want to continue? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Cleanup cancelled"
    exit 0
fi

# Clean up worker VMs first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/08-cleanup-workers.sh" ]; then
    echo -e "${GREEN}Cleaning up worker VMs...${NC}"
    "${SCRIPT_DIR}/08-cleanup-workers.sh"
    echo ""
fi

# Delete kind cluster
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${GREEN}Deleting kind cluster '${CLUSTER_NAME}'...${NC}"
    kind delete cluster --name "${CLUSTER_NAME}"
    echo -e "${GREEN}✓ Cluster deleted${NC}"
else
    echo -e "${YELLOW}Cluster '${CLUSTER_NAME}' not found${NC}"
fi

# Clean up Docker networks (optional)
echo -e "${GREEN}Checking for orphaned Docker networks...${NC}"
if docker network ls | grep -q "kind"; then
    echo -e "${YELLOW}Found kind networks. You may want to prune them:${NC}"
    echo "  docker network prune"
fi

echo -e "${GREEN}✓ Cleanup complete${NC}"
