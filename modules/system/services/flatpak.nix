{ config, lib, options, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.services.flatpak;
in
{
  options.modules.services.flatpak.enable = mkEnableOption "Flatpak";

  config = mkIf cfg.enable {
    # Only enable the system flatpak service when explicitly requested
    services.flatpak.enable = true;
  };
}
