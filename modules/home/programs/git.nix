{ config, lib, userVars, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf;
  inherit (userVars) gitUsername gitEmail;
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
