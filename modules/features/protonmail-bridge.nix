{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.modules.features.protonmail-bridge;
in
{
  options.modules.features.protonmail-bridge = {
    enable = mkEnableOption "ProtonMail Bridge for email client integration";

    username = mkOption {
      type = types.str;
      default = "admin";
      description = "Username for ProtonMail Bridge CLI (if needed)";
    };

    password = mkOption {
      type = types.str;
      default = "password";
      description = "Password for ProtonMail Bridge CLI (if needed)";
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${userVars.username} = {
      home.packages = with pkgs; [ protonmail-bridge ];

      # Optionally, write credentials to a file or set env vars here if needed by the CLI
      # home.sessionVariables = {
      #   PROTONMAIL_BRIDGE_USERNAME = cfg.username;
      #   PROTONMAIL_BRIDGE_PASSWORD = cfg.password;
      # };
    };
  };
}
