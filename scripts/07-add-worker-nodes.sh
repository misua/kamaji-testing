#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo -e "${GREEN}==> Adding Worker Nodes to Tenant Control Planes${NC}"
echo ""
echo -e "${YELLOW}This creates Vagrant VMs as worker nodes for each tenant${NC}"
echo -e "${YELLOW}Requirements: Vagrant + libvirt (or VirtualBox)${NC}"
echo ""

# Check if Vagrant is installed
if ! command -v vagrant &> /dev/null; then
    echo -e "${RED}✗ Vagrant is not installed${NC}"
    echo ""
    echo "Install Vagrant:"
    echo "  Ubuntu/Debian: sudo apt-get install vagrant"
    echo "  Fedora: sudo dnf install vagrant"
    echo "  Or download from: https://www.vagrantup.com/downloads"
    echo ""
    exit 1
fi

# Check for virtualization provider
if ! vagrant plugin list | grep -q "vagrant-libvirt"; then
    if ! command -v vboxmanage &> /dev/null; then
        echo -e "${YELLOW}⚠ No virtualization provider detected${NC}"
        echo ""
        echo "Install libvirt (recommended):"
        echo "  sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils"
        echo "  vagrant plugin install vagrant-libvirt"
        echo ""
        echo "Or install VirtualBox:"
        echo "  https://www.virtualbox.org/wiki/Linux_Downloads"
        echo ""
        exit 1
    fi
fi

echo -e "${BLUE}==> Creating worker VMs with Vagrant${NC}"
echo ""

# Navigate to project root (where Vagrantfile is)
cd "${PROJECT_ROOT}"

# Start all worker VMs
echo "Starting VMs (this may take 5-10 minutes)..."
vagrant up --provider=libvirt 2>&1 | grep -E "(Bringing|Machine|Running|Successfully)" || true

echo ""
echo -e "${GREEN}✓ Worker VMs created${NC}"
echo ""

# Join each worker to its tenant control plane
echo -e "${BLUE}==> Joining workers to tenant control planes${NC}"
echo ""

for tenant in dev staging prod; do
    echo -e "${YELLOW}Joining tcp-${tenant}-worker...${NC}"
    "${SCRIPT_DIR}/join-worker.sh" "${tenant}"
    echo ""
done

echo -e "${GREEN}==> Waiting for nodes to register (30 seconds)...${NC}"
sleep 30

echo ""
echo -e "${GREEN}==> Checking node status${NC}"
echo ""

for tenant in dev staging prod; do
    echo -e "${YELLOW}tcp-${tenant}:${NC}"
    kubectl --kubeconfig="${SCRIPT_DIR}/kubeconfigs/tcp-${tenant}.kubeconfig" get nodes 2>/dev/null || echo "No nodes yet"
    echo ""
done

echo -e "${GREEN}✓ Worker nodes setup complete${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Deploy demo applications:"
echo "   kubectl --kubeconfig=./kubeconfigs/tcp-dev.kubeconfig apply -f manifests/examples/nginx-dev.yaml"
echo ""
echo "2. Monitor nodes becoming Ready:"
echo "   watch -n 2 'kubectl --kubeconfig=./kubeconfigs/tcp-dev.kubeconfig get nodes'"
echo ""
echo "3. Check pod status:"
echo "   kubectl --kubeconfig=./kubeconfigs/tcp-dev.kubeconfig get pods -n demo"
echo ""
echo "4. Get LoadBalancer IPs:"
echo "   kubectl --kubeconfig=./kubeconfigs/tcp-dev.kubeconfig get svc -n demo"
