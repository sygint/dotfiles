# Desktop Utilities

Scripts for managing desktop environment features and peripherals.

## Scripts

### monitors.sh / monitor-handler.sh
Dynamic monitor configuration for Hyprland. Reads configurations from `monitors.json` and applies them.

**Usage:**
```bash
./scripts/desktop/monitors.sh [--fast|--no-delay] [--bar=waybar|hyprpanel]
./scripts/desktop/monitor-handler.sh [--fast|--no-delay] [--bar=waybar|hyprpanel]
```

**Examples:**
```bash
# Quick monitor setup
./scripts/desktop/monitors.sh --fast

# With specific bar system
./scripts/desktop/monitors.sh --bar=waybar
```

**Keybinding:** `SUPER + CTRL + SHIFT + M` in Hyprland

### bluetooth-tui.sh
Interactive Bluetooth device management TUI.

**Usage:**
```bash
./scripts/desktop/bluetooth-tui.sh [left|right|middle]
```

**Waybar Integration:** Click on Bluetooth module

### network-tui.sh
Interactive network connection management TUI.

**Usage:**
```bash
./scripts/desktop/network-tui.sh [right]
```

**Waybar Integration:** Right-click on network module

### screenshot.sh
Screenshot utility with region selection.

**Usage:**
```bash
./scripts/desktop/screenshot.sh
```

**Keybinding:** `SUPER + CTRL + SHIFT + S` or `SUPER + CTRL + SHIFT + 4` in Hyprland

### rofi-audio.sh
Audio device selector using Rofi.

**Usage:**
```bash
./scripts/desktop/rofi-audio.sh
```

### volume-control.sh
Volume control with notification support.

**Usage:**
```bash
./scripts/desktop/volume-control.sh <up|down|mute>
```

**Keybindings:**
- `XF86AudioRaiseVolume` - Volume up
- `XF86AudioLowerVolume` - Volume down
- `XF86AudioMute` - Toggle mute

### waybar-audio.sh
Waybar audio module integration.

**Usage:**
```bash
./scripts/desktop/waybar-audio.sh
```

**Waybar Config:** Automatically called by Waybar audio module
