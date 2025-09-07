{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.modules.programs.kitty;
in
{
  options.modules.programs.kitty.enable = mkEnableOption "Kitty terminal emulator";

  config = mkIf cfg.enable {
    home = {
      packages = [ pkgs.kitty ];
      file = {
        ".config/kitty/kitty.conf" = {
          source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/kitty/kitty.conf";
          force = true;
        };
        ".config/kitty/base16-catppuccin-mocha.conf" = {
          source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/kitty/base16-catppuccin-mocha.conf";
          force = true;
        };
      };
    };
  };
}
