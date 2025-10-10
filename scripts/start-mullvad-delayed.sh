#!/usr/bin/env bash
# Start Mullvad VPN with a delay to ensure systray is ready

# Wait for hyprpanel/systray to be fully initialized
sleep 3

# Start Mullvad VPN GUI
mullvad-vpn