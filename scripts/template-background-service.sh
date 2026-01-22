#!/usr/bin/env bash
# Template for reliable background service scripts
# Use this as a reference when creating scripts that run via nohup, systemd, or exec-once

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_NAME="my-service"
LOGFILE="$HOME/.cache/${SCRIPT_NAME}.log"

# Use absolute paths for all external commands (critical for nohup/systemd)
# These paths are standard on NixOS
SOCAT="/run/current-system/sw/bin/socat"
NC="/run/current-system/sw/bin/nc"
JQ="/run/current-system/sw/bin/jq"

# ============================================================================
# Logging
# ============================================================================

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

log_error() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOGFILE" >&2
}

# ============================================================================
# Process Management
# ============================================================================

# Kill existing instances forcefully
# Use specific process patterns that match the actual running processes
kill_existing() {
  local process_pattern="$1"
  
  # Force kill with SIGKILL (-9) to ensure termination
  pkill -9 -f "$process_pattern" 2>/dev/null || true
  
  # Wait for cleanup - use 2 seconds minimum for complex processes
  sleep 2
}

# Check if a process is running
is_running() {
  local process_pattern="$1"
  pgrep -f "$process_pattern" >/dev/null 2>&1
}

# ============================================================================
# Dependency Checking
# ============================================================================

# Check for required executables using absolute paths
check_dependencies() {
  local missing=0
  
  for cmd in "$@"; do
    if [ ! -x "$cmd" ]; then
      log_error "Required executable not found or not executable: $cmd"
      missing=1
    fi
  done
  
  if [ $missing -eq 1 ]; then
    log_error "Missing required dependencies. Exiting."
    exit 1
  fi
}

# ============================================================================
# Main Service Logic
# ============================================================================

start_service() {
  log "Starting ${SCRIPT_NAME}..."
  
  # Example: Start a process
  # /path/to/binary &
  
  log "${SCRIPT_NAME} started"
}

# Example event loop for monitoring
monitor_events() {
  log "Starting event monitor..."
  
  # Primary method: socat
  if [ -x "$SOCAT" ]; then
    "$SOCAT" -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
      handle_event "$line"
    done
  # Fallback: nc (netcat)
  elif [ -x "$NC" ]; then
    "$NC" -U "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
      handle_event "$line"
    done
  else
    log_error "Neither socat nor nc found at expected paths"
    exit 1
  fi
}

handle_event() {
  local event="$1"
  log "Event received: $event"
  
  # Add your event handling logic here
  # Example: Filter for specific events
  if echo "$event" | grep -qE "^monitor(added|removed)"; then
    log "Monitor change detected, taking action..."
    sleep 2  # Let system settle
    # perform_action
    sleep 3  # Prevent rapid-fire actions
  fi
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
  log "=== ${SCRIPT_NAME} starting ==="
  
  # Check dependencies before doing anything
  # check_dependencies "$SOCAT" "$NC"
  
  # Kill any existing instances
  # kill_existing "my-service-pattern"
  
  # Start the service
  # start_service
  
  # Or start monitoring (blocks)
  # monitor_events
  
  log "${SCRIPT_NAME} initialized successfully"
}

# Run main function
main "$@"
