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
          # Use the real filesystem path, NOT inputs.dotfiles.outPath (which
          # resolves to a read-only /nix/store copy). mkOutOfStoreSymlink needs
          # to point to the actual mutable file on disk.
          configWaybarDir = "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/waybar";
        in
        {
          home.packages = with pkgs; [
            waybar
            mako # Notification daemon (waybar doesn't have built-in notifications)
            # Waybar dependencies
            font-awesome
            pavucontrol
            wlogout
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

          # Waybar needs mako for notifications (it doesn't have built-in notifications)
          services.mako = {
            enable = true;
            settings = lib.mkForce {
              default-timeout = 3000;
              anchor = "top-right";
              background-color = "#1e1e2e";
              text-color = "#cdd6f4";
              border-color = "#89b4fa";
              border-size = 2;
              border-radius = 10;
              font = "Inter 11";
              width = 300;
              height = 100;
              margin = "10";
              padding = "10";
              max-visible = 5;
              group-by = "app-name";
              actions = 1;
            };
            extraConfig = ''
              [app-name=volume-control]
              format=%s\n%b
            '';
          };
        }
      )
    ];
  };
}
