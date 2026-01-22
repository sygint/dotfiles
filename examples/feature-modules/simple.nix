# Example: Simple Feature Module
#
# This example shows a simple feature module that:
# - Installs a package system-wide
# - Configures a simple service
# - Adds user-level configuration
#
# Location: modules/features/example-simple.nix

{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.example-simple;
in
{
  options.modules.features.example-simple = {
    enable = mkEnableOption "Example Simple Feature";
  };

  config = mkIf cfg.enable {
    # System: Install tool
    environment.systemPackages = with pkgs; [
      htop # Example package
    ];

    # User: Configuration file
    home-manager.users.${userVars.username} = {
      home.file.".config/example/config.txt".text = ''
        # Example configuration
        user = ${userVars.username}
      '';
    };
  };
}
