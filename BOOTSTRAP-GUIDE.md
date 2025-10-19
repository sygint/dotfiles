# NixOS Bootstrap & Deployment Guide

## Overview

This guide covers the automated bootstrap and deployment workflow for NixOS hosts in this fleet. The system uses a centralized configuration pattern with integrated secrets management.

## Architecture

### Centralized Configuration Pattern

All host configurations use a centralized network topology defined in `network-config.nix`:

```nix
# network-config.nix - Central source of truth for all hosts
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
- Imports from centralized `network-config.nix`
- Defines machine-specific settings (user preferences, applications, etc.)
- Re-exports network config for convenient access

Example:
```nix
let
  networkConfig = import ../../network-config.nix;
  thisHost = networkConfig.hosts.orion;
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

## Prerequisites

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

### SSH Keys

1. **LiveISO Key**: Required for initial bootstrap
   - Location: `systems/custom-live-iso/keys/liveiso`
   - Used to SSH into the target machine during bootstrap

2. **Host SSH Keys**: Generated automatically during bootstrap
   - Converted to age keys for secrets encryption

## Bootstrap Workflow

### Automated Bootstrap

The fully automated bootstrap script handles the complete deployment:

```bash
./scripts/bootstrap-automated.sh <hostname> <ip-address>
```

Example:
```bash
./scripts/bootstrap-automated.sh cortex 192.168.1.34
```

### What the Script Does

**Phase 0: Validation**
- Checks all required tools are available
- Verifies host configuration exists
- Validates secrets directory
- Loads host variables from Nix config

**Phase 1: NixOS Installation**
- Installs base NixOS via `nixos-anywhere`
- Waits for system to stabilize
- Verifies SSH connectivity

**Phase 2: Secrets Configuration**
- Extracts age key from host SSH key
- Detects re-bootstrap scenarios (existing age keys)
- Updates `.sops.yaml` with new host
- Rekeys all secrets for all hosts
- Saves age key to `nixos-secrets/keys/hosts/<hostname>.txt`

**Phase 3: Full Deployment**
- Deploys complete configuration via `deploy-rs`
- Includes all secrets and services

**Phase 4: Validation**
- Tests SSH connectivity with deployed user
- Verifies secrets decryption service

### Re-Bootstrap Scenario

If you're re-bootstrapping an existing host:
- The script detects the existing age key
- Compares it with the newly extracted key
- If they match: seamless re-bootstrap
- If they don't match: prompts for action (key regeneration detected)

### Manual Steps After Bootstrap

If this was a **new host**:

```bash
# Commit the new age key to secrets repo
cd ../nixos-secrets
git add keys/hosts/<hostname>.txt .sops.yaml
git commit -m 'feat: add age key for <hostname>'
git push
```

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

If configured in `network-config.nix`:

```bash
# Wake a sleeping host
just wake-orion
# or
just wake-cortex
```

## Secrets Management

### Structure

```
nixos-secrets/
├── .sops.yaml          # SOPS configuration with age keys
├── secrets.yaml        # Encrypted secrets
└── keys/
    └── hosts/
        ├── orion.txt   # Age public key for orion
        └── cortex.txt  # Age public key for cortex
```

### Adding a New Secret

1. Edit the encrypted secrets file:
```bash
cd ../nixos-secrets
sops secrets.yaml
```

2. Add your secret in YAML format:
```yaml
myservice:
  api_key: "secret-value-here"
```

3. The secret is automatically encrypted for all hosts listed in `.sops.yaml`

### Rekeying After Adding a Host

When you add a new host via the bootstrap script, secrets are automatically rekeyed. To manually rekey:

```bash
cd ../nixos-secrets
sops updatekeys secrets.yaml
```

## Deployment Strategies

### Initial Deployment (Bootstrap)

Use `bootstrap-automated.sh` for first-time installation on bare metal or VM.

### Incremental Updates

After bootstrap, use `deploy-rs` for updates:

```bash
# Via justfile (recommended)
just deploy-orion

# Or via fleet script
./scripts/fleet.sh update orion

# Or directly
deploy --targets ".#orion"
```

### Local Testing

Build and test locally before deployment:

```bash
# Build the system
nixos-rebuild build --flake .#orion

# Test changes
nixos-rebuild test --flake .#orion

# Switch (makes it the default boot option)
nixos-rebuild switch --flake .#orion
```

## Troubleshooting

### Bootstrap Fails at Tool Check

Enter the dev shell first:
```bash
nix-shell devenv.nix
./scripts/bootstrap-automated.sh <hostname> <ip>
```

### Can't Extract Age Key

Ensure the target host:
- Has SSH running
- Has an ed25519 host key
- Is reachable at the specified IP

### Secrets Won't Decrypt

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

Check SSH connectivity manually:
```bash
ssh <user>@<ip> "echo 'SSH OK'"
```

Verify SSH keys are loaded:
```bash
ssh-add -l
```

## Best Practices

### Before Bootstrap

1. **Prepare the target machine**
   - Boot from NixOS LiveISO
   - Ensure network connectivity
   - Note the IP address

2. **Configure the host**
   - Add entry to `network-config.nix`
   - Create `systems/<hostname>/` directory with configuration
   - Create `systems/<hostname>/variables.nix`

3. **Test the configuration**
   ```bash
   nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel
   ```

### During Bootstrap

- Review the configuration summary before confirming
- Monitor the output for any errors
- Don't interrupt during disk partitioning

### After Bootstrap

1. Test SSH connectivity
2. Verify services are running
3. Check secrets decryption
4. Commit age keys to secrets repo
5. Document any issues or customizations

### Regular Maintenance

- Keep secrets repo up to date
- Regularly rekey secrets when adding/removing hosts
- Test deployments on non-critical hosts first
- Use version control for all changes

## Integration with CI/CD

The centralized config pattern makes it easy to:
- Validate all host configs in CI
- Auto-deploy on merge to main
- Run security audits on secrets
- Generate documentation from config

Example CI check:
```bash
# Validate all host configurations
for host in $(nix eval .#nixosConfigurations --apply 'builtins.attrNames' --json | jq -r '.[]'); do
  nix build .#nixosConfigurations.$host.config.system.build.toplevel
done
```

## Next Steps

- [ ] Set up router-level DNS for `.local` hostnames
- [ ] Configure automated health checks
- [ ] Implement backup/restore workflow
- [ ] Add monitoring and alerting
- [ ] Document per-host customizations

## References

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
- [deploy-rs](https://github.com/serokell/deploy-rs)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [SOPS](https://github.com/mozilla/sops)
