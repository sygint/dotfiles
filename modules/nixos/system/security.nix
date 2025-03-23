{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.system.security;
in {
  options.settings.system.security = {
    enable = mkEnableOption "Security";
  };

  config = mkIf cfg.enable {
    security = {
      sudo = {
        enable             = true;
        wheelNeedsPassword = true;
      };

      rtkit.enable = true;
    };
  };
}