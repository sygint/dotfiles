#!/usr/bin/env bash
# Screenshot tool using grim, slurp, and swappy
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

# Watch for new files and notify on save (runs in background, dies with swappy)
inotifywait -m -e close_write "$SAVE_DIR" --format '%f' 2>/dev/null | while read -r filename; do
    notify-send "Screenshot saved" "$SAVE_DIR/$filename"
done &
WATCH_PID=$!

grim -g "$(slurp)" - | swappy -f -

kill $WATCH_PID 2>/dev/null
