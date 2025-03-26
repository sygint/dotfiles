{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.services.virtualbox;
in {
  options.settings.services.virtualbox = {
    enable = mkEnableOption "VirtualBox";

    username = lib.mkOption {
      type = lib.types.str;
      description = "User that will have access to VirtualBox.";
    };
  };

  config = mkIf cfg.enable {
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
  };
}