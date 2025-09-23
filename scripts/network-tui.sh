#!/usr/bin/env bash
# TUI Network Manager for Waybar

case "${1:-left}" in
    "left")
        # Open nmtui - NetworkManager TUI
        kitty --title "Network Manager" --class floating-tui nmtui
        ;;
    "right")
        # Open nmtui - NetworkManager TUI (same as left click for now)
        kitty --title "Network Manager" --class floating-tui nmtui
        ;;
    "middle")
        # Toggle WiFi quickly
        if nmcli radio wifi | grep -q "enabled"; then
            nmcli radio wifi off
            notify-send "Network" "WiFi turned off" -i network-wireless-disabled
        else
            nmcli radio wifi on
            notify-send "Network" "WiFi turned on" -i network-wireless
        fi
        ;;
esac
