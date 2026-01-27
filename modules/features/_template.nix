# Feature Module Template
#
# This template shows the standard pattern for dendritic feature modules.
# Copy this file to create new features in modules/features/
#
# Usage:
#   1. Copy this to modules/features/myfeature.nix
#   2. Replace all instances of "myfeature" with your feature name
#   3. Add system-level config in the config block
#   4. Add home-manager config in home-manager.users block
#   5. Enable in system: modules.features.myfeature.enable = true;

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.features.myfeature;
in
{
  options.modules.features.myfeature = {
    enable = lib.mkEnableOption "MyFeature description";

    # Add feature-specific options here
    exampleOption = lib.mkOption {
      type = lib.types.str;
      default = "default-value";
      description = "Example option description";
    };

    # Common patterns:
    # - package = lib.mkOption { type = lib.types.package; default = pkgs.myfeature; };
    # - enableSomething = lib.mkOption { type = lib.types.bool; default = true; };
    # - settings = lib.mkOption { type = lib.types.attrs; default = {}; };
  };

  config = lib.mkIf cfg.enable {
    # ============================================================================
    # SYSTEM CONFIGURATION
    # ============================================================================
    # Everything that requires root/system-level access goes here

    # System services
    # services.myfeature = {
    #   enable = true;
    #   # ...
    # };

    # System packages (daemons, system tools)
    # environment.systemPackages = with pkgs; [
    #   myfeature-daemon
    # ];

    # System-level files
    # environment.etc."myfeature/config".text = ''
    #   # system config
    # '';

    # Security/PAM
    # security.pam.services.myfeature = {};

    # Networking
    # networking.firewall.allowedTCPPorts = [ 1234 ];

    # ============================================================================
    # HOME-MANAGER CONFIGURATION
    # ============================================================================
    # User-level configuration goes here
    # Uses home-manager as a NixOS module (not standalone)

    home-manager.users = lib.mkMerge [
      # For each user that exists in the system
      (lib.mkIf (config.home-manager.users ? syg) {
        syg = {
          # User packages
          home.packages = with pkgs; [
            # myfeature-client
          ];

          # Program configuration using home-manager modules
          # programs.myfeature = {
          #   enable = true;
          #   settings = cfg.settings;
          # };

          # XDG config files
          # xdg.configFile."myfeature/config.conf".text = ''
          #   setting = ${cfg.exampleOption}
          # '';

          # Services (user-level systemd services)
          # services.myfeature = {
          #   enable = true;
          # };
        };
      })

      # Add more users as needed
      # (lib.mkIf (config.home-manager.users ? otheruser) {
      #   otheruser = { ... };
      # })
    ];
  };
}
