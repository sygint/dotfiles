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
        # Faster initial connection for audio devices
        FastConnectable = true;
        # Retry reconnection up to 7 times on connection failure
        ReconnectAttempts = 7;
        # Intervals (seconds) between reconnection attempts
        ReconnectIntervals = "1,2,4,8,16,32,64";
      };
    };

    environment.systemPackages = with pkgs; [
      bluetuith # Modern TUI Bluetooth manager with mouse support
      bluez-tools # For bluetoothctl and bluetooth TUI
    ];

    # Ensure bluetooth is not soft-blocked by rfkill on boot
    systemd.services.bluetooth-rfkill-unblock = {
      description = "Unblock Bluetooth via rfkill";
      after = [ "bluetooth.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
      };
    };

    # Enable blueman service for GUI management
    services.blueman.enable = true;
  };
}
