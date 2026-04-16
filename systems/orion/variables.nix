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

    git = {
      username = "sygint";
      email = "sygint@users.noreply.github.com";
    };

    hyprland = {
      terminal = "ghostty";
      fileManager = "nemo";
      webBrowser = "brave";
      menu = "rofi -show drun";
      bar = "noctalia"; # or "hyprpanel"
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

  # Workspace configuration
  # Each workspace has a name and optional compositor-specific settings.
  # - hyprland: id (required), monitorDesc for monitor pinning
  # The first workspace assigned to each monitor gets default:true automatically (Hyprland).
  workspaces = [
    # Order: System -> ES -> HSFF -> PRJ -> PRJ2 -> Media -> Media 2 -> Chat -> Info
    { name = "System"; hyprland = { id = 1;  monitorDesc = "Acer Technologies ED343CUR V 1326001BF2X00"; }; }
    { name = "ES";     hyprland = { id = 2;  monitorDesc = "Acer Technologies ED343CUR V 1326001BF2X00"; }; }
    { name = "HSFF";   hyprland = { id = 3;  monitorDesc = "Acer Technologies ED343CUR V 1326001BF2X00"; }; }
    { name = "PRJ";    hyprland = { id = 4;  monitorDesc = "Acer Technologies ED343CUR V 1326001BF2X00"; }; }
    { name = "PRJ2";   hyprland = { id = 5;  monitorDesc = "Acer Technologies ED343CUR V 1326001BF2X00"; }; }
    { name = "Media";   hyprland = { id = 6;  monitorDesc = "BOE 0x0BCA"; }; }
    { name = "Media 2"; hyprland = { id = 7;  monitorDesc = "BOE 0x0BCA"; }; }
    { name = "Chat"; hyprland = { id = 8;  monitorDesc = "Sceptre Tech Inc Sceptre M24 00"; }; }
    { name = "Info"; hyprland = { id = 9;  monitorDesc = "Sceptre Tech Inc Sceptre M24 00"; }; }
  ];

  # Re-export network config for this host (optional, for convenience)
  network = thisHost;
}
