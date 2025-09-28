#!/usr/bin/env bash

# Rofi Audio Device Switcher
# GNOME-like audio device selection with Catppuccin Mocha theme

set -euo pipefail

# Test mode
if [[ "${1:-}" == "--test" ]]; then
    echo "Audio Device Selector Test Mode"
    echo "Available output devices:"
    wpctl status | grep -A 20 "Sinks:" | grep -B 20 "Sources:" | grep -E "^\s*│.*[0-9]+\." | while read -r line; do
        # Extract device info
        DEVICE_ID=$(echo "$line" | grep -o "[0-9]\+\." | tr -d '.')
        DEVICE_NAME=$(echo "$line" | sed 's/^.*[0-9]\+\. //' | sed 's/\[.*\]$//' | sed 's/[[:space:]]*$//')
        CURRENT_MARKER=$(echo "$line" | grep -o "\*" || echo "")

        # Create friendly name
        case "$DEVICE_NAME" in
            *"TOZO"*) FRIENDLY_NAME="🎧 TOZO Earbuds" ;;
            *"SteelSeries"*) FRIENDLY_NAME="🎮 SteelSeries Headset" ;;
            *"Family 17h"*) FRIENDLY_NAME="🔊 Built-in Audio" ;;
            *"HDMI"*) FRIENDLY_NAME="📺 HDMI Audio" ;;
            *"PCM2912A"*) FRIENDLY_NAME="🎤 USB Audio" ;;
            *) FRIENDLY_NAME="🔊 $DEVICE_NAME" ;;
        esac

        if [[ -n "$CURRENT_MARKER" ]]; then
            echo "  ✅ [$DEVICE_ID] $FRIENDLY_NAME (active)"
        else
            echo "  ⚪ [$DEVICE_ID] $FRIENDLY_NAME"
        fi
    done
    exit 0
fi

# Catppuccin Mocha theme colors
MOCHA_BG="#1e1e2e"
MOCHA_FG="#cdd6f4"
MOCHA_HIGHLIGHT="#89b4fa"
MOCHA_ACCENT="#f38ba8"

# Function to get friendly device names
get_device_name() {
    local device_info="$1"
    local device_id
    local device_name
    device_id=$(echo "$device_info" | grep -o "^[0-9]*")
    device_name=$(echo "$device_info" | sed 's/^[[:space:]]*[*[:space:]]*[0-9]*\. //' | sed 's/ \[.*$//')

    case "$device_name" in
        *"TOZO Open EarRing"*) echo "$device_id|🎧 TOZO Earbuds" ;;
        *"SteelSeries Arctis"*) echo "$device_id|🎮 SteelSeries Headset" ;;
        *"HD Audio Controller Analog"*) echo "$device_id|🔊 Built-in Speakers" ;;
        *"HD Audio Controller Digital"*) echo "$device_id|📺 HDMI Audio" ;;
        *"PCM2912A Audio Codec"*) echo "$device_id|🎵 USB Audio Device" ;;
        *"Webcam"*) echo "$device_id|📹 Webcam Audio" ;;
        *) echo "$device_id|🔈 $(echo "$device_name" | cut -c1-30)" ;;
    esac
}

# Get current default sink
CURRENT_SINK=$(wpctl status | grep -A 20 "Sinks:" | grep -B 20 "Sources:" | grep "\*" | head -1 | grep -o "[0-9]\+" | head -1)

# Get all output devices
DEVICES=()
DEVICE_NAMES=()

while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        device_info=$(get_device_name "$line")
        device_id=$(echo "$device_info" | cut -d'|' -f1)
        device_name=$(echo "$device_info" | cut -d'|' -f2)

        if [[ "$device_id" == "$CURRENT_SINK" ]]; then
            device_name="✅ $device_name (current)"
        fi

        DEVICES+=("$device_id")
        DEVICE_NAMES+=("$device_name")
    fi
done < <(wpctl status | grep -A 20 "Sinks:" | grep -B 20 "Sources:" | grep -E "^\s*[│\s]*[0-9]+\." | grep -v "Sources:")

# Create rofi menu
if [[ ${#DEVICE_NAMES[@]} -eq 0 ]]; then
    notify-send -t 3000 -i dialog-error "Audio Error" "No audio devices found"
    exit 1
fi

# Show rofi menu with Catppuccin Mocha theme
SELECTED=$(printf '%s\n' "${DEVICE_NAMES[@]}" | rofi -dmenu -i \
    -p "🎵 Select Audio Device" \
    -theme-str "window { background-color: $MOCHA_BG; border-color: $MOCHA_ACCENT; }" \
    -theme-str "textbox { text-color: $MOCHA_FG; }" \
    -theme-str "listview { background-color: $MOCHA_BG; }" \
    -theme-str "element { text-color: $MOCHA_FG; }" \
    -theme-str "element selected { background-color: $MOCHA_HIGHLIGHT; text-color: $MOCHA_BG; }" \
    -theme-str "prompt { text-color: $MOCHA_ACCENT; }" \
    -theme-str "entry { text-color: $MOCHA_FG; }" \
    -lines 8 \
    -width 40)

# Exit if nothing selected
if [[ -z "$SELECTED" ]]; then
    exit 0
fi

# Find the corresponding device ID
for i in "${!DEVICE_NAMES[@]}"; do
    if [[ "${DEVICE_NAMES[$i]}" == "$SELECTED" ]]; then
        SELECTED_ID="${DEVICES[$i]}"
        break
    fi
done

# Switch to the selected device
if [[ -n "${SELECTED_ID:-}" ]]; then
    wpctl set-default "$SELECTED_ID"

    # Extract clean device name for notification
    CLEAN_NAME=$(echo "$SELECTED" | sed 's/✅ //' | sed 's/ (current)//')

    # Send success notification
    notify-send -t 2000 -i audio-card "Audio Device Changed" "Switched to: $CLEAN_NAME"

    # Update waybar if systemBar is waybar
    SYSTEM_BAR_FILE="$HOME/.config/nixos/systemBar"
    SYSTEM_BAR="waybar"
    if [[ -f "$SYSTEM_BAR_FILE" ]]; then
        SYSTEM_BAR="$(cat "$SYSTEM_BAR_FILE" | tr -d '\n')"
    fi
    if [[ "$SYSTEM_BAR" == "waybar" ]]; then
        pkill -RTMIN+8 waybar 2>/dev/null || true
    fi
else
    notify-send -t 2000 -i dialog-error "Audio Error" "Failed to switch audio device"
fi
