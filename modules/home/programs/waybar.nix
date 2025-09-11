{ config, lib, options, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.modules.programs.waybar;
in
{
  options.modules.programs.waybar.enable = mkEnableOption "Waybar - A modern bar for Wayland";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      waybar
      # Waybar dependencies
      font-awesome
      pavucontrol
      wlogout

      # Network and Bluetooth GUI tools
      blueman # Bluetooth manager for waybar click handler
      networkmanagerapplet # nm-connection-editor for network click handler

      # Cursor theme
      adwaita-icon-theme
      gnome-themes-extra
    ];

    # GTK and cursor theme settings for waybar
    gtk = {
      enable = true;
      cursorTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
        size = 24;
      };
    };

    # Link waybar configuration files
    xdg = {
      configFile = {
        "waybar/config.jsonc" = {
          source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/waybar/config.jsonc";
          force = true;
        };
        "waybar/style.css" = {
          source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/waybar/style.css";
          force = true;
        };
      };
    };
  };
}
