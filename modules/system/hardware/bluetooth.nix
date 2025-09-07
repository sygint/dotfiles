{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.hardware.bluetooth;
in
{
  options.modules.hardware.bluetooth.enable = mkEnableOption "Bluetooth";

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;

      # Show battery charge of connected Bluetooth devices.
      settings.general.experimental = true;
    };
  };
}
