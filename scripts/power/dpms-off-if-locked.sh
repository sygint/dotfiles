#!/usr/bin/env bash
# Script to turn off monitors only if the session is locked
# This prevents DPMS from triggering during active use while allowing
# monitors to turn off when you're away from the desk

set -euo pipefail

# Function to log to journal (viewable with journalctl)
log() {
    logger -t "dpms-lock-aware" "$1"
}

# Function to check if session is locked
is_session_locked() {
    pidof hyprlock > /dev/null 2>&1
}

# Main logic
if is_session_locked; then
    log "Session is locked, turning off monitors"
    hyprctl dispatch dpms off
    exit 0
else
    log "Session is unlocked, skipping monitor turn-off (user may be active)"
    exit 0
fi
