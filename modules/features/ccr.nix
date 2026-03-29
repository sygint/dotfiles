{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.ccr;
in
{
  options.modules.features.ccr.enable = mkEnableOption "Claude Code Router";

  config = mkIf cfg.enable {
    home-manager.users.${userVars.username} = {
      home.packages = with pkgs; [ claude-code-router ];

      systemd.user.services.claude-code-router = {
        Unit = {
          Description = "Claude Code Router";
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "forking";
          PIDFile = "%t/ccr.pid";
          ExecStart = "${pkgs.claude-code-router}/bin/ccr start";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
  };
}
