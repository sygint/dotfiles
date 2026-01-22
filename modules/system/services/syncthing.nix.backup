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
      description = "Username for the Syncthing";
    };

    password = lib.mkOption {
      type = lib.types.str;
      default = "password";
      description = "Password for the Syncthing";
    };
  };

  config = mkIf cfg.enable {
    services = {
      syncthing = {
        enable = true;
        openDefaultPorts = false; # Don't auto-open ports to internet
        settings.gui = {
          user = "${cfg.username}";
          password = "${cfg.password}";
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
