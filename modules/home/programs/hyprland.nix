{
  config,
  lib,
  options,
  pkgs,
  userVars,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.settings.programs.hyprland;

  # Generate hyprland.conf from template with variable substitution
  hyprlandConf = pkgs.writeText "hyprland.conf" (
    lib.replaceStrings 
      [ "@terminal@" "@fileManager@" "@webBrowser@" "@menu@" ]
      [ 
        (userVars.terminal or "kitty")
        (userVars.fileManager or "nemo") 
        (userVars.webBrowser or "librewolf")
        (userVars.menu or "wofi")
      ]
      (builtins.readFile ../../../dotfiles/.config/hypr/hyprland.conf)
  );
in {
  options.settings.programs.hyprland.enable = mkEnableOption "Hyprland window manager configuration";

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        rofi-wayland # Application launcher
        waypaper     # Wallpaper selector
        playerctl    # Media player control
      ];

      file = {
        ".config/hypr/hypridle.conf" = {
          source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/hypr/hypridle.conf";
          force = true;
        };
        ".config/hypr/hyprlock.conf" = {
          source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/hypr/hyprlock.conf";
          force = true;
        };
        # Use generated config with variables for hyprland.conf
        ".config/hypr/hyprland.conf" = {
          source = hyprlandConf;
        };
        ".config/hypr/mocha.conf" = {
          source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/hypr/mocha.conf";
          force = true;
        };
      };
    };
  };
}
