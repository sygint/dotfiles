#!/usr/bin/env bash

# Enhanced Volume Control Script
# Provides better volume control with notifications using a stack tag.

# Test mode check
if [[ "${1:-}" == "--test-mode" ]]; then
    echo "Volume control script test mode - all functions available"
    exit 0
fi

ACTION="$1"
STEP="${2:-5}"
# Use a unique tag for volume notifications to prevent stacking
MSG_TAG="volume-control"

# Check if hyprpanel is running - if so, skip all notifications (hyprpanel has its own OSD)
HYPRPANEL_RUNNING=false
if pgrep -f hyprpanel >/dev/null 2>&1; then
    HYPRPANEL_RUNNING=true
fi

# Get current default sink - prioritize actual audio devices over webcams
SINK_ID=$(wpctl status | grep -A 20 "Sinks:" | grep -B 20 "Sources:" | grep "\*" | grep -v -E "(Webcam|V4L2)" | head -1 | grep -o "[0-9]\+" | head -1)

# Fallback to any default sink if no non-webcam device found
if [[ -z "$SINK_ID" ]]; then
    SINK_ID=$(wpctl status | grep -A 20 "Sinks:" | grep -B 20 "Sources:" | grep "\*" | head -1 | grep -o "[0-9]\+" | head -1)
fi

if [[ -z "$SINK_ID" ]] && [[ "$HYPRPANEL_RUNNING" == "false" ]]; then
    notify-send -t 2000 -i dialog-error "Audio Error" "No audio device found"
    exit 1
fi

# Get device info for notification
SINK_INFO=$(wpctl status | grep -A 20 "Sinks:" | grep -B 20 "Sources:" | grep "\*" | grep "$SINK_ID" | head -1)
DEVICE_NAME=$(echo "$SINK_INFO" | sed 's/^[[:space:]]*\*[[:space:]]*[0-9]*\. //' | sed 's/ \[.*$//')

# Simplify device name
case "$DEVICE_NAME" in
    *"TOZO Open EarRing"*) DISPLAY_NAME="🎧 TOZO Earbuds" ;;
    *"SteelSeries Arctis"*) DISPLAY_NAME="🎮 SteelSeries Headset" ;;
    *"HD Audio Controller Analog"*) DISPLAY_NAME="🔊 Built-in Speakers" ;;
    *"HD Audio Controller Digital"*) DISPLAY_NAME="📺 HDMI Audio" ;;
    *"PCM2912A Audio Codec"*) DISPLAY_NAME="🎵 USB Audio" ;;
    *"Webcam"*) DISPLAY_NAME="📹 Webcam Audio" ;;
    *) DISPLAY_NAME="🔈 Audio Device" ;;
esac

# Perform action
case "$ACTION" in
    "up")
        # Get volume before change
        OLD_VOLUME=$(wpctl get-volume "$SINK_ID" | grep -o "[0-9.]*" | head -1)
        OLD_VOLUME_PERCENT=$(awk "BEGIN {printf \"%.0f\", $OLD_VOLUME * 100}")
        
        wpctl set-volume -l 1.0 "$SINK_ID" "${STEP}%+"
        
        # Get volume after change to detect if it actually changed
        NEW_VOLUME=$(wpctl get-volume "$SINK_ID" | grep -o "[0-9.]*" | head -1)
        NEW_VOLUME_PERCENT=$(awk "BEGIN {printf \"%.0f\", $NEW_VOLUME * 100}")
        
        # If volume didn't change (hit limit), show different message
        if [[ "$OLD_VOLUME_PERCENT" == "$NEW_VOLUME_PERCENT" ]] && [[ "$HYPRPANEL_RUNNING" == "false" ]]; then
            notify-send -t 1500 -i "audio-volume-high" -h "int:value:$NEW_VOLUME_PERCENT" -h "string:x-dunst-stack-tag:$MSG_TAG" -a "volume-control" "$DISPLAY_NAME" "Volume: ${NEW_VOLUME_PERCENT}% (Max)"
            # Update waybar if it's running
            pkill -RTMIN+8 waybar 2>/dev/null || true
            exit 0
        fi
        ;;
    "down")
        # Get volume before change
        OLD_VOLUME=$(wpctl get-volume "$SINK_ID" | grep -o "[0-9.]*" | head -1)
        OLD_VOLUME_PERCENT=$(awk "BEGIN {printf \"%.0f\", $OLD_VOLUME * 100}")
        
        wpctl set-volume "$SINK_ID" "${STEP}%-"
        
        # Get volume after change to detect if it actually changed
        NEW_VOLUME=$(wpctl get-volume "$SINK_ID" | grep -o "[0-9.]*" | head -1)
        NEW_VOLUME_PERCENT=$(awk "BEGIN {printf \"%.0f\", $NEW_VOLUME * 100}")
        
        # If volume didn't change (hit minimum), show different message
        if [[ "$OLD_VOLUME_PERCENT" == "$NEW_VOLUME_PERCENT" ]] && [[ "$HYPRPANEL_RUNNING" == "false" ]]; then
            notify-send -t 1500 -i "audio-volume-low" -h "int:value:$NEW_VOLUME_PERCENT" -h "string:x-dunst-stack-tag:$MSG_TAG" -a "volume-control" "$DISPLAY_NAME" "Volume: ${NEW_VOLUME_PERCENT}% (Min)"
            # Update waybar if it's running
            pkill -RTMIN+8 waybar 2>/dev/null || true
            exit 0
        fi
        ;;
    "mute")
        wpctl set-mute "$SINK_ID" toggle
        ;;
    "get")
        # Just get volume without notification
        VOLUME=$(wpctl get-volume "$SINK_ID" | grep -o "[0-9.]*" | head -1)
        VOLUME_PERCENT=$(awk "BEGIN {printf \"%.0f\", $VOLUME * 100}")
        echo "${VOLUME_PERCENT}%"
        exit 0
        ;;
    *)
        echo "Usage: $0 {up|down|mute|get} [step]"
        exit 1
        ;;
esac

# Get new volume and mute state
VOLUME=$(wpctl get-volume "$SINK_ID" | grep -o "[0-9.]*" | head -1)
VOLUME_PERCENT=$(awk "BEGIN {printf \"%.0f\", $VOLUME * 100}")
MUTED=$(wpctl get-volume "$SINK_ID" | grep -q "MUTED" && echo "true" || echo "false")

# Choose icon and message
if [[ "$MUTED" == "true" ]]; then
    ICON="audio-volume-muted"
    MESSAGE="Muted"
    PROGRESS=0
elif (( VOLUME_PERCENT > 70 )); then
    ICON="audio-volume-high"
    MESSAGE="Volume: ${VOLUME_PERCENT}%"
    PROGRESS=$VOLUME_PERCENT
elif (( VOLUME_PERCENT > 30 )); then
    ICON="audio-volume-medium"
    MESSAGE="Volume: ${VOLUME_PERCENT}%"
    PROGRESS=$VOLUME_PERCENT
else
    ICON="audio-volume-low"
    MESSAGE="Volume: ${VOLUME_PERCENT}%"
    PROGRESS=$VOLUME_PERCENT
fi

# Add a subtle indicator of the action taken to make notifications unique
case "$ACTION" in
    "up") MESSAGE="$MESSAGE ▲" ;;
    "down") MESSAGE="$MESSAGE ▼" ;;
    "mute") 
        if [[ "$MUTED" == "true" ]]; then
            MESSAGE="Muted 🔇"
        else
            MESSAGE="Unmuted 🔊"
        fi
        ;;
esac

# Send notification with progress bar - only if hyprpanel is not running
if [[ "$HYPRPANEL_RUNNING" == "false" ]]; then
    notify-send -t 1500 -i "$ICON" -h "int:value:$PROGRESS" -h "string:x-dunst-stack-tag:$MSG_TAG" -a "volume-control" "$DISPLAY_NAME" "$MESSAGE"
fi


# Update waybar if it's running, but only if systemBar is waybar
if [[ "$HYPRPANEL_RUNNING" == "false" ]]; then
    pkill -RTMIN+8 waybar 2>/dev/null || true
fi
