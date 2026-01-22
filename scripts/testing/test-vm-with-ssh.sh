#!/usr/bin/env bash
# Build and test NixOS configurations in VMs with SSH port forwarding
# This version enables SSH testing from the host
# Usage: ./test-vm-with-ssh.sh <system-name> [memory-mb] [cpu-cores] [ssh-port]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
SYSTEM="${1:-}"
MEMORY="${2:-4096}"
CORES="${3:-4}"
SSH_PORT="${4:-2222}"
DISK_SIZE="40G"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

usage() {
    echo "Usage: $0 <system-name> [memory-mb] [cpu-cores] [ssh-port]"
    echo
    echo "Arguments:"
    echo "  memory-mb    RAM in MB (default: 4096)"
    echo "  cpu-cores    Number of CPU cores (default: 4)"
    echo "  ssh-port     Host port to forward to VM SSH (default: 2222)"
    echo
    echo "This script enables SSH access from host to VM via:"
    echo "  ssh -p $SSH_PORT deploy@localhost"
    echo
    echo "Examples:"
    echo "  $0 nexus              # Test nexus with 4GB RAM, SSH on port 2222"
    echo "  $0 nexus 8192         # Test nexus with 8GB RAM"
    echo "  $0 nexus 8192 4 10022 # Test nexus, SSH on port 10022"
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

echo -e "${BLUE}🔨 Building VM for $SYSTEM with SSH access...${NC}"
echo -e "${BLUE}   Memory: ${MEMORY}MB${NC}"
echo -e "${BLUE}   Cores: ${CORES}${NC}"
echo -e "${BLUE}   SSH Port: ${SSH_PORT} (host) -> 22 (VM)${NC}"
echo -e "${BLUE}   Disk Size: ${DISK_SIZE}${NC}"
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
            echo -e "${BLUE}🚀 Starting VM with SSH port forwarding...${NC}"
            echo
            echo -e "${BLUE}📝 Login credentials:${NC}"
            echo -e "   Console: rescue / rescue"
            echo -e "   SSH:     deploy@localhost -p $SSH_PORT (key auth only)"
            echo
            echo -e "${BLUE}🌐 SSH Access:${NC}"
            echo -e "   Test connection: ${GREEN}ssh -p $SSH_PORT deploy@localhost${NC}"
            echo -e "   Test sudo:       ${GREEN}ssh -p $SSH_PORT deploy@localhost 'sudo -n whoami'${NC}"
            echo -e "   Health check:    ${GREEN}ssh -p $SSH_PORT deploy@localhost 'vm-health-check'${NC}"
            echo
            echo -e "${BLUE}⌨️  Serial console controls:${NC}"
            echo -e "   Ctrl+A then X - Exit QEMU"
            echo -e "   Ctrl+A then C - QEMU monitor"
            echo
            
            # Set QEMU options with SSH port forwarding
            export QEMU_OPTS="-enable-kvm -m $MEMORY -smp $CORES -nographic -nic user,hostfwd=tcp::${SSH_PORT}-:22"
            export NIX_DISK_IMAGE_SIZE="$DISK_SIZE"
            
            # Try to detect available terminal emulator
            if command -v kitty &> /dev/null; then
                echo -e "${GREEN}✅ Opening VM in new Kitty terminal...${NC}"
                echo -e "${YELLOW}   Test SSH from this terminal while VM runs${NC}"
                echo
                kitty --title "NixOS VM: $SYSTEM (SSH: localhost:$SSH_PORT)" -- "$VM_SCRIPT" &
            elif command -v alacritty &> /dev/null; then
                echo -e "${GREEN}✅ Opening VM in new Alacritty terminal...${NC}"
                echo -e "${YELLOW}   Test SSH from this terminal while VM runs${NC}"
                echo
                alacritty --title "NixOS VM: $SYSTEM" -e "$VM_SCRIPT" &
            elif command -v gnome-terminal &> /dev/null; then
                echo -e "${GREEN}✅ Opening VM in new GNOME terminal...${NC}"
                echo -e "${YELLOW}   Test SSH from this terminal while VM runs${NC}"
                echo
                gnome-terminal --title "NixOS VM: $SYSTEM" -- "$VM_SCRIPT" &
            elif command -v xterm &> /dev/null; then
                echo -e "${GREEN}✅ Opening VM in new xterm...${NC}"
                echo -e "${YELLOW}   Test SSH from this terminal while VM runs${NC}"
                echo
                xterm -title "NixOS VM: $SYSTEM" -e "$VM_SCRIPT" &
            else
                echo -e "${YELLOW}⚠️  No terminal emulator found, running in current terminal${NC}"
                echo -e "${YELLOW}   Install kitty, alacritty, or gnome-terminal for better experience${NC}"
                echo -e "${YELLOW}   You won't be able to test SSH from this terminal${NC}"
                echo
                exec "$VM_SCRIPT"
            fi
            
            # Wait a moment for the VM to start
            sleep 3
            echo
            echo -e "${GREEN}✅ VM started in new terminal window${NC}"
            echo
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${BLUE}  Waiting for VM to boot (this may take 30-60s)...${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo
            
            # Wait for SSH to become available
            MAX_WAIT=60
            WAITED=0
            while [ $WAITED -lt $MAX_WAIT ]; do
                if timeout 2 ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $SSH_PORT deploy@localhost 'exit 0' 2>/dev/null; then
                    echo
                    echo -e "${GREEN}✅✅✅ VM is ready! SSH is accessible! ✅✅✅${NC}"
                    echo
                    echo -e "${BLUE}🧪 Running automated tests...${NC}"
                    echo
                    
                    # Test 1: Basic SSH
                    echo -e "${YELLOW}Test 1: SSH Connection${NC}"
                    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $SSH_PORT deploy@localhost 'hostname' 2>/dev/null; then
                        echo -e "${GREEN}✅ SSH connection successful${NC}"
                    else
                        echo -e "${RED}❌ SSH connection failed${NC}"
                    fi
                    echo
                    
                    # Test 2: Passwordless sudo
                    echo -e "${YELLOW}Test 2: Passwordless Sudo${NC}"
                    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $SSH_PORT deploy@localhost 'sudo -n whoami' 2>/dev/null | grep -q root; then
                        echo -e "${GREEN}✅ Passwordless sudo works${NC}"
                    else
                        echo -e "${RED}❌ Passwordless sudo failed${NC}"
                    fi
                    echo
                    
                    # Test 3: Health check
                    echo -e "${YELLOW}Test 3: System Health Check${NC}"
                    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $SSH_PORT deploy@localhost 'vm-health-check' 2>/dev/null || echo -e "${YELLOW}⚠️  Health check unavailable${NC}"
                    echo
                    
                    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                    echo -e "${GREEN}  All tests complete! VM is ready for use.${NC}"
                    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                    echo
                    echo -e "${YELLOW}💡 Useful commands:${NC}"
                    echo -e "   SSH into VM:     ${GREEN}ssh -p $SSH_PORT deploy@localhost${NC}"
                    echo -e "   Run as root:     ${GREEN}ssh -p $SSH_PORT deploy@localhost 'sudo -i'${NC}"
                    echo -e "   Check services:  ${GREEN}ssh -p $SSH_PORT deploy@localhost 'systemctl status jellyfin grafana prometheus'${NC}"
                    echo
                    break
                fi
                echo -n "."
                sleep 2
                WAITED=$((WAITED + 2))
            done
            
            if [ $WAITED -ge $MAX_WAIT ]; then
                echo
                echo -e "${YELLOW}⚠️  SSH not ready after ${MAX_WAIT}s${NC}"
                echo -e "${YELLOW}   The VM may still be booting. Try manually:${NC}"
                echo -e "   ${GREEN}ssh -p $SSH_PORT deploy@localhost${NC}"
                echo
            fi
            
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
