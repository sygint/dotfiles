{
  config,
  lib,
  pkgs,
  userVars,
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
            configRoot = "/home/${userVars.username}/.config/nixos";
            configKittyDir = "${configRoot}/dotfiles/.config/kitty";
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
