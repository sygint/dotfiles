{
  config,
  lib,
  options,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.services.hypridle;
in {
  options.settings.services.hypridle.enable = mkEnableOption "Hypridle";

  config = mkIf cfg.enable {
    services = {
      hypridle = {
        enable = true;

        settings = {
          general = {
            lock_cmd            = "pidof hyprlock || hyprlock";  # avoid starting multiple hyprlock instances.
            before_sleep_cmd    = "loginctl lock-session";       # lock before suspend.
            after_sleep_cmd     = "hyprctl dispatch dpms on";    # to avoid having to press a key twice to turn on the display.
            ignore_dbus_inhibit = false;
          };

          listener = [
            # Screenlock
            {
              timeout    = 300;
              on-timeout = "hyprlock";
            }
            # DPMS
            {
              timeout    = 600;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume  = "hyprctl dispatch dpms on";
            }
            # Suspend
            {
              timeout    = 1200;
              on-timeout = "systemctl suspend";
            }
          ];
        };
      };

      # This doesn't seem to work for some reason
      # xdg-desktop-portal-hyprland.enable = true;
    };
  };
}