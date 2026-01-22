#!/usr/bin/env bash
# hyprpanel-auto-restart.sh: Restart Hyprpanel on Hyprland monitor events

HYPRPANEL_START_SCRIPT="$HOME/.config/nixos/systems/orion/scripts/start-hyprpanel.sh"
LOGFILE="$HOME/.cache/hyprpanel-auto-restart.log"

# Function to restart Hyprpanel
restart_hyprpanel() {
  echo "[$(date)] Restarting Hyprpanel due to monitor event..." | tee -a "$LOGFILE"
  "$HYPRPANEL_START_SCRIPT" >> "$LOGFILE" 2>&1
}

# Listen for Hyprland events and restart Hyprpanel on monitor add/remove events
echo "[$(date)] Starting Hyprpanel auto-restart monitor..." >> "$LOGFILE"

# Use socat (preferred) or fallback to nc - use absolute paths for nohup compatibility
SOCAT="/run/current-system/sw/bin/socat"
NC="/run/current-system/sw/bin/nc"

if [ -x "$SOCAT" ]; then
  "$SOCAT" -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    # Only restart on monitoradded or monitorremoved events
    if echo "$line" | grep -qE "^monitor(added|removed)"; then
      echo "[$(date)] Monitor event detected: $line" >> "$LOGFILE"
      # Small delay to let monitor config settle
      sleep 2
      restart_hyprpanel
      # Prevent multiple restarts in quick succession
      sleep 3
    fi
  done
elif [ -x "$NC" ]; then
  "$NC" -U "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    # Only restart on monitoradded or monitorremoved events
    if echo "$line" | grep -qE "^monitor(added|removed)"; then
      echo "[$(date)] Monitor event detected: $line" >> "$LOGFILE"
      # Small delay to let monitor config settle
      sleep 2
      restart_hyprpanel
      # Prevent multiple restarts in quick succession
      sleep 3
    fi
  done
else
  echo "[$(date)] Error: Neither socat nor nc found at expected paths" >> "$LOGFILE"
  exit 1
fi
