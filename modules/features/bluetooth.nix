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
      # Power on Bluetooth adapter at boot
      powerOnBoot = true;

      settings.General = {
        # Show battery charge of connected Bluetooth devices
        Experimental = true;
        # Enable all Bluetooth profiles
        Enable = "Source,Sink,Media,Socket";
      };
    };

    # Enable blueman service for GUI management
    services.blueman.enable = true;
  };
}
