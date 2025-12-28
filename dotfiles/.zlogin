# Start Hyprland automatically on TTY1 after login
# Only runs on login shells (not subshells)
if [[ -z "$DISPLAY" ]] && [[ -z "$WAYLAND_DISPLAY" ]] && [[ "$(tty)" == "/dev/tty1" ]]; then
  exec Hyprland
fi
