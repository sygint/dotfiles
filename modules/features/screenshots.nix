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
        ];
      }
    ];
  };
}
