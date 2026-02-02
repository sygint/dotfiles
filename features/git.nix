{
  config,
  lib,
  userVars,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  gitUsername = userVars.git.username;
  gitEmail = userVars.git.email;
  cfg = config.modules.features.git;
in
{
  options.modules.features.git.enable =
    mkEnableOption "Git version control with dotfiles configuration";

  config = mkIf cfg.enable {
    home-manager.users.${userVars.username} = {
      home.packages = [ pkgs.git ];

      xdg.configFile."git/config" = {
        text = import ../../dotfiles/.config/git/config.nix { inherit gitUsername gitEmail; };
      };
    };
  };
}
