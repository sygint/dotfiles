# VM Testing Checklist

This document provides a comprehensive checklist for testing NixOS system configurations in VMs before deploying to physical hardware.

## Quick Start

```bash
# Test a system with defaults
./scripts/testing/test-vm.sh <system-name>

# Test with custom resources
./scripts/testing/test-vm.sh <system-name> [memory-mb] [cpu-cores] [headless] [disk-size]
```

## System Testing Matrix

### Desktop Systems (GUI Mode)
- [ ] **HTPC**: `./scripts/testing/test-vm.sh htpc 8192 4`
- [ ] **Orion**: `./scripts/testing/test-vm.sh orion 4096 2`

### Server Systems (Headless Mode)
- [ ] **Nexus**: `./scripts/testing/test-vm.sh nexus 4096 2 yes 40G`
- [ ] **Cortex**: `./scripts/testing/test-vm.sh cortex 4096 2 yes 20G`

## Pre-Deployment Testing Checklist

### 1. Boot and Authentication ✓

**Login Tests:**
- [ ] Deploy user can SSH (if configured)
- [ ] Rescue user can login at console
  - Username: `rescue`
  - Password: `rescue` (test) or from secrets (prod)
- [ ] Admin user can login (legacy systems only)
  - Username: `admin`
  - Password: `admin`

**Commands to verify:**
```bash
# In VM console
whoami
groups
sudo -l  # Should allow passwordless sudo for wheel group
```

### 2. Core System Health

**System Status:**
```bash
# Check failed services (should be empty)
systemctl --failed

# Check system info
hostnamectl
uptime
df -h  # Check disk space
free -h  # Check memory
```

**Network Configuration:**
```bash
# Get IP address
ip addr show

# Check DNS resolution
ping -c 2 1.1.1.1
ping -c 2 google.com

# Check listening ports
ss -tlnp
```

### 3. Service-Specific Tests

#### Nexus (Homelab Server)

**Service Status:**
```bash
systemctl status jellyfin
systemctl status grafana
systemctl status prometheus
systemctl status prometheus-node-exporter
systemctl status vikunja-api
systemctl status vikunja-frontend
```

**Port Checks:**
```bash
# Verify services are listening
ss -tlnp | grep -E '(3000|3456|8096|9090|9100)'
# Expected:
# 3000  - Grafana
# 3456  - Vikunja
# 8096  - Jellyfin HTTP
# 9090  - Prometheus
# 9100  - Node Exporter
```

**Service Health:**
```bash
# Test web interfaces respond
curl -I http://localhost:3000  # Grafana (expect 302 redirect to /login)
curl -I http://localhost:3456  # Vikunja (expect 200)
curl -I http://localhost:8096  # Jellyfin (expect 302 or 200)
curl http://localhost:9090/-/healthy  # Prometheus (expect "Prometheus is Healthy")
curl http://localhost:9100/metrics | head -n 20  # Node exporter metrics
```

**Jellyfin-Specific:**
```bash
# Check if Jellyfin needs more disk space
journalctl -u jellyfin -n 50 | grep -i "space\|error"

# If disk space error, restart VM with larger disk:
# ./scripts/testing/test-vm.sh nexus 4096 2 yes 40G
```

**Storage Mounts (Production only - won't work in VM):**
```bash
# These will fail in VM but verify the config exists
systemctl list-unit-files | grep mnt-nas
# Should see: mnt-nas-movies.mount, mnt-nas-tvshows.mount, mnt-nas-music.mount
```

#### Cortex (Future Network Controller)
```bash
# TBD - Add Cortex-specific tests when implemented
```

#### HTPC (Desktop)
```bash
# Check display server
systemctl status display-manager
echo $XDG_SESSION_TYPE  # Should be wayland

# Check audio
pactl info

# Check Jellyfin client (if installed)
which jellyfin-media-player
```

### 4. Security Configuration

**SSH Configuration:**
```bash
# Verify SSH settings
sudo cat /etc/ssh/sshd_config | grep -E "PasswordAuthentication|PermitRootLogin|PubkeyAuthentication"
# Expected:
# PasswordAuthentication no
# PermitRootLogin no
# PubkeyAuthentication yes
```

**Firewall Status:**
```bash
# Check firewall is enabled
sudo systemctl status firewall

# List open ports
sudo nft list ruleset | grep -A 5 "tcp dport"
```

**Security Modules (if enabled):**
```bash
# Check fail2ban
systemctl status fail2ban
sudo fail2ban-client status

# Check if auditd is running (server hardening)
systemctl status auditd
```

### 5. Nix Configuration

**Flakes and Features:**
```bash
# Verify experimental features are enabled
nix show-config | grep experimental-features
# Should include: nix-command flakes

# Test nix commands work
nix --version
nix flake show --help
```

**Trusted Users:**
```bash
# Check trusted users for remote deployments
nix show-config | grep trusted-users
# Should include: root deploy (and possibly admin for legacy)
```

### 6. User Environment

**Shell Configuration:**
```bash
# Check shell
echo $SHELL  # Should be /run/current-system/sw/bin/zsh or similar

# Test common tools
which git htop tmux curl wget
```

**Home Manager (if enabled):**
```bash
# Check home-manager generation
home-manager generations | head -n 5
```

## VM Testing Tips

### Terminal Controls

**Headless VMs (Serial Console):**
- `Ctrl+A` then `X` - Exit QEMU
- `Ctrl+A` then `C` - QEMU monitor console
- `Ctrl+A` then `H` - Help (show all commands)

**GUI VMs (QEMU Window):**
- `Ctrl+Alt+G` - Release mouse/keyboard from QEMU window
- `Ctrl+Alt+F` - Toggle fullscreen
- `Ctrl+Alt+1` - Switch to VM display
- `Ctrl+Alt+2` - Switch to QEMU monitor

### Common Issues

#### Issue: Jellyfin fails with "insufficient disk space"
**Solution:** Restart VM with larger disk:
```bash
./scripts/testing/test-vm.sh nexus 4096 2 yes 40G
```

#### Issue: VM window hangs/blocks terminal
**Solution:** The script now auto-detects and opens headless VMs in a new terminal window. Make sure you have kitty, alacritty, gnome-terminal, or xterm installed.

#### Issue: Services fail to start
**Solution:** Check logs:
```bash
journalctl -u <service-name> -n 50
journalctl -xe  # Show recent errors
```

#### Issue: Can't access services from host
**Solution:** Services are only accessible within the VM by default. The VM uses NAT networking (10.0.2.15). To access from host:
1. Use port forwarding in QEMU_OPTS
2. Or use `user,hostfwd=tcp::8080-:8096` syntax
3. Or test services from within the VM console

## Resource Recommendations

### Memory (RAM)

| System Type | Minimum | Recommended | Heavy Load |
|-------------|---------|-------------|------------|
| Server (headless) | 2048 MB | 4096 MB | 8192 MB |
| Desktop (HTPC) | 4096 MB | 8192 MB | 16384 MB |
| Workstation | 8192 MB | 16384 MB | 32768 MB |

### CPU Cores

| System Type | Minimum | Recommended |
|-------------|---------|-------------|
| Server | 2 | 4 |
| Desktop | 2 | 4 |
| Workstation | 4 | 8 |

### Disk Size

| System Type | Minimum | Recommended | With Media Services |
|-------------|---------|-------------|---------------------|
| Server | 10G | 20G | 40G+ |
| Desktop | 20G | 40G | 60G+ |

**Note:** Jellyfin requires minimum 2GB free space in `/var/lib/jellyfin/data`

## Automated Testing Script Ideas

Future improvements to consider:

```bash
# Example automated test script structure
#!/usr/bin/env bash
# scripts/testing/auto-test.sh

# 1. Build VM
# 2. Boot and wait for SSH/serial
# 3. Run health checks automatically
# 4. Generate test report
# 5. Cleanup

# Could use expect/pexpect for automation
```

## Pre-Production Deployment Checklist

Before deploying a tested configuration to production hardware:

- [ ] All VM tests pass
- [ ] Secrets are properly configured (not using test passwords)
- [ ] Hardware-specific configuration reviewed (disk-config.nix, hardware.nix)
- [ ] Network configuration matches production (static IPs, DNS, etc.)
- [ ] Backup strategy in place
- [ ] Rollback plan documented
- [ ] Deploy user SSH keys are correct
- [ ] Rescue user password is stored securely (not 'rescue')

## Related Documentation

- [VM Testing Guide](./VM-TESTING.md) - Detailed VM testing procedures
- [Deployment Guide](./IMPLEMENTATION-GUIDE.md) - nixos-anywhere deployment
- [Security Guide](./SECURITY.md) - Security hardening checklist
- [Fleet Management](../FLEET-MANAGEMENT.md) - Multi-system deployment

## Troubleshooting

### Getting Help

1. Check system logs: `journalctl -xe`
2. Check service logs: `journalctl -u <service> -n 100`
3. Review build output for warnings
4. Check NixOS manual: `nixos-help` (in VM) or https://nixos.org/manual
5. Search NixOS Discourse: https://discourse.nixos.org

### Debug Mode

To get more verbose output during VM build:
```bash
# Add --show-trace for detailed error traces
nixos-rebuild build-vm --flake ".#nexus" --show-trace
```

## Notes

- VMs use NAT networking by default (10.0.2.x)
- VM state is ephemeral - changes are lost on restart
- VMs are perfect for testing config changes before deployment
- The test-vm.sh script automatically sets `isTest = true` to skip disk-config.nix
