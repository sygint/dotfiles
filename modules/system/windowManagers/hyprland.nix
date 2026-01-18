{ config
, lib
, options
, pkgs
, inputs
, ...
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
        # Note: withUWSM removed - using start-hyprland wrapper instead (simpler, recommended approach)
        # UWSM is for advanced users who want full systemd unit management
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      };
    };

    # PAM service for hyprlock authentication
    security.pam.services.hyprlock = {};

    environment.systemPackages = with pkgs; [
      hyprlock
      hypridle
      # light
    ];
  };
}
