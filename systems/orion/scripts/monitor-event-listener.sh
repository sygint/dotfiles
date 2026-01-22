#!/usr/bin/env bash
# Hyprland monitor event listener
# This script runs in the background and listens for monitor connect/disconnect events
# When a monitor event is detected, it triggers the monitor-handler script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HANDLER_SCRIPT="$SCRIPT_DIR/monitor-handler.sh"
LOG_FILE="/tmp/hyprland-monitor-events.log"

# Use absolute paths for external commands
NC="/run/current-system/sw/bin/nc"
SOCAT="/run/current-system/sw/bin/socat"

echo "[$(date)] 🎧 Monitor event listener started" | tee -a "$LOG_FILE"

# Function to handle monitor events
handle_monitor_event() {
    local event_type="$1"
    echo "[$(date)] 📺 Monitor event detected: $event_type" | tee -a "$LOG_FILE"
    
    # Small debounce delay to avoid triggering multiple times for the same event
    sleep 1
    
    # Run the monitor handler script
    echo "[$(date)] 🔧 Triggering monitor-handler..." | tee -a "$LOG_FILE"
    "$HANDLER_SCRIPT" --fast >> "$LOG_FILE" 2>&1
    
    echo "[$(date)] ✅ Monitor event handling complete" | tee -a "$LOG_FILE"
}

# Get the Hyprland socket path
HYPR_SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

if [[ ! -S "$HYPR_SOCKET" ]]; then
    echo "[$(date)] ❌ Hyprland socket not found at $HYPR_SOCKET" | tee -a "$LOG_FILE"
    exit 1
fi

echo "[$(date)] 📡 Listening on $HYPR_SOCKET" | tee -a "$LOG_FILE"

# Listen to Hyprland socket for monitor events
# Prefer socat if available, fallback to nc
if [ -x "$SOCAT" ]; then
    echo "[$(date)] Using socat for event monitoring" | tee -a "$LOG_FILE"
    "$SOCAT" -U - UNIX-CONNECT:"$HYPR_SOCKET" | while read -r line; do
        # Monitor events: monitoradded and monitorremoved
        if [[ "$line" == "monitoradded"* ]] || [[ "$line" == "monitorremoved"* ]]; then
            # Extract event type
            event_type="${line%%>>*}"
            
            # Run handler in background to not block the listener
            handle_monitor_event "$event_type" &
        fi
    done
elif [ -x "$NC" ]; then
    echo "[$(date)] Using nc for event monitoring" | tee -a "$LOG_FILE"
    "$NC" -U "$HYPR_SOCKET" | while read -r line; do
        # Monitor events: monitoradded and monitorremoved
        if [[ "$line" == "monitoradded"* ]] || [[ "$line" == "monitorremoved"* ]]; then
            # Extract event type
            event_type="${line%%>>*}"
            
            # Run handler in background to not block the listener
            handle_monitor_event "$event_type" &
        fi
    done
else
    echo "[$(date)] ❌ Neither socat nor nc found at expected paths" | tee -a "$LOG_FILE"
    exit 1
fi

