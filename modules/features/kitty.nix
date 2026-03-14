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
            # Use the real filesystem path, NOT inputs.dotfiles.outPath (which
            # resolves to a read-only /nix/store copy). mkOutOfStoreSymlink needs
            # to point to the actual mutable file on disk.
            configKittyDir = "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/kitty";
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
