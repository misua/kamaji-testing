#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Progress tracking
TOTAL_STEPS=5
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
echo ""
echo "Estimated time: 10-15 minutes"
echo ""

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
"${SCRIPT_DIR}/05-deploy-tenant-control-planes.sh" || print_error "Failed to deploy tenant control planes"

# Success!
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✓ Setup Complete!                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Your Kamaji environment is ready!"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Check tenant control planes:"
echo "   kubectl get tenantcontrolplanes"
echo ""
echo "2. Extract kubeconfig for a tenant:"
echo "   ./scripts/06-extract-kubeconfig.sh tcp-dev"
echo "   ./scripts/06-extract-kubeconfig.sh tcp-staging"
echo "   ./scripts/06-extract-kubeconfig.sh tcp-prod"
echo ""
echo "3. Use a tenant cluster:"
echo "   export KUBECONFIG=./kubeconfigs/tcp-dev.kubeconfig"
echo "   kubectl get nodes"
echo ""
echo "4. View all resources:"
echo "   kubectl get all -A"
echo ""
echo -e "${YELLOW}Documentation:${NC}"
echo "  • README: ./README.md"
echo "  • Prerequisites: ./docs/PREREQUISITES.md"
echo "  • Troubleshooting: ./docs/TROUBLESHOOTING.md"
echo ""
