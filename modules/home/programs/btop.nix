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
  cfg = config.modules.programs.btop;
in
{
  options.modules.programs.btop.enable = mkEnableOption "btop system monitor";

  config = mkIf cfg.enable {
    home.packages = [ pkgs.btop ];

    home.file.".config/btop/btop.conf" = {
      source = mkOutOfStoreSymlink "${configRoot}/dotfiles/.config/btop/btop.conf";
      force = true;
    };
  };
}
