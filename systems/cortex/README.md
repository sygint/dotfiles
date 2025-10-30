# Cortex - Secure AI Server System

Cortex is a hardened NixOS system designed for secure AI/ML workloads and remote deployments. It features comprehensive security hardening, automated secret scanning, and deployment automation.

**📍 Network Configuration**: The IP address and system variables for Cortex are configured in `systems/cortex/variables.nix`. Update that file if network settings change.

## 🎯 Overview

**Cortex** is a security-focused NixOS configuration designed for:
- Remote AI/ML server deployments
- Secure infrastructure management
- Automated deployments with nixos-anywhere
- Comprehensive security monitoring and hardening

## 🔐 Security Features

### 1. **Fail2ban** - Automatic Intrusion Prevention
- Automatically blocks malicious IP addresses
- SSH brute force protection
- Configurable whitelist for trusted networks
- Default settings protect against common attacks

### 2. **Audit Logging** - Security Event Monitoring
- Comprehensive system audit logging via `auditd`
- Monitors:
  - Authentication events
  - Sudo usage and privilege escalation
  - SSH configuration changes
  - User/group modifications
  - Service user directory access

### 3. **SSH Hardening**
- **Key-only authentication** (passwords disabled)
- Limited to specific users only (jarvis)
- Connection attempt limits (max 3 tries)
- Session timeouts (5-minute idle timeout)
- No X11 forwarding, no TCP forwarding
- SSH Protocol 2 only

### 4. **Firewall Configuration**
- Strict iptables rules
- SSH access restricted to local network ranges
- All unmatched traffic logged and dropped
- Ping responses disabled for stealth
- Optional outbound traffic restrictions

### 5. **Kernel Hardening**
Network security via sysctl parameters:
- IP forwarding disabled
- ICMP redirects disabled
- Source routing disabled
- SYN flood protection enabled
- TCP SYN/ACK retry limits

### 6. **Secret Scanning** (Development)
- Pre-commit hooks with `git-secrets`
- Entropy-based scanning with `trufflehog`
- Pattern-based secret detection
- Prevents accidental secret commits

## 📁 File Structure

```
systems/cortex/
├── default.nix           # Main system configuration with security hardening
├── disk-config.nix       # Disko disk partitioning configuration
└── README.md            # This file

Documentation/
├── Cortex-SECURITY.md            # Detailed security implementation guide
├── SECRETS.md                    # Secrets management with sops-nix
└── examples/
    └── deploy-rs-integration.md  # Deploy-rs setup guide

Deployment Scripts/
├── scripts/deploy-cortex.sh            # Deploy cortex system
├── scripts/deploy-cortex.sh             # Enhanced deployment with health checks
├── scripts/verify-cortex-security.sh   # Verify security services
├── scripts/troubleshoot-cortex.sh      # Troubleshooting utilities
└── scripts/setup-security-tools.sh     # Install git-secrets and trufflehog
```

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Install security scanning tools (optional, for development)
./scripts/setup-security-tools.sh

# Review the configuration
cat systems/cortex/default.nix
```

### 2. Build Configuration Locally

```bash
# Test build without deploying
nix build .#nixosConfigurations.cortex.config.system.build.toplevel

# Check flake validity
nix flake check --no-build
```

### 3. Deploy to Target System

#### Option A: Using nixos-anywhere (Initial Installation)

```bash
# Deploy to a fresh system (will partition and install)
# Check systems/cortex/variables.nix for the current IP address
./scripts/deploy-cortex.sh <CORTEX_IP> nixos

# The script will:
# - Test the configuration builds
# - Deploy using nixos-anywhere
# - Set up the jarvis user with SSH key access
# - Apply all security hardening
```

#### Option B: Using deploy-rs (Ongoing Updates)

First, set up deploy-rs (see `examples/deploy-rs-integration.md`):

```bash
# Deploy updates to an existing system
nix run github:serokell/deploy-rs -- .#cortex
```

#### Option C: Manual Deployment

```bash
# Build locally and deploy manually
nixos-rebuild switch --flake .#cortex --target-host jarvis@cortex.local --use-remote-sudo
```

### 4. Verify Deployment

```bash
# Run security verification
# Check systems/cortex/variables.nix for the current IP address
./scripts/verify-cortex-security.sh <CORTEX_IP> jarvis

# SSH into the system
ssh jarvis@cortex.local
# or
ssh jarvis@<CORTEX_IP>

# Check security services
sudo systemctl status fail2ban auditd sshd
```

## 👥 User Accounts

### Jarvis (Admin User)
- **Purpose**: Main administrative user
- **Access**: SSH key authentication only
- **Groups**: wheel, networkmanager, systemd-journal
- **Sudo**: Password required (security best practice)

### Friday (Service User)
- **Purpose**: AI/ML service workloads
- **Type**: System user
- **Home**: `/var/lib/friday`
- **Sudo**: Limited to service management only

## 🔧 Configuration

### Customizing Security Settings

Edit `systems/cortex/default.nix`:

```nix
# Adjust firewall rules
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ ];  # Add ports as needed
  # ...
};

# Modify SSH settings
services.openssh.settings = {
  MaxAuthTries = 3;  # Adjust as needed
  AllowUsers = [ "jarvis" ];  # Add more users if needed
  # ...
};

# Configure fail2ban
services.fail2ban = {
  enable = true;
  ignoreIP = [
    "192.168.0.0/16"  # Add your trusted networks
  ];
};
```

### Adding Secrets Management

See `../../SECRETS.md` for complete secrets management guide with sops-nix and age encryption.

## 🔍 Monitoring and Maintenance

### Check Security Services

```bash
# SSH into cortex
ssh jarvis@cortex.local

# Check fail2ban status
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Check audit logs
sudo journalctl -u auditd
sudo ausearch -ts today

# Check SSH logs
sudo journalctl -u sshd | tail -50

# Monitor system logs
sudo journalctl -f
```

### Review Blocked IPs

```bash
# List currently banned IPs
sudo fail2ban-client status sshd

# Unban an IP if needed (replace with actual IP)
sudo fail2ban-client set sshd unbanip <IP_ADDRESS>
```

### Update System

```bash
# SSH into cortex
ssh jarvis@cortex.local

# Pull latest configuration (if managed via git)
cd /etc/nixos
git pull

# Rebuild system
sudo nixos-rebuild switch --flake .#cortex

# Or deploy from your local machine
# Check systems/cortex/variables.nix for the current IP address
./scripts/deploy-cortex.sh <CORTEX_IP>
```

## 🛠️ Troubleshooting

### Can't SSH into System

1. Check SSH service: `sudo systemctl status sshd`
2. Check firewall: `sudo iptables -L INPUT -n | grep 22`
3. Verify SSH keys are correct
4. Check fail2ban hasn't banned you: `sudo fail2ban-client status sshd`

### Security Services Not Running

```bash
# Use the troubleshooting script
# Check systems/cortex/variables.nix for the current IP address
./scripts/troubleshoot-cortex.sh <CORTEX_IP>

# Or manually check and restart
ssh jarvis@cortex.local
sudo systemctl status fail2ban auditd
sudo systemctl restart fail2ban auditd
```

### Build Failures

```bash
# Check for syntax errors
nix flake check

# Build with more verbose output
nix build --show-trace .#nixosConfigurations.cortex.config.system.build.toplevel
```

## 📚 Additional Documentation

- **[Cortex-SECURITY.md](../../Cortex-SECURITY.md)** - Comprehensive security implementation guide
- **[SECRETS.md](../../SECRETS.md)** - Complete secrets management guide with sops-nix
- **[SECURITY-COMPARISON.md](../../SECURITY-COMPARISON.md)** - Security features comparison
- **[examples/deploy-rs-integration.md](../../examples/deploy-rs-integration.md)** - Deploy-rs setup

## 🤝 Contributing

When working on Cortex:

1. **Security scanning is automatic** - Pre-commit hooks will scan for secrets
2. **Test builds before committing** - Run `nix flake check --no-build`
3. **Document security changes** - Update relevant documentation
4. **Follow the security model** - Maintain least-privilege principles

## 📝 Notes

- The system hostname is `cortex` (originally had "cortex" references, now unified)
- Default disk device is `/dev/nvme0n1` (customize in `disk-config.nix`)
- SSH keys need to be added to `jarvis` user's `authorizedKeys`
- Secrets management via sops-nix is optional but recommended for production

## 🔗 Related Systems

This is part of a larger NixOS configuration. See also:
- **Orion** - Desktop workstation system
- **Bifrost** - Bridge/network gateway system  
- **Lemuria** - Home lab infrastructure

---

**Status**: Work in Progress (WIP)  
**Last Updated**: 2025-10-05  
**System Version**: NixOS 24.11
