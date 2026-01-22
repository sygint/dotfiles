# NixOS Bootstrap & Deployment

**Complete guide to bootstrapping and deploying NixOS systems in this fleet.**

**Last Updated:** October 29, 2025

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Bootstrap Workflow](#bootstrap-workflow)
5. [Post-Installation](#post-installation)
6. [Fleet Management](#fleet-management)
7. [Deployment Strategies](#deployment-strategies)
8. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Automated Bootstrap (Recommended)

For first-time installation on bare metal or VM:

```bash
# Enter dev environment
nix-shell devenv.nix

# Run automated bootstrap
./scripts/bootstrap-automated.sh <hostname> <ip-address>

# Example
./scripts/bootstrap-automated.sh cortex 192.168.1.34
```

### Manual Bootstrap Script

For more control over the installation process:

```bash
./scripts/bootstrap-nixos.sh -n <hostname> -d <destination>

# Example with options
./scripts/bootstrap-nixos.sh \
  -n cortex \
  -d cortex.home \
  -u jarvis \
  -k ~/.config/nixos-secrets/keys/liveiso
```

### Available Options

```
REQUIRED:
  -n <hostname>       Hostname (must match flake config)
  -d <destination>    IP address or domain name of target

OPTIONAL:
  -u <user>          Target user (default: jarvis)
  -k <ssh_key>       SSH key for liveiso (default: ~/.config/nixos-secrets/keys/liveiso)
  --port <port>      SSH port (default: 22)
  --debug            Enable bash debug mode
```

---

## Architecture

### Centralized Configuration Pattern

All host configurations use a centralized network topology defined in `fleet-config.nix`:

```nix
# fleet-config.nix - Central source of truth for all hosts
{
  hosts = {
    orion = {
      hostname = "orion";
      ip = "192.168.1.100";
      mac = "00:11:22:33:44:55";
      ssh = {
        user = "syg";
        port = 22;
      };
      wol = {
        enabled = true;
        interface = "enp6s0";
      };
    };
    cortex = {
      hostname = "cortex";
      ip = "192.168.1.34";
      # ... etc
    };
  };
}
```

### System Variables Pattern

Each host has a `systems/<hostname>/variables.nix` file that:
- Imports from centralized `fleet-config.nix`
- Defines machine-specific settings (user preferences, applications, etc.)
- Re-exports fleet config for convenient access

**Example:**

```nix
let
  fleetConfig = import ../../fleet-config.nix;
  thisHost = fleetConfig.hosts.orion;
in
{
  system = {
    hostName = thisHost.hostname;
  };

  user = {
    username = "syg";
    # ... user preferences
  };

  # Re-export network config
  network = thisHost;
}
```

### Why This Approach?

This bootstrap pattern (based on EmergentMind's approach) provides:

1. **Clean slate**: Fresh install ensures no legacy config issues
2. **Trust from start**: `trusted-users` configured before first boot
3. **Automated keys**: SSH host keys generated and managed by script
4. **Secrets ready**: Age keys prepared for sops-nix integration
5. **Reproducible**: Same process for any new host

---

## Prerequisites

### Target Machine Requirements

1. **Boot into the custom liveiso** (located in `systems/custom-live-iso/`)
   - SSH enabled for root
   - Your public key authorized for root login
   - Network connectivity working (DHCP)

2. **Know the target's IP or hostname**
   - Use `ip a` on the target if needed
   - Ensure DNS resolution works (e.g., `cortex.home`)

### Source Machine Requirements

1. **This nix-config repository** cloned and up to date
2. **nix-secrets repository** at `../nixos-secrets` (optional but recommended)
3. **SSH key for liveiso access** at `~/.config/nixos-secrets/keys/liveiso`
4. **Target host configuration** in `systems/<hostname>/`
   - `default.nix` - Main configuration
   - `disk-config.nix` - Disko disk partitioning config
   - `variables.nix` - System/user variables

### Required Tools

All tools are available in the dev environment:

```bash
nix-shell devenv.nix
```

This provides:
- `nixos-anywhere` - Remote NixOS installation
- `sops` - Secrets management
- `ssh-to-age` - Age key extraction from SSH keys
- `deploy-rs` - Declarative deployment tool
- `jq` - JSON processing
- `yq` - YAML processing

### Critical Configuration Requirements

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

---

## Bootstrap Workflow

### Automated Bootstrap Script

The `bootstrap-automated.sh` script handles the complete deployment:

**Phase 0: Validation**
- ✅ Checks all required tools are available
- ✅ Verifies host configuration exists
- ✅ Validates secrets directory
- ✅ Loads host variables from Nix config

**Phase 1: NixOS Installation**
- ✅ Installs base NixOS via `nixos-anywhere`
- ✅ Waits for system to stabilize
- ✅ Verifies SSH connectivity

**Phase 2: Secrets Configuration**
- ✅ Extracts age key from host SSH key
- ✅ Detects re-bootstrap scenarios (existing age keys)
- ✅ Updates `.sops.yaml` with new host
- ✅ Rekeys all secrets for all hosts
- ✅ Saves age key to `nixos-secrets/keys/hosts/<hostname>.txt`

**Phase 3: Full Deployment**
- ✅ Deploys complete configuration via `deploy-rs`
- ✅ Includes all secrets and services

**Phase 4: Validation**
- ✅ Tests SSH connectivity with deployed user
- ✅ Verifies secrets decryption service

### Manual Bootstrap Script Steps

The `bootstrap-nixos.sh` script will guide you through:

#### 1. Pre-flight Checks

The script will:
- Verify SSH connectivity to the liveiso
- Check that required files exist
- Display a summary of the installation parameters

**Prompt:** "Proceed with installation?"

#### 2. nixos-anywhere Installation

The script will:
- Generate new SSH host keys for the target
- Clear old SSH host keys from known_hosts
- Run nixos-anywhere to:
  - Format disks according to `disk-config.nix`
  - Install NixOS with your configuration
  - Copy SSH host keys to the target
- The target will automatically reboot

**Prompt:** "Run nixos-anywhere installation?"

⚠️ **WARNING: This step will WIPE ALL DATA on the target disk!**

#### 3. Post-Reboot Verification

After the target reboots:
- The script will wait for the system to come back online
- It will verify SSH connectivity as the target user (not root)
- It will add the new SSH host fingerprint to known_hosts

**Prompt:** "Has the system restarted? Ready to continue?"

#### 4. Age Key Generation

For secrets management with sops-nix:
- The script will generate an age key from the SSH host key
- The key will be saved to `../nixos-secrets/keys/hosts/<hostname>.txt`
- You'll need to manually add this key to `secrets.yaml` and rekey

**Prompt:** "Generate age keys for secrets management?"

### Re-Bootstrap Scenario

If you're re-bootstrapping an existing host:
- ✅ The script detects the existing age key
- ✅ Compares it with the newly extracted key
- ✅ If they match: seamless re-bootstrap
- ⚠️ If they don't match: prompts for action (key regeneration detected)

---

## Post-Installation

### 1. Configure Secrets (if using sops-nix)

If this was a **new host**:

```bash
# Commit the new age key to secrets repo
cd ../nixos-secrets
git add keys/hosts/<hostname>.txt .sops.yaml
git commit -m 'feat: add age key for <hostname>'
git push

# Or manually add to secrets.yaml
sops secrets.yaml

# Find the public key that was generated
cat keys/hosts/<hostname>.txt

# Add it to the creation_rules for your secrets
# Then rekey all secrets
sops updatekeys secrets.yaml
```

### 2. Test Deployment

```bash
# From nix-config root
just deploy-<hostname>

# Example
just deploy-cortex
```

### 3. Verify System

SSH into the new system:

```bash
ssh jarvis@cortex.home

# Verify the configuration
nixos-version
systemctl status

# Check secrets are decrypted
systemctl status sops-nix
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
cd ../nixos-secrets
sops secrets.yaml
```

Deploy again to apply:

```bash
just deploy-<hostname>
```

---

## Fleet Management

### Using the Fleet Script

The `fleet.sh` script auto-loads host configuration from your Nix config:

```bash
# List all systems
./scripts/fleet.sh list

# Build a system locally
./scripts/fleet.sh build orion

# Check system health (auto-loads IP and user from config)
./scripts/fleet.sh check orion

# Deploy updates (via deploy-rs)
./scripts/fleet.sh update orion
```

### Wake-on-LAN

If configured in `fleet-config.nix`:

```bash
# Wake a sleeping host
just wake-orion
# or
just wake-cortex
```

---

## Deployment Strategies

### Initial Deployment (Bootstrap)

Use `bootstrap-automated.sh` for first-time installation on bare metal or VM.

**Best for:**
- New machines
- Clean installs
- Reformatting existing machines

### Incremental Updates

After bootstrap, use `deploy-rs` for updates:

```bash
# Via justfile (recommended)
just deploy-orion
just deploy-cortex

# Or via fleet script
./scripts/fleet.sh update orion

# Or directly
deploy --targets ".#orion"
```

**Best for:**
- Configuration updates
- Package upgrades
- Daily/weekly maintenance

### Local Testing

Build and test locally before deployment:

```bash
# Build the system
nixos-rebuild build --flake .#orion

# Test changes (doesn't set as default)
nixos-rebuild test --flake .#orion

# Switch (makes it the default boot option)
nixos-rebuild switch --flake .#orion
```

**Best for:**
- Testing on the current machine
- Debugging configuration issues
- Rapid iteration

---

## Troubleshooting

### Bootstrap Fails at Tool Check

**Problem:** Required tools not found

**Solution:**
```bash
# Enter the dev shell first
nix-shell devenv.nix
./scripts/bootstrap-automated.sh <hostname> <ip>
```

### SSH Connection Fails

**Problem:** Cannot connect to liveiso

**Solutions:**
1. Verify target is booted into liveiso (check monitor/TTY)
2. Check network: `ping cortex.home` from source
3. Verify SSH key: `ssh -i ~/.config/nixos-secrets/keys/liveiso root@cortex.home`
4. Check liveiso has your public key in authorized_keys

### Can't Extract Age Key

**Problem:** Age key extraction fails

**Solutions:**

Ensure the target host:
- Has SSH running
- Has an ed25519 host key
- Is reachable at the specified IP

```bash
# Verify SSH host key exists
ssh target-host "ls -l /etc/ssh/ssh_host_ed25519_key"
```

### nixos-anywhere Fails

**Problem:** Installation fails during formatting or installation

**Solutions:**
1. Check disk configuration in `systems/<hostname>/disk-config.nix`
2. Verify disk exists: `ssh root@<target> lsblk`
3. Try with `--debug` flag for verbose output
4. Check nix-config flake builds:
   ```bash
   nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel
   ```

### Trust/Signature Errors After Install

**Problem:** Deploy-rs fails with "lacks a signature by a trusted key"

**Solutions:**
1. Verify `trusted-users = [ "root" "@wheel" ]` is in base config
2. Verify target user is in wheel group
3. This should NOT happen with fresh bootstrap install
4. If it does, the config is incorrect - review `modules/system/base/default.nix`

### Secrets Won't Decrypt

**Problem:** Secrets decryption fails on target

**Solutions:**

1. Verify age key is in `.sops.yaml`:
   ```bash
   grep "<hostname>" ../nixos-secrets/.sops.yaml
   ```

2. Rekey secrets:
   ```bash
   cd ../nixos-secrets
   sops updatekeys secrets.yaml
   ```

3. Redeploy:
   ```bash
   deploy --targets ".#<hostname>"
   ```

### Deploy-rs Connection Issues

**Problem:** Deploy-rs can't connect

**Solutions:**

Check SSH connectivity manually:
```bash
ssh <user>@<ip> "echo 'SSH OK'"
```

Verify SSH keys are loaded:
```bash
ssh-add -l
```

### System Won't Boot After Install

**Problem:** System doesn't come back up after reboot

**Solutions:**
1. Check physical console/TTY for errors
2. May need to adjust boot configuration
3. Check `disk-config.nix` matches actual hardware
4. Verify UEFI boot is enabled in BIOS

---

## Best Practices

### Before Bootstrap

1. **Prepare the target machine**
   - Boot from NixOS LiveISO (custom liveiso from `systems/custom-live-iso/`)
   - Ensure network connectivity
   - Note the IP address

2. **Configure the host**
   - Add entry to `fleet-config.nix`
   - Create `systems/<hostname>/` directory with configuration
   - Create `systems/<hostname>/variables.nix`
   - Create `systems/<hostname>/disk-config.nix`

3. **Test the configuration**
   ```bash
   nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel
   ```

### During Bootstrap

- ✅ Review the configuration summary before confirming
- ✅ Monitor the output for any errors
- ⚠️ Don't interrupt during disk partitioning

### After Bootstrap

1. ✅ Test SSH connectivity
2. ✅ Verify services are running
3. ✅ Check secrets decryption
4. ✅ Commit age keys to secrets repo
5. ✅ Document any issues or customizations

### Regular Maintenance

- ✅ Keep secrets repo up to date
- ✅ Regularly rekey secrets when adding/removing hosts
- ✅ Test deployments on non-critical hosts first
- ✅ Use version control for all changes

---

## Custom LiveISO

The custom liveiso is configured in `systems/custom-live-iso/flake.nix`:

**Features:**
- ✅ Enables SSH for root
- ✅ Disables password authentication (keys only)
- ✅ Pre-configures your SSH public key
- ✅ Includes essential tools (vim, git, curl, htop)
- ✅ Uses DHCP for networking

**To rebuild the liveiso:**

```bash
cd systems/custom-live-iso
nix build .#nixosConfigurations.installer.config.system.build.isoImage
```

The ISO will be in `result/iso/`.

---

## Integration with CI/CD

The centralized config pattern makes it easy to:
- ✅ Validate all host configs in CI
- ✅ Auto-deploy on merge to main
- ✅ Run security audits on secrets
- ✅ Generate documentation from config

**Example CI check:**

```bash
# Validate all host configurations
for host in $(nix eval .#nixosConfigurations --apply 'builtins.attrNames' --json | jq -r '.[]'); do
  nix build .#nixosConfigurations.$host.config.system.build.toplevel
done
```

---

## Next Steps

- [ ] Set up router-level DNS for `.local` hostnames
- [ ] Configure automated health checks
- [ ] Implement backup/restore workflow
- [ ] Add monitoring and alerting
- [ ] Document per-host customizations

---

## Resources

### Documentation
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
- [deploy-rs](https://github.com/serokell/deploy-rs)
- [disko](https://github.com/nix-community/disko)

### Related Docs
- [SECRETS.md](../SECRETS.md) - Secrets management guide
- [FLEET-MANAGEMENT.md](../FLEET-MANAGEMENT.md) - Multi-system deployment
- [PROJECT-OVERVIEW.md](PROJECT-OVERVIEW.md) - Overall architecture

### EmergentMind's Approach
- [nix-config repository](https://github.com/EmergentMind/nix-config)
- [Bootstrap script](https://github.com/EmergentMind/nix-config/blob/main/scripts/bootstrap-nixos.sh)
- [Remote installation blog post](https://unmovedcentre.com/posts/remote-install-nixos-config/)

---

**Last Updated:** January 22, 2026
**Pattern Source:** EmergentMind's nix-config  
**Status:** Active deployment method for all fleet systems
