#!/usr/bin/env bash

# Kill any existing instances first
pkill -x waybar 2>/dev/null || true
pkill -x blueman-applet 2>/dev/null || true

# Wait for system to be ready
sleep 2

# Start blueman-applet for bluetooth support
blueman-applet 2>/dev/null &

# Start waybar with proper Wayland backend setting
sleep 1
env GDK_BACKEND=wayland waybar 2>/dev/null &
