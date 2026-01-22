# HTPC Mini PC Setup Guide

## Overview
This configuration sets up a NixOS-based HTPC (Home Theater PC) optimized for streaming from your Synology NAS Jellyfin server.

## Features Included

### Media Applications
- **Jellyfin Media Player** - Primary client for your Synology Jellyfin server
- **Kodi** - Alternative full-featured media center
- **VLC & MPV** - Versatile media players for various formats
- **Firefox & Chromium** - For web-based streaming services

### HTPC Optimizations
- **Auto-login** - Boots directly to desktop
- **Quiet boot** - Minimal boot messages with Plymouth splash screen
- **Hardware acceleration** - Intel/AMD GPU acceleration for smooth playback
- **Audio optimization** - PipeWire configuration for high-quality audio
- **Power management** - Prevents sleep during media playback
- **CEC support** - TV remote control integration
- **Remote control** - LIRC support for IR remotes

### Network & Storage
- **NFS/SMB support** - For connecting to Synology NAS shares
- **Firewall configuration** - Jellyfin and DLNA ports opened
- **Network mounts** - Ready for NAS media library access

## Installation Steps

### 1. Prepare the Mini PC
1. Install NixOS on your mini PC using the standard installation media
2. Run `nixos-generate-config` to get hardware-specific configuration
3. Copy the generated `/etc/nixos/hardware-configuration.nix` content to replace the placeholder in `systems/htpc/hardware.nix`

### 2. Update Configuration
1. **Edit hardware.nix**: Update UUIDs and hardware-specific settings
2. **Update network settings**: Add your Synology NAS IP to `/etc/hosts` entries
3. **Configure variables.nix**: Update user email and other personal settings

### 3. Deploy the Configuration
```bash
# From your main NixOS machine (orion):
sudo nixos-rebuild switch --flake .#htpc --target-host root@<htpc-ip>

# Or using deploy-rs for fleet management:
nix run github:serokell/deploy-rs -- --targets .#htpc
```

### 4. Post-Installation Setup
Run the optimization script on the HTPC:
```bash
# Copy and run the setup script
scp scripts/htpc-setup.sh syg@<htpc-ip>:~/
ssh syg@<htpc-ip> "~/htpc-setup.sh"
```

## Network Configuration

### Synology NAS Integration
1. **Update IP addresses**: Edit the network configuration in `default.nix`
2. **NFS shares** (recommended): Uncomment and configure NFS mounts in `fileSystems`
3. **SMB/CIFS shares**: Alternative to NFS for Windows-style sharing

Example NFS configuration:
```nix
fileSystems."/mnt/nas/jellyfin" = {
  device = "192.168.1.X:/volume1/jellyfin";
  fsType = "nfs";
  options = [ "rw" "hard" "intr" "rsize=8192" "wsize=8192" "timeo=14" ];
};
```

### Jellyfin Setup
1. Configure Jellyfin server on Synology (port 8096)
2. On HTPC, launch Jellyfin Media Player
3. Connect to server: `http://<synology-ip>:8096`
4. Set up libraries pointing to NAS mount points

## Hardware Requirements

### Minimum Specifications
- **CPU**: Intel/AMD with hardware video decoding support
- **RAM**: 4GB (8GB recommended)
- **Storage**: 32GB SSD/eMMC
- **Network**: Gigabit Ethernet (for 4K streaming)
- **Graphics**: Integrated GPU with VAAPI/VDPAU support

### Recommended Mini PCs
- Intel NUC series
- ASUS PN series
- Beelink mini PCs
- Any x86_64 mini PC with Intel/AMD graphics

## Troubleshooting

### Video Acceleration Issues
```bash
# Test hardware acceleration
vainfo

# Check graphics drivers
lspci | grep VGA
dmesg | grep -i graphics
```

### Network Mount Issues
```bash
# Test NFS connectivity
showmount -e <synology-ip>
mount -t nfs <synology-ip>:/volume1/jellyfin /tmp/test

# Test SMB connectivity
smbclient -L //<synology-ip>
```

### Audio Issues
```bash
# Check audio devices
aplay -l
pactl list sinks

# Test audio playback
speaker-test -t wav -c 2
```

## Customization Options

### Desktop Environment
Currently configured with GNOME for simplicity. Can be changed to:
- KDE Plasma (better for power users)
- Custom Wayland compositor (minimal)
- Kodi as primary interface

### Additional Media Apps
Add to `environment.systemPackages`:
- `plex-media-player` - Alternative to Jellyfin
- `emby-theater` - Emby client
- `youtube-dl` / `yt-dlp` - Video downloading
- `handbrake` - Video transcoding

### Remote Control
- Configure LIRC for specific remote models
- Set up smartphone apps for remote control
- Use CEC for TV remote integration

## Fleet Management
Once deployed, the HTPC can be managed alongside other systems:
```bash
# Check status
./scripts/fleet.sh status

# Update all systems
./scripts/fleet.sh deploy

# Update just HTPC
nix run github:serokell/deploy-rs -- --targets .#htpc
```

## Security Considerations

### Kiosk Mode (Enabled)
The configuration uses **secure kiosk mode** by default:

✅ **What You Get:**
- Boots directly to Jellyfin Media Player fullscreen
- Dedicated `kiosk` user with minimal privileges
- Admin `syg` user for system management
- Automatic restart if Jellyfin crashes
- No desktop access from kiosk mode

🔐 **Security Features:**
- Kiosk user has no sudo privileges
- Kiosk user account is locked (no direct login)
- System directories are read-only for kiosk user
- Only essential media applications available

🛠️ **Admin Access:**
- Press `Ctrl+Alt+F2` to switch to TTY2
- Login as `syg` with your password
- Or use `kiosk-admin` command from kiosk session
- Switch back with `Ctrl+Alt+F1`

### Security Implementation
```nix
# Set password for login security
users.users.syg.hashedPassword = "$6$..."; # Generate with: mkpasswd -m sha-512

# Require sudo password
security.sudo.wheelNeedsPassword = true;

# Enable kiosk mode instead of auto-login
systemd.services.jellyfin-kiosk.enable = true;
```

### Additional Security
- HTPC has minimal attack surface (no SSH by default)
- Firewall configured for media streaming only
- Consider VPN for remote access if needed
- Physical security is critical for media room placement