# System-specific configuration for Cortex
#
# This file contains machine-specific settings like user preferences,
# application choices, and local configuration.
#
# Network configuration (IPs, MACs, SSH) is centralized in fleet-config.nix
let
  # Import centralized network configuration
  networkConfig = import ../../fleet-config.nix;
  # Get this host's network settings
  thisHost = networkConfig.hosts.cortex;
in
{
  system = {
    hostName = thisHost.hostname; # From fleet-config.nix
    # Machine-specific settings
    # Add other system-level configs here
  };

  user = {
    username = "syg";
    # Note: Passwords should be managed via sops-nix secrets, not here
    # syncPassword removed for security - use secrets management instead

    git = {
      username = "sygint";
      email = "sygint@users.noreply.github.com";
    };

    hyprland = {
      terminal = "ghostty";
      fileManager = "nemo";
      webBrowser = "brave";
      menu = "rofi -show drun";
      bar = "hyprpanel"; # or "waybar"
    };
  };

  # Re-export network config for this host (optional, for convenience)
  network = thisHost;
}
