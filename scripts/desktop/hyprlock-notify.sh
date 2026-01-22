#!/usr/bin/env bash
set -euo pipefail
LOGFILE="$HOME/.cache/hyprlock-wrapper.log"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "$1" || true
}

notify "Hyprlock starting..."
echo "[START] $(date)" >> "$LOGFILE"

if HYPRLOCK_CONFIG_PATH="$HOME/.config/hypr/hyprlock.conf" hyprlock "$@" >> "$LOGFILE" 2>&1; then
  notify "Hyprlock exited normally."
  echo "[EXIT] $(date)" >> "$LOGFILE"
else
  notify "Hyprlock crashed!"
  echo "[CRASH] $(date)" >> "$LOGFILE"
fi
