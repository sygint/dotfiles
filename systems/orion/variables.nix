# System-specific configuration for Orion
#
# This file contains machine-specific settings like user preferences,
# application choices, and local configuration.
#
# Network configuration (IPs, MACs, SSH) is centralized in fleet-config.nix
let
  # Import centralized network configuration
  networkConfig = import ../../fleet-config.nix;
  # Get this host's network settings
  thisHost = networkConfig.hosts.orion;
in
{
  system = {
    hostName = thisHost.hostname; # From fleet-config.nix
    # Machine-specific settings
    # Add other system-level configs here
  };

  user = {
    username = "syg";

    # Which compositor is in use (used by swhkd for lock screen selection)
    # Options: "Hyprland", "niri"
    compositor = "niri";

    git = {
      username = "sygint";
      email = "sygint@users.noreply.github.com";
    };

    hyprland = {
      terminal = "ghostty";
      fileManager = "nemo";
      webBrowser = "brave";
      menu = "noctalia-shell ipc call launcher toggle";
      bar = "hyprpanel"; # or "waybar"
    };
  };

  # Monitor configuration
  # Layout: Laptop on top, ultrawide below, portrait monitor on right
  #
  #     ┌─────────────┐
  #     │   Laptop    │ (2256x1504)
  #     │   (top)     │
  #     └─────────────┘
  #     ┌───────────────────────┐ ┌──────┐
  #     │      Ultrawide        │ │Portr.│ (1080x1920)
  #     │       (3440)          │ │      │
  #     └───────────────────────┘ └──────┘
  #
  # Using description matching for stable identification across reboots/ports
  # Full "manufacturer model serial" from EDID — works for both compositors:
  #   Niri: exact match on "manufacturer model serial" (run `niri msg outputs`)
  #   Hyprland: substring match with `desc:` prefix (run `hyprctl monitors`)
  monitors = [
    # Laptop display (BOE panel)
    {
      desc = "BOE 0x0BCA Unknown";
      resolution = "2256x1504@60";
      position = "0x0";
      scale = "1";
    }
    # Acer ultrawide - below laptop
    {
      desc = "Acer Technologies ED343CUR V 1326001BF2X00";
      resolution = "3440x1440@60";
      position = "0x1504";
      scale = "1";
    }
    # Sceptre portrait monitor - right side, bottom-aligned with ultrawide
    {
      desc = "Sceptre Tech Inc Sceptre M24 00";
      resolution = "1920x1080@165";
      position = "3440x1024";
      scale = "1";
      transform = "1"; # 90° rotation
    }
  ];

  # Re-export network config for this host (optional, for convenience)
  network = thisHost;
}
