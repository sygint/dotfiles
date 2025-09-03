{
  config,
  lib,
  options,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.wayland;
in {
  options.settings.wayland.enable = mkEnableOption "Wayland";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wdisplays
      swww
      waypaper
    ];
  };
}