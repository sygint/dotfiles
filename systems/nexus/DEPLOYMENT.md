# Nexus Deployment Guide - HP EliteDesk G4 800

## Recommended: Automated Deployment with nixos-anywhere

**Easiest method - fully automated!**

1. **Boot any Linux USB** on HP EliteDesk (Ubuntu live USB works great)
2. **Enable SSH:**
   ```bash
   # On HP EliteDesk
   sudo passwd ubuntu  # Set password
   sudo systemctl start ssh
   ip addr show  # Note the IP
   ```
3. **Deploy from Orion:**
   ```bash
   ./scripts/fleet.sh deploy nexus
   # Or manually: nix run github:nix-community/nixos-anywhere -- --flake .#nexus root@<ip>
   ```

Done! The system will automatically partition, install NixOS, and reboot.

See [nixos-anywhere docs](https://nix-community.github.io/nixos-anywhere/) for details.

---

## Alternative: Manual Installation

If you prefer step-by-step control or nixos-anywhere fails:

## What You're Getting

**Simplified Nexus Setup:**
- ✅ **Jellyfin** - Stream your media
- ✅ **Prometheus** - System metrics
- ✅ **Grafana** - Pretty dashboards
- 🔜 **Home Assistant** - Commented out, enable when needed
- 🔜 **Loki/Promtail** - Log aggregation, commented out for now

## Quick Start: Deploy to HP EliteDesk

### Step 1: Prepare the HP EliteDesk

1. **Download NixOS ISO** (if not already installed):
   ```bash
   # On Orion, download latest NixOS
   wget https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso
   
   # Flash to USB with:
   sudo dd if=latest-nixos-minimal-x86_64-linux.iso of=/dev/sdX bs=4M status=progress
   ```

2. **Boot HP EliteDesk from USB**

3. **Set up networking:**
   ```bash
   # Check network
   ip addr
   
   # If using WiFi
   sudo systemctl start wpa_supplicant
   wpa_cli
   > add_network
   > set_network 0 ssid "YourNetworkName"
   > set_network 0 psk "YourPassword"
   > enable_network 0
   > quit
   ```

### Step 2: Partition and Format Disks

**Simple single-disk setup:**
```bash
# Identify your disk
lsblk

# Assuming /dev/sda (adjust if different!)
# Wipe and partition
sudo parted /dev/sda -- mklabel gpt
sudo parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
sudo parted /dev/sda -- set 1 esp on
sudo parted /dev/sda -- mkpart primary 512MiB 100%

# Format partitions
sudo mkfs.fat -F 32 -n boot /dev/sda1
sudo mkfs.ext4 -L nixos /dev/sda2

# Mount
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot
```

### Step 3: Generate Hardware Config

```bash
# Generate config
sudo nixos-generate-config --root /mnt

# View the hardware config
cat /mnt/etc/nixos/hardware-configuration.nix

# Copy the fileSystems sections - you'll need these!
```

**Important:** Copy the `fileSystems."/"` and `fileSystems."/boot"` sections with their UUIDs!

### Step 4: Update Your Config on Orion

On your Orion machine:

1. **Edit the hardware.nix with real UUIDs:**
   ```bash
   cd ~/.config/nixos
   nano systems/nexus/hardware.nix
   ```

2. **Replace the commented-out fileSystems sections** with what you copied from the HP EliteDesk

3. **Check MAC address for network config:**
   ```bash
   # On the HP EliteDesk, find MAC address:
   ip link show
   
   # Update fleet-config.nix with the MAC address
   nano fleet-config.nix
   # Find the nexus section and add the MAC
   ```

### Step 5: Initial Manual Install

**On the HP EliteDesk (from NixOS installer):**

```bash
# Create minimal initial config
sudo nano /mnt/etc/nixos/configuration.nix
```

Add this minimal config:
```nix
{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  networking.hostName = "nexus";
  networking.networkmanager.enable = true;
  
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSdxXvx7Df+/2cPMe7C2TUSqRkYee5slatv7t3MG593 syg@nixos"
    ];
    initialPassword = "changeme";  # Change this immediately!
  };
  
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  
  system.stateVersion = "24.11";
}
```

**Install:**
```bash
sudo nixos-install
# Set root password when prompted
sudo reboot
```

### Step 6: Deploy Full Config from Orion

Once the HP EliteDesk reboots and you can SSH in:

```bash
# On Orion
cd ~/.config/nixos

# Test SSH connection
ssh admin@192.168.1.10

# Commit your changes
git add systems/nexus/
git commit -m "Add Nexus configuration for HP EliteDesk G4 800"

# Deploy!
./scripts/fleet.sh update nexus

# Or use deploy-rs directly:
nix run github:serokell/deploy-rs -- --targets .#nexus
```

## Post-Deployment

### Access Your Services

- **Grafana**: http://192.168.1.10:3000 (admin/admin - change this!)
- **Jellyfin**: http://192.168.1.10:8096
- **Prometheus**: http://192.168.1.10:9090

### Set Up Jellyfin

1. Open http://192.168.1.10:8096
2. Complete setup wizard
3. Add media library pointing to your NAS
4. Configure hardware transcoding:
   - Dashboard → Playback → Transcoding
   - Hardware acceleration: Video Acceleration API (VAAPI)

### Import Grafana Dashboard

1. Open http://192.168.1.10:3000
2. Login and change password
3. Import dashboard:
   - Click + → Import
   - Enter ID: **1860** (Node Exporter Full)
   - Click Load → Import

### Enable Home Assistant (when ready)

```bash
# Edit default.nix
nano systems/nexus/default.nix

# Uncomment the Home Assistant section
# Rebuild
./scripts/fleet.sh update nexus
```

## Troubleshooting

### Can't SSH to Nexus
```bash
# Check if it's on the network
ping 192.168.1.10

# Check from HP EliteDesk itself
# Log in directly and check:
ip addr
systemctl status sshd
```

### Hardware Video Acceleration Not Working
```bash
# SSH into Nexus
ssh admin@192.168.1.10

# Check VAAPI
vainfo

# Should show Intel iHD driver
# If not, check dmesg for errors:
dmesg | grep -i drm
```

### Services Not Starting
```bash
# Check service status
systemctl status jellyfin
systemctl status prometheus
systemctl status grafana

# View logs
journalctl -u jellyfin -f
journalctl -u grafana -f
```

## What's Different From The Original Plan?

**Removed (for now):**
- ❌ Home Assistant - Commented out, enable when you need it
- ❌ Loki/Promtail - Log aggregation, nice to have but not essential
- ❌ Nextcloud - Not needed right now

**Kept:**
- ✅ Jellyfin - Your media server
- ✅ Prometheus + Grafana - Monitor your homelab
- ✅ All security features (SSH, fail2ban, firewall)

**Why This is Better:**
- Simpler, less to troubleshoot
- Faster deployment
- Add services incrementally as you need them
- Still production-quality setup

## Next Steps

1. Get Jellyfin working with your media
2. Set up nice Grafana dashboards
3. When you're ready, uncomment Home Assistant
4. Later, add Loki for log aggregation if you want

Good luck! 🚀
