# NixOS Bootstrap Installation

This document explains how to install NixOS on a target machine using the `bootstrap-nixos.sh` script.

## Overview

The bootstrap script automates the process of:
1. Installing NixOS on a target machine via `nixos-anywhere`
2. Setting up SSH host keys
3. Generating age keys for secrets management
4. Preparing the system for remote deployments with `deploy-rs`

This approach is based on [EmergentMind's bootstrap pattern](https://github.com/EmergentMind/nix-config).

## Prerequisites

### On the Target Machine

1. **Boot into the custom liveiso** (located in `systems/custom-live-iso/`)
   - The liveiso must have SSH enabled for root
   - The liveiso must have your public key authorized for root login
   - Network connectivity must be working (DHCP)

2. **Know the target's IP or hostname**
   - Use `ip a` on the target if needed
   - Ensure DNS resolution works (e.g., `cortex.home`)

### On the Source Machine (where you run the script)

1. **This nix-config repository** cloned and up to date
2. **nix-secrets repository** at `../nixos-secrets` (optional but recommended)
3. **SSH key for liveiso access** at `~/.config/nixos-secrets/keys/liveiso`
4. **Target host configuration** in `systems/<hostname>/`
   - `default.nix` - Main configuration
   - `disk-config.nix` - Disko disk partitioning config

### Important Configuration Requirements

Your target host configuration MUST include:

```nix
# In systems/<hostname>/default.nix or modules/system/base/default.nix
nix.settings = {
  experimental-features = [ "nix-command" "flakes" ];
  trusted-users = [ "root" "@wheel" ];  # Critical for deploy-rs
};

# User must be in wheel group
users.users.<username> = {
  isNormalUser = true;
  extraGroups = [ "wheel" "networkmanager" ];
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA... your-key"
  ];
};
```

## Usage

### Basic Installation

From the root of the nix-config repository:

```bash
./scripts/bootstrap-nixos.sh -n <hostname> -d <destination>
```

**Example:**
```bash
./scripts/bootstrap-nixos.sh -n cortex -d cortex.home
```

### With Options

```bash
./scripts/bootstrap-nixos.sh \
  -n cortex \
  -d 192.168.1.7 \
  -u jarvis \
  -k ~/.config/nixos-secrets/keys/liveiso \
  --port 22
```

### Available Options

```
REQUIRED:
  -n <hostname>       Hostname of the target machine (must match flake config)
  -d <destination>    IP address or domain name of target

OPTIONAL:
  -u <user>          Target user (default: jarvis)
  -k <ssh_key>       SSH key for liveiso (default: ~/.config/nixos-secrets/keys/liveiso)
  --port <port>      SSH port (default: 22)
  --impermanence     Use /persist for impermanence (not currently used)
  --debug            Enable bash debug mode
  -h | --help        Show help message
```

## Installation Steps

The script will guide you through the following steps:

### 1. Pre-flight Checks

The script will:
- Verify SSH connectivity to the liveiso
- Check that required files exist
- Display a summary of the installation parameters

You'll be prompted: **"Proceed with installation?"**

### 2. nixos-anywhere Installation

The script will:
- Generate new SSH host keys for the target
- Clear old SSH host keys from known_hosts
- Run nixos-anywhere to:
  - Format disks according to `disk-config.nix`
  - Install NixOS with your configuration
  - Copy SSH host keys to the target
- The target will automatically reboot

You'll be prompted: **"Run nixos-anywhere installation?"**

**This step will WIPE ALL DATA on the target disk!**

### 3. Post-Reboot Verification

After the target reboots:
- The script will wait for the system to come back online
- It will verify SSH connectivity as the target user (not root)
- It will add the new SSH host fingerprint to known_hosts

You'll be prompted: **"Has the system restarted? Ready to continue?"**

### 4. Age Key Generation

For secrets management with sops-nix:
- The script will generate an age key from the SSH host key
- The key will be saved to `../nixos-secrets/keys/hosts/<hostname>.txt`
- You'll need to manually add this key to `secrets.yaml` and rekey

You'll be prompted: **"Generate age keys for secrets management?"**

## Post-Installation Steps

### 1. Configure Secrets (if using sops-nix)

```bash
cd ../nixos-secrets

# Add the new host's age key to secrets.yaml recipients
sops secrets.yaml

# Find the public key that was generated
cat keys/hosts/<hostname>.txt

# Add it to the creation_rules for your secrets
# Then rekey all secrets
sops updatekeys secrets.yaml

# Commit the new host key
git add keys/hosts/<hostname>.txt
git commit -m "Add age key for <hostname>"
git push
```

### 2. Test Deployment

```bash
# From nix-config root
just deploy-<hostname>
```

If using cortex as an example:
```bash
just deploy-cortex
```

### 3. Verify System

SSH into the new system:
```bash
ssh jarvis@cortex.home
```

Verify the configuration:
```bash
nixos-version
systemctl status
```

### 4. Re-enable Password Security (Important!)

After the first successful deployment, update the target's configuration:

```nix
# In systems/<hostname>/default.nix
security.sudo.wheelNeedsPassword = true;  # Change back to true
```

Then set the user's password via secrets:
```bash
# Generate password hash
mkpasswd -m sha-512

# Add to secrets.yaml in nix-secrets
```

Deploy again to apply:
```bash
just deploy-<hostname>
```

## Troubleshooting

### SSH Connection Fails

**Problem:** Cannot connect to liveiso

**Solutions:**
1. Verify target is booted into liveiso (check monitor/TTY)
2. Check network: `ping cortex.home` from source
3. Verify SSH key: `ssh -i ~/.config/nixos-secrets/keys/liveiso root@cortex.home`
4. Check liveiso has your public key in authorized_keys

### nixos-anywhere Fails

**Problem:** Installation fails during formatting or installation

**Solutions:**
1. Check disk configuration in `systems/<hostname>/disk-config.nix`
2. Verify disk exists: `ssh root@<target> lsblk`
3. Try with `--debug` flag for verbose output
4. Check nix-config flake builds: `nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel`

### Trust/Signature Errors After Install

**Problem:** Deploy-rs fails with "lacks a signature by a trusted key"

**Solutions:**
1. Verify `trusted-users = [ "root" "@wheel" ]` is in base config
2. Verify target user is in wheel group
3. This should NOT happen with fresh bootstrap install
4. If it does, the config is incorrect - review base/default.nix

### System Won't Boot After Install

**Problem:** System doesn't come back up after reboot

**Solutions:**
1. Check physical console/TTY for errors
2. May need to adjust boot configuration
3. Check disk-config.nix matches actual hardware
4. Verify UEFI boot is enabled in BIOS

## Architecture Notes

### Why This Approach?

This bootstrap script follows EmergentMind's pattern because:

1. **Clean slate**: Fresh install ensures no legacy config issues
2. **Trust from start**: `trusted-users` configured before first boot
3. **Automated keys**: SSH host keys generated and managed by script
4. **Secrets ready**: Age keys prepared for sops-nix integration
5. **Reproducible**: Same process for any new host

### Differences from Manual Install

**Manual install problems:**
- Often leaves inconsistent permissions
- Hard to track what was done
- Easy to forget critical settings like trusted-users
- No automated SSH key management

**Bootstrap script benefits:**
- Fully automated and reproducible
- Consistent across all hosts
- Documents the process
- Generates required keys
- Verifies connectivity at each step

### Integration with deploy-rs

After bootstrap:
1. System has `trusted-users = ["@wheel"]` from start
2. Target user is in wheel group
3. SSH keys are authorized
4. deploy-rs can push unsigned paths without sudo password
5. No chicken-and-egg trust issues

## Custom LiveISO

The custom liveiso is configured in `systems/custom-live-iso/flake.nix`:

- Enables SSH for root
- Disables password authentication (keys only)
- Pre-configures your SSH public key
- Includes essential tools (vim, git, curl, htop)
- Uses DHCP for networking

To rebuild the liveiso:
```bash
cd systems/custom-live-iso
nix build .#nixosConfigurations.installer.config.system.build.isoImage
```

The ISO will be in `result/iso/`.

## References

- [EmergentMind's nix-config](https://github.com/EmergentMind/nix-config)
- [EmergentMind's bootstrap script](https://github.com/EmergentMind/nix-config/blob/main/scripts/bootstrap-nixos.sh)
- [EmergentMind's blog post on remote installation](https://unmovedcentre.com/posts/remote-install-nixos-config/)
- [nixos-anywhere documentation](https://github.com/nix-community/nixos-anywhere)
- [disko documentation](https://github.com/nix-community/disko)

## Support

For issues:
1. Check troubleshooting section above
2. Review EmergentMind's documentation
3. Check nixos-anywhere issues on GitHub
4. Verify your host configuration builds: `nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel`
