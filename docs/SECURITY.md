# NixOS System Security Guide (Merged)

This guide combines actionable configuration steps ("what"), rationale ("why"), and implementation details ("how") for securing any NixOS system. It is designed for clarity, completeness, and practical use.

## Security Features Implemented

### 1. Fail2ban - Automatic IP Blocking
**What:**
```nix
services.fail2ban = {
  enable = true;
  bantime = 3600; # 1 hour
  findtime = 600; # 10 minutes
  maxretry = 3;
  ignoreip = [ "127.0.0.1/8" "192.168.1.0/24" ];
  jails = {
    sshd = {
      enabled = true;
      port = "ssh";
      filter = "sshd";
      logpath = "/var/log/auth.log";
      maxretry = 3;
    };
  };
};
```
**Why:** Protects against brute force attacks by automatically banning IPs that fail authentication repeatedly.
**How:** Adjust ban time, detection window, and whitelisted networks as needed.

### 2. Audit Logging - Security Event Monitoring
**What:**
```nix
security.auditd.enable = true;
security.audit.enable = true;
security.audit.rules = [
  "-w /etc/passwd -p wa -k identity"
  "-w /etc/group -p wa -k identity"
  "-w /etc/ssh/sshd_config -p wa -k ssh"
  "-w /etc/sudoers -p wa -k sudo"
  "-w /etc/crontab -p wa -k cron"
  "-w /etc/systemd -p wa -k systemd"
];
```
**Why:** Provides a record of security-relevant events for monitoring, compliance, and forensics.
**How:** Monitor authentication, sudo, SSH config changes, user/group modifications, logins/logouts, and more.

### 3. SSH Hardening
**What:**
```nix
services.openssh = {
  enable = true;
  passwordAuthentication = false;
  permitRootLogin = "prohibit-password";
  maxAuthTries = 3;
  clientAliveInterval = 300; # 5 minutes
  clientAliveCountMax = 2;
  protocol = 2;
  allowTcpForwarding = false;
  x11Forwarding = false;
};
```
**Why:** Reduces attack surface and enforces strong authentication.
**How:** Disable password authentication, restrict root access, limit attempts, set timeouts, and restrict protocols.

### 4. Kernel Security Parameters
**What:**
```nix
boot.kernel.sysctl = {
  "net.ipv4.ip_forward" = 0;
  "net.ipv4.conf.all.accept_redirects" = 0;
  "net.ipv4.conf.all.send_redirects" = 0;
  "net.ipv4.conf.all.rp_filter" = 1;
  "net.ipv4.tcp_syncookies" = 1;
  "net.ipv4.tcp_max_syn_backlog" = 2048;
  "net.ipv4.tcp_synack_retries" = 2;
};
```
**Why:** Protects against common network attacks and misconfigurations.
**How:** Set sysctl parameters to disable IP forwarding, ICMP redirects, source routing, and enable SYN flood protection.

### 5. System Monitoring
**What:**
```nix
services.chrony.enable = true;
systemd.journald = {
  maxRetentionSec = 2592000; # 1 month
  maxFileSize = 1048576000; # 1GB
  maxFiles = 10;
};
```
**Why:** Ensures logs are available for troubleshooting and security audits; keeps system time accurate for log integrity.
**How:** Configure journald for log rotation and retention, enable chronyd or another time sync service.

---

## Deployment

### Prerequisites
1. Ensure nixos-anywhere is installed:
   ```bash
   nix-env -iA nixpkgs.nixos-anywhere
   ```
2. Ensure SSH key is added to ssh-agent:
   ```bash
   ssh-add ~/.ssh/id_ed25519
   ```

## Verification & Maintenance

After deploying or updating a system, always verify that security services are running and configured as expected:
```bash
sudo systemctl status fail2ban auditd
sudo fail2ban-client status
sudo auditctl -l
ssh -o PreferredAuthentications=password <user>@<host>
ssh <user>@<host>
```

## Troubleshooting

#### Fail2ban Not Starting
- Check service status: `sudo systemctl status fail2ban`
- Check logs: `sudo journalctl -u fail2ban -n 50`
- Verify configuration: `sudo fail2ban-client -t`

#### Audit Service Issues
- Check service status: `sudo systemctl status auditd`
- Check logs: `sudo journalctl -u auditd -n 50`
- Verify rules: `sudo auditctl -l`

#### SSH Connection Issues
- Verify SSH service: `sudo systemctl status sshd`
- Check SSH configuration: `sudo sshd -T`
- Monitor auth logs: `sudo tail -f /var/log/auth.log`

#### Service Missing After Deployment
- Check configuration syntax (build logs)
- Check service dependencies (systemd logs)
- Check package availability (should be auto-provided)

## Security Monitoring

### Log Locations & Maintenance
- **Fail2ban logs**: `journalctl -u fail2ban`
- **Audit logs**: `journalctl -u auditd` and `/var/log/audit/audit.log`
- **SSH logs**: `/var/log/auth.log` and `journalctl -u sshd`
- **System logs**: `journalctl -f`

#### Regular Maintenance
- Review blocked IPs: `sudo fail2ban-client status sshd`
- Check audit events: `sudo ausearch -ts today`
- Monitor system logs: `sudo journalctl -f`
- Update system regularly: `sudo nixos-rebuild switch --flake .#<system>`

## Advanced Configuration

### Custom Fail2ban Jails
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
```nix
security.audit.rules = [
  "-w /etc/crontab -p wa -k cron"
  "-w /etc/systemd -p wa -k systemd"
];
```

---

This guide provides enterprise-grade security best practices for any NixOS system, while maintaining ease of management through declarative configuration.
