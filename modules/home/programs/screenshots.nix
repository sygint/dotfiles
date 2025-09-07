{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.programs.screenshots;
in
{
  options.modules.programs.screenshots.enable = mkEnableOption "Screenshot helpers (user)";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      grim
      slurp
      swappy
    ];
  };
}
