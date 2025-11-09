#!/usr/bin/env bash
# Fix WiFi after undocking by reloading the driver and restarting Hyprpanel
# This script is triggered when the WiFi interface disappears or dock is removed

set -euo pipefail

LOGFILE="$HOME/.cache/fix-wifi-undock.log"
WIFI_INTERFACE="wlp1s0"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

log "WiFi fix triggered - checking interface status..."

# Check if WiFi interface exists
if ! ip link show "$WIFI_INTERFACE" &>/dev/null; then
    log "ERROR: WiFi interface $WIFI_INTERFACE not found"
    exit 1
fi

# Check if WiFi is in DOWN or DORMANT state
WIFI_STATE=$(ip link show "$WIFI_INTERFACE" | grep -oP 'state \K\w+' || echo "UNKNOWN")
log "WiFi interface state: $WIFI_STATE"

# Check if we can see any networks
SSID_COUNT=$(nmcli device wifi list 2>/dev/null | wc -l)
log "SSIDs visible: $((SSID_COUNT - 1))"

# If no SSIDs or interface is DOWN/DORMANT, reload driver
if [ "$SSID_COUNT" -le 1 ] || [ "$WIFI_STATE" = "DOWN" ] || [ "$WIFI_STATE" = "DORMANT" ]; then
    log "No SSIDs detected or interface down - reloading mt7921e driver..."
    
    # Reload the WiFi driver
    if sudo modprobe -r mt7921e 2>&1 | tee -a "$LOGFILE"; then
        sleep 1
        if sudo modprobe mt7921e 2>&1 | tee -a "$LOGFILE"; then
            log "Driver reloaded successfully"
            sleep 2
        else
            log "ERROR: Failed to reload driver"
            exit 1
        fi
    else
        log "ERROR: Failed to unload driver"
        exit 1
    fi
    
    # Bring up the interface
    sudo ip link set "$WIFI_INTERFACE" up 2>&1 | tee -a "$LOGFILE" || log "Interface already up"
    
    # Enable WiFi radio
    nmcli radio wifi on 2>&1 | tee -a "$LOGFILE"
    
    # Rescan for networks
    sleep 1
    nmcli device wifi rescan 2>&1 | tee -a "$LOGFILE" || log "Rescan triggered"
    
    # Wait for scan to complete
    sleep 3
fi

log "WiFi fix complete"

