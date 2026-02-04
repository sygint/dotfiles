#!/usr/bin/env bash
# Apply monitor configuration from hyprland.conf
# This re-reads and applies the monitor= lines from the config
#
# Usage: apply-monitors.sh

set -euo pipefail

CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ hyprland.conf not found at $CONFIG_FILE"
    exit 1
fi

echo "🔧 Applying monitor configuration..."

# Extract and apply monitor lines from config
while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue

    # Extract the monitor config (everything after "monitor = ")
    if [[ "$line" =~ ^[[:space:]]*monitor[[:space:]]*=[[:space:]]*(.+)$ ]]; then
        monitor_config="${BASH_REMATCH[1]}"
        echo "  📺 Applying: $monitor_config"
        hyprctl keyword monitor "$monitor_config" 2>/dev/null || true
    fi
done < "$CONFIG_FILE"

echo "✅ Monitor configuration applied"

# Optional: restore wallpaper
if command -v swww >/dev/null 2>&1; then
    echo "🖼️ Restoring wallpaper..."
    swww restore 2>/dev/null || true
fi
