# HTPC Kiosk Mode - Quick Reference

## 🚀 What Happens on Boot
1. System boots to login screen
2. Automatically logs in as `kiosk` user
3. Jellyfin Media Player launches in fullscreen TV mode
4. Ready for streaming from your Synology NAS

## 🎮 Using the Kiosk
- **Navigate**: Use TV remote (if CEC enabled) or keyboard/mouse
- **Exit fullscreen**: Press `Esc` key
- **Emergency terminal**: Press `Ctrl+Alt+T`
- **Switch to admin**: Press `Ctrl+Alt+F2`, login as `syg`

## 🔧 Admin Access Methods

### Method 1: TTY Switch (Recommended)
```bash
# From kiosk session
Ctrl+Alt+F2          # Switch to TTY2
# Login as: syg
# Password: [your password]
Ctrl+Alt+F1          # Return to kiosk
```

### Method 2: Emergency Terminal
```bash
# In kiosk session
Ctrl+Alt+T           # Open terminal
kiosk-admin          # Switch to admin user
```

### Method 3: SSH (if enabled)
```bash
# From another machine
ssh syg@htpc-ip
```

## 🛠️ Kiosk Management Commands

### Restart Jellyfin
```bash
systemctl --user restart jellyfin-kiosk
# or
kiosk-restart
```

### Check Jellyfin Status
```bash
systemctl --user status jellyfin-kiosk
```

### Switch Users
```bash
# From kiosk to admin
sudo -u syg -i

# From admin back to kiosk
sudo -u kiosk -i
```

## 🔒 Security Features

### What Kiosk User CAN Do:
- ✅ Run Jellyfin Media Player
- ✅ Access media files (read-only)
- ✅ Use basic shell commands
- ✅ Restart media applications

### What Kiosk User CANNOT Do:
- ❌ Install/remove software
- ❌ Modify system settings
- ❌ Access other users' files
- ❌ Use sudo commands
- ❌ Access network configuration

### Admin User Powers:
- 🔧 Full system administration
- 🔧 Install/update software
- 🔧 Modify configurations
- 🔧 Manage other users
- 🔧 Network settings

## 🎯 Jellyfin Setup Steps

1. **First Boot**: System launches Jellyfin automatically
2. **Server Setup**: Enter your Synology NAS IP (e.g., `http://192.168.1.X:8096`)
3. **Login**: Use your Jellyfin credentials
4. **Libraries**: Should auto-discover your media libraries
5. **Done**: Jellyfin will remember settings and auto-connect

## 🔄 Troubleshooting

### Jellyfin Won't Start
```bash
# Check service status
systemctl --user status jellyfin-kiosk

# View logs
journalctl --user -u jellyfin-kiosk -f

# Restart service
systemctl --user restart jellyfin-kiosk
```

### Can't Connect to Jellyfin Server
```bash
# Test network connectivity
ping 192.168.1.X  # Your NAS IP

# Check if Jellyfin port is accessible
curl http://192.168.1.X:8096
```

### Need to Reconfigure
```bash
# Switch to admin
Ctrl+Alt+F2
# Login as syg
sudo nixos-rebuild switch --flake .#htpc
```

### Emergency Recovery
```bash
# If kiosk mode is stuck, disable the service temporarily
sudo systemctl disable jellyfin-kiosk
sudo reboot

# Re-enable after fixing issues
sudo systemctl enable jellyfin-kiosk
```

## 📱 Remote Control Options

### CEC (TV Remote)
- Should work automatically with HDMI CEC-enabled TVs
- Use TV remote to navigate Jellyfin

### Smartphone Apps
- **Jellyfin Mobile**: Control playback remotely
- **KDE Connect**: Use phone as remote control
- **Unified Remote**: Universal remote app

### Physical Remotes
- Any USB/Bluetooth media remote
- Wireless keyboard with trackpad
- Gaming controller (Xbox/PlayStation)

## 🏠 Network Integration

### NAS Mount Points
```bash
# Media will be accessible at:
/mnt/nas/jellyfin  # Main Jellyfin library
/mnt/nas/movies    # Movie collection
/mnt/nas/tv        # TV shows
/mnt/nas/music     # Music library
```

### Jellyfin Server Connection
- **URL**: `http://synology-ip:8096`
- **Discovery**: Should auto-discover on same network
- **Ports**: 8096 (HTTP), 8920 (HTTPS), 1900 (DLNA)

This kiosk setup gives you a secure, appliance-like HTPC experience while maintaining full admin control when needed!