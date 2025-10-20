# Brave Browser Troubleshooting

Quick reference for Brave browser optimization and common issues on NixOS with Hyprland/Wayland.

## Optimized Launcher

An optimized launcher script is configured with Wayland and GPU acceleration flags.

**Launch with:** `SUPER + B` or `~/.config/nixos/scripts/brave-optimized.sh`

### Performance Flags

Based on [Arch Wiki Chromium recommendations](https://wiki.archlinux.org/title/Chromium):

- **Wayland**: Native backend (`--ozone-platform=wayland`)
- **Hardware Video**: VA-API acceleration for decode/encode
- **GPU**: Rasterization, zero-copy, ignore blocklist
- **Process Model**: Process-per-site (balanced overhead)

## Common Issues

### High CPU Usage

**Symptom**: One process consuming 100% CPU after restart

**Cause**: Browser overhead from managing many open tabs (20+)

**Solution**:
1. Close unused tabs (primary fix)
2. Don't restore previous session on startup
3. Use bookmarks instead of persistent tabs
4. Clear cache periodically: `brave://settings/clearBrowserData`

**Check what's using CPU:**
```bash
# Brave's built-in task manager
Press Shift+Esc in browser

# System monitoring
ps aux | grep brave | sort -k3 -rn | head -5
htop  # then F4 and search "brave"
```

### Cache Buildup

**Check cache size:**
```bash
du -sh ~/.config/BraveSoftware/Brave-Browser/
```

**Clear cache (browser closed):**
```bash
rm -rf ~/.config/BraveSoftware/Brave-Browser/Default/Cache/*
rm -rf ~/.config/BraveSoftware/Brave-Browser/Default/Code\ Cache/*
rm -rf ~/.config/BraveSoftware/Brave-Browser/ShaderCache/*
```

### Hardware Acceleration Issues

**Verify GPU acceleration:**
1. Go to `brave://gpu`
2. Check "Video Decode" and "Video Encode" show "Hardware accelerated"

**If disabled:**
- Go to `brave://settings/system`
- Toggle "Use hardware acceleration when available"
- Restart browser

### Extension Issues

**Current extensions** on your system:
- Bitwarden, HTTPS Everywhere, Privacy Cards, Privacy Badger, React DevTools

**Debug extensions:**
```bash
# Start without extensions
brave --disable-extensions

# If that fixes it, re-enable one by one at brave://extensions
```

## Quick Fixes

**Browser hanging:**
```bash
# Kill hung process
pkill -9 brave

# Start fresh with optimizations
~/.config/nixos/scripts/brave-optimized.sh
```

**Nuclear option (removes all data):**
```bash
# ⚠️ Warning: Removes passwords, history, settings
rm -rf ~/.config/BraveSoftware/Brave-Browser/*
```

## Configuration

Brave is managed through NixOS Home Manager:
- Module: `modules/home/programs/brave.nix`
- Also in: `modules/home/programs/hyprland.nix` (default browser)

**Rebuild after config changes:**
```bash
cd ~/.config/nixos
home-manager switch --flake .#syg
```

## Resources

- [Brave Support](https://support.brave.com)
- [Chromium Command Line Switches](https://peter.sh/experiments/chromium-command-line-switches/)
- [Arch Wiki - Chromium](https://wiki.archlinux.org/title/Chromium)

---

*For detailed history and legacy troubleshooting, see git history of this file.*
