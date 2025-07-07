{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.settings.programs.hyprpanel;
in {
  options.settings.programs.hyprpanel.enable = mkEnableOption "HyprPanel - A Bar/Panel for Hyprland";

  config = mkIf cfg.enable {
    # Install hyprpanel from AUR or build from source
    # For now, we'll assume it's installed manually or via other means
    
    # Link hyprpanel configuration files with live updates
    home.file.".config/hyprpanel/config.json" = {
      source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/dot_config/hyprpanel/config.json";
      force = true;
    };

    home.file.".config/hyprpanel/modules.json" = {
      source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/dot_config/hyprpanel/modules.json";
      force = true;
    };

    home.file.".config/hyprpanel/modules.scss" = {
      source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/dot_config/hyprpanel/modules.scss";
      force = true;
    };
  };
}
