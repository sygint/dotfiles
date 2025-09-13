{ config
, lib
, options
, pkgs
, userVars
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.lib.file) mkOutOfStoreSymlink;

  configRoot = "/home/${userVars.username}/.config/nixos";
  configKittyDir = "${configRoot}/dotfiles/.config/kitty";
  cfg = config.modules.programs.kitty;
in
{
  options.modules.programs.kitty.enable = mkEnableOption "Kitty terminal emulator";

  config = mkIf cfg.enable {
    home = {
      packages = [ pkgs.kitty ];
      file = {
        ".config/kitty/kitty.conf" = {
          source = mkOutOfStoreSymlink "${configKittyDir}/kitty.conf";
          force = true;
        };
        ".config/kitty/base16-catppuccin-mocha.conf" = {
          source = mkOutOfStoreSymlink "${configKittyDir}/base16-catppuccin-mocha.conf";
          force = true;
        };
      };
    };
  };
}
