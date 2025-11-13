# Network Scripts

Scripts for network configuration and troubleshooting.

## Scripts

### fix-wifi-after-undock.sh
Automatically fixes WiFi connectivity issues after laptop undocking.

**Usage:**
```bash
./scripts/network/fix-wifi-after-undock.sh
```

**What it does:**
- Detects when laptop is undocked from network-connected dock
- Restarts NetworkManager to restore WiFi
- Restarts status bar (HyprPanel/Waybar) to refresh network widget
- Logs activity to systemd journal

**Auto-trigger:**
This script can be configured to run automatically via:
- Hyprland keybinding for manual trigger
- Systemd service watching for dock events
- NetworkManager dispatcher script

**Manual trigger:**
If WiFi stops working after undocking, run:
```bash
./scripts/network/fix-wifi-after-undock.sh
```

**Logs:**
```bash
# View fix-wifi logs
journalctl -t fix-wifi-after-undock
```

## Common Network Issues

### WiFi Not Working After Undock
**Symptoms:**
- Laptop was docked with ethernet
- After undocking, WiFi icon shows but can't connect
- `nmcli` shows devices but no connection

**Solution:**
```bash
./scripts/network/fix-wifi-after-undock.sh
```

### Check Network Status
```bash
# List all network devices
nmcli device

# List all connections
nmcli connection show

# Check WiFi status
nmcli radio wifi
```

### Manual WiFi Restart
```bash
# Restart NetworkManager
sudo systemctl restart NetworkManager

# Or just restart WiFi
nmcli radio wifi off
nmcli radio wifi on
```

## See Also
- `modules/system/network.nix` - Network configuration
- [docs/troubleshooting/](../../docs/troubleshooting/) - Troubleshooting guides
