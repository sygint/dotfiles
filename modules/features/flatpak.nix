{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.flatpak;
in
{
  options.modules.features.flatpak.enable =
    mkEnableOption "Flatpak application sandboxing and distribution";

  config = mkIf cfg.enable {
    # Enable the system flatpak service
    services.flatpak.enable = true;
  };
}
