#!/usr/bin/env bash
# Monitor event handler for Hyprland
# This script is triggered on monitor connect/disconnect events
# Usage: monitor-handler.sh [--fast|--no-delay] [--bar=waybar|hyprpanel]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
FAST_MODE=false
BAR_SYSTEM=""

for arg in "$@"; do
    case $arg in
        --fast|--no-delay)
            FAST_MODE=true
            ;;
        --bar=*)
            BAR_SYSTEM="${arg#*=}"
            ;;
    esac
done

# Auto-detect bar system if not specified
if [[ -z "$BAR_SYSTEM" ]]; then
    if pgrep -f "hyprpanel\|HyprPanel" >/dev/null 2>&1; then
        BAR_SYSTEM="hyprpanel"
    elif pgrep -x waybar >/dev/null 2>&1; then
        BAR_SYSTEM="waybar"
    else
        # Default to hyprpanel if neither is running
        BAR_SYSTEM="hyprpanel"
    fi
fi

echo "📺 Monitor event detected at $(date)"
echo "🎯 Using bar system: $BAR_SYSTEM"

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
    "$SCRIPT_DIR/monitors.sh" --fast --bar="$BAR_SYSTEM"
else
    "$SCRIPT_DIR/monitors.sh" --bar="$BAR_SYSTEM"
fi

# Restart the appropriate bar system
case "$BAR_SYSTEM" in
    "hyprpanel")
        echo "🔄 Restarting hyprpanel..."
        pkill -f "hyprpanel\|HyprPanel" 2>/dev/null || true
        if [[ "$FAST_MODE" == "false" ]]; then
            sleep 2  # HyprPanel needs a bit more time to clean up
            "$SCRIPT_DIR/start-hyprpanel.sh"
        else
            # Fast mode - minimal delay
            sleep 0.5
            "$SCRIPT_DIR/start-hyprpanel.sh"
        fi
        ;;
    "waybar")
        echo "🔄 Restarting waybar..."
        pkill -x waybar 2>/dev/null || true
        if [[ "$FAST_MODE" == "false" ]]; then
            sleep 1  # Waybar needs less time to clean up
            "$SCRIPT_DIR/start-waybar.sh"
        else
            # Fast mode - minimal delay
            sleep 0.2
            "$SCRIPT_DIR/start-waybar.sh"
        fi
        ;;
    *)
        echo "⚠️ Unknown bar system: $BAR_SYSTEM"
        echo "   Supported: waybar, hyprpanel"
        ;;
esac

# Restore wallpaper if using swww
if command -v swww >/dev/null 2>&1; then
    echo "🖼️ Restoring wallpaper..."
    swww restore 2>/dev/null || true
fi

echo "✅ Monitor event handling complete"
