#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
SKIP_WORKERS=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-workers)
            SKIP_WORKERS=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--skip-workers]"
            exit 1
            ;;
    esac
done

# Progress tracking
TOTAL_STEPS=7
if [ "$SKIP_WORKERS" = true ]; then
    TOTAL_STEPS=6
fi
CURRENT_STEP=0

print_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Step ${CURRENT_STEP}/${TOTAL_STEPS}: $1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_error() {
    echo -e "${RED}✗ Error: $1${NC}"
    echo ""
    echo "Setup failed. To clean up, run:"
    echo "  ./scripts/99-cleanup.sh"
    exit 1
}

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Kamaji Local Setup with Kind        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "This script will set up a complete Kamaji environment with:"
echo "  • kind cluster"
echo "  • cert-manager"
echo "  • MetalLB"
echo "  • Kamaji operator"
echo "  • Three tenant control planes (dev, staging, prod)"
if [ "$SKIP_WORKERS" = false ]; then
    echo "  • Worker nodes (VMs) for running pods"
fi
echo ""
echo "Estimated time: 10-15 minutes (+ 10-15 min for workers)"
echo ""
if [ "$SKIP_WORKERS" = false ]; then
    echo -e "${YELLOW}Note: Worker nodes require Vagrant and libvirt${NC}"
    echo "To skip worker setup, run: $0 --skip-workers"
    echo ""
fi

# Step 1: Create kind cluster
print_step "Creating kind cluster"
"${SCRIPT_DIR}/01-create-kind-cluster.sh" || print_error "Failed to create kind cluster"

# Step 2: Install cert-manager
print_step "Installing cert-manager"
"${SCRIPT_DIR}/02-install-cert-manager.sh" || print_error "Failed to install cert-manager"

# Step 3: Install MetalLB
print_step "Installing MetalLB"
"${SCRIPT_DIR}/03-install-metallb.sh" || print_error "Failed to install MetalLB"

# Step 4: Install Kamaji
print_step "Installing Kamaji"
"${SCRIPT_DIR}/04-install-kamaji.sh" || print_error "Failed to install Kamaji"

# Step 5: Deploy tenant control planes
print_step "Deploying tenant control planes"
echo -e "${YELLOW}This step may take 5-10 minutes...${NC}"
"${SCRIPT_DIR}/05-deploy-tenant-control-planes.sh" || print_error "Failed to deploy tenant control planes"

# Step 6: Extract kubeconfigs
print_step "Extracting kubeconfigs"
for env in dev staging prod; do
    "${SCRIPT_DIR}/06-extract-kubeconfig.sh" "tcp-${env}" || echo -e "${YELLOW}Warning: Failed to extract kubeconfig for tcp-${env}${NC}"
done
echo -e "${GREEN}✓ Kubeconfigs saved to scripts/kubeconfigs/${NC}"

# Step 7: Add worker nodes (optional)
if [ "$SKIP_WORKERS" = false ]; then
    print_step "Adding worker nodes (optional)"
    echo -e "${YELLOW}This will create 3 VMs and may take 10-15 minutes...${NC}"
    echo ""
    
    # Check if vagrant is available
    if ! command -v vagrant &> /dev/null; then
        echo -e "${YELLOW}⚠ Vagrant not found. Skipping worker nodes.${NC}"
        echo "To add workers later, see: WORKER-SETUP.md"
    else
        cd "$(dirname "${SCRIPT_DIR}")"  # Go to project root
        
        # Create VMs
        echo "Creating worker VMs..."
        vagrant up --provider=libvirt 2>&1 | grep -E "(Bringing|Machine|Running|Successfully|Error)" || true
        
        # Join workers
        echo ""
        echo "Joining workers to control planes..."
        for tenant in dev staging prod; do
            "${SCRIPT_DIR}/join-worker.sh" "${tenant}" || echo -e "${YELLOW}Warning: Failed to join tcp-${tenant}-worker${NC}"
        done
        
        echo -e "${GREEN}✓ Worker nodes added${NC}"
    fi
fi

# Success!
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✓ Setup Complete!                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Your Kamaji environment is ready!"
echo ""

# Show what was created
echo -e "${BLUE}What you have:${NC}"
kubectl get tenantcontrolplanes 2>/dev/null || true
echo ""

if [ "$SKIP_WORKERS" = false ] && command -v vagrant &> /dev/null; then
    echo -e "${BLUE}Worker nodes:${NC}"
    vagrant status 2>/dev/null | grep -E "tcp-.*-worker" || true
    echo ""
fi

echo -e "${YELLOW}Next steps:${NC}"
echo ""
if [ "$SKIP_WORKERS" = true ]; then
    echo "1. Add worker nodes (optional):"
    echo "   See WORKER-SETUP.md for instructions"
    echo ""
fi
echo "1. Check nodes in each cluster:"
echo "   kubectl --kubeconfig=scripts/kubeconfigs/tcp-dev.kubeconfig get nodes"
echo ""
echo "2. Deploy demo applications:"
echo "   kubectl --kubeconfig=scripts/kubeconfigs/tcp-dev.kubeconfig apply -f manifests/examples/nginx-dev.yaml"
echo ""
echo "3. Get LoadBalancer IPs:"
echo "   kubectl --kubeconfig=scripts/kubeconfigs/tcp-dev.kubeconfig get svc -n demo"
echo ""
echo -e "${YELLOW}Documentation:${NC}"
echo "  • README: ./README.md"
echo "  • Worker Setup: ./WORKER-SETUP.md"
echo "  • Troubleshooting: ./docs/TROUBLESHOOTING.md"
echo ""
