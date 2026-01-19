{
  config,
  lib,
  options,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.wayland.hyprland;
in
{
  options.modules.wayland.hyprland.enable = mkEnableOption "Hyprland";

  config = mkIf cfg.enable {
    programs = {
      hyprland = {
        enable = true;
        # Note: withUWSM removed - using the start-hyprland wrapper instead (simpler, recommended approach).
        # The start-hyprland wrapper is installed by this Hyprland package into $PATH; use `start-hyprland`
        # as your session/exec command in your display manager or TTY. UWSM is for advanced users who want
        # full systemd unit management.
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      };
    };

    # PAM service for hyprlock authentication
    security.pam.services.hyprlock = { };

    environment.systemPackages = with pkgs; [
      hyprlock
      hypridle
      # light
    ];
  };
}
