{ config, lib, pkgs, userVars, ... }:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.modules.programs.hyprland;
  barCfg = config.modules.programs.desktopBar;

  # Generate hyprland.conf from template with variable substitution
  hyprlandConf = pkgs.writeText "hyprland.conf" (
    lib.replaceStrings
      [ "@terminal@" "@fileManager@" "@webBrowser@" "@menu@" "@desktopBarScript@" ]
      [
        (userVars.user.hyprland.terminal or "ghostty")
        (userVars.user.hyprland.fileManager or "nemo")
        (userVars.user.hyprland.webBrowser or "brave")
        (userVars.user.hyprland.menu or "rofi")
        (
          if barCfg.type == "waybar" then "$NIXOS_CONFIG_DIR/scripts/start-waybar.sh"
          else if barCfg.type == "hyprpanel" then "$NIXOS_CONFIG_DIR/scripts/start-hyprpanel.sh"
          else ""
        )
      ]
      (builtins.readFile ../../../dotfiles/.config/hypr/hyprland.conf)
  );

  # Only install package for the default if the user did NOT override it
  defaultTerminalPkg = if cfg.defaults ? terminal && cfg.defaults.terminal != "ghostty" then null else pkgs.ghostty;
  defaultBrowserPkg  = if cfg.defaults ? browser  && cfg.defaults.browser  != "brave"   then null else pkgs.brave;
  defaultFileMgrPkg  = if cfg.defaults ? fileManager && cfg.defaults.fileManager != "nemo" then null else pkgs.nemo;

  # Always include hyprland itself when enabled. Related utilities and extras are controlled by packages.
  hyprlandPkgs = [
    pkgs.hypridle
    pkgs.hyprlock
  ] ++ lib.filter (x: x != null) [defaultTerminalPkg defaultBrowserPkg defaultFileMgrPkg] ++ cfg.packages.extra;

in
{
  options.modules.programs.hyprland = {
    enable = mkEnableOption "Enable Hyprland window manager";

    packages = {
      enable = mkEnableOption "Install Hyprland-related packages";

      extra = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Extra packages to install with Hyprland";
      };
    };

    defaults = {
      terminal = mkOption { type = types.str; default = "ghostty"; };
      browser = mkOption { type = types.str; default = "brave"; };
      fileManager = mkOption { type = types.str; default = "nemo"; };
    };
  };

  # Desktop bar type option (shared)
  options.modules.programs.desktopBar.type = mkOption {
    type = types.enum [ "waybar" "hyprpanel" "none" ];
    default = "waybar";
    description = "Which desktop bar to start (waybar, hyprpanel, none)";
  };

  config = mkIf cfg.enable {
    home = {
      # Always include hyprland itself when enabled
      packages = [ pkgs.hyprland ] ++ (if cfg.packages.enable then hyprlandPkgs else []);

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
        ".config/rofi/config.rasi" = {
          source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/rofi/config.rasi";
          force = true;
        };
      };
    };
  };
}
