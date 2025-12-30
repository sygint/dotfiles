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
      networkmanager.enable = true;

      # Configure network proxy if necessary
      # networking.proxy = {
      # default = "http://user:password@proxy:port/";
      # noProxy = "127.0.0.1,localhost,internal.domain";
      # };

      # Enable firewall
      firewall = {
        enable = true;
        allowedTCPPorts = [ ]; # No TCP ports open to internet
        # SSH access via interfaces configuration for LAN-only access
        # interfaces = {
        #   # Allow SSH only on LAN interfaces
        #   "eth0".allowedTCPPorts = [ 22 ];
        #   "wlp1s0".allowedTCPPorts = [ 22 ];
        #   # No internet-facing SSH access
        # };
      };
    };

    # Configure SSH server with security settings
    # services.openssh = {
    #   enable = true;
    #   settings = {
    #     PasswordAuthentication = true; # Change to false after setting up key auth
    #     PermitRootLogin = "no";
    #     X11Forwarding = false;
    #   };
    # };
  };
}
