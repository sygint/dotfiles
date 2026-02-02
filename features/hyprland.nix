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

          configDotfilesDir = "${inputs.dotfiles.outPath}/.config";
          hyprland = userVars.hyprland;
          hostName = userVars.hostName or "orion";
          configRoot = "/home/${userVars.username}/.config/nixos";
          scriptsDir = "${configRoot}/systems/${hostName}/scripts";

          # Generate hyprland.conf from template with variable substitution
          hyprlandConfTemplate = builtins.readFile "${configDotfilesDir}/hypr/hyprland.conf";

          hyprlandConf = pkgs.writeText "hyprland.conf" (
            lib.replaceStrings
              [ "@terminal@" "@fileManager@" "@webBrowser@" "@menu@" "@monitorHandler@" ]
              [
                (hyprland.terminal or "ghostty")
                (hyprland.fileManager or "nemo")
                (hyprland.webBrowser or "brave")
                (hyprland.menu or "rofi")
                "${scriptsDir}/monitor-handler.sh --fast"
              ]
              hyprlandConfTemplate
          );

          # Determine which packages to auto-install
          defaultTerminalPkg = cfg.packages.terminal;
          defaultBrowserPkg = cfg.packages.browser;
          defaultFileMgrPkg = cfg.packages.fileManager;

          hyprlandPkgs = [
            pkgs.brightnessctl
          ]
          ++ lib.filter (x: x != null) [
            defaultTerminalPkg
            defaultBrowserPkg
            defaultFileMgrPkg
          ]
          ++ cfg.packages.extra;

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
        }
      )
    ];
  };
}
