# Start compositor automatically on TTY1 after login
# Only runs on login shells (not subshells)
# Compositor is set via variables.nix and processed by zsh.nix
if [[ -z "$DISPLAY" ]] && [[ -z "$WAYLAND_DISPLAY" ]] && [[ "$(tty)" == "/dev/tty1" ]]; then
  exec @compositor@
fi
