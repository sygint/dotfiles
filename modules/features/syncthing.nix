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
  cfg = config.modules.features.syncthing;
in
{
  options.modules.features.syncthing = {
    enable = mkEnableOption "Syncthing file synchronization service";

    username = mkOption {
      type = types.str;
      default = userVars.username;
      description = "Username for running Syncthing service and GUI access";
    };

    lanInterfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Network interfaces to open Syncthing ports on (LAN only). If empty, no per-interface firewall rules are created.";
      example = [
        "wlp1s0"
        "enp0s0"
      ];
    };
  };

  config = mkIf cfg.enable {
    services = {
      syncthing = {
        enable = true;
        user = cfg.username; # Run as this user
        group = "users"; # Group for the user
        dataDir = "/home/${cfg.username}/.local/share/syncthing";
        configDir = "/home/${cfg.username}/.config/syncthing";
        openDefaultPorts = false; # Don't auto-open ports to internet
        settings.gui = {
          user = "${cfg.username}";
          # Password is managed by sops-nix secret at runtime
          # The secret file is available at: config.sops.secrets."syg/syncthing_password".path
        };
      };
    };

    # Open Syncthing ports only for specified LAN interfaces
    networking.firewall.interfaces = lib.mkIf (cfg.lanInterfaces != [ ]) (
      lib.genAttrs cfg.lanInterfaces (_: {
        allowedTCPPorts = [ 22000 ]; # Syncthing transfer protocol
        allowedUDPPorts = [
          22000
          21027
        ]; # Syncthing transfer and discovery
      })
    );
  };
}
