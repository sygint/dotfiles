#!/usr/bin/env bash
# Enhanced Bluetooth TUI Manager for Waybar using bluetuith

case "${1:-left}" in
    "right")
        # Open bluetuith - modern TUI with mouse support, use same floating approach as nmtui
        kitty --title "Bluetooth Manager" --class floating-tui bluetuith
        ;;
    "middle")
        # Toggle Bluetooth power quickly
        if bluetoothctl show | grep -q "Powered: yes"; then
            bluetoothctl power off
            notify-send "Bluetooth" "Bluetooth turned off" -i bluetooth-disabled
        else
            bluetoothctl power on
            notify-send "Bluetooth" "Bluetooth turned on" -i bluetooth-active
        fi
        ;;
esac
