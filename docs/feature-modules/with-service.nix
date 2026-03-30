# Example: Feature with Service
#
# This example shows a feature module that:
# - Runs a systemd service
# - Opens firewall ports
# - Provides user-level tools
#
# Location: modules/features/example-service.nix

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
  cfg = config.modules.features.example-service;
in
{
  options.modules.features.example-service = {
    enable = mkEnableOption "Example Service Feature";

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port for the service to listen on";
    };
  };

  config = mkIf cfg.enable {
    # System: Service configuration
    systemd.services.example-service = {
      enable = true;
      description = "Example Service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 -m http.server ${toString cfg.port}";
        Restart = "always";
        WorkingDirectory = "/tmp";
      };
    };

    # System: Firewall
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    # User: Client tool
    home-manager.users.${userVars.username} = {
      home.packages = with pkgs; [
        curl # Client tool to interact with service
      ];
    };
  };
}
