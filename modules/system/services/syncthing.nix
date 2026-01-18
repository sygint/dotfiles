{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.services.syncthing;
in
{
  options.modules.services.syncthing = {
    enable = mkEnableOption "Syncthing";

    username = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Username for running Syncthing service and GUI access";
    };
  };

  config = mkIf cfg.enable {
    services = {
      syncthing = {
        enable = true;
        user = cfg.username;  # Run as this user
        group = "users";      # Group for the user
        dataDir = "/home/${cfg.username}/.local/share/syncthing";
        configDir = "/home/${cfg.username}/.config/syncthing";
        openDefaultPorts = false; # Don't auto-open ports to internet
        settings.gui = {
          user = "${cfg.username}";
          # Password is managed by a sops-nix secret at runtime
          # The secret file is expected at: config.sops.secrets."${cfg.username}/syncthing_password".path
        };
      };
    };

    # Open Syncthing ports only for LAN interfaces
    networking.firewall.interfaces = {
      "eth0" = {
        allowedTCPPorts = [ 22000 ]; # Syncthing transfer protocol
        allowedUDPPorts = [ 22000 21027 ]; # Syncthing transfer and discovery
      };
      "wlp1s0" = {
        allowedTCPPorts = [ 22000 ]; # Syncthing transfer protocol  
        allowedUDPPorts = [ 22000 21027 ]; # Syncthing transfer and discovery
      };
      # Not exposed to internet - LAN interfaces only
    };
  };
}
