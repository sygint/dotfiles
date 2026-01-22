{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.wayland;
in
{
  options.modules.features.wayland.enable = mkEnableOption "Wayland display server utilities";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wdisplays
      swww
      waypaper
    ];
  };
}
