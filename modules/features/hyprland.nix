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

    monitors = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Monitor connector name (e.g., eDP-1, DP-2). Prefer 'desc' for stability.";
            };
            desc = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Monitor description for stable matching (e.g., 'Acer Technologies ED343CUR V'). Use `hyprctl monitors` to find.";
            };
            resolution = mkOption {
              type = types.str;
              default = "preferred";
              description = "Resolution and refresh rate (e.g., 1920x1080@60)";
            };
            position = mkOption {
              type = types.str;
              default = "auto";
              description = "Position (e.g., 0x0, auto)";
            };
            scale = mkOption {
              type = types.str;
              default = "1";
              description = "Scale factor";
            };
            transform = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Transform (0-7, null for no rotation). 1=90°, 2=180°, 3=270°";
            };
            extra = mkOption {
              type = types.str;
              default = "";
              description = "Extra options to append";
            };
          };
        }
      );
      default = [ ];
      description = "Monitor configurations. Use 'desc' for stable matching across reboots.";
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

          # Generate monitor configuration lines from Nix
          monitorConfigs = userVars.monitors or [ ];
          monitorLines = lib.concatMapStringsSep "\n" (
            m:
            let
              # Use desc: prefix for description matching, otherwise use name
              # desc matching is more stable across reboots and port changes
              identifier =
                if (m.desc or null) != null then
                  "desc:${m.desc}"
                else if (m.name or null) != null then
                  m.name
                else
                  throw "Monitor must have either 'name' or 'desc' set";
              base = "monitor = ${identifier}, ${m.resolution or "preferred"}, ${m.position or "auto"}, ${m.scale or "1"}";
              transform = m.transform or null;
              extra = m.extra or "";
              withTransform = if transform != null then "${base}, transform, ${transform}" else base;
              withExtra = if extra != "" then "${withTransform}, ${extra}" else withTransform;
            in
            withExtra
          ) monitorConfigs;

          # Fallback for unknown monitors
          monitorSection =
            if monitorLines != "" then
              ''
                # ═══════════════════════════════════════════════════════════════════════════════
                # MONITORS - Generated from Nix configuration
                # ═══════════════════════════════════════════════════════════════════════════════
                ${monitorLines}

                # Fallback for any other monitors
                monitor = , preferred, auto, 1
              ''
            else
              ''
                # No monitors configured in Nix - using auto-detection
                monitor = , preferred, auto, 1
              '';

          # Generate hyprland.conf from template with variable substitution
          hyprlandConfTemplate = builtins.readFile "${configDotfilesDir}/hypr/hyprland.conf";

          # Default wallpaper — use the first wallpaper in the repo
          wallpaperPath = "${configRoot}/wallpapers/wallpaperflare.com_wallpaper-1.jpg";
          lockWallpaper = "${configRoot}/wallpapers/wallpaperflare.com_wallpaper-6.jpg";

          hyprlandConf = pkgs.writeText "hyprland.conf" (
            lib.replaceStrings
              [
                "@terminal@"
                "@fileManager@"
                "@webBrowser@"
                "@menu@"
                "@monitorHandler@"
                "@wallpaperPath@"
                "@monitors@"
              ]
              [
                (hyprland.terminal or "ghostty")
                (hyprland.fileManager or "nemo")
                (hyprland.webBrowser or "brave")
                (hyprland.menu or "rofi")
                "${scriptsDir}/monitor-handler.sh --fast"
                wallpaperPath
                monitorSection
              ]
              hyprlandConfTemplate
          );

          # Generate hyprlock.conf from template with variable substitution
          hyprlockConfTemplate = builtins.readFile "${configDotfilesDir}/hypr/hyprlock.conf";
          hyprlockConf = pkgs.writeText "hyprlock.conf" (
            lib.replaceStrings [ "@lockWallpaper@" ] [ lockWallpaper ] hyprlockConfTemplate
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

          # Hyprland session target — started by exec-once in hyprland.conf,
          # pulls in graphical-session.target so all WantedBy services
          # (noctalia-shell, swhks, swhkd, hypridle, etc.) start automatically.
          systemd.user.targets.hyprland-session = {
            Unit = {
              Description = "Hyprland compositor session";
              Documentation = [ "man:systemd.special(7)" ];
              BindsTo = [ "graphical-session.target" ];
              Wants = [ "graphical-session-pre.target" ];
              After = [ "graphical-session-pre.target" ];
            };
          };

          home.file = {
            ".config/hypr/hyprlock.conf" = {
              source = hyprlockConf;
            };
            ".config/hypr/hyprland.conf" = {
              source = hyprlandConf;
            };
            ".config/hypr/mocha.conf" = {
              source = mkOutOfStoreSymlink "${configDotfilesDir}/hypr/mocha.conf";
              force = true;
            };
          };
        }
      )
    ];
  };
}
