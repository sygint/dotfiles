{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.modules.programs.hyprpanel;
in
{
  options.modules.programs.hyprpanel.enable = mkEnableOption "HyprPanel - A Bar/Panel for Hyprland";

  config = mkIf cfg.enable {
    # Install hyprpanel from nixpkgs
    home.packages = with pkgs; [
      hyprpanel
    ];

    # Link hyprpanel configuration files with live updates
    # Note: JSON files are processed by Home Manager but will update on rebuild
    xdg = {
      configFile = {
        "hyprpanel/config.json" = {
          source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/hyprpanel/config.json";
          force = true;
        };
        "hyprpanel/modules.json" = {
          source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/hyprpanel/modules.json";
          force = true;
        };
        "hyprpanel/modules.scss" = {
          source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/hyprpanel/modules.scss";
          force = true;
        };
      };
    };
  };
}
