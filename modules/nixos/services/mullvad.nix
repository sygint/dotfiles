{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.services.mullvad;
in {
  options.settings.services.mullvad.enable = mkEnableOption "Mullvad VPN and Browser";

  config = mkIf cfg.enable {
    services = {
      mullvad-vpn = {
        enable = true;
        package = pkgs.mullvad-vpn;
      };
    };

  };
}