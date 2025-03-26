{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.services.protonmail-bridge;
in {
  options.settings.services.protonmail-bridge = {
    enable = mkEnableOption "ProtonMail Bridge";

    username = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Username for the Syncthing";
    };

    password = lib.mkOption {
      type = lib.types.str;
      default = "password";
      description = "Password for the Syncthing";
    };
  };

  config = mkIf cfg.enable {
    services.protonmail-bridge.enable = true;

    environment.systemPackages = with pkgs; [
      protonmail-bridge
    ];
  };
}