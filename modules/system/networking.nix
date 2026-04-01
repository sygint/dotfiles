# Fleet-wide networking configuration
# Generates /etc/hosts from fleet-config.nix
# Includes host FQDNs and service subdomains (e.g. git.cortex.home)
{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Import the fleet configuration
  fleetConfig = import ../../fleet-config.nix;

  # Generate hosts entries from fleet config
  # Maps each host's IP to its hostname, fqdn, and service subdomains
  #
  # Example output for cortex:
  #   192.168.1.7  cortex  cortex.home  git.cortex.home  chat.cortex.home  ai.cortex.home
  fleetHosts = lib.mapAttrs' (
    name: hostCfg:
    let
      serviceNames = lib.attrValues (hostCfg.services or { });
    in
    lib.nameValuePair hostCfg.ip (
      [ hostCfg.hostname hostCfg.fqdn ] ++ serviceNames
    )
  ) fleetConfig.hosts;

  # Also map infrastructure hosts (NAS, etc.)
  infraHosts = lib.optionalAttrs (fleetConfig ? infrastructure.nas) {
    ${fleetConfig.infrastructure.nas.ip} = [
      fleetConfig.infrastructure.nas.hostname
      fleetConfig.infrastructure.nas.fqdn
    ];
  };

in
{
  # Merge fleet hosts + infrastructure into networking.hosts
  # This adds entries like:
  #   192.168.1.7   cortex  cortex.home  git.cortex.home  chat.cortex.home
  #   192.168.1.136 synology  synology.home
  networking.hosts = fleetHosts // infraHosts;
}
