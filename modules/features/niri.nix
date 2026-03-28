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
  cfg = config.modules.features.niri;
in
{
  options.modules.features.niri = {
    enable = mkEnableOption "Niri scrollable tiling compositor";

    packages = {
      enable = mkEnableOption "Install Niri-related packages";

      terminal = mkOption {
        type = types.nullOr types.package;
        default = pkgs.ghostty;
        description = "Terminal package to install (null = don't install)";
      };
      browser = mkOption {
        type = types.nullOr types.package;
        default = null;
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
        description = "Extra packages to install with Niri";
      };
    };

    monitors = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Monitor connector name (e.g., eDP-1, DP-2).";
            };
            desc = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Monitor description for stable matching (e.g., 'BOE 0x0BCA'). Use `niri msg outputs` to find.";
            };
            resolution = mkOption {
              type = types.str;
              default = "preferred";
              description = "Resolution and refresh rate (e.g., 1920x1080@120)";
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
              description = "Transform: normal, 90, 180, 270, flipped, flipped-90, flipped-180, flipped-270";
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
              description = "Workspace display name (shared across compositors)";
            };
            hyprland = mkOption {
              type = types.nullOr types.attrs;
              default = null;
              description = "Hyprland-specific config: { id, monitorDesc?, monitorName?, default?, persistent? }";
            };
            niri = mkOption {
              type = types.nullOr types.attrs;
              default = null;
              description = "Niri-specific config: { rule? }";
            };
          };
        }
      );
      default = [
        { name = "System"; niri = { rule = "open-on-output=BOE 0x0BCA Unknown"; }; }
        { name = "ES"; niri = { rule = "open-on-output=BOE 0x0BCA Unknown"; }; }
        { name = "HSFF"; niri = { rule = "open-on-output=BOE 0x0BCA Unknown"; }; }
        { name = "PRJ"; niri = { rule = "open-on-output=BOE 0x0BCA Unknown"; }; }
        { name = "PRJ2"; niri = { rule = "open-on-output=BOE 0x0BCA Unknown"; }; }
        { name = "Media"; niri = { rule = "open-on-output=Acer Technologies ED343CUR V 1326001BF2X00"; }; }
        { name = "Media 2"; niri = { rule = "open-on-output=Acer Technologies ED343CUR V 1326001BF2X00"; }; }
        { name = "Chat"; niri = { rule = "open-on-output=Sceptre Tech Inc Sceptre M24 00"; }; }
        { name = "Info"; niri = { rule = "open-on-output=Sceptre Tech Inc Sceptre M24 00"; }; }
      ];
      description = "Unified workspace configuration consumed by all compositor modules.";
    };
  };

  config = mkIf cfg.enable {
    # Niri is available in nixpkgs — no separate flake input needed
    programs.niri = {
      enable = true;
      useNautilus = false; # We use nemo, not nautilus
    };

    # PAM service for swaylock authentication
    security.pam.services.swaylock = { };

    environment.systemPackages = with pkgs; [
      swaylock
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
          hostName = userVars.hostName or "orion";
          configRoot = "/home/${userVars.username}/.config/nixos";
          scriptsDir = "${configRoot}/systems/${hostName}/scripts";

          # Generate niri monitor output blocks from the shared monitors config
          monitorConfigs = cfg.monitors;
          monitorBlocks = lib.concatMapStringsSep "\n\n" (
            m:
            let
              # Niri matches outputs by "manufacturer model serial" (exact match)
              # desc should contain the full identifier from `niri msg outputs`
              identifier =
                if (m.desc or null) != null then
                  m.desc
                else if (m.name or null) != null then
                  m.name
                else
                  throw "Monitor must have either 'name' or 'desc' set";
              resolution = m.resolution or "preferred";
              position = m.position or "auto";
              scale = m.scale or "1";
              transform = m.transform or null;

              # Parse resolution "WxH@R" format
              modeStr = if resolution == "preferred" then "" else ''mode "${resolution}"'';

              # Parse position "XxY" into x=X y=Y
              positionStr =
                if position == "auto" then
                  ""
                else
                  let
                    parts = lib.splitString "x" position;
                    x = builtins.elemAt parts 0;
                    y = builtins.elemAt parts 1;
                  in
                  "position x=${x} y=${y}";

              scaleStr = "scale ${scale}";

              # Niri uses "normal", "90", "180", "270" for transform
              # Our variables.nix uses "1"=90°, "2"=180°, "3"=270° (Hyprland style)
              transformMap = {
                "0" = "normal";
                "1" = "90";
                "2" = "180";
                "3" = "270";
                "4" = "flipped";
                "5" = "flipped-90";
                "6" = "flipped-180";
                "7" = "flipped-270";
              };
              transformStr =
                if transform != null then ''transform "${transformMap.${transform} or transform}"'' else "";

              # Build the output block with only non-empty lines
              lines = lib.filter (s: s != "") [
                modeStr
                scaleStr
                positionStr
                transformStr
              ];
              body = lib.concatMapStringsSep "\n" (line: "    ${line}") lines;
            in
            ''
              output "${identifier}" {
              ${body}
              }''
          ) monitorConfigs;

          monitorSection =
            if monitorBlocks != "" then monitorBlocks else "// No monitors configured — niri will auto-detect";

          # Generate workspace blocks from workspaces config
          # Reads unified workspace format: { name, niri = { rule, ... }; }
          # Creates named workspaces on every configured monitor for consistency.
          # When multiple monitors are configured, workspaces are suffixed
          # (e.g. "Nixos", "Nixos:2", "Nixos:3") and pinned via open-on-output.
          # With a single monitor (or no monitors), workspaces are created without suffixes.
          workspaceConfigs = cfg.workspaces;

          # Helper to extract niri rule from unified workspace format
          getRule = w:
            let niri = w.niri or null;
            in if niri != null then (niri.rule or null) else null;

          # Helper to extract monitor assignment from niri config
          getMonitor = w:
            let niri = w.niri or null;
            in if niri != null then (niri.monitor or null) else null;

          # Build a per-monitor suffix: first monitor gets no suffix, second gets ":2", etc.
          monitorCount = builtins.length monitorConfigs;
          # Multi-monitor: show only assigned workspaces per monitor
          # Single monitor: all workspaces in order (no output rules)
          usePerMonitor = monitorCount > 1;

          # Filter workspaces for a specific monitor (by niri.monitor short name)
          workspacesForMonitor = monitorDesc:
            lib.filter (w:
              let wsMonitor = getMonitor w;
              in wsMonitor == null || lib.hasPrefix wsMonitor monitorDesc
            ) workspaceConfigs;

          # Generate workspace blocks for a single workspace on a single monitor
          mkWorkspaceBlock =
            w: monitorIdx: monitor:
            let
              suffix = if monitorIdx == 0 then "" else ":${toString (monitorIdx + 1)}";
              wsName = "${w.name}${suffix}";
              outputId =
                if (monitor.desc or null) != null then
                  monitor.desc
                else if (monitor.name or null) != null then
                  monitor.name
                else
                  null;
              outputLine = if outputId != null then ''open-on-output "${outputId}"'' else "";
              rule = getRule w;
              ruleStr =
                if rule != null && rule != "" then
                  let
                    eqSplit = builtins.split "=" rule;
                  in
                  if builtins.length eqSplit == 2 then
                    let
                      key = builtins.elemAt eqSplit 0;
                      rawVal = builtins.elemAt eqSplit 1;
                      val =
                        if
                          (builtins.match ''^\s*\".*\"\s*$'' rawVal) != null
                          || (builtins.match ''^\s*r#\".*\"#\s*$'' rawVal) != null
                        then
                          builtins.replaceStrings [ " " "\t" ] [ "" "" ] rawVal
                        else
                          "\"${builtins.replaceStrings [ " " "\t" ] [ "" "" ] rawVal}\"";
                    in
                    "    rule ${key}=${val}"
                  else
                    ""
                else
                  "";
              lines = lib.filter (s: s != "") [
                outputLine
                ruleStr
              ];
              body = lib.concatStringsSep "\n" lines;
            in
            ''
              workspace "${wsName}" {
              ${body}
              }'';

          # Generate all workspace blocks
          workspaceBlocks =
            if usePerMonitor then
              # Multi-monitor: only workspaces assigned to each monitor
              # NOTE: Niri does not reorder existing workspaces on config reload —
              # a session restart (log out/in) is required for order changes to take effect.
              lib.concatStringsSep "\n\n" (
                lib.concatMap (
                  monitorWithIdx:
                  let
                    wsForThisMonitor = workspacesForMonitor monitorWithIdx.monitor.desc;
                  in
                  map (w: mkWorkspaceBlock w monitorWithIdx.idx monitorWithIdx.monitor) wsForThisMonitor
                ) (lib.imap0 (idx: monitor: { inherit idx monitor; }) monitorConfigs)
              )
            else
              # Single/no monitor: emit all workspaces in correct order
              lib.concatMapStringsSep "\n\n" (
                w:
                let
                  rule = getRule w;
                  # Parse "key=value" — builtins.split returns [before [] after] (length 3)
                  ruleStr =
                    if rule != null && rule != "" then
                      let
                        eqSplit = builtins.split "=" rule;
                      in
                      if builtins.length eqSplit >= 3 then
                        let
                          key = builtins.elemAt eqSplit 0;
                          rawVal = builtins.elemAt eqSplit 2;
                        in
                        ''    ${key} "${rawVal}"''
                      else
                        ""
                    else
                      "";
                in
                ''
                  workspace "${w.name}" {
                  ${ruleStr}
                  }''
              ) workspaceConfigs;

          # COMMENT-OUT OPTION: keep original generated workspace blocks but
          # comment them in the produced config so the logic is preserved
          # in the file for later re-enabling, without being active now.
          workspaceBlocksCommented =
            if workspaceBlocks != "" then
              let
                lines = lib.splitString "\n" workspaceBlocks;
              in lib.concatStringsSep "\n" (map (l: "// " + l) lines)
            else
              "// No workspaces configured";

          workspaceSection = if workspaceBlocks != "" then
              "// Workspaces generation disabled by user\n" + workspaceBlocksCommented
            else
              "// No workspaces configured";

          # Read template and substitute variables
          niriConfTemplate = builtins.readFile "${configDotfilesDir}/niri/config.kdl";

          wallpaperPath = "${configRoot}/wallpapers/wallpaperflare.com_wallpaper-1.jpg";

          renameWorkspaceScript = "${configRoot}/scripts/desktop/rename-workspace.sh";

          niriConf = pkgs.writeText "config.kdl" (
            lib.replaceStrings
              [
                "@monitors@"
                "@wallpaperPath@"
                "@monitorHandler@"
                "@renameWorkspaceScript@"
                "@workspaces@"
              ]
              [
                monitorSection
                wallpaperPath
                "${scriptsDir}/monitor-handler.sh --fast"
                renameWorkspaceScript
                workspaceSection
              ]
              niriConfTemplate
          );

          # Packages to auto-install
          niriPkgs = [
            pkgs.swww
            pkgs.brightnessctl
            pkgs.xwayland-satellite # XWayland support for niri
          ]
          ++ lib.filter (x: x != null) [
            cfg.packages.terminal
            cfg.packages.browser
            cfg.packages.fileManager
          ]
          ++ cfg.packages.extra;

        in
        {
          home.packages = if cfg.packages.enable then niriPkgs else [ ];

          # Niri session target — started by spawn-at-startup in config.kdl,
          # pulls in graphical-session.target so all WantedBy services
          # (noctalia-shell, swhks, swhkd, etc.) start automatically.
          systemd.user.targets.niri-session = {
            Unit = {
              Description = "Niri compositor session";
              Documentation = [ "man:systemd.special(7)" ];
              BindsTo = [ "graphical-session.target" ];
              Wants = [
                "graphical-session-pre.target"
                "graphical-session.target"
              ];
              After = [ "graphical-session-pre.target" ];
            };
          };

          home.file = {
            ".config/niri/config.kdl" = {
              source = niriConf;
            };
          };
        }
      )
    ];
  };
}
