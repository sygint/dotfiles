#!/usr/bin/env bash
# Monitor event handler for Hyprland
# This script is triggered on monitor connect/disconnect events
# Usage: monitor-handler.sh [--fast|--no-delay]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if fast mode is requested (skip delays)
FAST_MODE=false
if [[ "${1:-}" == "--fast" || "${1:-}" == "--no-delay" ]]; then
    FAST_MODE=true
fi

echo "📺 Monitor event detected at $(date)"

# Wait for system to stabilize (skip in fast mode)
if [[ "$FAST_MODE" == "false" ]]; then
    echo "⏳ Waiting for system to stabilize..."
    sleep 2
else
    echo "⚡ Fast mode - skipping delays"
fi

# Reconfigure monitors
echo "🔧 Reconfiguring monitors..."
if [[ "$FAST_MODE" == "true" ]]; then
    "$SCRIPT_DIR/monitors.sh" --fast
else
    "$SCRIPT_DIR/monitors.sh"
fi

# Restart waybar to ensure it appears on all monitors
echo "🔄 Restarting waybar..."
pkill -f waybar 2>/dev/null || true
if [[ "$FAST_MODE" == "false" ]]; then
    sleep 1
    "$SCRIPT_DIR/start-waybar.sh"
else
    "$SCRIPT_DIR/start-waybar.sh" --fast
fi

# Restore wallpaper if using swww
if command -v swww >/dev/null 2>&1; then
    echo "🖼️ Restoring wallpaper..."
    swww restore 2>/dev/null || true
fi

echo "✅ Monitor event handling complete"
