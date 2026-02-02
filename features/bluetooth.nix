{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.bluetooth;
in
{
  options.modules.features.bluetooth.enable = mkEnableOption "Bluetooth hardware support";

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;

      # Show battery charge of connected Bluetooth devices.
      settings.general.experimental = true;
    };
  };
}
