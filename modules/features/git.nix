{
  config,
  lib,
  userVars,
  pkgs,
  inputs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  gitUsername = userVars.git.username;
  gitEmail = userVars.git.email;
  cfg = config.modules.features.git;
  gitConfigNixPath = "${inputs.dotfiles.outPath}/.config/git/config.nix";
in
{
  options.modules.features.git.enable =
    mkEnableOption "Git version control with dotfiles configuration";

  config = mkIf cfg.enable {
    home-manager.users.${userVars.username} = {
      home.packages = [ pkgs.git ];

      xdg.configFile."git/config" = {
        text =
          if builtins.pathExists gitConfigNixPath then
            import gitConfigNixPath { inherit gitUsername gitEmail; }
          else
            ''
              [user]
                name = ${gitUsername}
                email = ${gitEmail}
              [core]
                editor = nano
            '';
      };
    };
  };
}
