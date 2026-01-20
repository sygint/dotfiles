{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.modules.features.hyprland;
in
{
  options.modules.features.hyprland = {
    enable = mkEnableOption "Hyprland window manager with full configuration";

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
        default = null; # Don't auto-install browser (usually managed elsewhere)
        description = "Browser package to install (null = don't install)";
      };
      fileManager = mkOption {
        type = types.nullOr types.package;
        default = pkgs.nemo;
        description = "File manager package to install (null = don't install)";
      };

      extra = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Extra packages to install with Hyprland";
      };
    };

    # Command names used in hyprland config (independent of what's installed)
    defaults = {
      terminal = mkOption {
        type = types.str;
        default = "ghostty";
      };
      browser = mkOption {
        type = types.str;
        default = "brave";
      };
      fileManager = mkOption {
        type = types.str;
        default = "nemo";
      };
    };
  };

  config = mkIf cfg.enable {
    # System-level configuration
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    };

    # PAM service for hyprlock authentication
    security.pam.services.hyprlock = { };

    environment.systemPackages = with pkgs; [
      hyprlock
      hypridle
    ];

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

          configRoot = "/home/${userVars.username}/.config/nixos";
          configDotfilesDir = "${configRoot}/dotfiles/.config";
          hyprland = userVars.hyprland;
          barCfg = hyprland.bar or "hyprpanel";
          hostName = userVars.hostName or "orion";
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
                  if barCfg == "waybar" then
                    "${scriptsDir}/start-waybar.sh"
                  else if barCfg == "hyprpanel" then
                    "${scriptsDir}/start-hyprpanel.sh"
                  else
                    ""
                )
                ("${scriptsDir}/monitor-handler.sh --fast --bar=" + barCfg)
              ]
              (builtins.readFile ../../dotfiles/.config/hypr/hyprland.conf)
          );

          # Determine which packages to auto-install
          defaultTerminalPkg = cfg.packages.terminal;
          defaultBrowserPkg = cfg.packages.browser;
          defaultFileMgrPkg = cfg.packages.fileManager;

          hyprlandPkgs = [
            pkgs.hypridle
            pkgs.hyprlock
            pkgs.brightnessctl
          ]
          ++ lib.filter (x: x != null) [
            defaultTerminalPkg
            defaultBrowserPkg
            defaultFileMgrPkg
          ]
          ++ cfg.packages.extra
          ++ lib.optionals (barCfg == "waybar") [ pkgs.mako ];

        in
        {
          home.packages = [ pkgs.hyprland ] ++ (if cfg.packages.enable then hyprlandPkgs else [ ]);

          home.file = {
            ".config/hypr/hyprlock.conf" = {
              source = mkOutOfStoreSymlink "${configDotfilesDir}/hypr/hyprlock.conf";
              force = true;
            };
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

          # Start mako notification daemon only when using waybar
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
        }
      )
    ];
  };
}
