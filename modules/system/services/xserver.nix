{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.services.xserver;
in
{
  options.modules.services.xserver.enable = mkEnableOption "Xserver";

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
