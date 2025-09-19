#!/usr/bin/env bash
# Dynamic monitor configuration for Hyprland
# Reads monitor configurations from monitors.json and applies them
# Usage: monitors.sh [--fast|--no-delay]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITORS_JSON="${SCRIPT_DIR}/../monitors.json"

# Check if fast mode is requested (skip delays)
FAST_MODE=false
if [[ "${1:-}" == "--fast" || "${1:-}" == "--no-delay" ]]; then
    FAST_MODE=true
fi

if [[ ! -f "$MONITORS_JSON" ]]; then
    echo "❌ monitors.json not found at $MONITORS_JSON"
    exit 1
fi

echo "🔍 Detecting monitors..."

# Wait for monitors to be ready (skip in fast mode)
if [[ "$FAST_MODE" == "false" ]]; then
    sleep 1
fi

# Store monitor configuration state
declare -A configured_monitors

# Parse monitors using a simpler approach that's more robust
while IFS= read -r line; do
    if [[ $line =~ ^Monitor\ ([^\ ]+)\ \(ID\ [0-9]+\):$ ]]; then
        current_monitor="${BASH_REMATCH[1]}"
        echo "📺 Found monitor: $current_monitor"
        configured_monitors["$current_monitor"]="pending"
    elif [[ $line =~ ^[[:space:]]+model:\ (.+)$ ]] && [[ -n "$current_monitor" ]] && [[ "${configured_monitors["$current_monitor"]:-}" == "pending" ]]; then
        model="${BASH_REMATCH[1]}"
        echo "   Model: $model"
        
        # Look up configuration in JSON (using jq)
        if command -v jq >/dev/null 2>&1; then
            config=$(jq -r --arg model "$model" '.[$model] // empty' "$MONITORS_JSON")
            
            if [[ -n "$config" && "$config" != "null" ]]; then
                echo "   Configuring: hyprctl keyword monitor $current_monitor, $config"
                if hyprctl keyword monitor "$current_monitor, $config" >/dev/null; then
                    configured_monitors["$current_monitor"]="configured"
                    echo "   ✅ Successfully configured $current_monitor"
                else
                    echo "   ❌ Failed to configure $current_monitor"
                    configured_monitors["$current_monitor"]="failed"
                fi
            else
                echo "   ⚠️  No configuration found for model: $model - using auto"
                # Apply fallback configuration for unknown monitors
                if hyprctl keyword monitor "$current_monitor, preferred, auto, 1" >/dev/null; then
                    configured_monitors["$current_monitor"]="auto"
                    echo "   ✅ Applied auto configuration to $current_monitor"
                else
                    echo "   ❌ Failed to apply auto configuration to $current_monitor"
                    configured_monitors["$current_monitor"]="failed"
                fi
            fi
        else
            echo "   ❌ jq not available - cannot parse monitors.json"
            exit 1
        fi
    fi
done < <(hyprctl monitors all)

# Force workspace refresh to prevent workspace loss issues
echo "🔄 Refreshing workspace assignments..."
if [[ "$FAST_MODE" == "false" ]]; then
    sleep 0.5
fi

# Move to workspace 1 and back to ensure proper workspace restoration
current_workspace=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id' || echo "1")
hyprctl dispatch workspace 1 >/dev/null 2>&1
if [[ "$FAST_MODE" == "false" ]]; then
    sleep 0.2
fi
if [[ "$current_workspace" != "1" ]]; then
    hyprctl dispatch workspace "$current_workspace" >/dev/null 2>&1
fi

echo "✅ Monitor configuration complete"
