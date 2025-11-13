# Browser Optimization Scripts

Scripts for launching and monitoring Brave browser with performance optimizations.

## Scripts

### brave-optimized.sh
Launches Brave browser with optimized performance flags to reduce CPU usage and improve stability on Wayland.

**Usage:**

#### Keybinding (Recommended)
Press **SUPER + B** in Hyprland

#### Command Line
```bash
./scripts/browser/brave-optimized.sh
```

#### What it does
- Enables GPU rasterization for better graphics performance
- Enables zero-copy for reduced memory overhead
- Groups tabs by site to reduce process count
- Disables crash reporting overhead
- Optimizes for Wayland with hardware video acceleration

#### Features Added
- `--enable-gpu-rasterization`: Better GPU utilization
- `--enable-zero-copy`: Reduced memory copying
- `--process-per-site`: Groups same-site tabs together
- `--disable-crash-reporter`: Removes crash reporting CPU overhead
- `--disable-breakpad`: Removes crash handler overhead
- `--enable-features=UseOzonePlatform,VaapiVideoDecoder,VaapiVideoEncoder`: Hardware video acceleration
- `--ozone-platform=wayland`: Native Wayland support
- `--disable-features=OutdatedBuildDetector,UseChromeOSDirectVideoDecoder`: Removes unnecessary features

### brave-cpu-monitor.sh
Monitors Brave browser CPU usage and provides statistics.

**Usage:**
```bash
./scripts/browser/brave-cpu-monitor.sh
```

**What it monitors:**
- Total CPU usage across all Brave processes
- Per-process breakdown
- Memory usage
- Tab count

## Keybinding Setup

The Brave optimized keybinding is configured in `dotfiles/.config/hypr/hyprland.conf`:
```
bind = $modMain, B, exec, $HOME/.config/nixos/scripts/browser/brave-optimized.sh
```

## Troubleshooting

See [docs/troubleshooting/brave.md](../../docs/troubleshooting/brave.md) for:
- Performance optimization tips
- Common issues and solutions
- Flag explanations
- Debugging steps

## See Also
- [Brave Browser](https://brave.com/)
- [Chromium Command Line Switches](https://peter.sh/experiments/chromium-command-line-switches/)
