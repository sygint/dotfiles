{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.waybar;
in
{
  options.modules.features.waybar = {
    enable = mkEnableOption "Waybar - A modern bar for Wayland";
  };

  config = mkIf cfg.enable {
    # Home-manager configuration
    home-manager.sharedModules = [
      (
        {
          config,
          pkgs,
          userVars,
          ...
        }:
        let
          inherit (config.lib.file) mkOutOfStoreSymlink;
          configRoot = "/home/${userVars.username}/.config/nixos";
          configWaybarDir = "${configRoot}/dotfiles/.config/waybar";
        in
        {
          home.packages = with pkgs; [
            waybar
            # Waybar dependencies
            font-awesome
            pavucontrol
            wlogout

            # Network and Bluetooth TUI tools
            networkmanager # For nmtui terminal interface
            bluetuith # Modern TUI Bluetooth manager with mouse support
            bluez-tools # For bluetoothctl and bluetooth TUI

            # Keep minimal GUI options for fallback
            networkmanagerapplet # nm-connection-editor for advanced network settings
            blueman # For advanced Bluetooth settings

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
          xdg.configFile = {
            "waybar/config.jsonc" = {
              source = mkOutOfStoreSymlink "${configWaybarDir}/config.jsonc";
              force = true;
            };
            "waybar/style.css" = {
              source = mkOutOfStoreSymlink "${configWaybarDir}/style.css";
              force = true;
            };
          };
        }
      )
    ];
  };
}
