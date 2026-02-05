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

# Check if a shell with its own OSD is running - skip notifications if so
SKIP_NOTIFICATIONS=false
if pgrep -f hyprpanel >/dev/null 2>&1; then
    SKIP_NOTIFICATIONS=true
elif pgrep -f "quickshell.*noctalia" >/dev/null 2>&1; then
    # noctalia-shell has its own volume/notification OSD
    SKIP_NOTIFICATIONS=true
fi

# Use the proper WirePlumber default sink reference
SINK="@DEFAULT_AUDIO_SINK@"

# Check if default sink exists
if ! wpctl get-volume "$SINK" >/dev/null 2>&1; then
    if [[ "$SKIP_NOTIFICATIONS" == "false" ]]; then
        notify-send -t 2000 -i dialog-error "Audio Error" "No audio device found"
    fi
    exit 1
fi

# Get device name for notification
DEVICE_NAME=$(wpctl inspect "$SINK" 2>/dev/null | grep "node.description" | sed 's/.*= "\(.*\)"/\1/' | head -1)
if [[ -z "$DEVICE_NAME" ]]; then
    DEVICE_NAME=$(wpctl inspect "$SINK" 2>/dev/null | grep "node.nick" | sed 's/.*= "\(.*\)"/\1/' | head -1)
fi

# Simplify device name
case "$DEVICE_NAME" in
    *"TOZO"*) DISPLAY_NAME="🎧 TOZO Earbuds" ;;
    *"SteelSeries"*|*"Arctis"*) DISPLAY_NAME="🎮 SteelSeries Headset" ;;
    *"Analog Stereo"*) DISPLAY_NAME="🔊 Built-in Speakers" ;;
    *"HDMI"*|*"Digital Stereo"*) DISPLAY_NAME="📺 HDMI Audio" ;;
    *"PCM2912A"*|*"USB Audio"*) DISPLAY_NAME="🎵 USB Audio" ;;
    *"Webcam"*) DISPLAY_NAME="📹 Webcam Audio" ;;
    *) DISPLAY_NAME="🔈 ${DEVICE_NAME:-Audio Device}" ;;
esac

# Perform action
case "$ACTION" in
    "up")
        # Get volume before change
        OLD_VOLUME=$(wpctl get-volume "$SINK" | grep -o "[0-9.]*" | head -1)
        OLD_VOLUME_PERCENT=$(awk "BEGIN {printf \"%.0f\", $OLD_VOLUME * 100}")
        
        wpctl set-volume -l 1.0 "$SINK" "${STEP}%+"
        
        # Get volume after change to detect if it actually changed
        NEW_VOLUME=$(wpctl get-volume "$SINK" | grep -o "[0-9.]*" | head -1)
        NEW_VOLUME_PERCENT=$(awk "BEGIN {printf \"%.0f\", $NEW_VOLUME * 100}")
        
        # If volume didn't change (hit limit), show different message
        if [[ "$OLD_VOLUME_PERCENT" == "$NEW_VOLUME_PERCENT" ]] && [[ "$SKIP_NOTIFICATIONS" == "false" ]]; then
            notify-send -t 1500 -i "audio-volume-high" -h "int:value:$NEW_VOLUME_PERCENT" -h "string:x-dunst-stack-tag:$MSG_TAG" -a "volume-control" "$DISPLAY_NAME" "Volume: ${NEW_VOLUME_PERCENT}% (Max)"
            # Update waybar if it's running
            pkill -RTMIN+8 waybar 2>/dev/null || true
            exit 0
        fi
        ;;
    "down")
        # Get volume before change
        OLD_VOLUME=$(wpctl get-volume "$SINK" | grep -o "[0-9.]*" | head -1)
        OLD_VOLUME_PERCENT=$(awk "BEGIN {printf \"%.0f\", $OLD_VOLUME * 100}")
        
        wpctl set-volume "$SINK" "${STEP}%-"
        
        # Get volume after change to detect if it actually changed
        NEW_VOLUME=$(wpctl get-volume "$SINK" | grep -o "[0-9.]*" | head -1)
        NEW_VOLUME_PERCENT=$(awk "BEGIN {printf \"%.0f\", $NEW_VOLUME * 100}")
        
        # If volume didn't change (hit minimum), show different message
        if [[ "$OLD_VOLUME_PERCENT" == "$NEW_VOLUME_PERCENT" ]] && [[ "$SKIP_NOTIFICATIONS" == "false" ]]; then
            notify-send -t 1500 -i "audio-volume-low" -h "int:value:$NEW_VOLUME_PERCENT" -h "string:x-dunst-stack-tag:$MSG_TAG" -a "volume-control" "$DISPLAY_NAME" "Volume: ${NEW_VOLUME_PERCENT}% (Min)"
            # Update waybar if it's running
            pkill -RTMIN+8 waybar 2>/dev/null || true
            exit 0
        fi
        ;;
    "mute")
        wpctl set-mute "$SINK" toggle
        ;;
    "get")
        # Just get volume without notification
        VOLUME=$(wpctl get-volume "$SINK" | grep -o "[0-9.]*" | head -1)
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
VOLUME=$(wpctl get-volume "$SINK" | grep -o "[0-9.]*" | head -1)
VOLUME_PERCENT=$(awk "BEGIN {printf \"%.0f\", $VOLUME * 100}")
MUTED=$(wpctl get-volume "$SINK" | grep -q "MUTED" && echo "true" || echo "false")

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
if [[ "$SKIP_NOTIFICATIONS" == "false" ]]; then
    notify-send -t 1500 -i "$ICON" -h "int:value:$PROGRESS" -h "string:x-dunst-stack-tag:$MSG_TAG" -a "volume-control" "$DISPLAY_NAME" "$MESSAGE"
fi


# Update waybar if it's running, but only if systemBar is waybar
if [[ "$SKIP_NOTIFICATIONS" == "false" ]]; then
    pkill -RTMIN+8 waybar 2>/dev/null || true
fi
