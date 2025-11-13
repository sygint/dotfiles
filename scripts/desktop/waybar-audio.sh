#!/usr/bin/env bash

# Waybar Audio Info Script
# Provides enhanced audio information for waybar

set -euo pipefail

# Get current default sink
SINK_ID=$(wpctl status | grep -A 20 "Sinks:" | grep -B 20 "Sources:" | grep "\*" | head -1 | grep -o "[0-9]\+" | head -1)

if [[ -z "$SINK_ID" ]]; then
    echo '{"text": "󰝟 No Audio", "class": "disconnected", "tooltip": "No audio device found"}'
    exit 0
fi

# Get volume and mute state
VOLUME_INFO=$(wpctl get-volume "$SINK_ID")
VOLUME=$(echo "$VOLUME_INFO" | grep -o "[0-9.]*" | head -1)
VOLUME_PERCENT=$(awk "BEGIN {printf \"%.0f\", $VOLUME * 100}")
MUTED=$(echo "$VOLUME_INFO" | grep -q "MUTED" && echo "true" || echo "false")

# Get device info
SINK_INFO=$(wpctl status | grep -A 20 "Sinks:" | grep -B 20 "Sources:" | grep "\*" | head -1)
DEVICE_NAME=$(echo "$SINK_INFO" | sed 's/^.*[0-9]\+\. //' | sed 's/ \[.*$//')

# Create friendly device name and icon
case "$DEVICE_NAME" in
    *"TOZO Open EarRing"*)
        DISPLAY_NAME="🎧 TOZO Earbuds"
        ICON="🎧"
        ;;
    *"SteelSeries Arctis"*)
        DISPLAY_NAME="🎮 SteelSeries Headset"
        ICON="🎮"
        ;;
    *"HD Audio Controller Analog"*)
        DISPLAY_NAME="🔊 Built-in Speakers"
        ICON="🔊"
        ;;
    *"HD Audio Controller Digital"*)
        DISPLAY_NAME="📺 HDMI Audio"
        ICON="📺"
        ;;
    *"PCM2912A Audio Codec"*)
        DISPLAY_NAME="🎵 USB Audio"
        ICON="🎵"
        ;;
    *"Webcam"*)
        DISPLAY_NAME="📹 Webcam Audio"
        ICON="📹"
        ;;
    *) 
        DISPLAY_NAME="🔈 Audio Device"
        ICON="🔈"
        ;;
esac

# Choose volume icon and class
if [[ "$MUTED" == "true" ]]; then
    VOLUME_ICON="󰝟"
    CLASS="muted"
    TEXT="$VOLUME_ICON Muted"
elif (( VOLUME_PERCENT >= 70 )); then
    VOLUME_ICON="󰕾"
    CLASS="high"
    TEXT="$VOLUME_ICON ${VOLUME_PERCENT}%"
elif (( VOLUME_PERCENT >= 30 )); then
    VOLUME_ICON="󰖀"
    CLASS="medium"
    TEXT="$VOLUME_ICON ${VOLUME_PERCENT}%"
else
    VOLUME_ICON="󰕿"
    CLASS="low"
    TEXT="$VOLUME_ICON ${VOLUME_PERCENT}%"
fi

# Create tooltip
TOOLTIP="$DISPLAY_NAME\nVolume: ${VOLUME_PERCENT}%"
if [[ "$MUTED" == "true" ]]; then
    TOOLTIP="$DISPLAY_NAME\nMuted"
fi

# Output text for waybar
echo "$TEXT"
