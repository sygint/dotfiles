# System-specific configuration for Axon
#
# This file contains machine-specific settings like user preferences,
# application choices, and local configuration.
#
# Network configuration (IPs, MACs, SSH) is centralized in fleet-config.nix
let
  # Import centralized fleet configuration
  fleetConfig = import ../../fleet-config.nix;
  # Get this host's network settings
  thisHost = fleetConfig.hosts.axon;
in
{
  system = {
    hostName = thisHost.hostname; # From fleet-config.nix
    timeZone = fleetConfig.global.timeZone; # From fleet-config.nix
    # Machine-specific settings
  };

  user = {
    username = "axon";
    name = "axon";
    email = "axon@example.com";
    # Add any other user-specific variables here
  };

  # Re-export network config for this host (optional, for convenience)
  network = thisHost;
}
