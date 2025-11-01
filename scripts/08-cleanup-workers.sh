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

echo -e "${BLUE}==> Cleaning up worker VMs${NC}"
echo ""

cd "${PROJECT_ROOT}"

# Check if Vagrant is installed
if ! command -v vagrant &> /dev/null; then
    echo -e "${YELLOW}Vagrant not installed, skipping worker cleanup${NC}"
    exit 0
fi

# Check if any VMs exist
if ! vagrant status 2>/dev/null | grep -q "running\|poweroff\|saved"; then
    echo -e "${YELLOW}No worker VMs found${NC}"
    exit 0
fi

echo "Destroying worker VMs..."
vagrant destroy -f

echo ""
echo -e "${GREEN}✓ Worker VMs cleaned up${NC}"
