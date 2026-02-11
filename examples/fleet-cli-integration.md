# Fleet CLI Integration

This document explains how to use the `fleet` CLI for automated NixOS deployments.

## Overview

The fleet CLI (`nixos-fleet`) replaces direct deploy-rs usage with a unified interface that wraps Colmena for parallel deployments, nixos-anywhere for fresh installs, and sops-nix for secrets management.

## Prerequisites

The fleet CLI is available via the nixos-fleet flake overlay. It should already be in your system packages on Orion:

```nix
# In systems/orion/default.nix or flake devShell
environment.systemPackages = [
  inputs.nixos-fleet.packages.${system}.fleet
];
```

Or run directly:
```bash
nix run ~/Projects/open-source/nixos-fleet#fleet -- <command>
```

## Usage

### Deploy Updates to a Host

```bash
# Deploy to a single host
fleet push cortex

# Deploy to multiple hosts by tag
fleet push --tag servers

# Deploy without auto-syncing secrets first
fleet push cortex --no-sync
```

### Fresh Install (nixos-anywhere)

```bash
# Install NixOS on a new machine
fleet install nexus

# Or manually with nixos-anywhere:
nix run github:nix-community/nixos-anywhere -- --flake .#nexus root@<ip>
```

### Health Checks

```bash
# Check a host's status
fleet check cortex

# Check all hosts
fleet check all
```

### Secrets Management

```bash
# Sync secrets before deployment (automatic with fleet push)
fleet sync

# Rekey all secrets after adding a new host
fleet rekey
```

### ISO Generation

```bash
# Generate installer ISO
fleet iso
```

## Configuration

Fleet configuration lives in `fleet-config.nix` at the repo root. This is the single source of truth for host IPs, SSH users, tags, and network settings.

```nix
# fleet-config.nix
{
  network = {
    domain = "home";
    subnet = "192.168.1.0/24";
  };

  hosts = {
    orion = {
      ip = "...";
      tags = [ "workstation" "local" ];
    };
    cortex = {
      ip = "192.168.1.7";
      tags = [ "server" "ai" "remote" ];
    };
    nexus = {
      ip = "192.168.1.22";
      tags = [ "server" "homelab" "remote" ];
    };
    axon = {
      ip = "192.168.1.11";
      tags = [ "media" "local" ];
    };
  };
}
```

## SSH Configuration

Ensure you have SSH access to the target system:

```bash
# Test SSH connection
ssh jarvis@cortex.local

# Or with IP
ssh jarvis@192.168.1.7
```

For remote deployments, the deploy user needs passwordless sudo:

```nix
# Configured automatically by fleet-deploy-user module
security.sudo.wheelNeedsPassword = false;
```

## Troubleshooting

### Connection Issues

If deployment fails to connect:
- Verify SSH access works manually
- Check firewall rules on target system
- Ensure the hostname resolves correctly
- Check `fleet-config.nix` has the correct IP

### Build Failures

If builds fail:
- Check available disk space on the target
- Review error messages in the deployment output
- Try building locally first: `nix build .#nixosConfigurations.cortex.config.system.build.toplevel`

### Secrets Sync Failures

If secrets fail to sync:
- Ensure the secrets submodule is up to date: `git -C ../nixos-secrets pull`
- Check age keys exist for the target host in `nixos-secrets/keys/hosts/`
- Try manual sync: `fleet sync`

## Alternative: Manual Deployment with nixos-rebuild

If the fleet CLI is unavailable, you can deploy manually:

```bash
# Build configuration locally
nix build .#nixosConfigurations.cortex.config.system.build.toplevel

# Deploy with nixos-rebuild
nixos-rebuild switch --flake .#cortex --target-host jarvis@cortex.local --use-remote-sudo
```

## See Also

- [nixos-fleet source](https://github.com/sygint/nixos-fleet)
- [fleet-config.nix](../fleet-config.nix) - Host configuration
- [SECRETS.md](../SECRETS.md) - Secrets management guide
- [NixOS Manual - Remote Builds](https://nixos.org/manual/nix/stable/advanced-topics/distributed-builds.html)
