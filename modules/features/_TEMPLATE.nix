# Feature Module Template
#
# This is a template for creating new unified feature modules.
# Copy this file to create a new feature:
#   cp modules/features/_TEMPLATE.nix modules/features/myfeature.nix
#
# See docs/DENDRITIC-MIGRATION.md for complete documentation.

{
  config,
  lib,
  pkgs,
  userVars, # User variables: username, email, git config, etc.
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;

  # Replace 'myfeature' with your feature name
  cfg = config.modules.features.myfeature;
in
{
  # ===== OPTIONS =====
  # Define the feature options

  options.modules.features.myfeature = {
    # Required: Enable option for the feature
    enable = mkEnableOption "My Feature description";

    # Optional: Additional feature-specific options
    # Uncomment and customize as needed:

    # port = mkOption {
    #   type = types.port;
    #   default = 8080;
    #   description = "Port to listen on";
    # };

    # package = mkOption {
    #   type = types.package;
    #   default = pkgs.mypackage;
    #   description = "Package to use for this feature";
    # };

    # settings = mkOption {
    #   type = types.attrs;
    #   default = {};
    #   description = "Configuration settings";
    # };
  };

  # ===== CONFIGURATION =====
  # Implement the feature (only when enabled)

  config = mkIf cfg.enable {

    # ===== SYSTEM-LEVEL CONFIG =====
    # Configuration that affects the entire system

    # System packages
    environment.systemPackages = with pkgs; [
      # Add system-wide packages here
      # mypackage
    ];

    # System services
    # systemd.services.myservice = {
    #   enable = true;
    #   description = "My Service";
    #   wantedBy = [ "multi-user.target" ];
    #   serviceConfig = {
    #     ExecStart = "${pkgs.mypackage}/bin/myservice";
    #     Restart = "always";
    #   };
    # };

    # Firewall rules
    # networking.firewall.allowedTCPPorts = [ cfg.port ];

    # Other system configuration
    # programs.myprogram.enable = true;
    # services.myservice.enable = true;

    # ===== USER-LEVEL CONFIG =====
    # Configuration specific to the user

    home-manager.users.${userVars.username} = {

      # User packages
      home.packages = with pkgs; [
        # Add user-specific packages here
        # my-user-tool
      ];

      # User configuration files (inline)
      # home.file.".config/myapp/config.toml".text = ''
      #   setting = "value"
      #   username = "${userVars.username}"
      # '';

      # User configuration files (from source)
      # xdg.configFile."myapp/settings.json".source = ./myapp-settings.json;

      # Home Manager programs
      # programs.myapp = {
      #   enable = true;
      #   settings = {
      #     # ...
      #   };
      # };
    };
  };
}
