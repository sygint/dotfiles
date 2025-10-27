# Cortex Security Implementation Guide

**System:** Cortex AI Server (192.168.1.7)  
**User:** jarvis (admin)  
**Status:** ✅ Implemented and Active  

This document describes the actual security implementation for the Cortex AI server as configured in `systems/cortex/default.nix`.

## Security Features Implemented

### 1. Fail2ban - Automatic IP Blocking
- **Service**: `services.fail2ban.enable = true`
- **Purpose**: Automatically blocks IP addresses that show malicious intent (brute force attacks)
- **Configuration**:
  - Default SSH jail enabled
  - Whitelisted networks: Localhost (127.0.0.0/8), Private ranges (192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12)

### 2. Audit Logging - Security Event Monitoring
- **Services**: 
  - `security.auditd.enable = true` - Audit daemon
  - `security.audit.enable = true` - Audit subsystem
- **Purpose**: Logs security-relevant events for monitoring and compliance
- **Monitored Events**:
  - Authentication events (/var/log/auth.log)
  - Sudo usage (/etc/sudoers)
  - SSH configuration changes (/etc/ssh/sshd_config)
  - User/group modifications (/etc/passwd, /etc/group)
  - Login/logout events (/var/log/wtmp, /var/log/btmp)

### 3. SSH Hardening
- **Key-only authentication**: Password authentication completely disabled
- **Root access**: Completely prohibited (PermitRootLogin = "no")
- **User whitelist**: Only `jarvis` user allowed
- **Connection limits**: Maximum 3 authentication attempts, 2 max sessions
- **Session timeouts**: 5-minute idle timeout with 2 keepalive probes
- **Protocol restrictions**: SSH protocol 2 only, no X11 forwarding, no TCP forwarding
- **Additional hardening**: Login grace time 30s, connection rate limiting (3:50:10)

### 4. Kernel Security Parameters
Network security hardening through sysctl parameters:
- IP forwarding disabled
- ICMP redirects disabled
- Source routing disabled
- SYN flood protection enabled
- TCP SYN/ACK retry limits configured

### 5. System Monitoring
- **Journald**: Configured with log rotation (1GB max, 10 files, 1-month retention)
- **Time synchronization**: Chronyd enabled for accurate timestamps
- **System hardening**: Various kernel parameters for network security

## Deployment & Management

### Deploy Configuration Changes
```bash
# From Orion, rebuild Cortex
cd ~/.config/nixos

# Option 1: Using deploy-rs (if configured)
nix run github:serokell/deploy-rs -- .#cortex

# Option 2: Manual deployment
nix build .#nixosConfigurations.cortex.config.system.build.toplevel
# Then copy and activate on Cortex

# Option 3: On Cortex directly
ssh jarvis@192.168.1.7
cd /etc/nixos  # or wherever config is
sudo nixos-rebuild switch --flake .#cortex
```

### Verify Security Configuration
```bash
# Connect to cortex
ssh jarvis@192.168.1.7

# Check security services
sudo systemctl status fail2ban auditd

# Check fail2ban jails
sudo fail2ban-client status

# Check audit rules
sudo auditctl -l

# Check firewall rules
sudo iptables -L -n -v
```

## Post-Deployment Verification

### 1. Service Status Check
```bash
ssh jarvis@192.168.1.7 'sudo systemctl status fail2ban auditd'
```

Expected output:
- fail2ban.service: active (running)
- auditd.service: active (running)

### 2. Fail2ban Status
```bash
ssh jarvis@192.168.1.7 'sudo fail2ban-client status'
```

Expected output should show active jails (at minimum `sshd`).

### 3. Audit Rules
```bash
ssh jarvis@192.168.1.7 'sudo auditctl -l'
```

Expected output should show audit rules monitoring:
- Authentication logs (/var/log/auth.log)
- Sudo configuration (/etc/sudoers)
- SSH config (/etc/ssh/sshd_config)
- User/group files (/etc/passwd, /etc/group, /etc/shadow)
- Login logs (/var/log/wtmp, /var/log/btmp)
- Service user directories (/var/lib/friday)
- Systemd changes (/etc/systemd/system)

### 4. SSH Security Test
```bash
# This should fail (password auth disabled)
ssh -o PreferredAuthentications=password jarvis@192.168.1.7

# This should work (key auth from authorized workstation)
ssh jarvis@192.168.1.7

# Root login should fail completely
ssh root@192.168.1.7
```

### 5. Firewall Verification
```bash
# Check firewall status
ssh jarvis@192.168.1.7 'sudo iptables -L -n -v'

# Should show:
# - ACCEPT for localhost
# - ACCEPT for established connections
# - ACCEPT for SSH from local networks only (192.168.x.x, 10.x.x.x, 172.16.x.x)
# - LOG and DROP for everything else
```

## Troubleshooting

### Fail2ban Not Starting
1. Check service status: `sudo systemctl status fail2ban`
2. Check logs: `sudo journalctl -u fail2ban -n 50`
3. Verify configuration: `sudo fail2ban-client -t`

### Audit Service Issues
1. Check service status: `sudo systemctl status auditd`
2. Check logs: `sudo journalctl -u auditd -n 50`
3. Verify rules: `sudo auditctl -l`

### SSH Connection Issues
1. Verify SSH service: `sudo systemctl status sshd`
2. Check SSH configuration: `sudo sshd -T`
3. Monitor auth logs: `sudo tail -f /var/log/auth.log`

### Service Missing After Deployment
If services are not running after deployment, this could indicate:
1. Configuration syntax error (check build logs)
2. Service dependency issues (check systemd logs)
3. Package availability issues (services should auto-provide packages)

The configuration has been updated to address these common issues by:
- Using the standard NixOS service enablement patterns
- Removing redundant package declarations
- Adding explicit jail configuration for fail2ban
- Including comprehensive audit rules

## Security Monitoring

### Log Locations
- **Fail2ban logs**: `journalctl -u fail2ban`
- **Audit logs**: `journalctl -u auditd` and `/var/log/audit/audit.log`
- **SSH logs**: `/var/log/auth.log` and `journalctl -u sshd`
- **System logs**: `journalctl -f`

### Regular Maintenance

```bash
# Review blocked IPs
sudo fail2ban-client status sshd
sudo fail2ban-client status sshd --details

# Check recent audit events
sudo ausearch -ts today
sudo ausearch -k auth  # Authentication events
sudo ausearch -k sudoers  # Sudo usage

# Monitor system logs
sudo journalctl -f
sudo journalctl -u fail2ban -n 50
sudo journalctl -u auditd -n 50

# Check for failed login attempts
sudo journalctl _SYSTEMD_UNIT=sshd.service | grep -i failed

# Update system (from Orion workstation)
cd ~/.config/nixos
git pull
nix run github:serokell/deploy-rs -- .#cortex
```

## Advanced Configuration

### Custom Fail2ban Jails
Add additional jails to the configuration in `systems/cortex/default.nix`:
```nix
services.fail2ban.jails = {
  nginx-noscript = {
    settings = {
      enabled = true;
      filter = "nginx-noscript";
      logpath = "/var/log/nginx/access.log";
      maxretry = 6;
    };
  };
};
```

### Additional Audit Rules
Add more audit rules to monitor specific files or system calls in `systems/cortex/default.nix`:
```nix
security.audit.rules = [
  # Existing rules...
  "-w /etc/crontab -p wa -k cron"
  "-w /var/lib/friday -p rwxa -k ai-service-access"
];
```

## Current User Configuration

### Admin User: jarvis
- **Purpose**: System administrator for Cortex
- **SSH Access**: ✅ Key-only authentication
- **Sudo**: ✅ Full administrative access
- **Home**: /home/jarvis
- **Authorized Key**: syg@orion's SSH key

### Service User: friday
- **Purpose**: Run AI services (Ollama, Open WebUI)
- **Type**: System user (not login user)
- **SSH Access**: ❌ No SSH access
- **Sudo**: Limited (service management only)
- **Home**: /var/lib/friday
- **Audit**: All access logged

## Network Security

### Firewall Configuration
- **Default Policy**: DROP all incoming
- **SSH Access**: Only from local networks (192.168.x.x, 10.x.x.x, 172.16.x.x)
- **ICMP**: Limited to local networks only
- **Logging**: All dropped packets logged with "CORTEX-FIREWALL-DROP" prefix

### Network Hardening (sysctl)
```nix
# IP forwarding disabled
net.ipv4.ip_forward = 0

# ICMP/route manipulation disabled
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048

# Anti-spoofing
net.ipv4.conf.all.rp_filter = 1
```

## Summary

Cortex implements a defense-in-depth security posture suitable for a home AI server:

✅ **Minimal attack surface** - Only SSH open, only from LAN  
✅ **Strong authentication** - SSH keys only, no passwords  
✅ **User isolation** - Separate service user (friday) for AI workloads  
✅ **Comprehensive logging** - Auditd + journald with retention  
✅ **Automated blocking** - Fail2ban for brute force protection  
✅ **Network hardening** - Kernel-level security parameters  
✅ **Declarative config** - All security settings in version control  

This provides enterprise-grade security while maintaining ease of management through NixOS's declarative configuration approach.
