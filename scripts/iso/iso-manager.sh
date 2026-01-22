#!/usr/bin/env bash
# NixOS ISO Manager
# Build, flash, and manage custom NixOS installation ISOs

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ $*${NC}"; }
success() { echo -e "${GREEN}✓ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠ $*${NC}"; }
error() { echo -e "${RED}✗ $*${NC}" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="${FLAKE_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
ISO_FLAKE_DIR="${ISO_FLAKE_DIR:-$FLAKE_DIR/systems/custom-live-iso}"
ISO_RESULT_PATH="$ISO_FLAKE_DIR/result/iso/nixos-homelab-installer.iso"

usage() {
    cat <<EOF
NixOS ISO Manager

Usage: $0 <command> [options]

Commands:
  build              - Build custom NixOS ISO
  flash <device>     - Flash ISO to USB device
  list-devices       - Show available USB devices
  path               - Show path to built ISO
  clean              - Remove build artifacts

Environment Variables:
  FLAKE_DIR      - Path to flake directory (default: auto-detected)
  ISO_FLAKE_DIR  - Path to ISO flake (default: \$FLAKE_DIR/systems/custom-live-iso)

Examples:
  $0 build
  $0 list-devices
  $0 flash /dev/sda
  $0 path

Safety:
  - ISO flashing requires sudo
  - Confirmation prompt before destructive operations
  - USB device detection to prevent accidental internal drive wipes
EOF
}

build_iso() {
    info "Building custom live ISO..."
    
    if [ ! -d "$ISO_FLAKE_DIR" ]; then
        error "ISO flake directory not found: $ISO_FLAKE_DIR"
        exit 1
    fi
    
    cd "$ISO_FLAKE_DIR"
    
    info "This will take a few minutes (downloading packages + building)..."
    echo ""
    
    if nix build ".#nixosConfigurations.installer.config.system.build.isoImage"; then
        echo ""
        success "ISO built successfully!"
        
        if [ -f "$ISO_RESULT_PATH" ]; then
            local iso_size
            iso_size=$(du -h "$ISO_RESULT_PATH" | cut -f1)
            success "ISO location: $ISO_RESULT_PATH"
            success "ISO size: $iso_size"
            echo ""
            info "Next steps:"
            echo "  1. List USB devices: $0 list-devices"
            echo "  2. Flash to USB: $0 flash /dev/sdX"
        else
            warn "ISO built but not found at expected location: $ISO_RESULT_PATH"
        fi
    else
        error "ISO build failed"
        exit 1
    fi
    
    cd - >/dev/null
}

list_devices() {
    info "Available block devices:"
    echo ""
    
    # Show lsblk with useful columns
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,VENDOR,MODEL 2>/dev/null | grep -E "^NAME|disk|part" || true
    
    echo ""
    info "USB devices (likely candidates):"
    echo ""
    
    # Try to identify USB devices
    local found_usb=false
    for dev in /dev/sd[a-z]; do
        if [ -b "$dev" ]; then
            # Check if it's USB via udev
            if udevadm info --query=property --name="$dev" 2>/dev/null | grep -q "ID_BUS=usb"; then
                local size
                size=$(lsblk -ndo SIZE "$dev" 2>/dev/null || echo "unknown")
                local model
                model=$(lsblk -ndo MODEL "$dev" 2>/dev/null || echo "unknown")
                echo "  $dev - $size - $model (USB)"
                found_usb=true
            fi
        fi
    done
    
    if [ "$found_usb" = false ]; then
        warn "No USB devices detected"
    fi
    
    echo ""
    warn "IMPORTANT: Double-check the device before flashing!"
    info "Use: $0 flash /dev/sdX"
}

flash_iso() {
    local device="${1:-}"
    
    if [ -z "$device" ]; then
        error "Device is required"
        echo ""
        info "Usage: $0 flash <device>"
        info "Example: $0 flash /dev/sda"
        echo ""
        info "Tip: Run '$0 list-devices' to see available devices"
        exit 1
    fi
    
    if [ ! -f "$ISO_RESULT_PATH" ]; then
        error "ISO not found at: $ISO_RESULT_PATH"
        info "Build it first with: $0 build"
        exit 1
    fi
    
    if [ ! -b "$device" ]; then
        error "Device not found or not a block device: $device"
        info "Run '$0 list-devices' to see available devices"
        exit 1
    fi
    
    # Safety checks
    if [[ "$device" == *"nvme"* ]] || [[ "$device" == *"mmcblk"* ]]; then
        warn "WARNING: $device looks like an internal drive!"
        warn "Are you SURE this is your USB device?"
        echo ""
    fi
    
    # Check if device is mounted
    if mount | grep -q "^$device"; then
        warn "WARNING: $device has mounted partitions!"
        mount | grep "^$device"
        echo ""
    fi
    
    local iso_size
    iso_size=$(du -h "$ISO_RESULT_PATH" | cut -f1)
    
    echo ""
    warn "═══════════════════════════════════════════════════════════"
    warn "  DESTRUCTIVE OPERATION - THIS WILL ERASE $device!"
    warn "═══════════════════════════════════════════════════════════"
    echo ""
    info "ISO: $ISO_RESULT_PATH ($iso_size)"
    info "Target: $device"
    echo ""
    read -r -p "Type 'yes' to flash the ISO: " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        info "Cancelled"
        exit 0
    fi
    
    info "Unmounting any mounted partitions on $device..."
    sudo umount "${device}"* 2>/dev/null || true
    
    echo ""
    info "Flashing ISO to $device..."
    
    if sudo dd if="$ISO_RESULT_PATH" of="$device" bs=4M status=progress conv=fsync; then
        echo ""
        success "ISO flashed successfully to $device!"
        info "Syncing filesystem..."
        sync
        success "Done! You can now safely remove the USB drive"
        echo ""
        info "Next steps:"
        echo "  1. Insert USB into target system"
        echo "  2. Boot from USB"
        echo "  3. Deploy with: bootstrap-system.sh <system> <ip>"
    else
        echo ""
        error "Failed to flash ISO"
        exit 1
    fi
}

show_path() {
    if [ -f "$ISO_RESULT_PATH" ]; then
        echo "$ISO_RESULT_PATH"
        local iso_size
        iso_size=$(du -h "$ISO_RESULT_PATH" | cut -f1)
        info "Size: $iso_size"
    else
        warn "ISO not found at: $ISO_RESULT_PATH"
        info "Build it first with: $0 build"
        exit 1
    fi
}

clean_build() {
    info "Cleaning ISO build artifacts..."
    
    if [ -d "$ISO_FLAKE_DIR/result" ]; then
        rm -rf "$ISO_FLAKE_DIR/result"
        success "Removed: $ISO_FLAKE_DIR/result"
    else
        info "No build artifacts to clean"
    fi
}

# Main execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        usage
        exit 0
    fi
    
    cmd="$1"
    shift || true
    
    case "$cmd" in
        build)
            build_iso
            ;;
        flash)
            flash_iso "${1:-}"
            ;;
        list-devices)
            list_devices
            ;;
        path)
            show_path
            ;;
        clean)
            clean_build
            ;;
        *)
            error "Unknown command: $cmd"
            echo ""
            usage
            exit 1
            ;;
    esac
fi
