# Usage Guide

## 🚀 Quick Start

### Rebuild System (NixOS)
```bash
# Using nh (recommended)
nh os switch

# Or using the standard command (requires sudo)
sudo nixos-rebuild switch --flake .
```

### Rebuild Home Manager

#### As NixOS Module (Default)
This is handled automatically when you rebuild the system with `nh os switch` or `nixos-rebuild switch`.

#### As Standalone Home Manager
```bash
# Using nh (recommended)
nh home switch

# Or using the standard command (no sudo required)
home-manager switch --flake .#syg

# First time setup on a new machine (if home-manager is not yet installed)
nix run home-manager -- switch --flake .#syg
```

## 🔄 Dual-Mode Configuration

This configuration supports two modes of operation:

### 1. NixOS Module Mode (Default)
- Home Manager runs as a NixOS module
- Configuration: `home/syg.nix`
- Requires `sudo` for rebuilds
- System and home configuration rebuilt together

### 2. Standalone Home Manager Mode
- Home Manager runs independently 
- Configuration: `home-standalone.nix`
- No `sudo` required for home rebuilds
- Faster iteration for home-only changes
- Works on non-NixOS systems

### When to Use Each Mode

**Use NixOS Module Mode when:**
- Making system-wide changes
- You want everything rebuilt together
- First-time setup

**Use Standalone Mode when:**
- Testing home configuration changes
- You don't have sudo access
- Working on a non-NixOS system
- Faster development iteration

## Configuration Locations

### Hyprland
- Configuration: `dotfiles/.config/hypr/`
- Wallpapers: `wallpapers/`
- Scripts: `scripts/`

### Development
- VS Code settings: `dotfiles/.config/Code/User/settings.json`
- Git configuration: `dotfiles/.config/git/`

## Notes

- Dotfiles are managed using Home Manager with live-updating symlinks
- Monitor configuration is stored in `monitors.json`
- Additional notes in `notes.txt`
