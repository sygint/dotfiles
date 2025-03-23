{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.hardware.bluetooth;
in {
  options.settings.hardware.bluetooth = {
    enable = mkEnableOption "Bluetooth";
  };

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;

      # Show battery charge of connected Bluetooth devices.
      settings.general.experimental = true;
    };
  };
}