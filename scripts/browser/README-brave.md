# Brave Browser Optimization Scripts

## brave-optimized.sh

Launches Brave browser with optimized performance flags to reduce CPU usage and improve stability on Wayland.

### Usage

#### Keybinding (Recommended)
Press **SUPER + B** in Hyprland

#### Command Line
```bash
~/.config/nixos/scripts/brave-optimized.sh
```

#### What it does
- Enables GPU rasterization for better graphics performance
- Enables zero-copy for reduced memory overhead
- Groups tabs by site to reduce process count
- Disables crash reporting overhead
- Optimizes for Wayland with hardware video acceleration

### Features Added
- `--enable-gpu-rasterization`: Better GPU utilization
- `--enable-zero-copy`: Reduced memory copying
- `--process-per-site`: Groups same-site tabs together
- `--disable-crash-reporter`: Removes crash reporting CPU overhead
- `--disable-breakpad`: Removes crash handler overhead
- `--enable-features=UseOzonePlatform,VaapiVideoDecoder,VaapiVideoEncoder`: Hardware video acceleration
- `--ozone-platform=wayland`: Native Wayland support
- `--disable-features=OutdatedBuildDetector,UseChromeOSDirectVideoDecoder`: Removes unnecessary features

### Keybinding Setup
The keybinding is configured in `dotfiles/.config/hypr/hyprland.conf`:
```
bind = $modMain, B, exec, $HOME/.config/nixos/scripts/brave-optimized.sh
```

### See Also
- `BRAVE_OPTIMIZATION_GUIDE.md` - Complete troubleshooting and optimization guide
- [Brave Browser](https://brave.com/)
- [Chromium Command Line Switches](https://peter.sh/experiments/chromium-command-line-switches/)
