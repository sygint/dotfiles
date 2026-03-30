# Disko disk configuration for Nexus
# Used by nixos-anywhere for automated disk partitioning and formatting
# HP EliteDesk G4 800 - typical single disk setup

{ ... }:
{
  disko.devices = {
    disk = {
      main = {
        # Device name - this system uses NVMe storage
        device = "/dev/nvme0n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # EFI boot partition
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
              };
            };
            # Swap partition - 16GB for hibernation/memory pressure
            swap = {
              size = "16G";
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
            # Root partition - uses remaining space
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [
                  "defaults"
                  "noatime"
                ];
              };
            };
          };
        };
      };
    };
  };
}
