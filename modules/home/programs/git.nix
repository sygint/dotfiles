{ config, lib, userVars, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf;
  gitUsername = userVars.user.git.username;
  gitEmail = userVars.user.git.email;
  cfg = config.settings.programs.git;
in {
  options.settings.programs.git.enable = mkEnableOption "Git version control";

  config = mkIf cfg.enable {
    home.packages = [ pkgs.git ];
    
    xdg.configFile."git/config" = {
      text = import ../../../dotfiles/.config/git/config.nix { inherit gitUsername gitEmail; };
    };
  };
}
