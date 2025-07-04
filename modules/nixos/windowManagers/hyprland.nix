{
  config,
  lib,
  options,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.wayland.hyprland;
in {
  options.settings.wayland.hyprland.enable = mkEnableOption "Hyprland";

  config = mkIf cfg.enable {
    programs = {
      hyprland = {
        enable   = true;
        withUWSM = true;
        package  = inputs.hyprland.packages."${pkgs.system}".hyprland;
      };
    };

    environment.systemPackages = with pkgs; [
      hyprpanel
      hyprlock
      hypridle
      # light
      xdg-desktop-portal-hyprland
    ];
  };
}