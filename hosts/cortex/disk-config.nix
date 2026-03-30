{ config, lib, pkgs, modulesPath, ... }:
let
  # Default disk device - override with disko.devices.disk.main.device if needed
  defaultDisk = "/dev/nvme0n1";
in
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = defaultDisk;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";  # Larger for AI kernels
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];  # Secure boot partition
              };
            };
            root = {
              size = "100%";
              type = "8300";
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
}
