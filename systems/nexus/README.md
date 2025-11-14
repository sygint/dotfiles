# Nexus - Homelab Server

HP EliteDesk G4 800 running NixOS 24.11

## Quick Start

**Initial Deployment:**
```bash
# Boot any Linux USB on HP EliteDesk, enable SSH, then:
./scripts/fleet.sh deploy nexus
```

**Alternative:** See [DEPLOYMENT.md](./DEPLOYMENT.md) for manual step-by-step install

**Remote Management:** See [../../docs/VPRO-AMT-SETUP.md](../../docs/VPRO-AMT-SETUP.md) to enable Intel vPro/AMT KVM

## Services

## Purpose
Nexus is the centralized homelab services server, providing media streaming (Jellyfin), home automation (Home Assistant), and comprehensive monitoring (Prometheus/Grafana/Loki) for the entire home network.

## Hardware
- Mini PC or server hardware (Intel/AMD CPU with integrated graphics)
- Network: 192.168.1.10
- SSH: Port 22 (admin user)

## Core Services & Ports

### Media Services
- **Jellyfin** (Port 8096/8920)
  - Media server for movies, TV shows, music
  - Hardware-accelerated transcoding via Intel VAAPI
  - Auto-discovery via DLNA/UPnP (port 1900, 7359)
  - Web UI: http://nexus.home:8096

### Home Automation
- **Home Assistant** (Port 8123)
  - Smart home automation and control
  - ESPHome, Met, Radio Browser integrations
  - Web UI: http://nexus.home:8123

### Monitoring Stack
- **Prometheus** (Port 9090)
  - Time-series metrics database
  - Node exporter for system metrics (port 9100)
  - Web UI: http://nexus.home:9090

- **Grafana** (Port 3000)
  - Metrics visualization and dashboards
  - Pre-configured Prometheus and Loki data sources
  - Web UI: http://nexus.home:3000
  - Default login: admin/admin (change on first login!)

- **Loki** (Port 3100)
  - Log aggregation and storage
  - Automatically collects systemd journal logs

- **Promtail** (Port 28183)
  - Log shipper to Loki
  - Monitors systemd journal

### Security
- **SSH** (Port 22)
  - Key-based authentication only
  - Password authentication disabled
  
- **Fail2ban**
  - Automatic IP banning for failed login attempts
  - Protects SSH and other services

## Deployment

### Initial Setup

1. **Install NixOS on the hardware:**
   ```bash
   # Boot from NixOS installer
   # Partition disks and mount them
   # Generate hardware config
   nixos-generate-config --root /mnt
   
   # Copy the generated hardware-configuration.nix
   # Replace systems/nexus/hardware.nix with actual hardware config
   ```

2. **Update hardware.nix:**
   Replace the placeholder UUIDs in `systems/nexus/hardware.nix` with your actual hardware configuration from step 1.

3. **Update fleet-config.nix:**
   - Set the actual MAC address for the ethernet interface
   - Update interface names if different from default

4. **Build and deploy from Orion:**
   ```bash
   # Build configuration locally
   ./scripts/fleet.sh build nexus
   
   # Deploy to Nexus
   ./scripts/fleet.sh update nexus
   
   # Or use deploy-rs directly
   nix run github:serokell/deploy-rs -- --targets .#nexus
   ```

### Remote Deployment

Once initial setup is complete, you can deploy updates remotely:

```bash
# From Orion (control machine)
cd ~/.config/nixos

# Check configuration
nix flake check

# Build and deploy
./scripts/fleet.sh update nexus

# Or with deploy-rs
nix run github:serokell/deploy-rs -- --targets .#nexus
```

## User Accounts

- **admin**: Primary administrator user
  - Groups: wheel, networkmanager, jellyfin, grafana
  - SSH key authentication required
  - Full sudo access

## First-Time Configuration

### Jellyfin Setup
1. Navigate to http://nexus.home:8096
2. Complete the initial setup wizard
3. Create admin account
4. Add media libraries pointing to your NAS shares
5. Configure hardware transcoding:
   - Dashboard → Playback → Transcoding
   - Hardware acceleration: Video Acceleration API (VAAPI)
   - VA-API Device: /dev/dri/renderD128

### Home Assistant Setup
1. Navigate to http://nexus.home:8123
2. Complete onboarding and create user account
3. Configure integrations as needed
4. Set up automations and dashboards

### Grafana Setup
1. Navigate to http://nexus.home:3000
2. Login with admin/admin
3. Change admin password immediately
4. Data sources are pre-configured:
   - Prometheus (default)
   - Loki
5. Import or create dashboards:
   - Node Exporter Full dashboard (ID: 1860)
   - Loki dashboard for log exploration

## Monitoring & Maintenance

### Check Service Status
```bash
# SSH into Nexus
ssh admin@nexus.home

# Check service statuses
systemctl status jellyfin
systemctl status home-assistant
systemctl status prometheus
systemctl status grafana
systemctl status loki
systemctl status promtail

# View logs
journalctl -u jellyfin -f
journalctl -u home-assistant -f
journalctl -u prometheus -f
```

### Hardware Video Acceleration
```bash
# Verify VAAPI is working
vainfo

# Should show Intel driver and supported codecs
# Example output:
# libva info: VA-API version 1.xx.x
# libva info: Driver: iHD
# VAProfileH264Main              : VAEntrypointVLD
# etc.
```

### Prometheus Metrics
```bash
# Query node exporter directly
curl http://localhost:9100/metrics

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets
```

### Disk Usage
```bash
# Check Jellyfin data
du -sh /var/lib/jellyfin

# Check Loki logs
du -sh /var/lib/loki

# Check Prometheus metrics
du -sh /var/lib/prometheus2
```

## Networking

### Firewall Ports
- 22 (SSH)
- 80/443 (HTTP/HTTPS)
- 3000 (Grafana)
- 8096/8920 (Jellyfin)
- 8123 (Home Assistant)
- 9090 (Prometheus)
- 1900/7359 (UDP - Jellyfin discovery)

### Local DNS
Add to your router or `/etc/hosts`:
```
192.168.1.10  nexus.home nexus
```

## Troubleshooting

### Jellyfin Issues

**Problem:** Jellyfin won't start
```bash
# Check logs
journalctl -u jellyfin -n 50

# Check permissions
ls -la /var/lib/jellyfin

# Restart service
sudo systemctl restart jellyfin
```

**Problem:** No hardware transcoding
```bash
# Verify VAAPI devices exist
ls -la /dev/dri/

# Check if jellyfin user has access
groups jellyfin

# Should include: render, video
```

### Home Assistant Issues

**Problem:** ModuleNotFoundError for integrations
- These are expected on first start for auto-discovered devices
- Add required components to `extraComponents` in default.nix
- Rebuild and deploy

**Problem:** Can't access web UI
```bash
# Check if service is running
systemctl status home-assistant

# Check listening ports
ss -tulpn | grep 8123
```

### Monitoring Stack Issues

**Problem:** Grafana can't connect to Prometheus
```bash
# Verify Prometheus is running
curl http://localhost:9090/api/v1/status/config

# Check Grafana logs
journalctl -u grafana -f
```

**Problem:** No logs in Loki
```bash
# Check Promtail status
systemctl status promtail

# Check Promtail is shipping logs
curl http://localhost:28183/metrics
```

### Network Issues

**Problem:** Can't SSH into Nexus
- Verify SSH keys are correctly configured
- Check firewall rules on router
- Verify IP address: `ping 192.168.1.10`

**Problem:** Services not accessible from other machines
- Check `networking.firewall.allowedTCPPorts` in default.nix
- Verify services are listening on 0.0.0.0 (not just 127.0.0.1)
- Check router firewall rules

## Backup Recommendations

### Important Data Locations
- `/var/lib/jellyfin` - Jellyfin configuration and database
- `/var/lib/home-assistant` - Home Assistant configuration
- `/var/lib/grafana` - Grafana dashboards and settings
- `/var/lib/prometheus2` - Prometheus metrics (can be rebuilt)
- `/var/lib/loki` - Log data (can be rebuilt)

### Backup Strategy
```bash
# Manual backup example
rsync -avz /var/lib/jellyfin/ user@backup-server:/backups/nexus/jellyfin/
rsync -avz /var/lib/home-assistant/ user@backup-server:/backups/nexus/home-assistant/
rsync -avz /var/lib/grafana/ user@backup-server:/backups/nexus/grafana/
```

Consider setting up automated backups with:
- BorgBackup (built-in NixOS module)
- Restic
- Syncthing to Synology NAS

## Future Enhancements

### Planned Services
- [ ] Nextcloud (file sync and collaboration)
- [ ] AdGuard Home (DNS filtering)
- [ ] Nginx reverse proxy with SSL
- [ ] Uptime Kuma (uptime monitoring)
- [ ] Frigate NVR (security cameras)

### Monitoring Improvements
- [ ] Set up Grafana dashboards for all services
- [ ] Configure alerting (email, Discord, etc.)
- [ ] Add more Prometheus exporters
- [ ] Set up log-based alerts in Grafana

### Security Enhancements
- [ ] Implement Nginx reverse proxy with Let's Encrypt SSL
- [ ] Set up Authelia for SSO
- [ ] Enable automatic security updates
- [ ] Implement regular backup automation

## References
- [Jellyfin NixOS Wiki](https://nixos.wiki/wiki/Jellyfin)
- [Home Assistant NixOS Wiki](https://nixos.wiki/wiki/Home_Assistant)
- [Grafana NixOS Wiki](https://nixos.wiki/wiki/Grafana)
- [Prometheus + Grafana + Loki on NixOS](https://xeiaso.net/blog/prometheus-grafana-loki-nixos-2020-11-20)
- [NixOS Search - Service Options](https://search.nixos.org/options)
- [Homelab Strategy](../../docs/planning/homelab-strategy.md)

## Support
For issues or questions:
- Check the troubleshooting section above
- Review service logs with `journalctl`
- Consult the NixOS wiki and documentation
- Ask in NixOS communities (Discord, Matrix, Discourse)
