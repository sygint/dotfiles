# Nexus Quick Start Guide

**Status:** ✅ Configuration Complete - Ready for Deployment  
**Next Steps:** Deploy to your HP EliteDesk 800 G4

---

## Pre-Deployment Checklist

### 1. Update Configuration Files

Before deploying, customize these settings:

#### `network-config.nix`
```nix
nexus = {
  ip = "192.168.1.10";  # ← Verify this IP is available
  interfaces.ethernet = {
    name = "enp0s0";  # ← Check with `ip link` on EliteDesk
    mac = "xx:xx:xx:xx:xx:xx";  # ← Get MAC for Wake-on-LAN
  };
};
```

#### `systems/nexus/variables.nix`
```nix
storage = {
  synology = {
    host = "192.168.1.50";  # ← Your actual Synology IP
    # ...
  };
};
```

#### `systems/nexus/default.nix`
```nix
time.timeZone = "America/New_York";  # ← Your timezone
```

### 2. Synology NFS Setup

```bash
# SSH to Synology
ssh admin@192.168.1.50

# Create directories
sudo mkdir -p /volume1/homelab/{immich,vaultwarden,backups}
sudo chown -R 1000:1000 /volume1/homelab

# In Synology DSM:
# Control Panel → File Services → NFS → Enable NFSv4
# Control Panel → Shared Folder → homelab
#   → Edit → NFS Permissions → Add:
#     IP: 192.168.1.10 (Nexus)
#     Permission: Read/Write
#     Squash: Map all users to admin
```

---

## Deployment Methods

### Method 1: Fresh NixOS Install (Recommended)

**If starting from scratch:**

1. **Boot NixOS installer USB** on EliteDesk

2. **Basic setup:**
```bash
# On the EliteDesk during installation
sudo -i

# Partition disk (adjust as needed)
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MiB 100%

# Format
mkfs.fat -F 32 -n boot /dev/sda1
mkfs.ext4 -L nixos /dev/sda2

# Mount
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Generate initial config
nixos-generate-config --root /mnt

# Edit /mnt/etc/nixos/configuration.nix
# Add minimal SSH access:
services.openssh.enable = true;
users.users.root.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSdxXvx7Df+/2cPMe7C2TUSqRkYee5slatv7t3MG593 syg@nixos"
];
networking.hostName = "nexus";
networking.networkmanager.enable = true;

# Install
nixos-install

# Reboot
reboot
```

3. **Deploy full config from Orion:**
```bash
# On your Orion laptop
cd ~/.config/nixos

# Build first to check for errors
nix build .#nixosConfigurations.nexus.config.system.build.toplevel

# Deploy
nix run github:serokell/deploy-rs -- .#nexus
```

### Method 2: Deploy-rs from Orion (If NixOS already installed)

```bash
# From Orion
cd ~/.config/nixos

# Build configuration
nix build .#nixosConfigurations.nexus.config.system.build.toplevel

# Deploy to Nexus
nix run github:serokell/deploy-rs -- .#nexus

# Follow prompts, confirm deployment
```

### Method 3: Manual Deploy (If deploy-rs has issues)

```bash
# On Orion - copy config to Nexus
cd ~/.config/nixos
rsync -avz --exclude result . admin@192.168.1.10:/tmp/nixos-config/

# SSH to Nexus
ssh admin@192.168.1.10

# On Nexus - apply config
cd /tmp/nixos-config
sudo nixos-rebuild switch --flake .#nexus
```

---

## Post-Deployment Verification

### 1. SSH Access
```bash
# From Orion
ssh admin@nexus.home
# or
ssh admin@192.168.1.10
```

### 2. Check Docker Containers
```bash
# Should show 5 containers running
docker ps

# Expected:
# - vaultwarden
# - immich-server
# - immich-postgres  
# - immich-redis
# - syncthing
# - uptime-kuma
# - portainer
```

### 3. Check NFS Mounts
```bash
df -h | grep volume1

# Expected:
# 192.168.1.50:/volume1/homelab/immich
# 192.168.1.50:/volume1/homelab/vaultwarden
```

### 4. Test Services

| Service | URL | Test |
|---------|-----|------|
| Vaultwarden | http://nexus.home:8000 | Should show login page |
| Immich | http://nexus.home:2283 | Should show welcome page |
| Syncthing | http://nexus.home:8384 | Should show web UI |
| Uptime Kuma | http://nexus.home:3001 | Should show setup wizard |
| Portainer | http://nexus.home:9000 | Should show setup wizard |

### 5. Setup Tailscale
```bash
# On Nexus
sudo tailscale up

# Copy the auth URL and visit it in browser
# After auth, check status:
tailscale status

# Note the Tailscale IP (e.g., 100.64.0.3)
tailscale ip -4
```

---

## Initial Service Configuration

### Vaultwarden (Password Manager)
1. Visit http://nexus.home:8000
2. Create admin account
3. Login to admin panel: http://nexus.home:8000/admin
4. Disable new user registration (security)
5. Install Bitwarden app/extension, point to http://nexus.home:8000

### Immich (Photos)
1. Visit http://nexus.home:2283
2. Create admin account
3. Install mobile app
4. Add server: http://nexus.home:2283 (or Tailscale IP)
5. Enable auto-upload in app settings

### Syncthing (File Sync)
1. Visit http://nexus.home:8384
2. Configure settings → General → Set device name
3. Add folders to sync (e.g., ~/Documents, ~/Obsidian)
4. Install Syncthing on other devices
5. Add devices and share folders

### Uptime Kuma (Monitoring)
1. Visit http://nexus.home:3001
2. Create admin account
3. Add HTTP monitors for each service:
   - Vaultwarden: http://localhost:8000
   - Immich: http://localhost:2283
   - Syncthing: http://localhost:8384
4. Set notification methods (email, Discord, etc.)

### Portainer (Container Management)
1. Visit http://nexus.home:9000
2. Create admin account
3. Select "Docker" environment
4. Explore running containers

---

## Common Issues & Solutions

### Issue: Can't SSH to Nexus
```bash
# Check if Nexus is reachable
ping 192.168.1.10

# Check SSH service on Nexus (if you have physical access)
sudo systemctl status sshd

# Try with verbose output
ssh -v admin@192.168.1.10
```

### Issue: Docker containers not starting
```bash
# Check Docker daemon
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Check specific container logs
docker logs <container-name>

# Rebuild NixOS config
sudo nixos-rebuild switch
```

### Issue: NFS mounts failing
```bash
# Test NFS from Nexus
showmount -e 192.168.1.50

# Try manual mount
sudo mount -t nfs 192.168.1.50:/volume1/homelab/immich /mnt/test

# Check Synology NFS settings in DSM
# Ensure Nexus IP (192.168.1.10) is in allowed clients
```

### Issue: Services accessible locally but not via Tailscale
```bash
# On Nexus, check Tailscale status
sudo tailscale status

# Restart Tailscale
sudo systemctl restart tailscaled

# Check firewall
sudo iptables -L -n

# Ensure services bind to 0.0.0.0, not just 127.0.0.1
docker ps  # Check port bindings
```

---

## Maintenance Commands

```bash
# Update system
cd ~/.config/nixos
git pull
nix run github:serokell/deploy-rs -- .#nexus

# Check system status
ssh admin@nexus.home
systemctl --failed
docker ps -a
df -h

# View logs
journalctl -xe
docker logs <container>

# Cleanup old generations
sudo nix-collect-garbage -d

# Backup databases
docker exec vaultwarden sqlite3 /data/db.sqlite3 ".backup '/data/backup.sqlite3'"
```

---

## Next Steps

Once Nexus is running smoothly:

1. ✅ Set up regular backups
2. ✅ Configure Uptime Kuma alerts
3. ✅ Install Bitwarden/Immich on all devices
4. ⏳ When cameras arrive, add Frigate
5. ⏳ Consider adding Jellyfin for media
6. ⏳ Consider Home Assistant for automation

---

## Support Resources

- **Full README:** `systems/nexus/README.md`
- **Network Config:** `network-config.nix`
- **Service Modules:** `modules/system/homelab-services/`
- **Troubleshooting:** See README.md Troubleshooting section

---

**Ready to deploy?** Start with Method 1 or Method 2 above! 🚀
