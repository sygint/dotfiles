#!/usr/bin/env bash
# Build and test NixOS configurations in VMs
# Usage: ./test-vm.sh <system-name> [memory-mb] [cpu-cores]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SYSTEM="${1:-}"
MEMORY="${2:-4096}"
CORES="${3:-4}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
    echo "Usage: $0 <system-name> [memory-mb] [cpu-cores]"
    echo
    echo "Examples:"
    echo "  $0 htpc              # Test HTPC with defaults (4GB RAM, 4 cores)"
    echo "  $0 htpc 8192         # Test HTPC with 8GB RAM"
    echo "  $0 orion 4096 2      # Test Orion with 4GB RAM, 2 cores"
    echo
    echo "Available systems:"
    cd "$REPO_ROOT"
    find systems -maxdepth 1 -type d ! -name systems -exec basename {} \; | sort
    exit 1
}

if [ -z "$SYSTEM" ]; then
    usage
fi

cd "$REPO_ROOT"

# Check if system configuration exists
if [ ! -d "systems/$SYSTEM" ]; then
    echo -e "${RED}❌ System '$SYSTEM' not found${NC}"
    echo
    usage
fi

echo -e "${BLUE}🔨 Building VM for $SYSTEM...${NC}"
echo -e "${BLUE}   Memory: ${MEMORY}MB${NC}"
echo -e "${BLUE}   Cores: ${CORES}${NC}"
echo

# Check if git tree is dirty and warn user
if [ -d .git ] && ! git diff --quiet 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Git tree is dirty (uncommitted changes)${NC}"
    echo -e "${YELLOW}   Using --impure flag to build anyway${NC}"
    echo
    IMPURE_FLAG="--impure"
else
    IMPURE_FLAG=""
fi

# Build the VM
if nixos-rebuild build-vm --flake ".#$SYSTEM" $IMPURE_FLAG; then
    echo
    echo -e "${GREEN}✅ VM built successfully${NC}"
    echo
    
    # Check if result symlink exists
    if [ -L result ]; then
        VM_SCRIPT="$(readlink -f result)/bin/run-${SYSTEM}-vm"
        
        if [ -f "$VM_SCRIPT" ]; then
            echo -e "${BLUE}🚀 Starting VM...${NC}"
            echo -e "${YELLOW}   Press Ctrl+Alt+G to release mouse/keyboard${NC}"
            echo -e "${YELLOW}   Press Ctrl+Alt+F to toggle fullscreen${NC}"
            echo
            
            # Export QEMU options and run VM
            export QEMU_OPTS="-enable-kvm -m $MEMORY -smp $CORES"
            
            # Run the VM
            exec "$VM_SCRIPT"
        else
            echo -e "${RED}❌ VM script not found: $VM_SCRIPT${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Result symlink not found${NC}"
        exit 1
    fi
else
    echo
    echo -e "${RED}❌ VM build failed${NC}"
    echo -e "${YELLOW}Check the errors above for details${NC}"
    exit 1
fi
