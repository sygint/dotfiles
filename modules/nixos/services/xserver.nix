{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.services.xserver;
in {
  options.settings.services.xserver = {
    enable = mkEnableOption "Xserver";
  };

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;

      # Configure keymap for X11 (optional)
      xkb = {
        layout  = "us"; # Set keymap layout
        variant = "";  # Use the default variant
      };
    };
  };
}