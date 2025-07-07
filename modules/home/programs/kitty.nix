{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.settings.programs.kitty;
in {
  options.settings.programs.kitty.enable = mkEnableOption "Kitty terminal emulator";

  config = mkIf cfg.enable {
    home.packages = [ pkgs.kitty ];

    home.file.".config/kitty/kitty.conf" = {
      source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/kitty/kitty.conf";
      force = true;
    };

    home.file.".config/kitty/base16-catppuccin-mocha.conf" = {
      source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/kitty/base16-catppuccin-mocha.conf";
      force = true;
    };
  };
}
