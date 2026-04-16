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

    workspaces = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Workspace display name";
            };
            hyprland = mkOption {
              type = types.nullOr types.attrs;
              default = null;
              description = "Hyprland-specific config: { id, monitorDesc?, monitorName?, default?, persistent? }";
            };
          };
        }
      );
      default = [ ];
      description = "Workspace configuration for Hyprland monitor pinning and naming.";
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

          # inputs.dotfiles.outPath resolves to a read-only /nix/store copy —
          # fine for builtins.readFile (eval-time template reads) but NOT for
          # mkOutOfStoreSymlink (runtime symlinks that need to point to mutable files).
          configDotfilesDir = "${inputs.dotfiles.outPath}/.config";
          # Real filesystem path for mkOutOfStoreSymlink targets
          configRoot = "/home/${userVars.username}/.config/nixos";
          configDotfilesMutableDir = "${configRoot}/dotfiles/.config";
          hyprland = userVars.hyprland;
          barCfg = hyprland.bar or "hyprpanel";
          hostName = userVars.hostName or "orion";
          scriptsDir = "${configRoot}/systems/${hostName}/scripts";

          # Path to noctalia-shell binary (launched when bar = "noctalia")
          noctaliaShell = if barCfg == "noctalia" then
            "${inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/noctalia-shell"
          else
            "";

          # Generate monitor configuration lines from Nix
          monitorConfigs = cfg.monitors;
          monitorLines = lib.concatMapStringsSep "\n" (
            m:
            let
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

          # Generate workspace configuration lines from Nix
          workspaceConfigs = cfg.workspaces;
          hyprlandWorkspaces = builtins.filter (ws: (ws.hyprland or null) != null) workspaceConfigs;

          workspaceLines =
            let
              firstOnMonitor = map (
                ws:
                let
                  h = ws.hyprland;
                  thisMonitor =
                    if (h.monitorDesc or null) != null then
                      "desc:${h.monitorDesc}"
                    else if (h.monitorName or null) != null then
                      h.monitorName
                    else
                      null;
                  firstWsForMonitor =
                    if thisMonitor == null then
                      null
                    else
                      lib.findFirst (
                        w:
                        let
                          wh = w.hyprland;
                          wMonitor =
                            if (wh.monitorDesc or null) != null then
                              "desc:${wh.monitorDesc}"
                            else if (wh.monitorName or null) != null then
                              wh.monitorName
                            else
                              null;
                        in
                        wMonitor == thisMonitor
                      ) null hyprlandWorkspaces;
                  isFirst = firstWsForMonitor != null && (firstWsForMonitor.hyprland.id or 0) == (h.id or (0 - 1));
                  isDefault = if (h.default or null) != null then h.default else isFirst;
                  persistent = h.persistent or true;
                in
                { inherit ws isDefault persistent; }
              ) hyprlandWorkspaces;
            in
            lib.concatMapStringsSep "\n" (
              entry:
              let
                ws = entry.ws;
                h = ws.hyprland;
                id = toString h.id;
                parts = [ "workspace = ${id}" ]
                  ++ lib.optional ((h.monitorDesc or null) != null) "monitor:desc:${h.monitorDesc}"
                  ++ lib.optional ((h.monitorName or null) != null) "monitor:${h.monitorName}"
                  ++ lib.optional entry.isDefault "default:true"
                  ++ lib.optional entry.persistent "persistent:true"
                  ++ lib.optional ((ws.name or "") != "") "defaultName:${ws.name}";
              in
              lib.concatStringsSep ", " parts
            ) firstOnMonitor;

          workspaceSection =
            if workspaceLines != "" then
              ''
                # ═══════════════════════════════════════════════════════════════════════════════
                # WORKSPACES - Generated from Nix configuration
                # ═══════════════════════════════════════════════════════════════════════════════
                ${workspaceLines}
              ''
            else
              ''
                # No workspaces configured in Nix - using Hyprland defaults
              '';

          # Generate hyprland.conf from template with variable substitution
          hyprlandConfTemplate = builtins.readFile "${configDotfilesDir}/hypr/hyprland.conf";

          wallpaperPath = "${configRoot}/wallpapers/wallpaperflare.com_wallpaper-6.jpg";
          lockWallpaper = "${configRoot}/wallpapers/wallpaperflare.com_wallpaper-6.jpg";

          hyprlandConf = pkgs.writeText "hyprland.conf" (
            lib.replaceStrings
              [
                "@terminal@"
                "@fileManager@"
                "@webBrowser@"
                "@menu@"
                "@systemBarScript@"
                "@noctaliaShell@"
                "@monitorHandler@"
                "@wallpaperPath@"
                "@monitors@"
                "@workspaces@"
              ]
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
                noctaliaShell
                ("${scriptsDir}/monitor-handler.sh --fast --bar=" + barCfg)
                wallpaperPath
                monitorSection
                workspaceSection
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
          ++ cfg.packages.extra
          ++ lib.optionals (barCfg == "waybar") [ pkgs.mako ];

        in
        {
          home.packages = [ pkgs.hyprland ] ++ (if cfg.packages.enable then hyprlandPkgs else [ ]);

          home.file = {
            ".config/hypr/hyprlock.conf" = {
              source = hyprlockConf;
            };
            ".config/hypr/hyprland.conf" = {
              source = hyprlandConf;
            };
            ".config/hypr/mocha.conf" = {
              source = mkOutOfStoreSymlink "${configDotfilesMutableDir}/hypr/mocha.conf";
              force = true;
            };
            ".config/rofi/config.rasi" = {
              source = mkOutOfStoreSymlink "${configDotfilesMutableDir}/rofi/config.rasi";
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
