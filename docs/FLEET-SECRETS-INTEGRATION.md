# Fleet & Secrets Management Integration

**Unified workflow for deploying NixOS systems with encrypted secrets**

## Overview

The fleet management system now includes integrated secrets management, combining deployment automation with encrypted secrets handling through sops-nix.

## Architecture

```
fleet.sh (Deployment)
    │
    ├─→ secrets-manager.sh (Secrets)
    │       │
    │       └─→ sops + age (Encryption)
    │               │
    │               └─→ nixos-secrets/ (Private Repo)
    │
    └─→ deploy-rs / nixos-anywhere
            │
            └─→ Target Systems (with sops-nix)
```

## Quick Commands

### Secrets Management via Fleet

```bash
# View configuration
./scripts/deployment/fleet.sh secrets config

# Edit secrets
./scripts/deployment/fleet.sh secrets edit

# Validate encryption
./scripts/deployment/fleet.sh secrets validate

# Add system password
./scripts/deployment/fleet.sh secrets add-host nexus

# Rotate password
./scripts/deployment/fleet.sh secrets rotate nexus

# Check status
./scripts/deployment/fleet.sh secrets status
```

### Deployment with Secrets

```bash
# Deploy new system with secrets validation
./scripts/deployment/fleet.sh deploy nexus --validate-secrets

# Update existing system with secrets validation
./scripts/deployment/fleet.sh update nexus --validate-secrets
```

## Typical Workflow

### 1. Add New System with Secrets

```bash
# Create system configuration
mkdir -p systems/newsystem

# Add secrets for the system
./scripts/deployment/fleet.sh secrets add-host newsystem
# Enter password or generate random

# Commit secrets
cd ~/.config/nixos-secrets
git add secrets.yaml
git commit -m "add: newsystem secrets"
git push
```

### 2. Configure System to Use Secrets

Edit `systems/newsystem/default.nix`:

```nix
{ config, pkgs, ... }:
{
  imports = [
    # Import sops-nix module
    ../../nixos-secrets
  ];

  # Configure sops
  sops.secrets.newsystem-maintenance-password = {
    sopsFile = ../../nixos-secrets/secrets.yaml;
  };

  # Use secret in user configuration
  users.users.maintenance = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.newsystem-maintenance-password.path;
    extraGroups = [ "wheel" ];
  };
}
```

### 3. Deploy with Validation

```bash
# Build to validate configuration
./scripts/deployment/fleet.sh build newsystem

# Deploy with secrets validation
./scripts/deployment/fleet.sh deploy newsystem --validate-secrets
```

### 4. Rotate Secrets

```bash
# Rotate password
./scripts/deployment/fleet.sh secrets rotate newsystem

# Commit updated secrets
cd ~/.config/nixos-secrets
git add secrets.yaml
git commit -m "rotate: newsystem password"
git push

# Deploy updated configuration
cd ~/.config/nixos
./scripts/deployment/fleet.sh update newsystem --validate-secrets
```

## How Secrets Validation Works

When you use `--validate-secrets`:

1. **Checks encryption/decryption** - Ensures secrets file is valid
2. **Verifies system has secrets** - Warns if system not in secrets.yaml
3. **Blocks deployment on failure** - Prevents deploying with broken secrets

Example:
```bash
./scripts/deployment/fleet.sh deploy nexus --validate-secrets
# Output:
# ℹ Validating secrets before deployment...
# ✓ ✓ Decryption works
# ✓ ✓ Encryption works
# ✓ Secrets validated for nexus
# ℹ Building nexus configuration...
```

## Integration Points

### In fleet.sh

- `secrets_command()` - Passes through to secrets-manager.sh
- `validate_secrets()` - Validates before deployment
- Updated `deploy_system()` - Accepts `--validate-secrets` flag
- Updated `update_system()` - Accepts `--validate-secrets` flag

### In secrets-manager.sh

- All commands work independently or through fleet.sh
- Auto-detects secrets repository location
- Auto-detects age keys by hostname
- Configurable via environment variables

## Security Model

```
Control Machine (Orion)
├── Private age key (orion.txt)
├── Can decrypt all secrets
└── Can edit secrets

Target Machines (Cortex, Nexus)
├── Private age key (cortex.txt, nexus.txt)
├── Can decrypt only at boot time
├── sops-nix handles decryption
└── Secrets available as read-only files
```

## Benefits

1. **Unified Interface** - Single tool for deployment + secrets
2. **Validation Built-in** - Catch secrets issues before deployment
3. **Clear Workflow** - Documented path from secrets to deployment
4. **Security First** - Never commit unencrypted secrets
5. **Easy Rotation** - Simple commands for password rotation
6. **Fleet-wide Management** - Manage all system secrets in one place

## Related Documentation

- **Fleet Management**: `FLEET-MANAGEMENT.md`
- **Secrets Deep Dive**: `nixos-secrets/SECRETS-MANAGEMENT.md`
- **Security**: `docs/SECURITY.md`
- **Project Overview**: `docs/PROJECT-OVERVIEW.md`

## Troubleshooting

### Secrets validation fails

```bash
# Check secrets directly
./scripts/deployment/fleet.sh secrets validate

# View configuration
./scripts/deployment/fleet.sh secrets config

# Check recipients
./scripts/deployment/fleet.sh secrets recipients
```

### System missing from secrets

```bash
# Add the system
./scripts/deployment/fleet.sh secrets add-host <system>

# Or check if intentional (some systems may not need secrets)
./scripts/deployment/fleet.sh secrets cat | grep <system>
```

### Can't decrypt on target

1. Check age key exists: `/etc/age/keys.txt` (or configured path)
2. Verify key in `.sops.yaml` recipients
3. Re-encrypt secrets: `./scripts/deployment/fleet.sh secrets edit`
4. Check sops-nix configuration in system config

## Examples

See real examples in:
- `systems/nexus/default.nix` - Maintenance user with encrypted password
- `systems/cortex/default.nix` - Service credentials
- `nixos-secrets/secrets.yaml` - Encrypted secrets structure
