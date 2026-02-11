{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.noctalia-shell;
in
{
  options.modules.features.noctalia-shell = {
    enable = mkEnableOption "Noctalia Shell - Minimal Quickshell-based desktop shell for Wayland";
  };

  config = mkIf cfg.enable {
    # Home-manager configuration
    home-manager.sharedModules = [
      {
        programs.noctalia-shell = {
          enable = true;
          package = inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;
          systemd.enable = true;

          settings = {
            # ── General ────────────────────────────────────────────────────
            general = {
              telemetryEnabled = lib.mkDefault false;
              showChangelogOnStartup = lib.mkDefault false;
            };

            # ── Bar ───────────────────────────────────────────────────────
            # Opacity is managed by Stylix theming module — don't override here
            bar = {
              position = lib.mkDefault "top";
              floating = lib.mkDefault false;
            };

            # ── Dock ──────────────────────────────────────────────────────
            dock = {
              enabled = lib.mkDefault true;
              position = lib.mkDefault "bottom";
              displayMode = lib.mkDefault "auto_hide";
              pinnedApps = lib.mkDefault [
                "ghostty"
                "brave-browser"
                "nemo"
              ];
            };

            # ── App Launcher ──────────────────────────────────────────────
            appLauncher = {
              terminalCommand = lib.mkDefault "ghostty -e";
              sortByMostUsed = lib.mkDefault true;
              position = lib.mkDefault "center";
            };

            # ── Color Scheme ──────────────────────────────────────────────
            colorSchemes = {
              darkMode = lib.mkDefault true;
            };

            # ── Notifications ─────────────────────────────────────────────
            notifications = {
              enabled = lib.mkDefault true;
              location = lib.mkDefault "top_right";
            };

            # ── OSD ───────────────────────────────────────────────────────
            osd = {
              enabled = lib.mkDefault true;
              location = lib.mkDefault "top_right";
            };

            # ── Audio ─────────────────────────────────────────────────────
            audio = {
              volumeStep = lib.mkDefault 5;
            };

            # ── Brightness ────────────────────────────────────────────────
            brightness = {
              brightnessStep = lib.mkDefault 5;
            };
          };
        };
      }
    ];
  };
}
