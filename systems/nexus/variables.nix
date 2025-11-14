# System-specific configuration for Nexus
# 
# This file contains machine-specific settings like user preferences,
# application choices, and local configuration.
#
# Network configuration (IPs, MACs, SSH) is centralized in fleet-config.nix
let
  # Import centralized network configuration
  networkConfig = import ../../fleet-config.nix;
  # Get this host's network settings
  thisHost = networkConfig.hosts.nexus;
in
{
  system = {
    hostName = thisHost.hostname;  # From fleet-config.nix
    # Machine-specific settings
    # Add other system-level configs here
  };

  user = {
    username = "admin";
    name = "Nexus Administrator";
    email = "admin@nexus.home";
    # Add any other user-specific variables here
  };

  # Network and host re-export for convenience
  network = thisHost;
}
