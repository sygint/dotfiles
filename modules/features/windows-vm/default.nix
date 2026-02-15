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

    environment.systemPackages = [
      pkgs.libvirt
      pkgs.libosinfo
    ];

    users.users.syg.extraGroups = [
      "libvirtd"
      "kvm"
    ];

    # Note: VM creation is manual via virt-manager after deployment
    # Run: virt-manager to create and start the Windows 11 VM
  };
}
