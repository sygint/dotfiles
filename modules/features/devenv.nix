{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.devenv;
in
{
  options.modules.features.devenv.enable = mkEnableOption "devenv - Fast, Declarative, Reproducible Development Environments";

  config = mkIf cfg.enable {
    home-manager.users.${userVars.username} = {
      home.packages = with pkgs; [
        devenv
        cachix # Required by devenv for binary caches
      ];
    };
  };
}
