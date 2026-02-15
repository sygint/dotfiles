{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    ;
  cfg = config.modules.features.windows-vm;
in
{
  options.modules.features.windows-vm = {
    enable = mkEnableOption "Windows 11 VM for creating Windows To Go USB";
    iso = mkOption {
      type = types.path;
      default = "/home/syg/Downloads/Win11_24H2_English_x64.iso";
      description = "Path to Windows ISO";
    };
    diskSize = mkOption {
      type = types.int;
      default = 40;
      description = "Disk size in GB";
    };
    memory = mkOption {
      type = types.int;
      default = 4096;
      description = "Memory in MB";
    };
    cores = mkOption {
      type = types.int;
      default = 2;
      description = "CPU cores";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.libvirtd = {
      onBoot = "ignore";
      onShutdown = "ignore";
    };

    users.users.syg.extraGroups = [
      "libvirtd"
      "kvm"
    ];

    # Create the Windows VM via virt-install
    system.activationScripts.create-windows-vm = ''
      set -e

      VM_NAME="windows11"

      # Check if VM already exists
      if virsh dominfo "$VM_NAME" >/dev/null 2>&1; then
        echo "VM $VM_NAME already exists"
      else
        echo "Creating Windows 11 VM..."

        # Create disk image
        mkdir -p /var/lib/libvirt/images
        truncate -s ${toString cfg.diskSize}G /var/lib/libvirt/images/windows11.qcow2

        # Install Windows VM
        virt-install \
          --name "$VM_NAME" \
          --memory ${toString cfg.memory} \
          --vcpus ${toString cfg.cores} \
          --disk path=/var/lib/libvirt/images/windows11.qcow2,format=qcow2 \
          --cdrom "${cfg.iso}" \
          --os-variant win11 \
          --network network=default \
          --graphics spice \
          --video qxl \
          --machine q35 \
          --boot uefi \
          --controller type=usb,model=qemu-xhci

        echo "Windows 11 VM created successfully"
        echo "Run 'virt-manager' to access the VM"
      fi
    '';
  };
}
