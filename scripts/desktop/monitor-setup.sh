#!/usr/bin/env bash
set -euo pipefail

# Configure monitors using Hyprland based on nixos/monitors.json mappings
# Requires: hyprctl, jq

MONITORS_JSON="$(dirname "${BASH_SOURCE[0]}")/../../monitors.json"

# Exit cleanly if we're not in a graphical session (Wayland/X11) or
# when this script runs in a build/container environment (e.g. during
# nix build or system activation) — nothing to do there.
if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${DISPLAY:-}" && -z "${XDG_RUNTIME_DIR:-}" ]]; then
  echo "No graphical display detected (no WAYLAND_DISPLAY/DISPLAY/XDG_RUNTIME_DIR); skipping monitor setup."
  exit 0
fi

# If hyprctl is not available, this isn't the right environment to
# configure Hyprland monitors; don't fail the calling process.
if ! command -v hyprctl >/dev/null 2>&1; then
  echo "hyprctl not found; skipping monitor setup (ensure Hyprland is installed)." >&2
  exit 0
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found; skipping monitor setup (install jq if you want automatic monitor config)." >&2
  exit 0
fi

if [[ ! -f "$MONITORS_JSON" ]]; then
  echo "monitors.json not found at $MONITORS_JSON; nothing to configure." >&2
  exit 0
fi

# Get connected monitors
mapfile -t monitors < <(hyprctl monitors -j | jq -r '.[].name')

if [[ ${#monitors[@]} -eq 0 ]]; then
  echo "No monitors detected via hyprctl; skipping." >&2
  exit 0
fi

# Apply settings per monitor name using monitors.json entries
for name in "${monitors[@]}"; do
  if jq -e --arg n "$name" 'has($n)' "$MONITORS_JSON" >/dev/null; then
    config=$(jq -r --arg n "$name" '.[$n]' "$MONITORS_JSON")
    # Expected format examples:
    # "preferred, 0x1504, 1"
    # "1920x1080@165, 3440x1267, 1, transform, 1"
    # Hyprland format: monitor <name>, <resolution[@refresh]>, <position>, <scale>[, transform, <rotate>]
    echo "Applying monitor config for $name: $config"
    hyprctl keyword monitor "$name, $config" || {
      echo "Failed to apply config for $name" >&2
    }
  else
    echo "No config found for monitor: $name" >&2
  fi
done

exit 0
