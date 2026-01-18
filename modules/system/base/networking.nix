# Fleet-wide networking configuration
# Generates /etc/hosts from fleet-config.nix
{ config, pkgs, lib
, fleetConfig ? import (../../.. + "/fleet-config.nix")
, ...
}:

let
  # fleetConfig is provided as a module argument, defaulting to fleet-config.nix
  # in the repository root. Callers may override this to improve portability.

  # Generate hosts entries from fleet config
  # Maps each host's IP to its hostname and fqdn
  fleetHosts = lib.mapAttrs' (name: hostCfg:
    lib.nameValuePair hostCfg.ip [ hostCfg.hostname hostCfg.fqdn ]
  ) fleetConfig.hosts;

in {
  # Merge fleet hosts into networking.hosts
  # This adds entries like: 192.168.1.22 nexus nexus.home
  networking.hosts = fleetHosts;
}
