#!/bin/bash
set -e

VM_NAME="windows11"
ISO_PATH="${1:-/home/syg/Downloads/Win11_24H2_English_x64.iso}"
DISK_SIZE="${2:-40}"
MEMORY="${3:-4096}"
CORES="${4:-2}"

echo "Creating Windows 11 VM..."
echo "  ISO: $ISO_PATH"
echo "  Disk: ${DISK_SIZE}GB"
echo "  Memory: ${MEMORY}MB"
echo "  CPUs: $CORES"

# Create disk image
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
  --controller type=usb,model=qemu-xhci

echo ""
echo "Windows 11 VM created successfully!"
echo "Run 'virt-manager' to access the VM"
