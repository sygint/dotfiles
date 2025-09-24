{ config
, lib
, pkgs
, userVars
, ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  inherit (config.lib.file) mkOutOfStoreSymlink;

  configRoot = "/home/${userVars.username}/.config/nixos";
  configDotfilesDir = "${configRoot}/dotfiles/.config";
  cfg = config.modules.programs.hyprland;
  barCfg = cfg.systemBar;
  hyprland = userVars.hyprland;

  # Generate hyprland.conf from template with variable substitution
  hyprlandConf = pkgs.writeText "hyprland.conf" (
    lib.replaceStrings
      [ "@terminal@" "@fileManager@" "@webBrowser@" "@menu@" "@systemBarScript@" ]
      [
        (hyprland.terminal or "ghostty")
        (hyprland.fileManager or "nemo")
        (hyprland.webBrowser or "brave")
        (hyprland.menu or "rofi")
        (
          if barCfg == "waybar" then "/home/${userVars.username}/.config/nixos/scripts/start-waybar.sh"
          else if barCfg == "hyprpanel" then "/home/${userVars.username}/.config/nixos/scripts/start-hyprpanel.sh"
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
    pkgs.brightnessctl  # For screen brightness control
  ] ++ lib.filter (x: x != null) [defaultTerminalPkg defaultBrowserPkg defaultFileMgrPkg] ++ cfg.packages.extra
    # Only include mako when using waybar (hyprpanel has its own notification system)
    ++ lib.optionals (barCfg == "waybar") [ pkgs.mako ];

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

    systemBar = mkOption {
      type = types.enum [ "waybar" "hyprpanel" "none" ];
      default = "waybar";
      description = "Which system bar to start (waybar, hyprpanel, none)";
    };
  };

  config = mkIf cfg.enable {
    home = {
      # Always include hyprland itself when enabled
      packages = [ pkgs.hyprland ] ++ (if cfg.packages.enable then hyprlandPkgs else []);

      file = {
        ".config/hypr/hyprlock.conf" = {
          source = mkOutOfStoreSymlink "${configDotfilesDir}/hypr/hyprlock.conf";
          force = true;
        };
        # Use generated config with variables for hyprland.conf
        ".config/hypr/hyprland.conf" = {
          source = hyprlandConf;
        };
        ".config/hypr/mocha.conf" = {
          source = mkOutOfStoreSymlink "${configDotfilesDir}/hypr/mocha.conf";
          force = true;
        };
        ".config/rofi/config.rasi" = {
          source = mkOutOfStoreSymlink "${configDotfilesDir}/rofi/config.rasi";
          force = true;
        };
      };
    };

    # Start mako notification daemon only when using waybar
    # (HyprPanel has its own notification system)
    services.mako = mkIf (barCfg == "waybar") {
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
  };
}
