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
        withUWSM = true;
        package = inputs.hyprland.packages."${pkgs.system}".hyprland;
      };
    };

    # PAM service for hyprlock authentication
    security.pam.services.hyprlock = {
      text = ''
        auth include login
      '';
    };

    environment.systemPackages = with pkgs; [
      hyprlock
      hypridle
      # light
      xdg-desktop-portal-hyprland
    ];
  };
}
