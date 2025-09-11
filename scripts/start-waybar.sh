#!/usr/bin/env bash
# Ensure Bluetooth is unblocked and powered on
/home/syg/.config/nixos/scripts/bluetooth-startup.sh &

# Start blueman-applet for bluetooth support
blueman-applet 2>/dev/null &

# Start waybar with suppressed cursor warnings
waybar 2>/dev/null &
