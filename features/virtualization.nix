{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    mkMerge
    types
    ;
  cfg = config.modules.features.virtualization;
in
{
  options.modules.features.virtualization = {
    enable = mkEnableOption "virtualization with VirtualBox or QEMU/KVM";

    service = mkOption {
      type = types.enum [
        "virtualbox"
        "qemu"
      ];
      default = "virtualbox";
      description = "The virtualization service to use (either VirtualBox or QEMU).";
    };

    username = mkOption {
      type = types.str;
      default = userVars.username;
      description = "User that will have access to virtualization.";
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
      users.users."${cfg.username}".extraGroups = [ "vboxsf" ];
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
            # On current NixOS releases, libvirt's default QEMU firmware setup
            # already includes OVMF (including the "full" OVMFFull-style image),
            # so we do not need to add OVMF packages or options here. On older
            # NixOS versions, you may still need to configure OVMF explicitly.
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
        virtio-win
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
