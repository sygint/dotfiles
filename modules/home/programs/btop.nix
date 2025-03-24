{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.programs.btop;
in {
  options.settings.programs.btop = {
    enable = mkEnableOption "btop terminal";
  };

  config = mkIf cfg.enable {
    programs.btop = {
      enable            = true;
      settings.vim_keys = true;
    };
  };
}