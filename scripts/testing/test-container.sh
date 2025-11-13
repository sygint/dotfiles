#!/usr/bin/env bash
# Manage NixOS containers for testing
# Usage: ./test-container.sh <system-name> <action>

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SYSTEM="${1:-}"
ACTION="${2:-help}"
CONTAINER_NAME="test-${SYSTEM}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
    echo "Usage: $0 <system-name> <action>"
    echo
    echo "Actions:"
    echo "  create    - Create new container"
    echo "  start     - Start container"
    echo "  stop      - Stop container"
    echo "  restart   - Restart container"
    echo "  shell     - Open shell in container"
    echo "  status    - Show container status"
    echo "  ip        - Show container IP address"
    echo "  destroy   - Remove container"
    echo "  list      - List all containers"
    echo
    echo "Examples:"
    echo "  $0 htpc create       # Create HTPC test container"
    echo "  $0 htpc start        # Start HTPC container"
    echo "  $0 htpc shell        # Open shell in HTPC container"
    echo "  $0 htpc destroy      # Remove HTPC container"
    echo
    echo "Available systems:"
    cd "$REPO_ROOT"
    find systems -maxdepth 1 -type d ! -name systems -exec basename {} \; | sort
    exit 1
}

if [ "$ACTION" = "list" ]; then
    echo -e "${BLUE}📦 NixOS Containers:${NC}"
    sudo nixos-container list
    exit 0
fi

if [ -z "$SYSTEM" ] || [ "$ACTION" = "help" ] || [ "$ACTION" = "--help" ] || [ "$ACTION" = "-h" ]; then
    usage
fi

cd "$REPO_ROOT"

# Check if system configuration exists
if [ ! -d "systems/$SYSTEM" ]; then
    echo -e "${RED}❌ System '$SYSTEM' not found${NC}"
    echo
    usage
fi

case "$ACTION" in
    create)
        echo -e "${BLUE}📦 Creating container ${CONTAINER_NAME}...${NC}"
        echo
        
        # Check if container already exists
        if sudo nixos-container list | grep -q "^${CONTAINER_NAME}$"; then
            echo -e "${YELLOW}⚠️  Container ${CONTAINER_NAME} already exists${NC}"
            echo -e "${YELLOW}   Use 'destroy' first if you want to recreate it${NC}"
            exit 1
        fi
        
        # Create container configuration
        sudo nixos-container create "$CONTAINER_NAME" \
            --config-file "./systems/${SYSTEM}/default.nix"
        
        echo
        echo -e "${GREEN}✅ Container created successfully${NC}"
        echo -e "${BLUE}   To start: $0 $SYSTEM start${NC}"
        ;;
        
    start)
        echo -e "${BLUE}▶️  Starting container ${CONTAINER_NAME}...${NC}"
        
        if ! sudo nixos-container list | grep -q "^${CONTAINER_NAME}$"; then
            echo -e "${RED}❌ Container ${CONTAINER_NAME} does not exist${NC}"
            echo -e "${YELLOW}   Create it first: $0 $SYSTEM create${NC}"
            exit 1
        fi
        
        sudo nixos-container start "$CONTAINER_NAME"
        
        # Wait a moment for container to start
        sleep 2
        
        echo
        echo -e "${GREEN}✅ Container started${NC}"
        
        # Show IP if available
        if IP=$(sudo nixos-container show-ip "$CONTAINER_NAME" 2>/dev/null); then
            echo -e "${BLUE}   IP Address: $IP${NC}"
        fi
        
        echo -e "${BLUE}   Status: $0 $SYSTEM status${NC}"
        echo -e "${BLUE}   Shell: $0 $SYSTEM shell${NC}"
        ;;
        
    stop)
        echo -e "${BLUE}⏸️  Stopping container ${CONTAINER_NAME}...${NC}"
        sudo nixos-container stop "$CONTAINER_NAME"
        echo -e "${GREEN}✅ Container stopped${NC}"
        ;;
        
    restart)
        echo -e "${BLUE}🔄 Restarting container ${CONTAINER_NAME}...${NC}"
        sudo nixos-container stop "$CONTAINER_NAME" 2>/dev/null || true
        sleep 1
        sudo nixos-container start "$CONTAINER_NAME"
        echo -e "${GREEN}✅ Container restarted${NC}"
        ;;
        
    shell)
        echo -e "${BLUE}💻 Opening shell in ${CONTAINER_NAME}...${NC}"
        echo -e "${YELLOW}   (Type 'exit' or press Ctrl+D to leave)${NC}"
        echo
        sudo nixos-container root-login "$CONTAINER_NAME"
        ;;
        
    status)
        echo -e "${BLUE}📊 Container Status: ${CONTAINER_NAME}${NC}"
        echo
        
        if sudo nixos-container list | grep -q "^${CONTAINER_NAME}$"; then
            # Check if running
            if systemctl is-active "container@${CONTAINER_NAME}.service" >/dev/null 2>&1; then
                echo -e "${GREEN}   State: RUNNING${NC}"
                
                # Show IP
                if IP=$(sudo nixos-container show-ip "$CONTAINER_NAME" 2>/dev/null); then
                    echo -e "${BLUE}   IP: $IP${NC}"
                fi
                
                # Show resource usage
                echo
                echo -e "${BLUE}   Resource Usage:${NC}"
                systemctl status "container@${CONTAINER_NAME}.service" --no-pager | grep -E "(Memory|CPU)" || true
            else
                echo -e "${YELLOW}   State: STOPPED${NC}"
            fi
        else
            echo -e "${RED}   Container does not exist${NC}"
            echo -e "${YELLOW}   Create it: $0 $SYSTEM create${NC}"
        fi
        ;;
        
    ip)
        if IP=$(sudo nixos-container show-ip "$CONTAINER_NAME" 2>/dev/null); then
            echo "$IP"
        else
            echo -e "${RED}❌ Container not running or no IP assigned${NC}"
            exit 1
        fi
        ;;
        
    destroy)
        echo -e "${YELLOW}🗑️  Destroying container ${CONTAINER_NAME}...${NC}"
        read -p "Are you sure? This will delete all container data. [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Stop first if running
            sudo nixos-container stop "$CONTAINER_NAME" 2>/dev/null || true
            sleep 1
            sudo nixos-container destroy "$CONTAINER_NAME"
            echo -e "${GREEN}✅ Container destroyed${NC}"
        else
            echo -e "${BLUE}   Cancelled${NC}"
        fi
        ;;
        
    *)
        echo -e "${RED}❌ Unknown action: $ACTION${NC}"
        echo
        usage
        ;;
esac
