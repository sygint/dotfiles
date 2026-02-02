{
  config,
  lib,
  pkgs,
  userVars,
  inputs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.kitty;
in
{
  options.modules.features.kitty.enable =
    mkEnableOption "Kitty terminal emulator with dotfiles configuration";

  config = mkIf cfg.enable {
    home-manager.users.${userVars.username} =
      { config, ... }:
      {
        home =
          let
            inherit (config.lib.file) mkOutOfStoreSymlink;
            configKittyDir = "${inputs.dotfiles.outPath}/.config/kitty";
          in
          {
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
  };
}
