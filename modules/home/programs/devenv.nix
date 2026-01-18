{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.devenv;
in
{
  options.modules.programs.devenv = {
    enable = lib.mkEnableOption "devenv - Fast, Declarative, Reproducible Development Environments";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      devenv
      cachix # Required by devenv for binary caches
    ];
  };
}
