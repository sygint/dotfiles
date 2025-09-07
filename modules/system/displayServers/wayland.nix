{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.wayland;
in
{
  options.modules.wayland.enable = mkEnableOption "Wayland";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wdisplays
      swww
      waypaper
    ];
  };
}
