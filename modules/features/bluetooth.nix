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

    # Ensure bluetooth is not soft-blocked by rfkill
    # Use udev rule to trigger when BT device appears (handles firmware init race)
    services.udev.extraRules = ''
      # Unblock Bluetooth when the hci device appears
      SUBSYSTEM=="rfkill", ATTR{type}=="bluetooth", ACTION=="add", RUN+="${pkgs.util-linux}/bin/rfkill unblock bluetooth"
    '';

    # Fallback: systemd service to unblock after bluetooth service starts
    systemd.services.bluetooth-rfkill-unblock = {
      description = "Unblock Bluetooth via rfkill";
      after = [ "bluetooth.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
      };
    };

    # Also unblock when graphical session starts (handles DE/WM re-blocking)
    systemd.user.services.bluetooth-rfkill-unblock = {
      description = "Unblock Bluetooth via rfkill (user session)";
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
      };
    };

    # Enable blueman service for GUI management
    services.blueman.enable = true;
  };
}
