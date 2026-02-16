#!/usr/bin/env bash
set -e

VM_NAME="windows11"
ISO_PATH="${1:-}"
DISK_SIZE="${2:-80}"
MEMORY="${3:-4096}"
CORES="${4:-2}"

# Prompt for ISO path if not provided as argument
if [ -z "$ISO_PATH" ]; then
  read -rp "Path to Windows 11 ISO: " ISO_PATH
fi

# Resolve to absolute path
ISO_PATH="$(realpath "$ISO_PATH" 2>/dev/null || echo "$ISO_PATH")"

# Verify ISO exists
if [ ! -f "$ISO_PATH" ]; then
  echo "ERROR: ISO not found at $ISO_PATH"
  exit 1
fi

echo "Creating Windows 11 VM..."
echo "  ISO: $ISO_PATH"
echo "  Disk: ${DISK_SIZE}GB"
echo "  Memory: ${MEMORY}MB"
echo "  CPUs: $CORES"

# Create disk directory
mkdir -p /var/lib/libvirt/images
truncate -s ${DISK_SIZE}G /var/lib/libvirt/images/windows11.qcow2

# Install Windows VM
      virt-install \
        --name "$VM_NAME" \
        --memory "$MEMORY" \
        --vcpus "$CORES" \
        --disk path=/var/lib/libvirt/images/windows11.qcow2,format=qcow2 \
        --cdrom "$ISO_PATH" \
        --os-variant win11 \
        --network network=default \
        --graphics spice \
        --video qxl \
        --machine q35 \
        --boot uefi \
        --controller type=usb,model=qemu-xhci \
      --tpm type=emulator,version=2.0 \
        --noautoconsole

echo ""
echo "Windows 11 VM created successfully!"
echo "Run 'virt-manager' to access the VM"
