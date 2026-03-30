# System-specific configuration for Nexus
#
# This file contains machine-specific settings like user preferences,
# application choices, and local configuration.
#
# Network configuration (IPs, MACs, SSH) is centralized in fleet-config.nix
let
  # Import centralized network configuration
  networkConfig = import ../default.nix;
  # Get this host's network settings
  thisHost = networkConfig.hosts.nexus;
in
{
  system = {
    hostName = thisHost.hostname; # From fleet-config.nix
  };

  user = {
    username = "deploy";

    git = {
      username = "deploy";
      email = "deploy@nexus.home";
    };

    # No desktop environment on this server
    hyprland = { };
  };

  # Network and host re-export for convenience
  network = thisHost;
}
