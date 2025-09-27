{ config, lib, pkgs, userVars, ... }:

let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modules.programs.hypridle;
  hyprlandCfg = config.modules.programs.hyprland;
  barSystem = hyprlandCfg.systemBar or "hyprpanel";
  configRoot = "/home/${userVars.username}/.config/nixos";
  configscriptsDir = "${configRoot}/scripts";
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
          after_sleep_cmd = "hyprctl dispatch dpms on && ${configscriptsDir}/monitor-handler.sh --fast --bar=${barSystem}"; # restore display and monitors after suspend.
          ignore_dbus_inhibit = true; # ignore applications trying to inhibit idle (like browsers with video content)
        };

        listeners = [
          # Dim the screen
          {
            timeout = 150; # 2.5min.
            on-timeout = "brightnessctl -s set 10"; # set monitor backlight to minimum, avoid 0 on OLED monitor.
            on-resume = "brightnessctl -r"; # monitor backlight restore.
          }

          # Screenlock
          {
            timeout = 300; # 5 minutes
            on-timeout = "loginctl lock-session"; # lock the session
          }

          # DPMS
          {
            timeout = 600; # 10 minutes
            on-timeout = "hyprctl dispatch dpms off"; # turn off the display, set backlight to 0
            on-resume = "hyprctl dispatch dpms on && brightnessctl -r"; # turn on the display, restore backlight
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
