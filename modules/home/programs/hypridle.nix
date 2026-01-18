{ config, lib, pkgs, userVars, ... }:

let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modules.programs.hypridle;
  hyprlandCfg = config.modules.programs.hyprland;
  configRoot = "/home/${userVars.username}/.config/nixos";
  configscriptsDir = "${configRoot}/scripts";
  barCfg = userVars.hyprland.bar or "hyprpanel";  # Default to hyprpanel if not specified
  hostName = userVars.hostName or "orion";  # Default to orion for backward compatibility
  # Scripts directory for system-specific Hyprland scripts
  # Note: Only systems with Hyprland enabled should have this directory
  systemScriptsDir = "${configRoot}/systems/${hostName}/scripts";
in
{
  options.modules.programs.hypridle.enable = mkEnableOption "Hypridle idle daemon";

  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;

      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock"; # avoid starting multiple hyprlock instances.
          before_sleep_cmd = "loginctl lock-session"; # lock before suspend.
          after_sleep_cmd = "hyprctl dispatch dpms on && ${systemScriptsDir}/monitor-handler.sh --fast --bar=${barCfg}"; # restore display and monitors after suspend.
          ignore_dbus_inhibit = false; # respect app inhibitors (e.g., video playback)
        };

        listener = [
          # Dim the screen
          {
            timeout = 150; # 2.5min
            on-timeout = "brightnessctl -s set 10"; # set monitor backlight to minimum, avoid 0 on OLED monitor.
            on-resume = "brightnessctl -r"; # monitor backlight restore.
          }

          # Screenlock
          {
            timeout = 300; # 5 minutes
            on-timeout = "loginctl lock-session"; # lock the session
          }

          # DPMS - lock-aware monitor control
          # This listener uses a smart script that only turns off monitors when the screen is locked.
          # Benefits:
          #  - Work/watch videos without interruption (monitors stay on while unlocked)
          #  - Keep browsers open overnight (wake locks ignored for DPMS via ignore_inhibit)
          #  - Auto-off when locked and away (monitors turn off after 10min when locked)
          # See: scripts/dpms-off-if-locked.sh
          {
            timeout = 600; # 10 minutes
            on-timeout = "${configscriptsDir}/dpms-off-if-locked.sh"; # turn off displays only if session is locked
            on-resume = "hyprctl dispatch dpms on && brightnessctl -r"; # turn on the display, restore backlight
            ignore_inhibit = true; # check lock state even when apps request wake locks
          }

          # Suspend
          {
            timeout = 1200; # 20 minutes
            on-timeout = "systemctl suspend"; # suspend the system
          }
        ];
      };
    };
  };
}
