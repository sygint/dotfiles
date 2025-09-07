#!/usr/bin/env bash
# Dynamic monitor configuration for Hyprland
# Reads monitor configurations from monitors.json and applies them

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITORS_JSON="${SCRIPT_DIR}/../monitors.json"

if [[ ! -f "$MONITORS_JSON" ]]; then
    echo "❌ monitors.json not found at $MONITORS_JSON"
    exit 1
fi

echo "🔍 Detecting monitors..."

# Wait a moment for monitors to be ready
sleep 0.5

# Parse monitors using a simpler approach
current_monitor=""

hyprctl monitors all | while IFS= read -r line; do
    if [[ $line =~ ^Monitor\ ([^\ ]+)\ \(ID\ [0-9]+\):$ ]]; then
        current_monitor="${BASH_REMATCH[1]}"
        echo "📺 Found monitor: $current_monitor"
    elif [[ $line =~ ^[[:space:]]+model:\ (.+)$ ]] && [[ -n "$current_monitor" ]]; then
        model="${BASH_REMATCH[1]}"
        echo "  Model: $model"
        
        # Look up configuration in JSON (using jq)
        if command -v jq >/dev/null 2>&1; then
            config=$(jq -r --arg model "$model" '.[$model] // empty' "$MONITORS_JSON")
            
            if [[ -n "$config" && "$config" != "null" ]]; then
                echo "  ✅ Configuring: hyprctl keyword monitor $current_monitor, $config"
                hyprctl keyword monitor "$current_monitor, $config" || echo "  ❌ Failed to configure $current_monitor"
            else
                echo "  ⚠️  No configuration found for model: $model"
            fi
        else
            echo "  ❌ jq not available - cannot parse monitors.json"
            exit 1
        fi
    fi
done
