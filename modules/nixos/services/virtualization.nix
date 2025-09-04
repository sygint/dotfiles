{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf mkMerge;
  cfg = config.settings.services.virtualization;
in
{
  options.settings.services.virtualization = {
    enable = mkEnableOption "Enable Virtualization (VirtualBox or QEMU)";

    service = lib.mkOption {
      type = lib.types.enum [ "virtualbox" "qemu" ];
      default = "virtualbox";
      description = "The virtualization service to use (either VirtualBox or QEMU).";
    };

    username = lib.mkOption {
      type = lib.types.str;
      description = "User that will have access to VirtualBox.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (cfg.service == "virtualbox") {
      # VirtualBox
      virtualisation.virtualbox = {
        host = {
          enable = true;
          enableExtensionPack = true;
          enableKvm = true;
          addNetworkInterface = false;
        };

        guest = {
          enable = true;
          dragAndDrop = true;
          clipboard = true;
        };
      };
      users.extraGroups.vboxusers.members = [ cfg.username ];
    })
    (mkIf (cfg.service == "qemu") {
      # Qemu + Libvirt
      programs.virt-manager.enable = true;
      users.users."${cfg.username}".extraGroups = [ "libvirtd" ];

      virtualisation = {
        libvirtd = {
          enable = true;
          qemu = {
            swtpm.enable = true;
            ovmf.enable = true;
            ovmf.packages = [ pkgs.OVMFFull.fd ];
          };
        };
        spiceUSBRedirection.enable = true;
      };
      services.spice-vdagentd.enable = true;

      environment.systemPackages = with pkgs; [
        virt-manager
        virt-viewer
        spice
        spice-gtk
        spice-protocol
        win-virtio
        win-spice
        adwaita-icon-theme
      ];

      home-manager.users."${cfg.username}".dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
      };
    })
  ]);
}
