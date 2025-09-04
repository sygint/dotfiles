{ config, lib, pkgs, ... }:
let
  cfg = config.programs.protonmail-bridge;
in
{
  options.programs.protonmail-bridge = {
    enable = lib.mkEnableOption "ProtonMail Bridge CLI";
    username = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Username for ProtonMail Bridge CLI (if needed)";
    };
    password = lib.mkOption {
      type = lib.types.str;
      default = "password";
      description = "Password for ProtonMail Bridge CLI (if needed)";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ protonmail-bridge ];
    # Optionally, write credentials to a file or set env vars here if needed by the CLI
    # home.sessionVariables = {
    #   PROTONMAIL_BRIDGE_USERNAME = cfg.username;
    #   PROTONMAIL_BRIDGE_PASSWORD = cfg.password;
    # };
  };
}
