{
  config,
  lib,
  options,
  pkgs,
  inputs,
  userVars,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.windowManagers.hyprland;
in {
  options.settings.windowManagers.hyprland.enable = mkEnableOption "Hyprland";

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable  = true;
      package = inputs.hyprland.packages."${pkgs.system}".hyprland;
      # plugins   = [];
      # Configuration is now managed by chezmoi via dotfiles/dot_config/hypr/hyprland.conf.tmpl
    };

    # home.file = {
    #   "./hypr/mocha.conf".source = ./mocha.conf.nix;
    # };

    services = {
      # This doesn't seem to work for some reason
      # xdg-desktop-portal-hyprland.enable = true;
    };
  };
}