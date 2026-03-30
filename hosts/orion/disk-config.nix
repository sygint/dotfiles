{ config, lib, pkgs, modulesPath, ... }:
let
  # Default disk device - override with disko.devices.disk.main.device if needed
  defaultDisk = "/dev/nvme0n1";
in
{
  # Orion partitioning: matches actual hardware-configuration.nix
  # - EFI partition (512M, vfat, /boot)
  # - LUKS encrypted root partition (remaining space)
  # - Root filesystem (ext4, /) inside LUKS
  # - Swap is handled via /swapfile in hardware config (16GB)
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = defaultDisk;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                # Password will be prompted during installation
                # Set to empty for password prompt, or configure via keyFile
                passwordFile = "/tmp/luks-password";
                settings = {
                  allowDiscards = true;
                  bypassWorkqueues = true;
                };
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
  };
}
