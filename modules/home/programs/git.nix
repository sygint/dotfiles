{ config, lib, userVars, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf;
  gitUsername = userVars.git.username;
  gitEmail = userVars.git.email;
  cfg = config.modules.programs.git;
in
{
  options.modules.programs.git.enable = mkEnableOption "Git version control";

  config = mkIf cfg.enable {
    home.packages = [ pkgs.git ];

    xdg.configFile."git/config" = {
      text = import ../../../dotfiles/.config/git/config.nix { inherit gitUsername gitEmail; };
    };
  };
}
