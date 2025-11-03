# Scripts

## System Management

- **fleet.sh** - NixOS fleet deployment and management (see `./fleet.sh --help`)
  - For complete documentation, see [FLEET-MANAGEMENT.md](../FLEET-MANAGEMENT.md)

## Desktop Utilities

- **bluetooth-tui.sh** - Bluetooth device management
- **network-tui.sh** - Network connection management
- **rofi-audio.sh** - Audio device selector for Rofi
- **screenshot.sh** - Screenshot utility
- **volume-control.sh** - Volume control with notifications
- **waybar-audio.sh** - Waybar audio module

## Idle & Power Management

- **dpms-off-if-locked.sh** - Smart DPMS control that only turns off monitors when screen is locked
  - Called automatically by hypridle
  - Logs activity to systemd journal (viewable with `journalctl -t dpms-lock-aware`)
  - Prevents monitors from turning off during active use
  
- **check-idle-blockers.sh** - Diagnostic tool for troubleshooting idle/sleep issues
  - Shows systemd inhibitors, running processes, lock state, and hypridle status
  - Run before bed to verify everything is configured correctly
  - Color-coded output for easy scanning

## System Bars

- **start-hyprpanel.sh** - Launch HyprPanel
- **start-waybar.sh** - Launch Waybar

## Development

- **setup-dev-environment.sh** - Set up development environment
- **update_antidote_plugins.sh** - Update Zsh plugins

## Security

- **security-scan.sh** - Secret scanning with git-secrets and TruffleHog
  - Usage: `./security-scan.sh [quick|full|history]`
  - `quick` - Fast scan of current files (default)
  - `full` - Comprehensive scan including git history
  - `history` - Git history scan only
  - See [docs/SECURITY-SCANNING.md](../docs/SECURITY-SCANNING.md) for details

See individual scripts for usage or run with `--help` where available.
