{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.protonmail-bridge;
in
{
  options.modules.features.protonmail-bridge = {
    enable = mkEnableOption "ProtonMail Bridge for email client integration";
  };

  config = mkIf cfg.enable {
    home-manager.users.${userVars.username} = {
      home.packages = with pkgs; [ protonmail-bridge ];
    };
  };
}
