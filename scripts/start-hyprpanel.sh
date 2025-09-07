#!/usr/bin/env bash
# Start HyprPanel with logging and error handling

LOGFILE="$HOME/.cache/hyprpanel.log"
HYPRPANEL_BIN="$(command -v HyprPanel || command -v hyprpanel)"

if [ -z "$HYPRPANEL_BIN" ]; then
  echo "HyprPanel not found in PATH. Please install it." | tee -a "$LOGFILE"
  exit 1
fi

# Optionally, set environment variables here if needed
# export HYPRPANEL_CONFIG="$HOME/.config/hyprpanel/config.json"

# Start HyprPanel in the background and log output
nohup "$HYPRPANEL_BIN" > "$LOGFILE" 2>&1 &
echo "HyprPanel started: $HYPRPANEL_BIN (logging to $LOGFILE)"
