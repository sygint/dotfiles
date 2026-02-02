{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.mullvad;
in
{
  options.modules.features.mullvad = {
    enable = mkEnableOption "Mullvad VPN and Browser";
  };

  config = mkIf cfg.enable {
    # System-level configuration
    services.mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };

    # Home-manager configuration for all users
    home-manager.sharedModules = [
      {
        home.packages = with pkgs; [
          mullvad-browser
        ];
      }
    ];
  };
}
