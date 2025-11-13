#!/usr/bin/env bash
# Start HyprPanel with logging and error handling

LOGFILE="$HOME/.cache/hyprpanel.log"
HYPRPANEL_BIN="$(command -v HyprPanel || command -v hyprpanel)"

if [ -z "$HYPRPANEL_BIN" ]; then
  echo "HyprPanel not found in PATH. Please install it." | tee -a "$LOGFILE"
  exit 1
fi

# Kill any existing instances
pkill -f "hyprpanel\|HyprPanel" 2>/dev/null || true
pkill mako 2>/dev/null || true  # Kill mako since hyprpanel has its own notifications

# Wait a moment for processes to clean up
sleep 1

# Set proper Wayland environment variables
export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"

# Ensure XDG_RUNTIME_DIR is set
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# Start HyprPanel in the background and log output
nohup "$HYPRPANEL_BIN" > "$LOGFILE" 2>&1 &
echo "HyprPanel started: $HYPRPANEL_BIN (logging to $LOGFILE)"
