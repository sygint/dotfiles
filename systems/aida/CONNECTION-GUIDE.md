# AIDA Connection Setup & Verification Guide

**📍 Network**: Check `systems/aida/variables.nix` for the current IP address. Set up a DHCP reservation on your router for consistent access.

## 🔑 SSH Access

**Key**: `~/.ssh/id_ed25519_jarvis` (jarvis@aida)  
**User**: `jarvis`  
**Auth**: SSH key only (password authentication disabled)  
**Network**: Local networks only (192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12)

## 📋 Quick Start

1. **Load SSH key**: `ssh-add ~/.ssh/id_ed25519_jarvis`
2. **Set DHCP reservation** on router for AIDA's MAC address
3. **Deploy**: See deployment options below

## 🚀 Deployment

```bash
# Fresh install (check variables.nix for IP)
./scripts/deploy-aida.sh <AIDA_IP> nixos

# Update existing system
./scripts/deploy-aida-enhanced.sh <AIDA_IP> jarvis

# Manual deployment
nixos-rebuild switch --flake .#aida --target-host jarvis@<AIDA_IP> --use-remote-sudo
```

## 🔍 Connect

```bash
# Direct connection
ssh -i ~/.ssh/id_ed25519_jarvis jarvis@<AIDA_IP>

# Or add to ~/.ssh/config:
Host aida
    HostName <AIDA_IP>  # or aida.local once router DNS is configured
    User jarvis
    IdentityFile ~/.ssh/id_ed25519_jarvis

# Then: ssh aida
```

## ✅ Verify

```bash
hostname  # Should output: aida
whoami    # Should output: jarvis
sudo systemctl status fail2ban auditd sshd
```

## 🚨 Troubleshooting

**Can't connect?**
- Check: `ping <AIDA_IP>` (is it reachable?)
- Check: `ssh -v -i ~/.ssh/id_ed25519_jarvis jarvis@<AIDA_IP>` (verbose mode)
- Check: `ssh-add -l` (is key loaded?)
- Ensure you're on local network (192.168.x.x, 10.x.x.x, or 172.16.x.x)

**Permission denied?**
- Load key: `ssh-add ~/.ssh/id_ed25519_jarvis`
- Fix permissions: `chmod 600 ~/.ssh/id_ed25519_jarvis`

## 📚 Reference

See [AIDA README](README.md) for full documentation.
