{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.services.mullvad;
in
{
  options.modules.services.mullvad.enable = mkEnableOption "Mullvad VPN and Browser";

  config = mkIf cfg.enable {
    services = {
      mullvad-vpn = {
        enable = true;
        package = pkgs.mullvad-vpn;
      };
    };

  };
}
