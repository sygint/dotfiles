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
        configRoot = "/home/${userVars.username}/.config/nixos";
      in
      {
        home.packages = [ pkgs.btop ];

        home.file.".config/btop/btop.conf" = {
          source = mkOutOfStoreSymlink "${configRoot}/dotfiles/.config/btop/btop.conf";
          force = true;
        };
      };
  };
}
