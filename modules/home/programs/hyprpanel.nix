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
    # Note: JSON files are processed by Home Manager but will update on rebuild
    xdg.configFile."hyprpanel/config.json" = {
      source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/hyprpanel/config.json";
      force = true;
    };

    xdg.configFile."hyprpanel/modules.json" = {
      source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/hyprpanel/modules.json";
      force = true;
    };

    xdg.configFile."hyprpanel/modules.scss" = {
      source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/hyprpanel/modules.scss";
      force = true;
    };
  };
}
