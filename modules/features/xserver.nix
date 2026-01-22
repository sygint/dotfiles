{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.xserver;
in
{
  options.modules.features.xserver.enable = mkEnableOption "X11 server support";

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;

      # Configure keymap for X11 (optional)
      xkb = {
        layout = "us"; # Set keymap layout
        variant = ""; # Use the default variant
      };
    };
  };
}
