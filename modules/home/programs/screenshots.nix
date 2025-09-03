{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.programs.screenshots;
in
{
  options.settings.programs.screenshots.enable = mkEnableOption "Screenshot helpers (user)";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      grim
      slurp
      swappy
    ];
  };
}
