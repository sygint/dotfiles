#!/usr/bin/env bash
# Monitor event handler — compositor-aware
# Handles monitor connect/disconnect events for both Hyprland and niri
# Usage: monitor-handler.sh [--fast|--no-delay] [--bar=waybar|hyprpanel]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
FAST_MODE=false
BAR_SYSTEM=""

for arg in "$@"; do
    case $arg in
        --fast|--no-delay)
            FAST_MODE=true
            ;;
        --bar=*)
            BAR_SYSTEM="${arg#*=}"
            ;;
    esac
done

# Detect running compositor
if [[ -n "${NIRI_SOCKET:-}" ]] || pgrep -x niri >/dev/null 2>&1; then
    COMPOSITOR="niri"
elif [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || pgrep -x Hyprland >/dev/null 2>&1; then
    COMPOSITOR="hyprland"
else
    echo "No supported compositor detected, exiting."
    exit 1
fi

echo "Monitor event detected at $(date)"
echo "Compositor: $COMPOSITOR"

# Wait for system to stabilize (skip in fast mode)
if [[ "$FAST_MODE" == "false" ]]; then
    echo "Waiting for system to stabilize..."
    sleep 2
else
    echo "Fast mode - skipping delays"
fi

# ── Compositor-specific monitor reconfiguration ──────────────────────────────

case "$COMPOSITOR" in
    "niri")
        # Niri handles monitor configuration natively via config.kdl.
        # On hotplug, niri automatically applies the output rules from its config.
        # No manual reconfiguration needed.
        echo "Niri handles monitor config natively — skipping reconfiguration."
        ;;
    "hyprland")
        # Hyprland needs monitors.sh to apply hyprctl keyword commands
        echo "Reconfiguring monitors via hyprctl..."
        if [[ "$FAST_MODE" == "true" ]]; then
            "$SCRIPT_DIR/monitors.sh" --fast --bar="$BAR_SYSTEM"
        else
            "$SCRIPT_DIR/monitors.sh" --bar="$BAR_SYSTEM"
        fi
        ;;
esac

# ── Bar system restart ───────────────────────────────────────────────────────

case "$COMPOSITOR" in
    "niri")
        # Noctalia-shell runs as a systemd user service — it handles
        # monitor changes automatically via Wayland protocol. No restart needed.
        echo "Noctalia-shell (systemd service) handles monitor changes automatically."
        ;;
    "hyprland")
        # Auto-detect bar system if not specified
        if [[ -z "$BAR_SYSTEM" ]]; then
            if pgrep -f "hyprpanel\|HyprPanel" >/dev/null 2>&1; then
                BAR_SYSTEM="hyprpanel"
            elif pgrep -x waybar >/dev/null 2>&1; then
                BAR_SYSTEM="waybar"
            else
                BAR_SYSTEM="hyprpanel"
            fi
        fi
        echo "Using bar system: $BAR_SYSTEM"

        case "$BAR_SYSTEM" in
            "hyprpanel")
                echo "Restarting hyprpanel..."
                pkill -9 -f "hyprpanel\|HyprPanel" 2>/dev/null || true
                if [[ "$FAST_MODE" == "false" ]]; then
                    sleep 1.5
                else
                    sleep 0.8
                fi
                "$SCRIPT_DIR/start-hyprpanel.sh"
                ;;
            "waybar")
                echo "Restarting waybar..."
                pkill -x waybar 2>/dev/null || true
                if [[ "$FAST_MODE" == "false" ]]; then
                    sleep 1
                else
                    sleep 0.2
                fi
                "$SCRIPT_DIR/start-waybar.sh"
                ;;
            *)
                echo "Unknown bar system: $BAR_SYSTEM (supported: waybar, hyprpanel)"
                ;;
        esac
        ;;
esac

# ── Restore wallpaper (both compositors use swww) ────────────────────────────

if command -v swww >/dev/null 2>&1; then
    echo "Restoring wallpaper..."
    swww restore 2>/dev/null || true
fi

echo "Monitor event handling complete"
