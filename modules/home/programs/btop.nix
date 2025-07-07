{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.settings.programs.btop;
in {
  options.settings.programs.btop.enable = mkEnableOption "btop system monitor";

  config = mkIf cfg.enable {
    home.packages = [ pkgs.btop ];

    home.file.".config/btop/btop.conf" = {
      source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/dot_config/btop/btop.conf";
      force = true;
    };
  };
}
