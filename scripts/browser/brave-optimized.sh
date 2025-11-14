#!/usr/bin/env bash
# Optimized Brave Browser Launcher
# Performance and Wayland optimization flags based on Arch Wiki Chromium recommendations
# Reference: https://wiki.archlinux.org/title/Chromium

# Disable sponsored content before launching Brave
BRAVE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/BraveSoftware/Brave-Browser"
PREFS_FILE="$BRAVE_CONFIG_DIR/Default/Preferences"

# Create config directory if it doesn't exist
mkdir -p "$BRAVE_CONFIG_DIR/Default"

# Disable sponsored content if jq is available and Preferences file exists
if command -v jq &> /dev/null && [ -f "$PREFS_FILE" ]; then
  jq '.brave.new_tab_page.show_sponsored_images_background_image = false |
      .brave.new_tab_page.shows_options = false |
      .brave.rewards.show_brave_rewards_button_in_location_bar = false |
      .brave.rewards.inline_tip_buttons_enabled = false |
      .brave.rewards.enabled = false' \
    "$PREFS_FILE" > "$PREFS_FILE.tmp" && mv "$PREFS_FILE.tmp" "$PREFS_FILE"
fi

exec brave \
  --ozone-platform=wayland \
  --enable-features=VaapiVideoDecoder,VaapiVideoEncoder,VaapiIgnoreDriverChecks \
  --disable-features=UseChromeOSDirectVideoDecoder,BraveRewards \
  --enable-gpu-rasterization \
  --enable-zero-copy \
  --ignore-gpu-blocklist \
  --process-per-site \
  --disable-brave-rewards \
  --disable-brave-rewards-extension \
  --disable-brave-update \
  "$@"
