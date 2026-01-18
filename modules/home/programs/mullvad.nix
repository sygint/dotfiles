{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.mullvad-browser;
in
{
  options.modules.programs.mullvad-browser = {
    enable = lib.mkEnableOption "Mullvad Browser - Privacy-focused browser by Mullvad VPN";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      mullvad-browser
    ];
  };
}
