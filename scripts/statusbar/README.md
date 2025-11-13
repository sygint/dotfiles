# Status Bar Scripts

Scripts for launching and managing status bar systems.

## Scripts

### start-waybar.sh
Launches Waybar with proper configuration.

**Usage:**
```bash
./scripts/statusbar/start-waybar.sh
```

**Auto-start:** Configured in `modules/home/programs/hyprland.nix`

### start-hyprpanel.sh
Launches HyprPanel with proper configuration.

**Usage:**
```bash
./scripts/statusbar/start-hyprpanel.sh
```

**Auto-start:** Configured in `modules/home/programs/hyprland.nix`

## Configuration

The active status bar is controlled by the `bar` option in your system configuration:

```nix
# In your system's default.nix
bar = "waybar";  # or "hyprpanel"
```

The appropriate start script is automatically called on Hyprland startup.

## See Also
- `modules/home/programs/hyprland.nix` - Hyprland integration
- `dotfiles/.config/waybar/` - Waybar configuration
