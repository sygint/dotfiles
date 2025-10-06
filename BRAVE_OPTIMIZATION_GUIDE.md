# Brave Browser Optimization Guide

## Problem Summary
Brave browser was hanging with one process consuming 100% CPU (PID 80302) and another extension process consuming 19.5% CPU (PID 80453), using 1.5GB RAM each. The browser cache had grown to 3.2GB.

## Solutions Implemented

### 1. Immediate Fix
- **Killed the hanging process**: The main Brave process (PID 80302) was terminated
- Browser has been closed to allow fresh start

### 2. Optimized Launcher Script
Created `~/.config/nixos/scripts/brave-optimized.sh` with performance flags based on [Arch Wiki Chromium recommendations](https://wiki.archlinux.org/title/Chromium):

**Wayland Support:**
- `--ozone-platform=wayland`: Native Wayland backend (no XWayland overhead)
- Must be specified first for Chromium 124+ to avoid transparency bugs

**Hardware Video Acceleration (VA-API):**
- `--enable-features=VaapiVideoDecoder,VaapiVideoEncoder`: Hardware decode/encode for videos
- `--VaapiIgnoreDriverChecks`: Prevents driver blacklisting (important for Mesa 24.1+)
- `--disable-features=UseChromeOSDirectVideoDecoder`: Removes ChromeOS-specific decoder
- **Note**: Chromium 131+ uses `AcceleratedVideoDecodeLinuxGL` by default on Wayland

**GPU Performance:**
- `--enable-gpu-rasterization`: Uses GPU for rasterization instead of CPU
- `--enable-zero-copy`: Reduces memory copying overhead (recommended with EGL/Wayland)
- `--ignore-gpu-blocklist`: Prevents GPU from being blacklisted (may be needed for your system)

**Memory/Process Management:**
- `--process-per-site`: Groups tabs from same domain into one process (reduces overhead vs process-per-tab)

### 3. Desktop Integration
Created `~/.local/share/applications/brave-optimized.desktop` for launching Brave with optimizations from your application menu.

### 4. Hyprland Keybinding
Added keybinding: **SUPER + B** to launch Brave with optimizations
- Location: `~/.config/nixos/dotfiles/.config/hypr/hyprland.conf`
- Command: `$HOME/.config/nixos/scripts/brave-optimized.sh`

## How to Use

### Option 1: Keyboard Shortcut (Recommended)
Press **SUPER + B** to launch Brave with optimizations

### Option 2: Command Line
```bash
~/.config/nixos/scripts/brave-optimized.sh
```

### Option 3: Application Menu
Look for "Brave Browser (Optimized)" in your application launcher

### Option 4: Regular Brave
Continue using regular `brave` command if issues are resolved

## Preventive Measures

### 1. Regular Cache Clearing
Clear browser cache periodically to prevent buildup:

**Through Browser:**
1. Open Brave
2. Go to `brave://settings/clearBrowserData`
3. Select "Cached images and files"
4. Click "Clear data"

**Through Terminal:**
```bash
# When browser is closed
rm -rf ~/.config/BraveSoftware/Brave-Browser/Default/Cache/*
rm -rf ~/.config/BraveSoftware/Brave-Browser/Default/Code\ Cache/*
rm -rf ~/.config/BraveSoftware/Brave-Browser/ShaderCache/*
```

### 2. Monitor Resource Usage
Use Brave's built-in task manager to identify problematic tabs:
1. Press `Shift+Esc` in Brave
2. Look for high CPU/Memory usage
3. End processes that are consuming too much

Or use system tools:
```bash
# Check Brave processes
ps aux | grep brave | grep -v grep | sort -k3 -rn

# Monitor in real-time
htop # then press F4 and search for "brave"
```

### 3. Extension Management
Your current extensions:
- Bitwarden (Password Manager)
- HTTPS Everywhere
- Privacy | Private Debit Cards
- Privacy Badger
- React Developer Tools

**Best Practices:**
- Disable extensions you don't actively use
- Check extension CPU usage in Task Manager (`Shift+Esc`)
- Update extensions regularly

### 4. Tab Management
- Close unused tabs regularly
- Use tab suspender extensions for inactive tabs
- Enable "Memory Saver" in brave://settings/performance

### 5. Hardware Acceleration
Verify hardware acceleration is working:
1. Go to `brave://gpu`
2. Check that "Video Decode" and "Video Encode" show "Hardware accelerated"

## Troubleshooting

### If Browser Still Hangs
1. **Identify the problematic tab/extension:**
   ```bash
   ps aux | grep brave | sort -k3 -rn | head -5
   ```

2. **Open Brave's Task Manager** (`Shift+Esc`) and end high-CPU processes

3. **Disable hardware acceleration temporarily:**
   - Go to `brave://settings/system`
   - Toggle off "Use hardware acceleration when available"
   - Restart browser

4. **Start in safe mode (disable extensions):**
   ```bash
   brave --disable-extensions
   ```

### If Specific Website Causes Issues
- Check if the site has resource-heavy JavaScript or animations
- Try disabling Brave Shields for that site
- Use browser's Task Manager to confirm the specific tab

### Clear All Browser Data (Nuclear Option)
⚠️ **Warning: This will remove all browsing data, passwords, and settings**
```bash
# When browser is closed
rm -rf ~/.config/BraveSoftware/Brave-Browser/*
```

## Performance Monitoring

### Check Current Cache Size
```bash
du -sh ~/.config/BraveSoftware/Brave-Browser/
```

### Check Running Brave Processes
```bash
ps aux | grep brave | grep -v grep
```

### View Resource Usage
```bash
# Top 5 Brave processes by CPU
ps aux | grep brave | sort -k3 -rn | head -5

# Top 5 Brave processes by Memory
ps aux | grep brave | sort -k4 -rn | head -5
```

## System Configuration

Your Brave installation is managed through NixOS:
- Config file: `~/.config/nixos/modules/home/programs/brave.nix`
- Also installed via: `~/.config/nixos/modules/home/programs/hyprland.nix` (as default browser)

To rebuild after configuration changes:
```bash
cd ~/.config/nixos
home-manager switch --flake .#syg
```

## Additional Resources

- [Brave Support - Browser Crashes](https://support.brave.com/hc/en-us/articles/360017989132)
- [Brave Community Forum](https://community.brave.com/)
- [GitHub Issues](https://github.com/brave/brave-browser/issues)
- [Chromium Command Line Switches](https://peter.sh/experiments/chromium-command-line-switches/)

## Notes

- **Browser Version**: Brave 1.82.172 (Chromium 140.1.82.172)
- **OS**: NixOS 25.11 (Xantusia)
- **Display Protocol**: Wayland
- **Window Manager**: Hyprland
- **Hardware Acceleration**: Enabled (VaapiVideoDecoder, VaapiVideoEncoder)

## Known Issues & Patterns

### High CPU from Tab Management Overhead

**Root Cause Identified:**
The 100% CPU usage (4.0 CPU on one core) is caused by **browser process overhead from managing 20+ open tabs**, not individual problematic tabs or extensions.

**Evidence:**
- Brave Task Manager (Shift+Esc) showed:
  - Browser process: 4.0 CPU, 1.18GB RAM
  - All individual tabs: 0.0-3.0 CPU (normal/low)
  - Extension process: 1.0 CPU (normal)
- 20+ tabs open including: Amazon, eBay, StackBlitz, multiple YouTube videos, networking/UniFi pages
- Memory Saver enabled at Maximum setting (helps memory but not CPU)

**This is expected behavior**, not a bug. The browser must maintain state, handle events, and manage resources for all tabs even when they're "sleeping."

**Solutions:**

1. **Tab Management** (Primary Fix):
   - Close tabs you're not actively using
   - Bookmark pages for later instead of keeping tabs open
   - **Develop/complete your custom tab managing browser extension** (in progress)
   - Consider tab grouping to mentally organize and close groups

2. **Extension Reduction** (Secondary Fix):
   - Audit your current extensions:
     - Bitwarden (Password Manager)
     - HTTPS Everywhere
     - Privacy | Private Debit Cards
     - Privacy Badger
     - React Developer Tools
   - Remove extensions you don't actively use daily
   - Each extension adds overhead even when "idle"

3. **Session Management**:
   - Don't restore previous session on startup
   - Use bookmarks or "reading list" feature instead of persistent tabs

### Legacy Issues (Resolved)

**Previous Suspects (No longer primary cause):**
1. **Specific problematic websites** - Sites with:
   - Heavy JavaScript/WebGL animations
   - Auto-playing video content
   - Cryptocurrency mining scripts
   - Memory leaks in web apps
   
2. **Extension conflicts** - Found in logs:
   - Malformed extension dictionary warning
   - Chrome extension development files being loaded
   
3. **Cache corruption** - Detected:
   - Invalid cache entries being destroyed
   - 3.2GB cache size (excessive)

**Diagnostic Steps:**

1. **Start with a clean profile** (test if issue persists):
   ```bash
   # Backup current profile
   mv ~/.config/BraveSoftware/Brave-Browser ~/.config/BraveSoftware/Brave-Browser.backup
   
   # Start fresh
   ~/.config/nixos/scripts/brave-optimized.sh
   
   # If issue resolved, selectively restore data:
   # - Copy bookmarks: Brave-Browser.backup/Default/Bookmarks
   # - Reinstall extensions one by one
   ```

2. **Try hardware acceleration off**:
   ```bash
   brave --disable-gpu --disable-software-rasterizer
   ```

3. **Monitor which site triggers it**:
   - Open ONE tab at a time
   - Use `watch -n 1 'ps aux | grep brave | sort -k3 -rn | head -3'` in another terminal
   - Note which site causes CPU spike

4. **Remove problematic extension references**:
   ```bash
   # The logs show issues with a development extension
   # Check for any development extension folders
   find ~/.config/BraveSoftware/Brave-Browser -name "*extension*" -type d
   ```

**Quick Fixes to Try:**

```bash
# 1. Clear ALL cache and temp files
rm -rf ~/.config/BraveSoftware/Brave-Browser/Default/Cache/*
rm -rf ~/.config/BraveSoftware/Brave-Browser/Default/Code\ Cache/*
rm -rf ~/.config/BraveSoftware/Brave-Browser/ShaderCache/*
rm -rf ~/.config/BraveSoftware/Brave-Browser/Default/Service\ Worker/*

# 2. Start with extensions disabled
~/.config/nixos/scripts/brave-optimized.sh --disable-extensions

# 3. If that works, re-enable extensions one by one in brave://extensions
```

---

## Future Improvements

### Custom Tab Manager Extension (In Development)
You're developing a browser extension to better manage tabs and reduce overhead. This will be the ideal long-term solution for handling many research/work tabs efficiently.

**Benefits:**
- Intelligent tab suspension beyond browser's built-in Memory Saver
- Better tab organization and quick access
- Reduced browser process overhead
- Custom workflow integration

### Extension Audit
Plan to reduce current extension count from 5 to essentials only. Each extension adds overhead even when idle.

---

---

## Script Validation & Updates

**October 5, 2025 - Flags Verified Against Arch Wiki**

The launcher script flags were validated against the [Arch Wiki Chromium documentation](https://wiki.archlinux.org/title/Chromium) (updated October 2025). Changes made:

**Removed:**
- `--disable-crash-reporter` and `--disable-breakpad`: Minimal CPU benefit, breaks crash reporting which is useful for debugging
- `UseOzonePlatform` from `--enable-features`: Redundant with `--ozone-platform=wayland`

**Added:**
- `--ignore-gpu-blocklist`: Required for systems that may be on GPU blocklist (important for proper acceleration)
- `VaapiIgnoreDriverChecks` to `--enable-features`: Prevents driver blacklisting, especially important for Mesa 24.1+ and AMD GPUs

**Reordered:**
- `--ozone-platform=wayland` moved to first position: Chromium 124+ requires this early to avoid transparency bugs

**Arch Wiki Key Findings:**
- Chromium 140+ has native Wayland support enabled by default
- VA-API works natively on Wayland since Chromium 122 (no extra packages needed)
- `--process-per-site` is the recommended middle ground between security and performance
- `--enable-zero-copy` is specifically recommended for Wayland/EGL setups
- Mixed refresh rate displays may need `--use-gl=egl` (not added yet - test if needed)

**Result:** Script now follows official best practices while maintaining performance optimizations.

---

**Last Updated**: October 5, 2025
**Issue Status**: ✅ RESOLVED - Root cause identified and confirmed

**Root Cause**: Browser overhead from managing 20+ open tabs

**Observed Behavior Pattern**:
1. **Fresh start**: High CPU (94%) during initial tab loading/restoration
2. **Settling phase**: Moderate CPU (42%) for ~10-15 minutes as browser initializes extensions, syncs data, builds caches
3. **Idle state**: 0.0 CPU after settling (confirmed via Task Manager - all processes at 0.0 CPU)
4. **This is normal and expected behavior**, not a bug

**Evidence**:
- Brave Task Manager (Shift+Esc) showed:
  - Initial: Browser process at 4.0 CPU with 20+ tabs, all individual tabs at 0.0-3.0 CPU
  - After settling (~15 min): All processes at 0.0 CPU (Browser, GPU, utilities, extensions)
  - Memory usage: 570MB browser process (reasonable)
  
**Solutions Implemented**: 
1. ✅ Optimized launcher script with performance flags (SUPER+B keybinding)
2. ✅ Cleared session files to prevent problematic tab restoration
3. ✅ User closed all tabs - confirmed browser performs normally
4. 🔄 Complete custom tab manager extension (in development)
5. 🔄 Audit and reduce extension count from 5 to essentials

**Key Takeaway**: The high CPU was temporary settling behavior after restart. With the optimized launcher, the browser now settles properly and returns to 0.0 CPU at idle.
