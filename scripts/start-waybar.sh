#!/usr/bin/env bash
# Kill any existing instances first (but not this script)
pkill -x waybar
pkill -x blueman-applet

# Wait a moment for clean shutdown
sleep 0.5

# Start blueman-applet for bluetooth support
blueman-applet 2>/dev/null &

# Start waybar with proper Wayland backend setting
pkill waybar && env GDK_BACKEND=wayland waybar 2>/dev/null &
