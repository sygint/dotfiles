# System-specific configuration for Orion
# 
# This file contains machine-specific settings like user preferences,
# application choices, and local configuration.
#
# Network configuration (IPs, MACs, SSH) is centralized in network-config.nix
let
  # Import centralized network configuration
  networkConfig = import ../../network-config.nix;
  # Get this host's network settings
  thisHost = networkConfig.hosts.orion;
in
{
  system = {
    hostName = thisHost.hostname;  # From network-config.nix
    # Machine-specific settings
    # Add other system-level configs here
  };

  user = {
    username = "syg";
    syncPassword = "syncmybattleship";

    git = {
      username = "sygint";
      email = "sygint@users.noreply.github.com";
    };

    hyprland = {
      terminal = "ghostty";
      fileManager = "nemo";
      webBrowser = "brave";
      menu = "rofi -show drun";
      bar = "hyprpanel";  # or "waybar"
    };
  };

  # Re-export network config for this host (optional, for convenience)
  network = thisHost;
}
