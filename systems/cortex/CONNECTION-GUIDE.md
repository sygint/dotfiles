# Cortex Connection Setup & Verification Guide

**📍 Network**: Check `systems/cortex/variables.nix` for the current IP address. Set up a DHCP reservation on your router for consistent access.

## 🔑 SSH Access

**Key**: `~/.ssh/id_ed25519_jarvis` (jarvis@cortex)  
**User**: `jarvis`  
**Auth**: SSH key only (password authentication disabled)  
**Network**: Local networks only (192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12)

## 📋 Quick Start

1. **Load SSH key**: `ssh-add ~/.ssh/id_ed25519_jarvis`
2. **Set DHCP reservation** on router for Cortex's MAC address
3. **Deploy**: See deployment options below

## 🚀 Deployment

```bash
# Fresh install (check variables.nix for IP)
./scripts/deploy-cortex.sh <CORTEX_IP> nixos

# Update existing system
./scripts/deploy-cortex-enhanced.sh <CORTEX_IP> jarvis

# Manual deployment
nixos-rebuild switch --flake .#cortex --target-host jarvis@<CORTEX_IP> --use-remote-sudo
```

## 🔍 Connect

```bash
# Direct connection
ssh -i ~/.ssh/id_ed25519_jarvis jarvis@<CORTEX_IP>

# Or add to ~/.ssh/config:
Host cortex
    HostName <CORTEX_IP>  # or cortex.local once router DNS is configured
    User jarvis
    IdentityFile ~/.ssh/id_ed25519_jarvis

# Then: ssh cortex
```

## ✅ Verify

```bash
hostname  # Should output: cortex
whoami    # Should output: jarvis
sudo systemctl status fail2ban auditd sshd
```

## 🚨 Troubleshooting

**Can't connect?**
- Check: `ping <CORTEX_IP>` (is it reachable?)
- Check: `ssh -v -i ~/.ssh/id_ed25519_jarvis jarvis@<CORTEX_IP>` (verbose mode)
- Check: `ssh-add -l` (is key loaded?)
- Ensure you're on local network (192.168.x.x, 10.x.x.x, or 172.16.x.x)

**Permission denied?**
- Load key: `ssh-add ~/.ssh/id_ed25519_jarvis`
- Fix permissions: `chmod 600 ~/.ssh/id_ed25519_jarvis`

## 📚 Reference

See [Cortex README](README.md) for full documentation.
