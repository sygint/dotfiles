# Hardware configuration for Nexus - HP EliteDesk G4 800
# This is a template - run nixos-generate-config on the actual hardware
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # HP EliteDesk G4 800 typically has Intel 8th gen CPUs
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Filesystems - REPLACE WITH ACTUAL HARDWARE CONFIG
  # Boot from NixOS installer, then run:
  #   nixos-generate-config --show-hardware-config
  # Copy the output here, especially the fileSystems sections
  
  # Example - YOU MUST REPLACE THESE UUIDs:
  # fileSystems."/" =
  #   { device = "/dev/disk/by-uuid/YOUR-ROOT-UUID";
  #     fsType = "ext4";
  #   };
  #
  # fileSystems."/boot" =
  #   { device = "/dev/disk/by-uuid/YOUR-BOOT-UUID";
  #     fsType = "vfat";
  #   };

  # Swap configuration (optional)
  # swapDevices = [ ];

  # Networking
  networking.useDHCP = lib.mkDefault true;

  # HP EliteDesk G4 has Intel CPU - enable microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Enable hardware video acceleration for Jellyfin (Intel Quick Sync)
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver      # For 8th gen and newer
      intel-vaapi-driver      # Fallback
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime   # OpenCL
    ];
  };
}
