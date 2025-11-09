#!/usr/bin/env bash
# Start waybar script
# Usage: start-waybar.sh [--fast|--no-delay]

# Check if fast mode is requested (skip delays)
FAST_MODE=false
if [[ "${1:-}" == "--fast" || "${1:-}" == "--no-delay" ]]; then
    FAST_MODE=true
fi

# Kill any existing instances first
pkill -x waybar 2>/dev/null || true
pkill -x blueman-applet 2>/dev/null || true

# Wait for system to be ready (skip in fast mode)
if [[ "$FAST_MODE" == "false" ]]; then
    sleep 2
fi

# Start blueman-applet for bluetooth support
blueman-applet 2>/dev/null &

# Start waybar with proper Wayland backend setting
if [[ "$FAST_MODE" == "false" ]]; then
    sleep 1
fi
# Ensure Wayland environment is set properly
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export GDK_BACKEND=wayland
waybar 2>/dev/null &
