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

  # Workspace configuration (shared across compositors)
  # Each workspace has a name and optional compositor-specific settings.
  # - hyprland: id (required), monitorDesc for monitor pinning
  # - niri: rule for workspace rules
  # The first workspace assigned to each monitor gets default:true automatically (Hyprland).
  workspaces = [
    # Laptop (Main)
    { name = "System"; hyprland = { id = 1;  monitorDesc = "BOE 0x0BCA"; }; niri = { rule = "open-on-output=BOE 0x0BCA Unknown"; }; }
    { name = "ES";     hyprland = { id = 2;  monitorDesc = "BOE 0x0BCA"; }; niri = { rule = "open-on-output=BOE 0x0BCA Unknown"; }; }
    { name = "HSFF";   hyprland = { id = 3;  monitorDesc = "BOE 0x0BCA"; }; niri = { rule = "open-on-output=BOE 0x0BCA Unknown"; }; }
    { name = "PRJ";    hyprland = { id = 4;  monitorDesc = "BOE 0x0BCA"; }; niri = { rule = "open-on-output=BOE 0x0BCA Unknown"; }; }
    { name = "PRJ2";   hyprland = { id = 5;  monitorDesc = "BOE 0x0BCA"; }; niri = { rule = "open-on-output=BOE 0x0BCA Unknown"; }; }
    # Ultrawide (Secondary)
    { name = "Media";   hyprland = { id = 6;  monitorDesc = "Acer Technologies ED343CUR V 1326001BF2X00"; }; niri = { rule = "open-on-output=Acer Technologies ED343CUR V 1326001BF2X00"; }; }
    { name = "Media 2"; hyprland = { id = 7;  monitorDesc = "Acer Technologies ED343CUR V 1326001BF2X00"; }; niri = { rule = "open-on-output=Acer Technologies ED343CUR V 1326001BF2X00"; }; }
    # Portrait (Tertiary)
    { name = "Chat"; hyprland = { id = 8;  monitorDesc = "Sceptre Tech Inc Sceptre M24 00"; }; niri = { rule = "open-on-output=Sceptre Tech Inc Sceptre M24 00"; }; }
    { name = "Info"; hyprland = { id = 9;  monitorDesc = "Sceptre Tech Inc Sceptre M24 00"; }; niri = { rule = "open-on-output=Sceptre Tech Inc Sceptre M24 00"; }; }
  ];

  # Re-export network config for this host (optional, for convenience)
  network = thisHost;
}
