{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.swhkd;
in
{
  options.modules.features.swhkd = {
    enable = mkEnableOption "swhkd - Simple Wayland HotKey Daemon for compositor-agnostic keybindings";
  };

  config = mkIf cfg.enable {
    # swhkd needs to run as root to read input devices
    # We use the setuid approach for better UX
    security.wrappers.swhkd = {
      source = "${inputs.swhkd.packages.${pkgs.system}.default}/bin/swhkd";
      owner = "root";
      group = "root";
      setuid = true;
    };

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
          configSwhkdDir = "${inputs.dotfiles.outPath}/.config/swhkd";
          # Full path to config file for swhkd (runs as root, needs absolute path)
          swhkdConfigPath = "/home/${userVars.username}/.config/swhkd/swhkdrc";
        in
        {
          home.packages = [
            inputs.swhkd.packages.${pkgs.system}.default
          ];

          # Link swhkd configuration
          xdg.configFile."swhkd/swhkdrc" = {
            source = mkOutOfStoreSymlink "${configSwhkdDir}/swhkdrc";
            force = true;
          };

          # swhks (the server) runs as user, swhkd (daemon) runs as root
          # Start swhks via systemd user service
          systemd.user.services.swhks = {
            Unit = {
              Description = "Simple Wayland HotKey Server";
              PartOf = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
            };
            Service = {
              # swhks daemonizes itself (forks to background), so use forking type
              Type = "forking";
              ExecStart = "${inputs.swhkd.packages.${pkgs.system}.default}/bin/swhks";
              Restart = "on-failure";
              RestartSec = 1;
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
          };

          # Start swhkd daemon via systemd user service (uses setuid wrapper)
          # Note: swhkd runs as root via setuid, so we must specify the full config path
          systemd.user.services.swhkd = {
            Unit = {
              Description = "Simple Wayland HotKey Daemon";
              PartOf = [ "graphical-session.target" ];
              After = [
                "graphical-session.target"
                "swhks.service"
              ];
              Requires = [ "swhks.service" ];
            };
            Service = {
              ExecStart = "/run/wrappers/bin/swhkd -c ${swhkdConfigPath}";
              Restart = "on-failure";
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
          };
        }
      )
    ];
  };
}
