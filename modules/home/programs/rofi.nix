{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.settings.programs.rofi;
in {
  options.settings.programs.rofi.enable = mkEnableOption "rofi application launcher";

  config = mkIf cfg.enable {
    # Install rofi as a standalone package
    home.packages = with pkgs; [
      rofi
    ];

    home.file.".config/rofi/catppuccin-mocha.rasi" = {
      source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/rofi/catppuccin-mocha.rasi";
      force = true;
    };

    home.file.".config/rofi/config.rasi" = {
      source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/rofi/config.rasi";
      force = true;
    };
  };
}
