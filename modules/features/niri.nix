{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.modules.features.niri;
in
{
  options.modules.features.niri = {
    enable = mkEnableOption "Niri scrollable tiling compositor";

    packages = {
      enable = mkEnableOption "Install Niri-related packages";
    };
  };

  config = mkIf cfg.enable {
    # Niri compositor configuration goes here
    # Add packages, services, etc. as needed
  };
}
