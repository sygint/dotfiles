{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.hardware.networking;
in
{
  options.modules.hardware.networking = {
    enable = mkEnableOption "Networking";

    hostName = lib.mkOption {
      type = lib.types.str;
      description = "Host Name";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      hostName = "${cfg.hostName}"; # Define your hostname.
      wireless.enable = false; # Set to true to enable wireless support via wpa_supplicant.
      networkmanager.enable = true;

      # Configure network proxy if necessary
      # networking.proxy = {
      # default = "http://user:password@proxy:port/";
      # noProxy = "127.0.0.1,localhost,internal.domain";
      # };

      # Enable firewall (optional)
      firewall = {
        enable = true;
        allowedTCPPorts = [ 22 80 443 ]; # Allow SSH and HTTP/HTTPS ports
      };
    };

    # Configure SSH server (optional)
    # services.openssh.enable = true;
  };
}
