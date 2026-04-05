{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.screenshots;
in
{
  options.modules.features.screenshots = {
    enable = mkEnableOption "Screenshot utilities for Wayland";
  };

  config = mkIf cfg.enable {
    # Home-manager configuration
    home-manager.sharedModules = [
      {
        home.packages = with pkgs; [
          grim # Screenshot utility for Wayland
          slurp # Region selection tool for Wayland
          swappy # Screenshot editor
          inotify-tools # For screenshot save notifications
        ];

        # Swappy configuration — sets save directory so the save button works
        # (without this, swappy has no save_dir and save silently fails)
        xdg.configFile."swappy/config".text = ''
          [Default]
          save_dir=$HOME/Pictures/Screenshots
          save_filename_format=Screenshot from %Y-%m-%d %H-%M-%S.png
        '';
      }
    ];
  };
}
