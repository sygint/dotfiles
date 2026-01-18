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
  hyprland = userVars.hyprland;
  barCfg = hyprland.bar or "hyprpanel";  # Default to hyprpanel if not specified
  hostName = userVars.hostName or "orion";  # Default to orion for backward compatibility
  # Scripts directory for system-specific Hyprland scripts
  # Note: Only systems with Hyprland enabled should have this directory
  scriptsDir = "${configRoot}/systems/${hostName}/scripts";

  # Generate hyprland.conf from template with variable substitution
  hyprlandConf = pkgs.writeText "hyprland.conf" (
    lib.replaceStrings
      [ "@terminal@" "@fileManager@" "@webBrowser@" "@menu@" "@systemBarScript@" "@monitorHandler@" ]
      [
        (hyprland.terminal or "ghostty")
        (hyprland.fileManager or "nemo")
        (hyprland.webBrowser or "brave")
        (hyprland.menu or "rofi")
        (
          if barCfg == "waybar" then "${scriptsDir}/start-waybar.sh"
          else if barCfg == "hyprpanel" then "${scriptsDir}/start-hyprpanel.sh"
          else ""
        )
        (
          "${scriptsDir}/monitor-handler.sh --fast --bar=" + barCfg
        )
      ]
      (builtins.readFile ../../../dotfiles/.config/hypr/hyprland.conf)
  );

  # Determine which packages to auto-install (can be disabled by setting to null)
  defaultTerminalPkg = cfg.packages.terminal;
  defaultBrowserPkg  = cfg.packages.browser;
  defaultFileMgrPkg  = cfg.packages.fileManager;

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

      # Auto-install default applications (set to null to disable)
      terminal = mkOption {
        type = types.nullOr types.package;
        default = pkgs.ghostty;
        description = "Terminal package to install (null = don't install)";
      };
      browser = mkOption {
        type = types.nullOr types.package;
        default = null;  # Don't auto-install browser (usually managed elsewhere)
        description = "Browser package to install (null = don't install)";
      };
      fileManager = mkOption {
        type = types.nullOr types.package;
        default = pkgs.nemo;
        description = "File manager package to install (null = don't install)";
      };

      extra = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Extra packages to install with Hyprland";
      };
    };

    # Command names used in hyprland config (independent of what's installed)
    defaults = {
      terminal = mkOption { type = types.str; default = "ghostty"; };
      browser = mkOption { type = types.str; default = "brave"; };
      fileManager = mkOption { type = types.str; default = "nemo"; };
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
