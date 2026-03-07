# RustDesk - Open-source remote desktop client
#
# Installs the RustDesk client for connecting to remote machines.
# For LAN usage, no account or relay server is needed — just install
# RustDesk on both machines and connect via IP or ID.

{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.rustdesk;
in
{
  options.modules.features.rustdesk = {
    enable = mkEnableOption "RustDesk remote desktop client";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      rustdesk-flutter
    ];

    # RustDesk uses TCP 21115-21119 and UDP 21116 for direct connections
    networking.firewall = {
      allowedTCPPorts = [ 21115 21116 21117 21118 21119 ];
      allowedUDPPorts = [ 21116 ];
    };
  };
}
