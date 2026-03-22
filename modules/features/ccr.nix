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
    };
  };
}
