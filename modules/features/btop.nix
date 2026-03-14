{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.btop;
in
{
  options.modules.features.btop.enable =
    mkEnableOption "btop system monitor with dotfiles configuration";

  config = mkIf cfg.enable {
    home-manager.users.${userVars.username} =
      { config, ... }:
      let
        inherit (config.lib.file) mkOutOfStoreSymlink;
      in
      {
        home.packages = [ pkgs.btop ];

        # Use the real filesystem path, NOT inputs.dotfiles.outPath (which
        # resolves to a read-only /nix/store copy). mkOutOfStoreSymlink needs
        # to point to the actual mutable file on disk.
        home.file.".config/btop/btop.conf" = {
          source = mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/btop/btop.conf";
          force = true;
        };
      };
  };
}
