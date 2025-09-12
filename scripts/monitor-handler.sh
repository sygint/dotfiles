#!/usr/bin/env bash
# Monitor event handler for Hyprland
# This script is triggered on monitor connect/disconnect events

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📺 Monitor event detected at $(date)"

# Wait a bit for the system to stabilize
sleep 2

# Reconfigure monitors
echo "🔧 Reconfiguring monitors..."
"$SCRIPT_DIR/monitors.sh"

# Restart waybar to ensure it appears on all monitors
echo "🔄 Restarting waybar..."
pkill -f waybar 2>/dev/null || true
sleep 1
"$SCRIPT_DIR/start-waybar.sh"

# Restore wallpaper if using swww
if command -v swww >/dev/null 2>&1; then
    echo "🖼️ Restoring wallpaper..."
    swww restore 2>/dev/null || true
fi

echo "✅ Monitor event handling complete"
